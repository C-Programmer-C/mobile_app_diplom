"""placeholder: idempotency migration was removed; keep revision id for DB history

Revision ID: b2c4e8a1d0f3
Revises: d8b33684df79
Create Date: 2026-04-13

"""
from typing import Sequence, Union

from alembic import op


revision: str = "b2c4e8a1d0f3"
down_revision: Union[str, Sequence[str], None] = "d8b33684df79"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
