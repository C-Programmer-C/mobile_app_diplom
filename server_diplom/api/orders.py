from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from .auth import get_current_user_email
from database.auth import (
    cancel_order_for_user,
    create_order_from_cart,
    get_user_by_email,
)


orders_router = APIRouter(prefix="/orders", tags=["orders"])


class CheckoutIn(BaseModel):
    delivery_type_id: int
    city_id: int | None = None
    shipping_address: str
    phone: str
    pickup_point_id: int | None = None
    product_ids: list[int] | None = None


@orders_router.post("/checkout", summary="Create order from cart")
def checkout(data: CheckoutIn, user_email: str = Depends(get_current_user_email)):
    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    try:
        order = create_order_from_cart(
            user=user,
            delivery_type_id=data.delivery_type_id,
            city_id=data.city_id,
            shipping_address=data.shipping_address,
            phone=data.phone,
            pickup_point_id=data.pickup_point_id,
            product_ids=data.product_ids,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    return {
        "id": order.id,
        "status_id": order.status_id,
        "total_amount": float(order.total_amount),
        "created_at": order.created_at,
        "delivery_at": order.delivery_at,
        "delivery_comment": order.delivery_comment,
    }


@orders_router.post("/{order_id}/cancel", summary="Cancel order")
def cancel_order(order_id: int, user_email: str = Depends(get_current_user_email)):
    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    try:
        order = cancel_order_for_user(user, order_id)
    except PermissionError as exc:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    return {"id": order.id, "status_id": order.status_id}


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


@orders_router.get("/me", summary="My orders")
def my_orders(user_email: str = Depends(get_current_user_email)):
    from database.auth import get_orders_for_user_email

    return get_orders_for_user_email(user_email)


@orders_router.get("/{order_id}", summary="Order detail")
def order_detail(order_id: int, user_email: str = Depends(get_current_user_email)):
    from database.auth import get_order_detail_for_user_email

    try:
        return get_order_detail_for_user_email(user_email, order_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc

