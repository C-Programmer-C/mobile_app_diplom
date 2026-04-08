"""remove fields

Revision ID: 0981953ae90a
Revises: c3751e0dc5ac
Create Date: 2026-03-18 09:09:59.299348

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '0981953ae90a'
down_revision: Union[str, Sequence[str], None] = 'c3751e0dc5ac'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Переименование таблицы
    op.rename_table("fabricators", "brands")

    # 2. Переименование индексов
    op.drop_index(op.f("ix_fabricators_id"), table_name="brands")
    op.drop_index(op.f("ix_fabricators_name"), table_name="brands")

    op.create_index(op.f("ix_brands_id"), "brands", ["id"], unique=False)
    op.create_index(op.f("ix_brands_name"), "brands", ["name"], unique=True)

    # 3. Переименование колонки в products
    op.alter_column("products", "fabricator_id", new_column_name="brand_id")

    # 4. Обновление внешнего ключа
    op.drop_constraint(
        op.f("products_fabricator_id_fkey"), "products", type_="foreignkey"
    )

    op.create_foreign_key(
        "products_brand_id_fkey", "products", "brands", ["brand_id"], ["id"]
    )


def downgrade() -> None:
    op.drop_constraint("products_brand_id_fkey", "products", type_="foreignkey")

    op.alter_column("products", "brand_id", new_column_name="fabricator_id")

    op.create_foreign_key(
        op.f("products_fabricator_id_fkey"),
        "products",
        "brands",
        ["fabricator_id"],
        ["id"],
    )

    op.rename_table("brands", "fabricators")

    op.drop_index(op.f("ix_brands_id"), table_name="fabricators")
    op.drop_index(op.f("ix_brands_name"), table_name="fabricators")

    op.create_index(op.f("ix_fabricators_id"), "fabricators", ["id"], unique=False)
    op.create_index(op.f("ix_fabricators_name"), "fabricators", ["name"], unique=True)
