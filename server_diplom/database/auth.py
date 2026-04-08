import bcrypt
from datetime import timedelta
from config import settings
from database.base import Base
from models.brands import Brand
from models.cart import Cart
from models.category import Category
from models.city import City
from models.delivery_type import DeliveryType
from models.favorites import Favorites
from models.order import Order
from models.order_item import OrderItem
from models.pickup_point import PickupPoint
from models.product import Product
from models.product_images import ProductImages
from models.review import Reviews
from models.statuses import OrderStatusEnum, Status
from models.user import User
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine(settings.DATABASE_URL)
Session = sessionmaker(bind=engine)
Base.metadata.create_all(bind=engine)


def get_user_by_email(email: str) -> User | None:
    """
    Возвращает пользователя по email.
    Если не найден — возвращает None.
    """
    with Session(autoflush=False, bind=engine) as db:
        return db.query(User).filter(User.email == email).first()


def update_user_profile(
    email: str, name: str | None = None, phone: str | None = None
) -> User | None:
    with Session(autoflush=False, bind=engine) as db:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            return None
        if name is not None:
            user.name = name.strip() or user.name
        if phone is not None:
            user.phone = phone.strip()
        db.commit()
        db.refresh(user)
        return user


def hash_password(password: str) -> str:
    """Hash a password using bcrypt"""
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain_password: str, hashed: str) -> bool:
    """Verify a password against its hash"""
    return bcrypt.checkpw(
        plain_password.encode("utf-8"),
        hashed.encode("utf-8"),
    )


def create_user(email: str, password: str, name: str):
    """Create user in database with check existing user"""
    hashed_password = hash_password(password)
    with Session(autoflush=False, bind=engine) as db:
        existing_user = db.query(User).filter(User.email == email).first()
        if existing_user:
            return False
        new_user = User(name=name, email=email, hashed_password=hashed_password)
        db.add(new_user)
        db.commit()
        return True


def authenticate_user(email: str, password: str) -> None | User:
    with Session(autoflush=False, bind=engine) as db:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        return user


def get_favorite_product_ids_for_user(user: User) -> list[int]:
    """
    Возвращает список product_id из Favorites для указанного пользователя.
    """
    with Session(autoflush=False, bind=engine) as db:
        favorites = db.query(Favorites).filter(Favorites.user_id == user.id).all()
        return [fav.product_id for fav in favorites]


def toggle_favorite_for_user(user: User, product_id: int) -> bool:
    """
    Переключает избранное для товара.
    Возвращает True, если товар стал избранным, False — если был удалён.
    """
    with Session(autoflush=False, bind=engine) as db:
        favorite = (
            db.query(Favorites)
            .filter(
                Favorites.user_id == user.id,
                Favorites.product_id == product_id,
            )
            .first()
        )

        if favorite:
            db.delete(favorite)
            db.commit()
            return False

        new_favorite = Favorites(user_id=user.id, product_id=product_id)
        db.add(new_favorite)
        db.commit()
        return True


def get_all_products():
    """Получить все товары из базы данных"""
    with Session(autoflush=False, bind=engine) as db:
        products = db.query(Product).all()
        result: list[dict] = []
        for p in products:
            main_img = (
                db.query(ProductImages)
                .filter(
                    ProductImages.product_id == p.id, ProductImages.is_main == True
                )  # noqa: E712
                .first()
            )
            if not main_img:
                main_img = (
                    db.query(ProductImages)
                    .filter(ProductImages.product_id == p.id)
                    .first()
                )
            result.append(
                {
                    "id": p.id,
                    "name": p.name,
                    "brand": p.brand.name if p.brand else "",
                    "category_id": p.category_id,
                    "price": float(p.price),
                    "discount": float(p.discount),
                    "image_url": main_img.image_url if main_img else "",
                    "count_feedbacks": p.reviews_count,
                    "evaluation": float(p.rating),
                }
            )
        return result


def get_product_by_id(product_id: int):
    """Получить товар по его id. Возвращает None, если товар не найден."""
    with Session(autoflush=False, bind=engine) as db:
        p = db.query(Product).filter(Product.id == product_id).first()
        if not p:
            return None
        main_img = (
            db.query(ProductImages)
            .filter(
                ProductImages.product_id == p.id, ProductImages.is_main == True
            )  # noqa: E712
            .first()
        )
        if not main_img:
            main_img = (
                db.query(ProductImages).filter(ProductImages.product_id == p.id).first()
            )
        return {
            "id": p.id,
            "name": p.name,
            "brand": p.brand.name if p.brand else "",
            "category_id": p.category_id,
            "price": float(p.price),
            "discount": float(p.discount),
            "image_url": main_img.image_url if main_img else "",
            "count_feedbacks": p.reviews_count,
            "evaluation": float(p.rating),
        }


def get_detailed_product_by_id(product_id: int):
    """Получить подробную информацию о товаре включая все поля и информацию о производителе."""
    with Session(autoflush=False, bind=engine) as db:
        p = db.query(Product).filter(Product.id == product_id).first()
        if not p:
            return None
        main_img = (
            db.query(ProductImages)
            .filter(
                ProductImages.product_id == p.id, ProductImages.is_main == True
            )  # noqa: E712
            .first()
        )
        if not main_img:
            main_img = (
                db.query(ProductImages).filter(ProductImages.product_id == p.id).first()
            )

        # Собрать все изображения товара
        all_images = (
            db.query(ProductImages).filter(ProductImages.product_id == p.id).all()
        )
        images = [{"url": img.image_url, "is_main": img.is_main} for img in all_images]

        return {
            "id": p.id,
            "name": p.name,
            "brand": p.brand,
            "price": float(p.price),
            "discount": float(p.discount),
            "image_url": main_img.image_url if main_img else "",
            "images": images,
            "count_feedbacks": p.reviews_count,
            "evaluation": float(p.rating),
            "description": p.description,
            "specifications": p.specifications,
            "warranty": p.warranty,
            "color": p.color,
            "dimensions": p.dimensions,
            "weight": p.weight,
            "is_new": p.is_new,
            "is_popular": p.is_popular,
            "quantity": p.quantity,
            "sold_count": p.sold_count,
            "brand": p.brand.name,
        }


def get_product_reviews(product_id: int, limit: int = 0):
    """Получить отзывы о товаре. Если limit == 0, возвращает все. Если limit > 0, возвращает случайные."""
    import random

    with Session(autoflush=False, bind=engine) as db:
        p = db.query(Product).filter(Product.id == product_id).first()
        if not p:
            return []

        all_reviews = db.query(Reviews).filter(Reviews.product_id == product_id).all()

        if limit > 0 and len(all_reviews) > limit:
            # Вернуть случайные отзывы
            reviews = random.sample(all_reviews, limit)
        else:
            reviews = all_reviews

        result = []
        for review in reviews:
            result.append(
                {
                    "id": review.id,
                    "user_id": review.user_id,
                    "product_id": review.product_id,
                    "comment": review.comment,
                    "rating": float(review.rating),
                    "created_at": (
                        review.created_at.isoformat() if review.created_at else None
                    ),
                    "user_name": (
                        review.user.name if review.user else "Анонимный пользователь"
                    ),
                }
            )

        return result


def add_review_for_product(
    user: User,
    product_id: int,
    rating: float,
    comment: str | None = None,
) -> dict:
    """Создать отзыв от авторизованного пользователя; рейтинг обязателен, комментарий опционален."""
    if rating <= 0:
        raise ValueError("rating must be > 0")
    with Session(autoflush=False, bind=engine) as db:
        product = db.query(Product).filter(Product.id == product_id).first()
        if not product:
            raise ValueError("product not found")

        review = Reviews(
            user_id=user.id,
            product_id=product.id,
            rating=rating,
            comment=comment or "",
        )
        db.add(review)
        db.flush()

        # обновим агрегаты по продукту
        all_reviews = db.query(Reviews).filter(Reviews.product_id == product.id).all()
        if all_reviews:
            product.reviews_count = len(all_reviews)
            product.rating = sum(float(r.rating) for r in all_reviews) / len(
                all_reviews
            )

        db.commit()
        db.refresh(review)

        return {
            "id": review.id,
            "user_id": review.user_id,
            "product_id": review.product_id,
            "comment": review.comment,
            "rating": float(review.rating),
            "created_at": review.created_at.isoformat() if review.created_at else None,
            "user_name": user.name,
        }


def get_similar_products(product_id: int, limit: int = 4):
    """Получить похожие товары (из той же категории)."""
    with Session(autoflush=False, bind=engine) as db:
        p = db.query(Product).filter(Product.id == product_id).first()
        if not p:
            return []

        # Получить товары из той же категории, исключая сам товар
        similar = (
            db.query(Product)
            .filter(
                Product.category_id == p.category_id,
                Product.id != product_id,
            )
            .limit(limit)
            .all()
        )

        result = []
        for product in similar:
            main_img = (
                db.query(ProductImages)
                .filter(
                    ProductImages.product_id == product.id,
                    ProductImages.is_main == True,
                )  # noqa: E712
                .first()
            )
            if not main_img:
                main_img = (
                    db.query(ProductImages)
                    .filter(ProductImages.product_id == product.id)
                    .first()
                )
            result.append(
                {
                    "id": product.id,
                    "name": product.name,
                    "brand": product.brand.name if product.brand else "",
                    "category_id": product.category_id,
                    "price": float(product.price),
                    "discount": float(product.discount),
                    "image_url": main_img.image_url if main_img else "",
                    "count_feedbacks": product.reviews_count,
                    "evaluation": float(product.rating),
                }
            )

        return result


def get_cart_items_for_user(user: User) -> list[Cart]:
    with Session(autoflush=False, bind=engine) as db:
        return db.query(Cart).filter(Cart.user_id == user.id).all()


def search_products(query: str):
    """Поиск товаров по названию."""
    with Session(autoflush=False, bind=engine) as db:
        products = db.query(Product).filter(Product.name.ilike(f"%{query}%")).all()

        result = []
        for p in products:
            main_img = (
                db.query(ProductImages)
                .filter(
                    ProductImages.product_id == p.id, ProductImages.is_main == True
                )  # noqa: E712
                .first()
            )
            if not main_img:
                main_img = (
                    db.query(ProductImages)
                    .filter(ProductImages.product_id == p.id)
                    .first()
                )
            result.append(
                {
                    "id": p.id,
                    "name": p.name,
                    "brand": p.brand.name if p.brand else "",
                    "category_id": p.category_id,
                    "price": float(p.price),
                    "discount": float(p.discount),
                    "image_url": main_img.image_url if main_img else "",
                    "count_feedbacks": p.reviews_count,
                    "evaluation": float(p.rating),
                }
            )
        return result


def get_all_categories():
    """Получить все категории."""
    with Session(autoflush=False, bind=engine) as db:
        categories = db.query(Category).all()
        return [
            {
                "id": c.id,
                "name": c.name,
                "icon_path": c.icon_path,
            }
            for c in categories
        ]


def filter_products(
    sort_by=None,
    popular=False,
    high_rating=False,
    big_discount=False,
    is_new=False,
    category_id=None,
):
    """Фильтрация товаров с различными параметрами."""
    with Session(autoflush=False, bind=engine) as db:
        query = db.query(Product)

        # Фильтры
        if popular:
            query = query.filter(Product.is_popular == True)  # noqa: E712
        if high_rating:
            query = query.filter(Product.rating >= 4.0)
        if big_discount:
            query = query.filter(Product.discount > 30.0)
        if is_new:
            query = query.filter(Product.is_new == True)  # noqa: E712
        if category_id:
            query = query.filter(Product.category_id == category_id)

        # Сортировка
        if sort_by == "price_asc":
            query = query.order_by(Product.price.asc())
        elif sort_by == "price_desc":
            query = query.order_by(Product.price.desc())
        elif sort_by == "rating":
            query = query.order_by(Product.rating.desc())
        elif sort_by == "newest":
            query = query.order_by(Product.created_at.desc())
        else:
            query = query.order_by(Product.id)

        products = query.all()

        result = []
        for p in products:
            main_img = (
                db.query(ProductImages)
                .filter(
                    ProductImages.product_id == p.id, ProductImages.is_main == True
                )  # noqa: E712
                .first()
            )
            if not main_img:
                main_img = (
                    db.query(ProductImages)
                    .filter(ProductImages.product_id == p.id)
                    .first()
                )
            result.append(
                {
                    "id": p.id,
                    "name": p.name,
                    "brand": p.brand.name if p.brand else "",
                    "category_id": p.category_id,
                    "price": float(p.price),
                    "discount": float(p.discount),
                    "image_url": main_img.image_url if main_img else "",
                    "count_feedbacks": p.reviews_count,
                    "evaluation": float(p.rating),
                }
            )
        return result


def add_product_to_cart_for_user(
    user: User, product_id: int, quantity: int = 1
) -> Cart:
    if quantity <= 0:
        raise ValueError("quantity must be > 0")

    with Session(autoflush=False, bind=engine) as db:
        product = db.query(Product).filter(Product.id == product_id).first()
        if not product:
            raise ValueError("product not found")
        if product.quantity <= 0:
            raise ValueError("product is out of stock")

        cart_row = (
            db.query(Cart)
            .filter(Cart.user_id == user.id, Cart.product_id == product_id)
            .first()
        )

        new_quantity = quantity + (cart_row.quantity if cart_row else 0)
        if new_quantity > product.quantity:
            raise ValueError("requested quantity exceeds stock")

        if not cart_row:
            cart_row = Cart(user_id=user.id, product_id=product_id, quantity=quantity)
            db.add(cart_row)
        else:
            cart_row.quantity = new_quantity

        db.commit()
        db.refresh(cart_row)
        return cart_row


def set_cart_item_quantity_for_user(user: User, product_id: int, quantity: int) -> Cart:
    if quantity <= 0:
        raise ValueError("quantity must be > 0")
    with Session(autoflush=False, bind=engine) as db:
        product = db.query(Product).filter(Product.id == product_id).first()
        if not product:
            raise ValueError("product not found")
        if product.quantity <= 0:
            raise ValueError("product is out of stock")
        if quantity > product.quantity:
            raise ValueError("requested quantity exceeds stock")

        cart_row = (
            db.query(Cart)
            .filter(Cart.user_id == user.id, Cart.product_id == product_id)
            .first()
        )
        if not cart_row:
            raise ValueError("cart item not found")
        cart_row.quantity = quantity
        db.commit()
        db.refresh(cart_row)
        return cart_row


def remove_cart_item_for_user(user: User, product_id: int) -> None:
    with Session(autoflush=False, bind=engine) as db:
        cart_row = (
            db.query(Cart)
            .filter(Cart.user_id == user.id, Cart.product_id == product_id)
            .first()
        )
        if not cart_row:
            return
        db.delete(cart_row)
        db.commit()


def clear_cart_for_user(user: User) -> None:
    with Session(autoflush=False, bind=engine) as db:
        db.query(Cart).filter(Cart.user_id == user.id).delete()
        db.commit()


def _get_or_create_status(db, name: OrderStatusEnum) -> Status:
    status = db.query(Status).filter(Status.name == name).first()
    if status:
        return status
    status = Status(name=name)
    db.add(status)
    db.flush()
    return status


def create_order_from_cart(
    user: User,
    delivery_type_id: int,
    city_id: int | None,
    shipping_address: str,
    phone: str,
    pickup_point_id: int | None = None,
    product_ids: list[int] | None = None,
) -> Order:
    with Session(autoflush=False, bind=engine) as db:
        delivery_type = (
            db.query(DeliveryType).filter(DeliveryType.id == delivery_type_id).first()
        )
        if not delivery_type:
            raise ValueError("delivery type not found")

        city = None
        pickup_point = None
        order_shipping_address = shipping_address
        order_city_id = None
        order_pickup_point_id = None

        if pickup_point_id is not None or ("Самовывоз" in (delivery_type.name or "")):
            # Самовывоз: нужен город и ПВЗ, адрес строим из текущих значений справочников.
            if city_id is None:
                raise ValueError("city_id is required for pickup")
            if pickup_point_id is None:
                raise ValueError("pickup_point_id is required for pickup")

            city = db.query(City).filter(City.id == city_id).first()
            if not city:
                raise ValueError("city not found")
            pickup_point = (
                db.query(PickupPoint).filter(PickupPoint.id == pickup_point_id).first()
            )
            if not pickup_point:
                raise ValueError("pickup point not found")

            order_city_id = city.id
            order_pickup_point_id = pickup_point.id
            if pickup_point.address:
                order_shipping_address = f"{city.name}, {pickup_point.address}"
            else:
                order_shipping_address = f"{city.name}, {pickup_point.name}"
        else:
            # Доставка: город/ПВЗ не привязываем.
            order_shipping_address = shipping_address
            order_city_id = None
            order_pickup_point_id = None

        cart_items_query = db.query(Cart).filter(Cart.user_id == user.id)
        if product_ids is not None and len(product_ids) > 0:
            cart_items_query = cart_items_query.filter(Cart.product_id.in_(product_ids))

        cart_items = cart_items_query.all()
        if not cart_items:
            raise ValueError("cart is empty")

        status = _get_or_create_status(db, OrderStatusEnum.pending)

        estimated_days = 3
        delivery_comment = None
        if pickup_point is not None:
            estimated_days = max(1, int(pickup_point.estimated_days or 1))
            delivery_comment = (
                f"Ориентировочная дата прибытия в пункт выдачи через {estimated_days} дн."
            )
        else:
            delivery_comment = "Ориентировочная дата курьерской доставки."

        order = Order(
            user_id=user.id,
            delivery_type_id=delivery_type.id,
            status_id=status.id,
            shipping_address=order_shipping_address,
            city_id=order_city_id,
            pickup_point_id=order_pickup_point_id,
            phone=phone,
            total_amount=0,
            delivery_at=None,
            delivery_comment=delivery_comment,
        )
        db.add(order)
        db.flush()  # get order.id
        if order.created_at is not None:
            order.delivery_at = order.created_at + timedelta(days=estimated_days)

        total = 0
        for cart_row in cart_items:
            product = (
                db.query(Product).filter(Product.id == cart_row.product_id).first()
            )
            if not product:
                raise ValueError(f"product {cart_row.product_id} not found")
            if product.quantity < cart_row.quantity:
                raise ValueError(f"insufficient stock for product {product.id}")

            product.quantity -= cart_row.quantity
            line_total = float(product.price) * cart_row.quantity
            total += line_total

            db.add(
                OrderItem(
                    order_id=order.id,
                    product_id=product.id,
                    quantity=cart_row.quantity,
                    price=product.price,
                )
            )

        order.total_amount = total

        # clear cart
        for row in cart_items:
            db.delete(row)

        db.commit()
        db.refresh(order)
        return order


def cancel_order_for_user(user: User, order_id: int) -> Order:
    with Session(autoflush=False, bind=engine) as db:
        order = db.query(Order).filter(Order.id == order_id).first()
        if not order:
            raise ValueError("order not found")
        if order.user_id != user.id:
            raise PermissionError("forbidden")

        canceled = _get_or_create_status(db, OrderStatusEnum.canceled)
        if order.status_id == canceled.id:
            return order

        # Restock items (best-effort)
        items = db.query(OrderItem).filter(OrderItem.order_id == order.id).all()
        for it in items:
            product = db.query(Product).filter(Product.id == it.product_id).first()
            if product:
                product.quantity += it.quantity

        order.status_id = canceled.id
        db.commit()
        db.refresh(order)
        return order
        return order


def get_delivery_types() -> list[dict]:
    with Session(autoflush=False, bind=engine) as db:
        items = db.query(DeliveryType).order_by(DeliveryType.id.asc()).all()
        return [{"id": dt.id, "name": dt.name} for dt in items]


def get_cities() -> list[dict]:
    with Session(autoflush=False, bind=engine) as db:
        items = db.query(City).order_by(City.id.asc()).all()
        return [{"id": c.id, "name": c.name} for c in items]


def get_pickup_points_for_city(city_id: int) -> list[dict]:
    with Session(autoflush=False, bind=engine) as db:
        items = (
            db.query(PickupPoint)
            .filter(PickupPoint.city_id == city_id)
            .order_by(PickupPoint.id.asc())
            .all()
        )
        return [
            {
                "id": p.id,
                "name": p.name,
                "address": p.address,
                "working_hours": p.working_hours,
                "estimated_days": p.estimated_days,
            }
            for p in items
        ]


def _get_product_main_image_url(db, product_id: int) -> str:
    img = (
        db.query(ProductImages)
        .filter(
            ProductImages.product_id == product_id, ProductImages.is_main == True
        )  # noqa: E712
        .first()
    )
    if img:
        return img.image_url or ""
    img = db.query(ProductImages).filter(ProductImages.product_id == product_id).first()
    return img.image_url if img else ""


def get_orders_for_user(user: User) -> list[dict]:
    with Session(autoflush=False, bind=engine) as db:
        orders = (
            db.query(Order)
            .filter(Order.user_id == user.id)
            .order_by(Order.created_at.desc())
            .all()
        )

        result: list[dict] = []
        for order in orders:
            status_name = None
            if order.status and order.status.name is not None:
                status_name = (
                    order.status.name.value
                    if isinstance(order.status.name, OrderStatusEnum)
                    else str(order.status.name)
                )
            delivery_name = order.delivery_type.name if order.delivery_type else None
            result.append(
                {
                    "id": order.id,
                    "status": status_name,
                    "delivery_type": delivery_name,
                    "shipping_address": order.shipping_address,
                    "phone": order.phone,
                    "total_amount": float(order.total_amount),
                    "created_at": (
                        order.created_at.isoformat() if order.created_at else None
                    ),
                    "delivery_at": (
                        order.delivery_at.isoformat() if order.delivery_at else None
                    ),
                    "delivery_comment": order.delivery_comment,
                }
            )
        return result


def get_order_detail_for_user(user: User, order_id: int) -> dict:
    with Session(autoflush=False, bind=engine) as db:
        order = (
            db.query(Order)
            .filter(Order.id == order_id, Order.user_id == user.id)
            .first()
        )
        if not order:
            raise ValueError("order not found")

        items: list[dict] = []
        for it in order.items:
            items.append(
                {
                    "product_id": it.product_id,
                    "product_name": it.product.name if it.product else "",
                    "product_image_url": _get_product_main_image_url(db, it.product_id),
                    "quantity": it.quantity,
                    "price": float(it.price),
                    "line_total": float(it.price) * it.quantity,
                }
            )

        return {
            "id": order.id,
            "status": (
                order.status.name.value
                if order.status and isinstance(order.status.name, OrderStatusEnum)
                else (
                    str(order.status.name)
                    if order.status and order.status.name
                    else None
                )
            ),
            "delivery_type": order.delivery_type.name if order.delivery_type else None,
            "shipping_address": order.shipping_address,
            "phone": order.phone,
            "total_amount": float(order.total_amount),
            "created_at": order.created_at.isoformat() if order.created_at else None,
            "delivery_at": order.delivery_at.isoformat() if order.delivery_at else None,
            "delivery_comment": order.delivery_comment,
            "items": items,
        }


def get_orders_for_user_email(user_email: str) -> list[dict]:
    user = get_user_by_email(user_email)
    if not user:
        return []
    return get_orders_for_user(user)


def get_order_detail_for_user_email(user_email: str, order_id: int) -> dict:
    user = get_user_by_email(user_email)
    if not user:
        raise ValueError("user not found")
    return get_order_detail_for_user(user, order_id)
