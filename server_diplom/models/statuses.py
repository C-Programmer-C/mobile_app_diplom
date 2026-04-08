from enum import Enum as PyEnum
from sqlalchemy import Column, Integer, Enum as SAEnum
from database.base import Base
from sqlalchemy.orm import relationship

class OrderStatusEnum(str, PyEnum):
    canceled = "canceled"
    pending = "pending"
    processing = "processing"
    shipped = "shipped"
    in_transit = "in_transit"
    delivered = "delivered"
    pickup = "pickup"
    ready_for_pickup = "ready_for_pickup"

class Status(Base):
    __tablename__ = "statuses"
    id = Column("id", Integer, primary_key=True, index=True)
    name = Column(SAEnum(OrderStatusEnum), nullable=False, index=True, unique=True)  # type: ignore
    orders = relationship("Order", back_populates="status")
