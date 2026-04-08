from sqlalchemy import Column, ForeignKey, Integer, Text, func, DateTime, Numeric
from database.base import Base
from sqlalchemy.orm import relationship


class Reviews(Base):
    __tablename__ = "reviews"
    id = Column("id", Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    product_id = Column(Integer, ForeignKey("products.id"))
    user = relationship("User", back_populates="reviews")
    product = relationship("Product", back_populates="reviews")
    comment = Column(Text)
    rating = Column(Integer, nullable=False)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
