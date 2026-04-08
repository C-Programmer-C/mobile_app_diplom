from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from .auth import get_current_user_email
from database.auth import (
    add_product_to_cart_for_user,
    clear_cart_for_user,
    get_cart_items_for_user,
    get_user_by_email,
    remove_cart_item_for_user,
    set_cart_item_quantity_for_user,
)

cart_router = APIRouter(prefix="/cart", tags=["cart"])


class CartItemIn(BaseModel):
    product_id: int
    quantity: int = 1


class CartItemUpdate(BaseModel):
    product_id: int
    quantity: int


@cart_router.post("/add", summary="Add product to cart")
def add_to_cart(data: CartItemIn, user_email: str = Depends(get_current_user_email)):
    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    try:
        row = add_product_to_cart_for_user(user, data.product_id, data.quantity)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    return {"id": row.id, "product_id": row.product_id, "quantity": row.quantity}


@cart_router.get("/", summary="Get cart items")
def get_cart(user_email: str = Depends(get_current_user_email)):
    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    rows = get_cart_items_for_user(user)
    return [{"id": r.id, "product_id": r.product_id, "quantity": r.quantity} for r in rows]


@cart_router.post("/set_quantity", summary="Set cart item quantity")
def set_quantity(
    data: CartItemUpdate, user_email: str = Depends(get_current_user_email)
):
    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    try:
        row = set_cart_item_quantity_for_user(user, data.product_id, data.quantity)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)
        ) from exc
    return {"id": row.id, "product_id": row.product_id, "quantity": row.quantity}


@cart_router.post("/remove", summary="Remove item from cart")
def remove_item(data: CartItemIn, user_email: str = Depends(get_current_user_email)):
    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    remove_cart_item_for_user(user, data.product_id)
    return {"ok": True}


@cart_router.post("/clear", summary="Clear cart")
def clear_cart(user_email: str = Depends(get_current_user_email)):
    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    clear_cart_for_user(user)
    return {"ok": True}

