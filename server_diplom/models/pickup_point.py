from sqlalchemy import Column, ForeignKey, Integer, Numeric, String, DateTime, Text
from sqlalchemy.sql import func
from database.base import Base
from sqlalchemy.orm import relationship


class PickupPoint(Base):
    __tablename__ = "pickup_points"
    id = Column("id", Integer, primary_key=True, index=True)
    city_id = Column(Integer, ForeignKey("cities.id"))
    name = Column("name", String(100), nullable=False, index=True, unique=True)
    address = Column(Text)
    working_hours = Column(Text)            
    orders = relationship("Order", back_populates="pickup_points")
