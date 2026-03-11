from fastapi import APIRouter, HTTPException, Response, status
from database.auth import get_all_products, get_product_by_id

product_router = APIRouter(prefix="/products", tags=["Products"])

@product_router.get("/", summary="Получить список всех товаров")
def read_products():
    """
    Возвращает массив объектов всех товаров, имеющихся в базе данных.
    """
    products = get_all_products()
    return products


@product_router.get("/{product_id}", summary="Получить товар по его ID")
def read_product(product_id: int):
    """
    Возвращает один товар с указанным идентификатором.
    Если товар не найден, возвращается ошибка 404.
    """
    product = get_product_by_id(product_id)
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Product not found"
        )
    return product

    