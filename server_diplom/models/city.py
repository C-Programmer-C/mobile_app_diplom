from sqlalchemy import Column, Integer, Numeric, String, DateTime, Text
from sqlalchemy.sql import func
from database.base import Base
from sqlalchemy.orm import relationship


class City(Base):
    __tablename__ = "cities"
    id = Column("id", Integer, primary_key=True, index=True)
    name = Column("name", Text, nullable=False, index=True, unique=True)
    pickup_points = relationship("PickupPoint", back_populates="city")
    orders = relationship("Order", back_populates="city")
