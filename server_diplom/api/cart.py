from typing import Dict, List

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from .auth import get_current_user_email

cart_router = APIRouter(prefix="/cart", tags=["cart"])


class CartItemIn(BaseModel):
    product_id: int


_cart_storage: Dict[str, List[int]] = {}


@cart_router.post("/add", summary="Add product to cart")
def add_to_cart(data: CartItemIn, user_email: str = Depends(get_current_user_email)):
    user_cart = _cart_storage.setdefault(user_email, [])
    if data.product_id not in user_cart:
        user_cart.append(data.product_id)
    return {"status": "ok"}


@cart_router.get("/", summary="Get cart product ids")
def get_cart(user_email: str = Depends(get_current_user_email)):
    return _cart_storage.get(user_email, [])

