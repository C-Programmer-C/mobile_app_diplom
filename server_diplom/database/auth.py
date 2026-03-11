import bcrypt
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from config import settings
from database.base import Base
from models.favorites import Favorites
from models.product import Product
from models.user import User

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
        favorites = (
            db.query(Favorites)
            .filter(Favorites.user_id == user.id)
            .all()
        )
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
        return products


def get_product_by_id(product_id: int):
    """Получить товар по его id. Возвращает None, если товар не найден."""
    with Session(autoflush=False, bind=engine) as db:
        product = db.query(Product).filter(Product.id == product_id).first()
        return product
