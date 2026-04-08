from sqlalchemy import Column, Integer, Numeric, ForeignKey
from database.base import Base
from sqlalchemy.orm import relationship


class OrderItem(Base):
    __tablename__ = "order_items"
    id = Column("id", Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    order = relationship("Order", back_populates="items")
    product = relationship("Product", back_populates="order_items")
    quantity = Column(Integer, nullable=False)
    price = Column(Numeric(10, 2), nullable=False)