from sqlalchemy import Column, ForeignKey, Integer, Numeric, String, DateTime, Text, Boolean
from sqlalchemy.sql import func
from database.base import Base
from sqlalchemy.orm import relationship


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    category = relationship("Category", back_populates="products")
    brand_id = Column(Integer, ForeignKey("brands.id"), nullable=False)
    brand = relationship("Brand", back_populates="products")
    price = Column(Numeric(10, 2), nullable=False, index=True)
    name = Column(String(100), nullable=False, index=True, unique=True)
    description = Column(Text, nullable=False)
    specifications = Column(Text, nullable=False)
    warranty = Column(Integer, nullable=False)
    color = Column(Text, nullable=False)
    dimensions = Column(Text, nullable=False)
    weight = Column(Text, nullable=False)
    is_new = Column(Boolean, nullable=False, default=False)
    is_popular = Column(Boolean, nullable=False, default=False)
    discount = Column(Numeric(5, 2), nullable=False, default=0)
    quantity = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime, nullable=False, default=func.now())
    rating = Column(Numeric(10, 2), nullable=False)
    reviews_count = Column(Integer, nullable=False, default=0)
    sold_count = Column(Integer, nullable=False, default=0)
    favorites = relationship("Favorites", back_populates="product")
    carts = relationship("Cart", back_populates="product")
    order_items = relationship("OrderItem", back_populates="product")
    product_images = relationship("ProductImages", back_populates="product")
    reviews = relationship("Reviews", back_populates="product")