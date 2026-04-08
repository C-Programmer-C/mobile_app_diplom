"""add delivery eta fields

Revision ID: e1b7f6a9c2d4
Revises: d970d5774696
Create Date: 2026-04-08 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "e1b7f6a9c2d4"
down_revision: Union[str, Sequence[str], None] = "d970d5774696"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "pickup_points",
        sa.Column("estimated_days", sa.Integer(), nullable=True),
    )
    op.execute("UPDATE pickup_points SET estimated_days = 3 WHERE estimated_days IS NULL")
    op.alter_column("pickup_points", "estimated_days", nullable=False)

    op.add_column("orders", sa.Column("delivery_at", sa.DateTime(), nullable=True))
    op.add_column("orders", sa.Column("delivery_comment", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("orders", "delivery_comment")
    op.drop_column("orders", "delivery_at")
    op.drop_column("pickup_points", "estimated_days")
