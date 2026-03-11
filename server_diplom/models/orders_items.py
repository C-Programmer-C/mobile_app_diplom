from sqlalchemy import Column, Integer, Numeric, String, DateTime, Text, ForeignKey
from sqlalchemy.sql import func
from database.base import Base
from sqlalchemy.orm import relationship


class OrderItems(Base):
    __tablename__ = "order_items"
    id = Column("id", Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    orders = relationship("User", back_populates="cart")
    name = Column("name", String(100), nullable=False, index=True, unique=True)
    products = relationship("Product", back_populates="category")
