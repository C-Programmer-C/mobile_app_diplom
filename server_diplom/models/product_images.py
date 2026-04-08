from sqlalchemy import Column, ForeignKey, Integer, Numeric, String, DateTime, Text, Boolean
from sqlalchemy.sql import func
from database.base import Base
from sqlalchemy.orm import relationship


class ProductImages(Base):
    __tablename__ = "product_images"
    id = Column("id", Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"))
    name = Column("name", String(100), nullable=False, index=True, unique=True)
    image_url = Column(Text)
    is_main = Column(Boolean, default=False)      
    product = relationship("Product", back_populates="product_images")
