from sqlalchemy import Column, Integer, String, DateTime, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database.base import Base


class User(Base):
    __tablename__ = "users"
    id = Column("id", Integer, primary_key=True, index=True)
    email = Column("email", String(50), unique=True, nullable=False)
    phone = Column("phone", String(20), nullable=True, default="")
    hashed_password = Column("hashed_password", String(128), nullable=False)
    role = Column("role", String(50), default = "user", nullable=False)
    name = Column("name", String(100), nullable=False)
    created_at = Column(DateTime, default=func.now(), nullable=False)
    favorites = relationship("Favorites", back_populates="user")
    carts = relationship("Cart", back_populates="user")
    orders = relationship("Order", back_populates="user")
    reviews = relationship("Reviews", back_populates="user")