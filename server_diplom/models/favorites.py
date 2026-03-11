from sqlalchemy import Column, ForeignKey, Integer, Numeric, String, DateTime, Text, UniqueConstraint
from database.base import Base
from sqlalchemy.orm import relationship


class Favorites(Base):
    __tablename__ = "favorites"
    id = Column("id", Integer, primary_key=True, index=True)

    user_id = Column(Integer, ForeignKey("users.id"))
    product_id = Column(Integer, ForeignKey("products.id"))
    user = relationship("User", back_populates="favorites")
    product = relationship("Product", back_populates="favorites")
    __table_args__ = (UniqueConstraint("user_id", "product_id"),)
