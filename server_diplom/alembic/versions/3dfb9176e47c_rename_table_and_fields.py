"""rename table and fields

Revision ID: 3dfb9176e47c
Revises: 277806186239
Create Date: 2026-03-18 07:15:20.268347

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '3dfb9176e47c'
down_revision: Union[str, Sequence[str], None] = '277806186239'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Переименовать таблицу
    op.rename_table("suppliers", "fabricators")

    # 2. Переименовать индексы (важно!)
    op.drop_index(op.f("ix_suppliers_id"), table_name="fabricators")
    op.drop_index(op.f("ix_suppliers_name"), table_name="fabricators")

    op.create_index(op.f("ix_fabricators_id"), "fabricators", ["id"], unique=False)
    op.create_index(op.f("ix_fabricators_name"), "fabricators", ["name"], unique=True)

    # 3. Добавить новую колонку
    op.add_column("products", sa.Column("fabricator_id", sa.Integer(), nullable=True))

    # 4. Перенести данные из старого поля
    op.execute(
        """
        UPDATE products
        SET fabricator_id = supplier_id
    """
    )

    # 5. Сделать NOT NULL (после переноса)
    op.alter_column("products", "fabricator_id", nullable=False)

    # 6. Обновить внешний ключ
    op.drop_constraint(
        op.f("products_supplier_id_fkey"), "products", type_="foreignkey"
    )

    op.create_foreign_key(
        "products_fabricator_id_fkey",
        "products",
        "fabricators",
        ["fabricator_id"],
        ["id"],
    )

    # 7. Удалить старую колонку
    op.drop_column("products", "supplier_id")


def downgrade() -> None:
    op.add_column("products", sa.Column("supplier_id", sa.Integer(), nullable=True))

    op.execute(
        """
        UPDATE products
        SET supplier_id = fabricator_id
    """
    )

    op.alter_column("products", "supplier_id", nullable=False)

    op.drop_constraint("products_fabricator_id_fkey", "products", type_="foreignkey")

    op.create_foreign_key(
        op.f("products_supplier_id_fkey"),
        "products",
        "fabricators",
        ["supplier_id"],
        ["id"],
    )

    op.drop_column("products", "fabricator_id")

    op.rename_table("fabricators", "suppliers")

    op.drop_index(op.f("ix_fabricators_id"), table_name="suppliers")
    op.drop_index(op.f("ix_fabricators_name"), table_name="suppliers")

    op.create_index(op.f("ix_suppliers_id"), "suppliers", ["id"], unique=False)
    op.create_index(op.f("ix_suppliers_name"), "suppliers", ["name"], unique=True)
