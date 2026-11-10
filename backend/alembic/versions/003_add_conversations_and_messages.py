"""add conversations and messages tables

Revision ID: 003_add_conversations_and_messages
Revises: 002_add_pgvector_chunks
Create Date: 2026-11-10 15:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '003_add_conversations_and_messages'
down_revision: Union[str, None] = '002_add_pgvector_chunks'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    dialect_name = conn.dialect.name
    is_postgres = dialect_name == "postgresql"

    inspector = sa.inspect(conn)
    tables = inspector.get_table_names()

    json_type = postgresql.JSONB(astext_type=sa.Text()) if is_postgres else sa.JSON()

    # 1. Create conversations table
    if "conversations" not in tables:
        op.create_table(
            'conversations',
            sa.Column('id', sa.String(length=36), nullable=False),
            sa.Column('user_id', sa.String(length=36), nullable=False),
            sa.Column('title', sa.String(length=255), nullable=False, server_default='New Conversation'),
            sa.Column('document_ids', json_type, nullable=True),
            sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
            sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
            sa.PrimaryKeyConstraint('id'),
        )

        op.create_index('ix_conversations_id', 'conversations', ['id'], unique=False)
        op.create_index('ix_conversations_user_id', 'conversations', ['user_id'], unique=False)
        op.create_index('ix_conversations_created_at', 'conversations', ['created_at'], unique=False)
        op.create_index('ix_conversations_updated_at', 'conversations', ['updated_at'], unique=False)
        op.create_index('idx_conversations_user_updated', 'conversations', ['user_id', 'updated_at'], unique=False)

    # 2. Create messages table
    if "messages" not in tables:
        op.create_table(
            'messages',
            sa.Column('id', sa.String(length=36), nullable=False),
            sa.Column('conversation_id', sa.String(length=36), nullable=False),
            sa.Column('user_id', sa.String(length=36), nullable=False),
            sa.Column('role', sa.String(length=20), nullable=False),
            sa.Column('content', sa.Text(), nullable=False),
            sa.Column('citations', json_type, nullable=True),
            sa.Column('retrieval_metadata', json_type, nullable=True),
            sa.Column('token_usage', json_type, nullable=True),
            sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
            sa.ForeignKeyConstraint(['conversation_id'], ['conversations.id'], ondelete='CASCADE'),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
            sa.PrimaryKeyConstraint('id'),
        )

        op.create_index('ix_messages_id', 'messages', ['id'], unique=False)
        op.create_index('ix_messages_conversation_id', 'messages', ['conversation_id'], unique=False)
        op.create_index('ix_messages_user_id', 'messages', ['user_id'], unique=False)
        op.create_index('ix_messages_created_at', 'messages', ['created_at'], unique=False)
        op.create_index('idx_messages_conversation_created', 'messages', ['conversation_id', 'created_at'], unique=False)
        op.create_index('idx_messages_user_created', 'messages', ['user_id', 'created_at'], unique=False)


def downgrade() -> None:
    op.drop_index('idx_messages_user_created', table_name='messages')
    op.drop_index('idx_messages_conversation_created', table_name='messages')
    op.drop_index('ix_messages_created_at', table_name='messages')
    op.drop_index('ix_messages_user_id', table_name='messages')
    op.drop_index('ix_messages_conversation_id', table_name='messages')
    op.drop_index('ix_messages_id', table_name='messages')
    op.drop_table('messages')

    op.drop_index('idx_conversations_user_updated', table_name='conversations')
    op.drop_index('ix_conversations_updated_at', table_name='conversations')
    op.drop_index('ix_conversations_created_at', table_name='conversations')
    op.drop_index('ix_conversations_user_id', table_name='conversations')
    op.drop_index('ix_conversations_id', table_name='conversations')
    op.drop_table('conversations')

