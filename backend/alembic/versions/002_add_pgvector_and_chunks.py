"""add pgvector extension and document chunks table

Revision ID: 002_add_pgvector_chunks
Revises: 001_create_documents
Create Date: 2026-11-10 14:35:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from pgvector.sqlalchemy import Vector


# revision identifiers, used by Alembic.
revision: str = '002_add_pgvector_chunks'
down_revision: Union[str, None] = '001_create_documents'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# Embedding dimension matching Gemini gemini-embedding-001 default
EMBEDDING_DIM = 768


def upgrade() -> None:
    conn = op.get_bind()
    dialect_name = conn.dialect.name
    is_postgres = dialect_name == "postgresql"

    # 1. Enable pgvector extension in PostgreSQL
    if is_postgres:
        op.execute("CREATE EXTENSION IF NOT EXISTS vector")

    # 2. Check if table already exists
    inspector = sa.inspect(conn)
    tables = inspector.get_table_names()

    if "document_chunks" not in tables:
        # Define JSON type according to database engine
        metadata_col_type = postgresql.JSONB(astext_type=sa.Text()) if is_postgres else sa.JSON()

        op.create_table(
            'document_chunks',
            sa.Column('id', sa.String(length=36), nullable=False),
            sa.Column('document_id', sa.String(length=36), nullable=False),
            sa.Column('user_id', sa.String(length=36), nullable=False),
            sa.Column('chunk_index', sa.Integer(), nullable=False),
            sa.Column('content', sa.Text(), nullable=False),
            sa.Column('token_count', sa.Integer(), nullable=True),
            sa.Column('page_number', sa.Integer(), nullable=True),
            sa.Column('embedding', Vector(EMBEDDING_DIM), nullable=True),
            sa.Column('metadata', metadata_col_type, nullable=True),
            sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
            sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
            sa.ForeignKeyConstraint(['document_id'], ['documents.id'], ondelete='CASCADE'),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
            sa.PrimaryKeyConstraint('id'),
            sa.UniqueConstraint('document_id', 'chunk_index', name='uq_document_chunk_index'),
        )

        op.create_index('ix_document_chunks_id', 'document_chunks', ['id'], unique=False)
        op.create_index('ix_document_chunks_document_id', 'document_chunks', ['document_id'], unique=False)
        op.create_index('ix_document_chunks_user_id', 'document_chunks', ['user_id'], unique=False)
        op.create_index('ix_document_chunks_created_at', 'document_chunks', ['created_at'], unique=False)
        op.create_index('idx_chunks_document_index', 'document_chunks', ['document_id', 'chunk_index'], unique=False)
        op.create_index('idx_chunks_user_document', 'document_chunks', ['user_id', 'document_id'], unique=False)
        op.create_index('idx_chunks_user_created', 'document_chunks', ['user_id', 'created_at'], unique=False)

        # 3. Create HNSW vector similarity search index (PostgreSQL pgvector)
        if is_postgres:
            op.create_index(
                'idx_chunks_embedding_hnsw',
                'document_chunks',
                ['embedding'],
                postgresql_using='hnsw',
                postgresql_with={'m': 16, 'ef_construction': 64},
                postgresql_ops={'embedding': 'vector_cosine_ops'},
            )


def downgrade() -> None:
    conn = op.get_bind()
    dialect_name = conn.dialect.name
    is_postgres = dialect_name == "postgresql"

    if is_postgres:
        op.drop_index('idx_chunks_embedding_hnsw', table_name='document_chunks')

    op.drop_index('idx_chunks_user_created', table_name='document_chunks')
    op.drop_index('idx_chunks_user_document', table_name='document_chunks')
    op.drop_index('idx_chunks_document_index', table_name='document_chunks')
    op.drop_index('ix_document_chunks_created_at', table_name='document_chunks')
    op.drop_index('ix_document_chunks_user_id', table_name='document_chunks')
    op.drop_index('ix_document_chunks_document_id', table_name='document_chunks')
    op.drop_index('ix_document_chunks_id', table_name='document_chunks')
    op.drop_table('document_chunks')

