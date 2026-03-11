from sqlalchemy import Column, Integer, Numeric, String, DateTime, Text
from sqlalchemy.sql import func
from database.base import Base
from sqlalchemy.orm import relationship


class Supplier(Base):
    __tablename__ = "suppliers"
    id = Column("id", Integer, primary_key=True, index=True)
    name = Column("name", String(100), nullable=False, index=True, unique=True)
    description = Column(Text)
    phone = Column(Text)
    email = Column(Text)
    address = Column(Text)
    rating = Column(Numeric(5, 2), nullable=False, default=0)
    products = relationship("Product", back_populates="supplier")
