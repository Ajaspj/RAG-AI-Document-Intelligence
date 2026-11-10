"""add conversation archive fields

Revision ID: 004_add_conversation_archive_fields
Revises: 003_add_conversations_and_messages
Create Date: 2026-11-10 15:20:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '004_add_conversation_archive_fields'
down_revision: Union[str, None] = '003_add_conversations_and_messages'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    columns = [col['name'] for col in inspector.get_columns('conversations')]

    if "is_archived" not in columns:
        op.add_column(
            'conversations',
            sa.Column('is_archived', sa.Boolean(), nullable=False, server_default=sa.false()),
        )
        op.create_index('ix_conversations_is_archived', 'conversations', ['is_archived'], unique=False)

    if "archived_at" not in columns:
        op.add_column(
            'conversations',
            sa.Column('archived_at', sa.DateTime(timezone=True), nullable=True),
        )

    # Compound index
    indexes = [idx['name'] for idx in inspector.get_indexes('conversations')]
    if "idx_conversations_user_archived_updated" not in indexes:
        op.create_index(
            'idx_conversations_user_archived_updated',
            'conversations',
            ['user_id', 'is_archived', 'updated_at'],
            unique=False,
        )


def downgrade() -> None:
    op.drop_index('idx_conversations_user_archived_updated', table_name='conversations')
    op.drop_index('ix_conversations_is_archived', table_name='conversations')
    op.drop_column('conversations', 'archived_at')
    op.drop_column('conversations', 'is_archived')

