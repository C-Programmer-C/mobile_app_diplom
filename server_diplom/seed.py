# seed.py
from decimal import Decimal

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from models.category import Category
from models.favorites import Favorites
from models.product import Product
from models.user import User
from config import settings

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
session = SessionLocal()

# products = [
#     Product(
#         name="Galaxy Nova X1",
#         description="6.7'' AMOLED, 8GB RAM, 256GB, 108MP камера",
#         price=Decimal("28999.99"),
#         discount=Decimal("10.00"),
#         image_url="http://127.0.0.1:8000/static/products/telephone1.jpg",
#         stock=15,
#         count_feedbacks=34,
#         evaluation=Decimal("4.6"),
#     ),
#     Product(
#         name="iFruit Pro 14",
#         description="6.1'' OLED, 6GB RAM, 128GB, A-series chip",
#         price=Decimal("79999.99"),
#         discount=Decimal("5.00"),
#         image_url="http://127.0.0.1:8000/static/products/telephone2.jpg",
#         stock=7,
#         count_feedbacks=120,
#         evaluation=Decimal("4.8"),
#     ),
#     Product(
#         name="Pixelate 8",
#         description="6.3'' OLED, 8GB RAM, 128GB, чистый Android",
#         price=Decimal("54999.99"),
#         discount=Decimal("7.50"),
#         image_url="http://127.0.0.1:8000/static/products/telephone3.jpg",
#         stock=9,
#         count_feedbacks=58,
#         evaluation=Decimal("4.7"),
#     ),
#     Product(
#         name="Redmi Turbo 12",
#         description="6.67'' IPS, 8GB RAM, 256GB, 120Hz",
#         price=Decimal("23999.99"),
#         discount=Decimal("15.00"),
#         image_url="http://127.0.0.1:8000/static/products/telephone4.jpg",
#         stock=20,
#         count_feedbacks=42,
#         evaluation=Decimal("4.4"),
#     ),
#     Product(
#         name="OneMax Ultra",
#         description="6.8'' AMOLED, 12GB RAM, 256GB",
#         price=Decimal("65999.99"),
#         discount=Decimal("8.00"),
#         image_url="http://127.0.0.1:8000/static/products/telephone6.jpg",
#         stock=6,
#         count_feedbacks=21,
#         evaluation=Decimal("4.5"),
#     ),
#     Product(
#         name="Moto Edge Neo",
#         description="6.5'' OLED, 8GB RAM, 128GB",
#         price=Decimal("32999.99"),
#         discount=Decimal("12.00"),
#         image_url="http://127.0.0.1:8000/static/products/telephone7.jpg",
#         stock=11,
#         count_feedbacks=19,
#         evaluation=Decimal("4.3"),
#     ),
#     Product(
#         name="VivoMax S20",
#         description="6.4'' AMOLED, 8GB RAM, 256GB",
#         price=Decimal("37999.99"),
#         discount=Decimal("9.00"),
#         image_url="http://127.0.0.1:8000/static/products/telephone8.jpg",
#         stock=13,
#         count_feedbacks=27,
#         evaluation=Decimal("4.2"),
#     ),
#     Product(
#         name="Honor Magic Lite",
#         description="6.7'' OLED, 6GB RAM, 128GB",
#         price=Decimal("26999.99"),
#         discount=Decimal("6.00"),
#         image_url="http://127.0.0.1:8000/static/products/telephone9.jpg",
#         stock=18,
#         count_feedbacks=33,
#         evaluation=Decimal("4.4"),
#     ),
#     Product(
#         name="RealPro GT",
#         description="6.74'' AMOLED, 12GB RAM, 256GB",
#         price=Decimal("45999.99"),
#         discount=Decimal("11.00"),
#         image_url="http://127.0.0.1:8000/static/products/telephone11.jpg",
#         stock=8,
#         count_feedbacks=46,
#         evaluation=Decimal("4.6"),
#     ),
#     Product(
#         name="Asus Zen X",
#         description="6.78'' AMOLED, 16GB RAM, 512GB",
#         price=Decimal("72999.99"),
#         discount=Decimal("4.00"),
#         image_url="http://127.0.0.1:8000/static/products/telephone12.jpg",
#         stock=4,
#         count_feedbacks=15,
#         evaluation=Decimal("4.9"),
#     ),
# ]


# session.add_all(products)
session.commit()
# print("Данные были успешно добавлены")

# session.close()
