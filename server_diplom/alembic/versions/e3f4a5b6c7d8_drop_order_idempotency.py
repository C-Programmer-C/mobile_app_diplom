"""drop order idempotency (removed feature)

Revision ID: e3f4a5b6c7d8
Revises: b2c4e8a1d0f3
Create Date: 2026-04-13

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "e3f4a5b6c7d8"
down_revision: Union[str, Sequence[str], None] = "b2c4e8a1d0f3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        sa.text(
            "ALTER TABLE orders DROP CONSTRAINT IF EXISTS uq_orders_user_client_idempotency"
        )
    )
    op.execute(sa.text("ALTER TABLE orders DROP COLUMN IF EXISTS client_idempotency_key"))


def downgrade() -> None:
    op.add_column(
        "orders",
        sa.Column("client_idempotency_key", sa.String(length=64), nullable=True),
    )
    op.create_unique_constraint(
        "uq_orders_user_client_idempotency",
        "orders",
        ["user_id", "client_idempotency_key"],
    )
