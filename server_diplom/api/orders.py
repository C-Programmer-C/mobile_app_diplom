import re
from datetime import datetime, timezone
from typing import Literal
from threading import Lock

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from .auth import get_current_user_email
from database.auth import (
    cancel_order_for_user,
    create_order_from_cart,
    get_order_detail_by_id,
    get_order_statuses,
    get_order_statuses_for_delivery,
    get_user_by_email,
    get_cart_items_for_user,
    update_order_by_id,
)

orders_router = APIRouter(prefix="/orders", tags=["orders"])

# Per-process locks to avoid concurrent checkouts for the same user
_checkout_locks: dict[int, Lock] = {}


def _card_digits_only(card_pan: str | None) -> str:
    return re.sub(r"\D", "", card_pan or "")


def _card_pan_length_ok(pan: str) -> bool:
    return pan.isdigit() and 13 <= len(pan) <= 19


class CheckoutIn(BaseModel):
    delivery_type_id: int
    city_id: int | None = None
    shipping_address: str
    phone: str
    pickup_point_id: int | None = None
    product_ids: list[int] | None = None
    payment_method: Literal["card", "cash"]
    card_pan: str | None = None


@orders_router.post("/checkout", summary="Create order from cart")
def checkout(data: CheckoutIn, user_email: str = Depends(get_current_user_email)):
    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    
    uid = getattr(user, "id", None)
    if uid is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="invalid user id"
        )

    lock = _checkout_locks.setdefault(uid, Lock())
    if not lock.acquire(blocking=False):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Another checkout in progress for this user",
        )

    try:
        # basic payment parsing
        now = datetime.now(timezone.utc)
        if data.payment_method == "card":
            digits = _card_digits_only(data.card_pan)
            if not _card_pan_length_ok(digits):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Некорректный номер карты (нужно 13–19 цифр)",
                )
            payment_status = "paid"
            paid_at = now
            payment_method = "card"
        else:
            payment_status = "pending"
            paid_at = None
            payment_method = "cash"

        # validate cart contents (no negative/zero quantities and product_ids filter)
        cart_items = get_cart_items_for_user(user)
        if data.product_ids:
            wanted = set(data.product_ids)
            cart_items = [c for c in cart_items if c.product_id in wanted]

        if not cart_items:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="cart is empty"
            )

        for c in cart_items:
            if getattr(c, "quantity", 0) <= 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="invalid cart item quantity",
                )

        try:
            return create_order_from_cart(
                user=user,
                delivery_type_id=data.delivery_type_id,
                city_id=data.city_id,
                shipping_address=data.shipping_address,
                phone=data.phone,
                pickup_point_id=data.pickup_point_id,
                product_ids=data.product_ids,
                payment_method=payment_method,
                payment_status=payment_status,
                paid_at=paid_at,
            )
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)
            ) from exc
    finally:
        try:
            lock.release()
        except RuntimeError:
            pass


@orders_router.post("/{order_id}/cancel", summary="Cancel order")
def cancel_order(order_id: int, user_email: str = Depends(get_current_user_email)):
    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    try:
        return cancel_order_for_user(user, order_id)
    except PermissionError as exc:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail=str(exc)
        ) from exc
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)
        ) from exc


@orders_router.get("/meta/delivery_types", summary="Delivery types")
def delivery_types_meta():
    from database.auth import get_delivery_types

    return get_delivery_types()


@orders_router.get("/meta/cities", summary="Cities")
def cities_meta():
    from database.auth import get_cities

    return get_cities()


@orders_router.get("/meta/pickup_points", summary="Pickup points for city")
def pickup_points_meta(city_id: int):
    from database.auth import get_pickup_points_for_city

    return get_pickup_points_for_city(city_id)


@orders_router.get("/meta/statuses", summary="Order statuses")
def statuses_meta(
    delivery_type_id: int | None = None,
    current_status: str | None = None,
):
    if delivery_type_id is None:
        return get_order_statuses()
    try:
        return get_order_statuses_for_delivery(
            delivery_type_id,
            current_status_value=current_status,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)
        ) from exc


@orders_router.get("/me", summary="My orders")
def my_orders(user_email: str = Depends(get_current_user_email)):
    from database.auth import get_orders_for_user_email

    return get_orders_for_user_email(user_email)


@orders_router.get("/all", summary="All orders (admin/staff)")
def all_orders(user_email: str = Depends(get_current_user_email)):
    from database.auth import get_all_orders

    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    if user.role not in {"admin", "staff"}:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="insufficient permissions",
        )
    return get_all_orders()


@orders_router.get("/{order_id}", summary="Order detail")
def order_detail(order_id: int, user_email: str = Depends(get_current_user_email)):
    from database.auth import get_order_detail_for_user_email

    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    try:
        if user.role in {"admin", "staff"}:
            return get_order_detail_by_id(order_id)
        return get_order_detail_for_user_email(user_email, order_id)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)
        ) from exc


@orders_router.patch("/{order_id}", summary="Update order (admin/staff)")
def patch_order(
    order_id: int, payload: dict, user_email: str = Depends(get_current_user_email)
):
    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    if user.role not in {"admin", "staff"}:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="insufficient permissions"
        )
    try:
        return update_order_by_id(
            order_id=order_id,
            status_id=payload.get("status_id"),
            delivery_type_id=payload.get("delivery_type_id"),
            shipping_address=payload.get("shipping_address"),
            phone=payload.get("phone"),
            city_id=payload.get("city_id"),
            pickup_point_id=payload.get("pickup_point_id"),
            payment_status=payload.get("payment_status"),
            payment_method=payload.get("payment_method"),
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)
        ) from exc
