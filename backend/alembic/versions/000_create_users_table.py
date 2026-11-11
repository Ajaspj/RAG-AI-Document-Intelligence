"""create users table

Revision ID: 000_create_users
Revises: 
Create Date: 2026-11-11 09:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '000_create_users'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    tables = inspector.get_table_names()

    # Strict safety check: Target database must be fresh; fail if users table exists
    if "users" in tables:
        raise RuntimeError(
            "Migration 000 aborted: Table 'users' already exists in the target database. "
            "A fresh, clean database is expected for this migration."
        )

    op.create_table(
        'users',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('email', sa.String(length=255), nullable=False),
        sa.Column('full_name', sa.String(length=255), nullable=False),
        sa.Column('hashed_password', sa.String(length=255), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )

    op.create_index('ix_users_id', 'users', ['id'], unique=False)
    op.create_index('ix_users_email', 'users', ['email'], unique=True)


def downgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    tables = inspector.get_table_names()

    if "users" not in tables:
        return

    # Safety guard: Prevent accidental data loss if dependent tables exist
    dependent_tables = ["documents", "conversations", "messages", "document_chunks"]
    existing_dependents = [tbl for tbl in dependent_tables if tbl in tables]
    if existing_dependents:
        raise RuntimeError(
            f"Cannot downgrade migration 000: Dependent tables exist: {existing_dependents}. "
            "Downgrade dependent migrations first."
        )

    # Safely drop indexes only if they exist, then drop table
    indexes = [idx['name'] for idx in inspector.get_indexes('users')]
    if 'ix_users_email' in indexes:
        op.drop_index('ix_users_email', table_name='users')
    if 'ix_users_id' in indexes:
        op.drop_index('ix_users_id', table_name='users')

    op.drop_table('users')
