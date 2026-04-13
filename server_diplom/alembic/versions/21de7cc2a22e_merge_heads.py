"""merge heads

Revision ID: 21de7cc2a22e
Revises: 3906db666b7f, e1b7f6a9c2d4
Create Date: 2026-04-09 02:11:47.385247

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '21de7cc2a22e'
down_revision: Union[str, Sequence[str], None] = ('3906db666b7f', 'e1b7f6a9c2d4')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
