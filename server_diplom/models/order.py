from sqlalchemy import Column, ForeignKey, Integer, UniqueConstraint, Text, Numeric, DateTime
from database.base import Base
from sqlalchemy.orm import relationship


class Order(Base):
    __tablename__ = "orders"
    id = Column("id", Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    delivery_type_id = Column(Integer, ForeignKey("delivery_types.id.id"))
    status_id = Column(Integer, ForeignKey("statuses.id"))
    shipping_address = Column(Text, nullable=False)
    city_id = Column(Text, nullable=False)
    pickup_point_id = Column(Integer, ForeignKey("pickup_points.id"))
    total_amount = Column(Numeric(2, 1), nullable=False, default=0)
    phone = Column(Text, nullable=False)
    created_at = Column(DateTime, nullable=False)
    processed_at = Column(DateTime)
    shipped_at = Column(DateTime)
    delivered_at = Column(DateTime)
    product = relationship("Product", back_populates="favorites")
    __table_args__ = (UniqueConstraint("user_id", "product_id"),)
