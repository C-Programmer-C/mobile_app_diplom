# seed.py
from decimal import Decimal
from datetime import datetime, timedelta

from sqlalchemy import create_engine, func
from sqlalchemy.orm import sessionmaker

from config import settings
from database.auth import hash_password
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

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
session = SessionLocal()


def reset_tables() -> None:
    session.query(Favorites).delete()
    session.query(Cart).delete()
    session.query(OrderItem).delete()
    session.query(Order).delete()
    session.query(Reviews).delete()
    session.query(ProductImages).delete()
    session.query(Product).delete()
    session.query(Category).delete()
    session.query(Brand).delete()
    session.query(PickupPoint).delete()
    session.query(City).delete()
    session.query(DeliveryType).delete()
    session.query(Status).delete()
    session.query(User).delete()
    session.commit()


def seed_statuses() -> list[Status]:
    statuses: list[Status] = []
    for st in OrderStatusEnum:
        statuses.append(Status(name=st))
    session.add_all(statuses)
    session.commit()
    return statuses


def seed_delivery_types() -> list[DeliveryType]:
    items = [
        DeliveryType(name="Курьер"),
        DeliveryType(name="Самовывоз из пункта выдачи"),
    ]
    session.add_all(items)
    session.commit()
    return items


def seed_cities_and_pickup_points() -> tuple[list[City], list[PickupPoint]]:
    moscow = City(name="Москва")
    spb = City(name="Санкт‑Петербург")
    ekb = City(name="Екатеринбург")
    session.add_all([moscow, spb, ekb])
    session.flush()

    points = [
        PickupPoint(
            city_id=moscow.id,
            name="ПВЗ Москва, Тверская",
            address="Москва, ул. Тверская, д. 10",
            working_hours="Ежедневно 10:00–21:00",
            estimated_days=1,
        ),
        PickupPoint(
            city_id=moscow.id,
            name="ПВЗ Москва, Тёплый Стан",
            address="Москва, Новоясеневский пр-т, д. 3",
            working_hours="Ежедневно 10:00–22:00",
            estimated_days=2,
        ),
        PickupPoint(
            city_id=spb.id,
            name="ПВЗ СПб, Невский",
            address="Санкт‑Петербург, Невский пр-т, д. 50",
            working_hours="Ежедневно 10:00–21:00",
            estimated_days=3,
        ),
    ]
    session.add_all(points)
    session.commit()
    return [moscow, spb, ekb], points


def seed_categories() -> list[Category]:
    items = [
        Category(
            name="Смартфоны",
            icon_path="http://127.0.0.1:8000/static/icons/smartphone.png",
        ),
        Category(
            name="Ноутбуки",
            icon_path="http://127.0.0.1:8000/static/icons/laptop.png",
        ),
        Category(
            name="Планшеты",
            icon_path="http://127.0.0.1:8000/static/icons/tablet.webp",
        ),
    ]
    session.add_all(items)
    session.commit()
    return items


def seed_fabricators() -> list[Brand]:
    items = [
        Brand(
            name="Apple",
        ),
        Brand(
            name="Motorola",
        ),
        Brand(
            name="Samsung",
        ),
        Brand(
            name="Tecno",
        ),
        Brand(
            name="Xiaomi",
        ),
    ]
    session.add_all(items)
    session.commit()
    return items


def seed_users() -> list[User]:
    default_password_hash = hash_password("123456")
    items = [
        User(
            email="adm",
            phone="+7 900 000‑00‑01",
            hashed_password=default_password_hash,
            role="admin",
            name="Admin",
        ),
        User(
            email="stf",
            phone="+7 900 000‑00‑02",
            hashed_password=default_password_hash,
            role="staff",
            name="Staff",
        ),
    ]
    session.add_all(items)
    session.commit()
    return items


def seed_products(
    categories: list[Category],
    fabricators: list[Brand],
) -> list[Product]:
    smartphones = next(c for c in categories if c.name == "Смартфоны")
    laptops = next(c for c in categories if c.name == "Ноутбуки")
    tablets = next(c for c in categories if c.name == "Планшеты")

    apple = next(f for f in fabricators if f.name == "Apple")
    samsung = next(f for f in fabricators if f.name == "Samsung")
    xiaomi = next(f for f in fabricators if f.name == "Xiaomi")
    motorola = next(f for f in fabricators if f.name == "Motorola")
    tecno = next(f for f in fabricators if f.name == "Tecno")

    base_url = "http://127.0.0.1:8000/static/products"

    product_specs = [
        # Смартфоны
        (
            "Galaxy Nova X1",
            smartphones.id,
            samsung.id,
            "28999.99",
            "10.00",
            "telephone1.jpg",
        ),
        (
            "iFruit Pro 14",
            smartphones.id,
            apple.id,
            "79999.99",
            "5.00",
            "telephone2.jpg",
        ),
        (
            "Pixelate 8",
            smartphones.id,
            motorola.id,
            "54999.99",
            "7.50",
            "telephone3.jpg",
        ),
        (
            "Redmi Turbo 12",
            smartphones.id,
            xiaomi.id,
            "23999.99",
            "56.00",
            "telephone4.jpg",
        ),
        (
            "Moto Edge Air",
            smartphones.id,
            motorola.id,
            "32999.99",
            "32.00",
            "telephone6.jpg",
        ),
        (
            "Galaxy Lite M",
            smartphones.id,
            samsung.id,
            "19999.99",
            "6.00",
            "telephone7.jpg",
        ),
        (
            "Xiaomi Pro Max",
            smartphones.id,
            xiaomi.id,
            "42999.99",
            "11.00",
            "telephone8.jpg",
        ),
        (
            "iFruit Mini 13",
            smartphones.id,
            apple.id,
            "64999.99",
            "35.00",
            "telephone9.jpg",
        ),
        (
            "Tecno Spark X",
            smartphones.id,
            tecno.id,
            "15999.99",
            "14.00",
            "telephone11.jpg",
        ),
        (
            "Nova Fusion",
            smartphones.id,
            samsung.id,
            "36999.99",
            "8.00",
            "telephone12.jpg",
        ),
        # Ноутбуки
        ("UltraBook 15", laptops.id, tecno.id, "89999.99", "12.00", "laptop1.jpg"),
        ("MacLite Air 13", laptops.id, apple.id, "109999.99", "3.00", "laptop2.jpg"),
        ("Redmi Book 16", laptops.id, xiaomi.id, "67999.99", "9.00", "laptop3.jpg"),
        ("Galaxy Book Pro", laptops.id, samsung.id, "94999.99", "10.00", "laptop4.jpg"),
        ("Moto Work 14", laptops.id, motorola.id, "59999.99", "7.00", "laptop5.jpg"),
        ("Xiaomi Note Pro", laptops.id, xiaomi.id, "72999.99", "11.00", "laptop6.jpg"),
        ("Tecno Slim 14", laptops.id, tecno.id, "54999.99", "8.00", "laptop7.jpg"),
        (
            "Galaxy Creator 16",
            laptops.id,
            samsung.id,
            "119999.99",
            "6.00",
            "laptop8.jpg",
        ),
        ("iFruit Studio 14", laptops.id, apple.id, "139999.99", "2.50", "laptop9.jpg"),
        ("Moto Office 15", laptops.id, motorola.id, "64999.99", "9.50", "laptop10.jpg"),
        ("Redmi ZenBook", laptops.id, xiaomi.id, "81999.99", "10.00", "laptop11.jpg"),
        ("Tecno PowerBook", laptops.id, tecno.id, "58999.99", "12.00", "laptop12.jpg"),
        # Планшеты
        ("Tab Plus 11", tablets.id, samsung.id, "29999.99", "8.00", "tablet1.jpg"),
        ("iFruit Pad Air", tablets.id, apple.id, "55999.99", "4.00", "tablet2.jpg"),
        ("Redmi Pad Max", tablets.id, xiaomi.id, "27999.99", "10.00", "tablet3.jpg"),
        ("Galaxy Tab Core", tablets.id, samsung.id, "24999.99", "6.50", "tablet4.jpg"),
        ("Moto Tab Pro", tablets.id, motorola.id, "31999.99", "7.50", "tablet5.jpg"),
        ("Tecno Tab Neo", tablets.id, tecno.id, "21999.99", "9.00", "tablet6.jpg"),
        ("iFruit Pad Mini", tablets.id, apple.id, "49999.99", "3.00", "tablet7.jpg"),
        ("Galaxy Tab Ultra", tablets.id, samsung.id, "65999.99", "5.00", "tablet8.jpg"),
    ]

    items: list[Product] = []
    for idx, (name, category_id, brand_id, price, discount, _) in enumerate(
        product_specs
    ):
        items.append(
            Product(
                name=name,
                category_id=category_id,
                brand_id=brand_id,
                price=Decimal(price),
                discount=Decimal(discount),
                description=f"{name} — надежное устройство для повседневных задач.",
                specifications="8 ГБ ОЗУ, 256 ГБ накопитель, Wi‑Fi, Bluetooth",
                warranty=24,
                color="Черный",
                dimensions="250 x 160 x 8 мм",
                weight="450 г",
                is_new=idx % 3 == 0,
                is_popular=idx % 2 == 0,
                quantity=5 + (idx % 20),
                rating=Decimal("0.00"),
                reviews_count=0,
                sold_count=20 + idx * 3,
            )
        )

    session.add_all(items)
    session.flush()

    images: list[ProductImages] = []
    for p, spec in zip(items, product_specs):
        image_name = spec[5]
        img = ProductImages(
            product_id=p.id,
            name=f"product_{p.id}_main",
            image_url=f"{base_url}/{image_name}",
            is_main=True,
        )
        images.append(img)
        if image_name == "telephone2.jpg":
            extra_images = [
                "telephone2m1.jpg",
                "telephone2m2.jpg",
                "telephone2m3.jpg",
                "telephone2m4.jpg",
                "telephone2m5.jpg",
                "telephone2m6.jpg",
                "telephone2m7.jpg",
                "telephone2m8.jpg",
                "telephone2m9.jpg",
                "telephone2m10.jpg",
                "telephone2m11.jpg",
                "telephone2m12.jpg",
            ]
            for idx, extra_name in enumerate(extra_images, start=1):
                images.append(
                    ProductImages(
                        product_id=p.id,
                        name=f"product_{p.id}_extra_{idx}",
                        image_url=f"{base_url}/{extra_name}",
                        is_main=False,
                    )
                )

    session.add_all(images)

    session.commit()
    return items


def seed_cart_and_favorites(
    users: list[User],
    products: list[Product],
) -> None:
    if not users or not products:
        return

    user1 = users[0]
    user2 = users[1] if len(users) > 1 else users[0]

    cart_items = [
        Cart(user_id=user1.id, product_id=products[0].id, quantity=1),
        Cart(user_id=user1.id, product_id=products[1].id, quantity=2),
        Cart(user_id=user2.id, product_id=products[2].id, quantity=1),
    ]
    fav_items = [
        Favorites(user_id=user1.id, product_id=products[0].id),
        Favorites(user_id=user1.id, product_id=products[1].id),
        Favorites(user_id=user2.id, product_id=products[2].id),
    ]

    session.add_all(cart_items + fav_items)
    session.commit()


def seed_orders(
    users: list[User],
    products: list[Product],
    statuses: list[Status],
    delivery_types: list[DeliveryType],
    cities: list[City],
    pickup_points: list[PickupPoint],
) -> None:
    if not users or not products:
        return

    user1 = users[0]
    pending_status = next(s for s in statuses if s.name == OrderStatusEnum.pending)
    pickup_done_status = next(s for s in statuses if s.name == OrderStatusEnum.pickup)

    courier = next(dt for dt in delivery_types if "Курьер" in dt.name)
    pickup = next(dt for dt in delivery_types if "Самовывоз" in dt.name)

    moscow = next(c for c in cities if c.name == "Москва")
    pp_moscow = next(p for p in pickup_points if p.city_id == moscow.id)
    now = datetime.utcnow()

    order1 = Order(
        user_id=user1.id,
        delivery_type_id=courier.id,
        status_id=pending_status.id,
        shipping_address="Москва, ул. Пушкина, д. 1",
        city_id=moscow.id,
        pickup_point_id=None,
        total_amount=Decimal("0.00"),
        phone="+7 900 000‑00‑01",
        estimated_delivery_at=now + timedelta(days=3),
        delivery_comment="Ориентировочная дата курьерской доставки.",
        payment_status="pending",
        payment_method="cash",
        paid_at=None,
    )
    order2 = Order(
        user_id=user1.id,
        delivery_type_id=pickup.id,
        status_id=pickup_done_status.id,
        shipping_address=pp_moscow.address,
        city_id=moscow.id,
        pickup_point_id=pp_moscow.id,
        total_amount=Decimal("0.00"),
        phone="+7 900 000‑00‑01",
        estimated_delivery_at=now + timedelta(days=pp_moscow.estimated_days),
        delivery_comment=(
            f"Ориентировочная дата прибытия в пункт выдачи через {pp_moscow.estimated_days} дн."
        ),
        processed_at=now - timedelta(days=2),
        shipped_at=now - timedelta(days=1),
        ready_for_pickup_at=now - timedelta(hours=5),
        pickup_at=now - timedelta(hours=1),
        payment_status="paid",
        payment_method="card",
        paid_at=now,
    )

    session.add_all([order1, order2])
    session.flush()

    items = [
        OrderItem(
            order_id=order1.id,
            product_id=products[0].id,
            quantity=1,
            price=products[0].price,
        ),
        OrderItem(
            order_id=order1.id,
            product_id=products[1].id,
            quantity=1,
            price=products[1].price,
        ),
        OrderItem(
            order_id=order2.id,
            product_id=products[2].id,
            quantity=2,
            price=products[2].price,
        ),
    ]

    order1.total_amount = sum(
        i.price * i.quantity for i in items if i.order_id == order1.id
    )
    order2.total_amount = sum(
        i.price * i.quantity for i in items if i.order_id == order2.id
    )

    session.add_all(items)
    session.commit()


def seed_reviews(users: list[User], products: list[Product]) -> None:
    if not users or not products:
        return

    user1 = users[0]
    user2 = users[1] if len(users) > 1 else users[0]

    items = [
        Reviews(
            user_id=user1.id,
            product_id=products[0].id,
            rating=5,
            comment="Отличный смартфон, батарея держит целый день.",
        ),
        Reviews(
            user_id=user2.id,
            product_id=products[1].id,
            rating=5,
            comment="Экран и камера просто топ.",
        ),
        Reviews(
            user_id=user1.id,
            product_id=products[2].id,
            rating=4,
            comment="Чистый Android, всё летает, но хотелось бы больше памяти.",
        ),
        Reviews(
            user_id=user2.id,
            product_id=products[10].id,
            rating=4,
            comment="Хороший ноутбук для работы и учебы.",
        ),
        Reviews(
            user_id=user1.id,
            product_id=products[22].id,
            rating=5,
            comment="Планшет шустрый, экран очень приятный.",
        ),
    ]
    session.add_all(items)
    session.commit()


def recalc_products_rating_and_reviews_count() -> None:
    for product in session.query(Product).all():
        product.rating = Decimal("0.00")
        product.reviews_count = 0
    session.flush()

    aggregates = (
        session.query(
            Reviews.product_id,
            func.count(Reviews.id),
            func.avg(Reviews.rating),
        )
        .group_by(Reviews.product_id)
        .all()
    )

    for product_id, reviews_count, avg_rating in aggregates:
        product = session.query(Product).filter(Product.id == product_id).first()
        if product is None:
            continue
        product.reviews_count = int(reviews_count or 0)
        product.rating = Decimal(str(round(float(avg_rating or 0), 2)))

    session.commit()


def main() -> None:
    reset_tables()

    statuses = seed_statuses()
    delivery_types = seed_delivery_types()
    cities, pickup_points = seed_cities_and_pickup_points()
    categories = seed_categories()
    fabricators = seed_fabricators()
    users = seed_users()
    products = seed_products(categories, fabricators)

    seed_cart_and_favorites(users, products)
    seed_orders(users, products, statuses, delivery_types, cities, pickup_points)
    seed_reviews(users, products)
    recalc_products_rating_and_reviews_count()

    print("Seed completed successfully")


if __name__ == "__main__":
    main()
