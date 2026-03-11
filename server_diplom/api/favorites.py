from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from .auth import get_current_user_email
from database.auth import (
    get_user_by_email,
    get_favorite_product_ids_for_user,
    toggle_favorite_for_user,
)

favorites_router = APIRouter(prefix="/favorites", tags=["favorites"])


class FavoriteIn(BaseModel):
    product_id: int


@favorites_router.get("/", summary="Get favorite product ids")
def get_favorites(user_email: str = Depends(get_current_user_email)) -> List[int]:
    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    return get_favorite_product_ids_for_user(user)


@favorites_router.post("/toggle", summary="Toggle favorite for product")
def toggle_favorite(
    data: FavoriteIn, user_email: str = Depends(get_current_user_email)
):
    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    is_favorite = toggle_favorite_for_user(user, data.product_id)
    return {"is_favorite": is_favorite}

