from sqlalchemy import Column, ForeignKey, Integer, Numeric, String, DateTime, Text, UniqueConstraint
from sqlalchemy.sql import func
from database.base import Base
from sqlalchemy.orm import relationship


class Cart(Base):
    __tablename__ = "cart"
    id = Column("id", Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    users = relationship("User", back_populates="cart")
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity = Column(Integer, nullable=False, default=1)
    added_at = Column(DateTime, nullable=False, server_default=func.now())
    __table_args__ = (UniqueConstraint("user_id", "product_id"),)
