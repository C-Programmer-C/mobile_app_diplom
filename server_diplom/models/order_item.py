from sqlalchemy import Column, Integer, Numeric, String, DateTime, Text, ForeignKey
from sqlalchemy.sql import func
from database.base import Base
from sqlalchemy.orm import relationship


class OrderItems(Base):
    __tablename__ = "order_items"
    id = Column("id", Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    orders = relationship("User", back_populates="cart")
    products = relationship("Product", back_populates="category")
    quantity = Column(Integer, nullable=False)
    price = Column(Numeric(10, 2), nullable=False)