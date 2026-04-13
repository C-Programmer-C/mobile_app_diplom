from sqlalchemy import Column, ForeignKey, Integer, String, Text, Numeric, DateTime
from sqlalchemy.sql import func
from database.base import Base
from sqlalchemy.orm import relationship


class Order(Base):
    __tablename__ = "orders"
    id = Column("id", Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    delivery_type_id = Column(Integer, ForeignKey("delivery_types.id"), nullable=False, index=True)
    status_id = Column(Integer, ForeignKey("statuses.id"), nullable=False, index=True)
    shipping_address = Column(Text, nullable=False)
    city_id = Column(Integer, ForeignKey("cities.id"), index=True, nullable=True)
    pickup_point_id = Column(Integer, ForeignKey("pickup_points.id"), nullable=True, index=True)
    total_amount = Column(Numeric(10, 2), nullable=False, default=0)
    phone = Column(Text, nullable=False)
    delivery_at = Column(DateTime, nullable=True)
    delivery_comment = Column(Text, nullable=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now())
    processed_at = Column(DateTime)
    canceled_at = Column(DateTime)
    shipped_at = Column(DateTime)
    delivered_at = Column(DateTime)
    payment_status = Column(String, nullable=False, default="pending")
    paid_at = Column(DateTime, nullable=True)
    payment_method = Column(String, nullable=True)
    user = relationship("User", back_populates="orders")
    status = relationship("Status", back_populates="orders")
    delivery_type = relationship("DeliveryType", back_populates="orders")
    city = relationship("City", back_populates="orders")
    pickup_point = relationship("PickupPoint", back_populates="orders")
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
