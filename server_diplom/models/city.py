from sqlalchemy import Column, Integer, Numeric, String, DateTime, Text
from sqlalchemy.sql import func
from database.base import Base
from sqlalchemy.orm import relationship


class City(Base):
    __tablename__ = "cities"
    id = Column("id", Integer, primary_key=True, index=True)
    name = Column("name", Text, nullable=False, index=True, unique=True)
    products = relationship("Product", back_populates="category")
