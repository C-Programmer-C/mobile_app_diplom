from sqlalchemy import Column, Integer, Numeric, String, DateTime, Text
from sqlalchemy.sql import func
from database.base import Base
from sqlalchemy.orm import relationship


class DeliveryType(Base):
    __tablename__ = "delivery_types"
    id = Column("id", Integer, primary_key=True, index=True)
    name = Column("name", String(100), nullable=False, index=True, unique=True)
    products = relationship("Order", back_populates="delivery_types")
