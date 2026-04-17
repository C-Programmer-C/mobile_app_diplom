"""rename delivery_at, add pickup flow timestamps

Revision ID: f7c8d9e0a1b2
Revises: e3f4a5b6c7d8
Create Date: 2026-04-15 12:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "f7c8d9e0a1b2"
down_revision: Union[str, Sequence[str], None] = "e3f4a5b6c7d8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("orders", sa.Column("ready_for_pickup_at", sa.DateTime(), nullable=True))
    op.add_column("orders", sa.Column("pickup_at", sa.DateTime(), nullable=True))
    op.add_column("orders", sa.Column("estimated_delivery_at", sa.DateTime(), nullable=True))
    conn = op.get_bind()
    conn.execute(sa.text("UPDATE orders SET estimated_delivery_at = delivery_at"))
    op.drop_column("orders", "delivery_at")


def downgrade() -> None:
    op.add_column("orders", sa.Column("delivery_at", sa.DateTime(), nullable=True))
    conn = op.get_bind()
    conn.execute(sa.text("UPDATE orders SET delivery_at = estimated_delivery_at"))
    op.drop_column("orders", "estimated_delivery_at")
    op.drop_column("orders", "pickup_at")
    op.drop_column("orders", "ready_for_pickup_at")
