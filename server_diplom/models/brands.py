from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship

from database.base import Base


class Brand(Base):
    __tablename__ = "brands"

    id = Column("id", Integer, primary_key=True, index=True)
    name = Column("name", String(100), nullable=False, index=True, unique=True)
    products = relationship("Product", back_populates="brand")
