from typing import Optional

from config import settings
from database.auth import (
    add_review_for_product,
    get_all_products,
    get_detailed_product_by_id,
    get_product_by_id,
    get_product_reviews,
    get_similar_products,
)
from fastapi import APIRouter, Depends, HTTPException, Response, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from models.user import User

product_router = APIRouter(prefix="/products", tags=["Products"])

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def _get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token, settings.JWT_SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        sub = payload.get("sub")
        if sub is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    from database.auth import Session, engine
    from models.user import User as UserModel

    with Session(autoflush=False, bind=engine) as db:
        user = None
        if isinstance(sub, (int, float)) or (isinstance(sub, str) and sub.isdigit()):
            user_id = int(sub)
            user = db.query(UserModel).filter(UserModel.id == user_id).first()
        else:
            user = db.query(UserModel).filter(UserModel.email == str(sub)).first()
        if user is None:
            raise credentials_exception
        return user


@product_router.get("/", summary="Получить список всех товаров")
def read_products():
    products = get_all_products()
    return products


@product_router.get(
    "/public", summary="Получить список всех товаров (публичный доступ)"
)
def read_products_public():
    products = get_all_products()
    return products


@product_router.get("/search", summary="Поиск товаров")
def search_products(q: str):
    from database.auth import search_products as db_search_products

    products = db_search_products(q)
    return products


@product_router.get("/categories", summary="Получить все категории")
def read_categories():
    from database.auth import get_all_categories

    categories = get_all_categories()
    return categories


@product_router.get("/filter", summary="Фильтрация товаров")
def filter_products(
    sort: Optional[str] = None,
    popular: bool = False,
    high_rating: bool = False,
    big_discount: bool = False,
    is_new: bool = False,
    category_id: Optional[int] = None,
):
    from database.auth import filter_products as db_filter_products

    products = db_filter_products(
        sort_by=sort,
        popular=popular,
        high_rating=high_rating,
        big_discount=big_discount,
        is_new=is_new,
        category_id=category_id,
    )
    return products


@product_router.get("/{product_id}", summary="Получить товар по его ID")
def read_product(product_id: int):
    product = get_product_by_id(product_id)
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Product not found"
        )
    return product


@product_router.get(
    "/{product_id}/details", summary="Получить подробную информацию о товаре"
)
def read_product_details(product_id: int):
    product = get_detailed_product_by_id(product_id)
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Product not found"
        )
    return product


@product_router.get("/{product_id}/reviews", summary="Получить отзывы о товаре")
def read_product_reviews(product_id: int, limit: int = 0):
    reviews = get_product_reviews(product_id, limit)
    return reviews


@product_router.post(
    "/{product_id}/reviews", summary="Оставить отзыв о товаре", status_code=201
)
def create_product_review(
    product_id: int,
    payload: dict,
    current_user: User = Depends(_get_current_user),
):
    rating = float(payload.get("rating") or 0)
    comment = payload.get("comment") or ""
    if rating <= 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Rating must be greater than 0",
        )
    try:
        review = add_review_for_product(
            user=current_user,
            product_id=product_id,
            rating=rating,
            comment=comment,
        )
    except ValueError as e:
        if "product not found" in str(e):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Product not found"
            )
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    return review


@product_router.get("/{product_id}/similar", summary="Получить похожие товары")
def read_similar_products(product_id: int, limit: int = 4):
    products = get_similar_products(product_id, limit)
    return products
