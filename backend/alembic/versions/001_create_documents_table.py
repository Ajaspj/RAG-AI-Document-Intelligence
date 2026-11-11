"""create documents table

Revision ID: 001_create_documents
Revises: 000_create_users
Create Date: 2026-11-10 10:20:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '001_create_documents'
down_revision: Union[str, None] = '000_create_users'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Check if table already exists (in case Base.metadata.create_all was used)
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    tables = inspector.get_table_names()

    if "documents" not in tables:
        op.create_table(
            'documents',
            sa.Column('id', sa.String(length=36), nullable=False),
            sa.Column('user_id', sa.String(length=36), nullable=False),
            sa.Column('filename', sa.String(length=255), nullable=False),
            sa.Column('original_filename', sa.String(length=255), nullable=False),
            sa.Column('file_extension', sa.String(length=10), nullable=False),
            sa.Column('mime_type', sa.String(length=100), nullable=False),
            sa.Column('file_size', sa.BigInteger(), nullable=False),
            sa.Column('storage_path', sa.String(length=500), nullable=False),
            sa.Column('file_hash', sa.String(length=64), nullable=True),
            sa.Column('status', sa.String(length=20), nullable=False, server_default='pending'),
            sa.Column('error_message', sa.Text(), nullable=True),
            sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
            sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
            sa.PrimaryKeyConstraint('id'),
            sa.UniqueConstraint('filename'),
        )

        op.create_index('ix_documents_id', 'documents', ['id'], unique=False)
        op.create_index('ix_documents_user_id', 'documents', ['user_id'], unique=False)
        op.create_index('ix_documents_filename', 'documents', ['filename'], unique=True)
        op.create_index('ix_documents_file_extension', 'documents', ['file_extension'], unique=False)
        op.create_index('ix_documents_file_hash', 'documents', ['file_hash'], unique=False)
        op.create_index('ix_documents_status', 'documents', ['status'], unique=False)
        op.create_index('ix_documents_created_at', 'documents', ['created_at'], unique=False)
        op.create_index('idx_documents_user_created', 'documents', ['user_id', 'created_at'], unique=False)
        op.create_index('idx_documents_user_status', 'documents', ['user_id', 'status'], unique=False)


def downgrade() -> None:
    op.drop_index('idx_documents_user_status', table_name='documents')
    op.drop_index('idx_documents_user_created', table_name='documents')
    op.drop_index('ix_documents_created_at', table_name='documents')
    op.drop_index('ix_documents_status', table_name='documents')
    op.drop_index('ix_documents_file_hash', table_name='documents')
    op.drop_index('ix_documents_file_extension', table_name='documents')
    op.drop_index('ix_documents_filename', table_name='documents')
    op.drop_index('ix_documents_user_id', table_name='documents')
    op.drop_index('ix_documents_id', table_name='documents')
    op.drop_table('documents')

