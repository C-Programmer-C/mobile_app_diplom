from sqlalchemy import Column, ForeignKey, Integer, Numeric, String, DateTime, Text
from sqlalchemy.sql import func
from database.base import Base
from sqlalchemy.orm import relationship


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)

    name = Column(String(100), nullable=False, index=True, unique=True)
    description = Column(Text, nullable=False)

    price = Column(Numeric(10, 2), nullable=False, index=True)
    discount = Column(Numeric(5, 2), nullable=False, default=0)

    image_url = Column(String(255), nullable=False)

    stock = Column(Integer, nullable=False)

    count_feedbacks = Column(Integer, nullable=False, default=0)
    evaluation = Column(Numeric(2, 1), nullable=False, default=0)
    favorites = relationship("Favorites", back_populates="product")
