from sqlalchemy import Column, ForeignKey, Integer, UniqueConstraint, Text
from database.base import Base
from sqlalchemy.orm import relationship


class Orders(Base):
    __tablename__ = "orders"
    id = Column("id", Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    total_amount = Column(Integer, nullable=False)
    status = Column(Text, nullable=False, default="pending")
    shipping_address = Column(Text, nullable=False)
    city = Column(Text, nullable=False)
    
    product_id = Column(Integer, ForeignKey("products.id"))
    product = relationship("Product", back_populates="favorites")
    __table_args__ = (UniqueConstraint("user_id", "product_id"),)
