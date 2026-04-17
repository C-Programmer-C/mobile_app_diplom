from typing import Optional
from pathlib import Path
from uuid import uuid4

from config import settings
from database.auth import (
    add_review_for_product,
    clear_product_main_image_url,
    create_product,
    get_all_brands,
    get_all_products,
    get_detailed_product_by_id,
    get_product_by_id,
    get_product_reviews,
    get_similar_products,
    set_product_main_image_url,
    update_product_by_id,
)
from fastapi import APIRouter, Depends, File, HTTPException, Response, UploadFile, status
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


@product_router.get("/brands", summary="Получить все бренды")
def read_brands():
    return get_all_brands()


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


@product_router.patch("/{product_id}", summary="Обновить товар (admin)")
def patch_product(
    product_id: int,
    payload: dict,
    current_user: User = Depends(_get_current_user),
):
    if current_user.role not in {"admin", "staff"}:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="admin or staff only",
        )
    product = update_product_by_id(
        product_id=product_id,
        category_id=payload.get("category_id"),
        brand_id=payload.get("brand_id"),
        price=payload.get("price"),
        name=payload.get("name"),
        description=payload.get("description"),
        specifications=payload.get("specifications"),
        warranty=payload.get("warranty"),
        color=payload.get("color"),
        dimensions=payload.get("dimensions"),
        weight=payload.get("weight"),
        is_new=payload.get("is_new"),
        is_popular=payload.get("is_popular"),
        discount=payload.get("discount"),
        quantity=payload.get("quantity"),
    )
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    return product


@product_router.post("/", summary="Создать товар (admin)")
def post_product(
    payload: dict,
    current_user: User = Depends(_get_current_user),
):
    if current_user.role not in {"admin", "staff"}:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="admin or staff only",
        )
    try:
        product = create_product(
            category_id=int(payload.get("category_id")),
            brand_id=int(payload.get("brand_id")),
            price=float(payload.get("price") or 0),
            name=str(payload.get("name") or ""),
            description=str(payload.get("description") or ""),
            specifications=str(payload.get("specifications") or ""),
            warranty=int(payload.get("warranty") or 0),
            color=str(payload.get("color") or ""),
            dimensions=str(payload.get("dimensions") or ""),
            weight=str(payload.get("weight") or ""),
            is_new=bool(payload.get("is_new")),
            is_popular=bool(payload.get("is_popular")),
            discount=float(payload.get("discount") or 0),
            quantity=int(payload.get("quantity") or 0),
            image_url=payload.get("image_url"),
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    if not product:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="invalid payload")
    return product


@product_router.post("/{product_id}/image", summary="Загрузить главное изображение товара (admin)")
async def upload_product_image(
    product_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(_get_current_user),
):
    if current_user.role not in {"admin", "staff"}:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="admin or staff only",
        )
    uploads_dir = Path("static/products")
    uploads_dir.mkdir(parents=True, exist_ok=True)

    original_name = file.filename or "image"
    suffix = Path(original_name).suffix.lower() or ".jpg"
    filename = f"product_{product_id}_{uuid4().hex}{suffix}"
    target_path = uploads_dir / filename
    content = await file.read()
    target_path.write_bytes(content)

    image_url = f"http://127.0.0.1:8000/static/products/{filename}"
    product = set_product_main_image_url(product_id, image_url)
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    return product


@product_router.delete("/{product_id}/image", summary="Удалить главное изображение товара (admin)")
def delete_product_image(
    product_id: int,
    current_user: User = Depends(_get_current_user),
):
    if current_user.role not in {"admin", "staff"}:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="admin or staff only",
        )
    product = get_detailed_product_by_id(product_id)
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")

    old_url = str(product.get("image_url") or "")
    old_prefix = "http://127.0.0.1:8000/static/products/"
    if old_url.startswith(old_prefix):
        filename = old_url.replace(old_prefix, "", 1)
        file_path = Path("static/products") / filename
        if file_path.exists():
            file_path.unlink()

    updated = clear_product_main_image_url(product_id)
    if not updated:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    return updated


@product_router.get("/{product_id}/similar", summary="Получить похожие товары")
def read_similar_products(product_id: int, limit: int = 4):
    products = get_similar_products(product_id, limit)
    return products
