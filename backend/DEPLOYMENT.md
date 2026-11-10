# DocuMind AI — Backend Deployment & Operations Guide

This guide provides operational and configuration instructions for deploying the **DocuMind AI** FastAPI backend with PostgreSQL, pgvector, and Gemini conversational RAG.

---

## 1. System Requirements

### Software
- **Python**: 3.10, 3.11, or 3.12 (64-bit recommended)
- **PostgreSQL**: Version 15 or 16 with the `pgvector` extension (v0.5.0 or later)
- **Operating System**: Linux (Ubuntu 22.04 LTS / Debian 12 / RHEL 9), macOS, or Windows 10/11 / Windows Server 2022
- **Process Manager**: Systemd / Supervisord / Docker (for production)
- **Reverse Proxy**: Nginx, Caddy, or AWS ALB / Cloudflare (with TLS termination)

### Hardware Recommendations
- **Minimum (Dev/Test)**: 2 CPU cores, 4 GB RAM, 20 GB SSD
- **Production**: 4+ CPU cores, 8–16 GB RAM, High-IOPS NVMe SSD (pgvector index queries are memory- and IO-bound)

---

## 2. Environment Variables Configuration

Copy `.env.example` to `.env` in the `backend/` directory:

```bash
cp .env.example .env
```

### Critical Environment Variables

| Variable | Type | Default / Example | Purpose & Notes |
|---|---|---|---|
| `ENVIRONMENT` | string | `development` or `production` | When set to `production`, enforces strict secret key validation and restricted CORS. |
| `PROJECT_NAME` | string | `DocuMind AI Backend` | Display name for OpenAPI docs and health endpoints. |
| `API_V1_STR` | string | `/api/v1` | URL routing prefix for all version 1 endpoints. |
| `SECRET_KEY` | string | `[32+ character random string]` | Secret key used to sign JWT access and refresh tokens. **Must be changed in production.** |
| `ALGORITHM` | string | `HS256` | JWT signing algorithm. |
| `ACCESS_TOKEN_EXPIRE_MINUTES`| int | `1440` (24 hours) | Access token lifetime. |
| `REFRESH_TOKEN_EXPIRE_DAYS` | int | `7` | Refresh token lifetime. |
| `DATABASE_URL` | string | `postgresql+psycopg://user:pw@host:5432/db` | PostgreSQL connection string using the high-performance `psycopg` (v3) driver. |
| `DB_POOL_SIZE` | int | `10` | SQLAlchemy persistent connection pool size. |
| `DB_MAX_OVERFLOW` | int | `20` | Maximum surge connections beyond pool size. |
| `DB_POOL_TIMEOUT` | int | `30` | Seconds to wait before timing out on connection pool exhaustion. |
| `DB_POOL_RECYCLE` | int | `1800` | Seconds after which idle database connections are refreshed (avoids stale socket disconnects). |
| `DB_POOL_PRE_PING` | bool | `true` | Tests connection liveness before checking out from pool. |
| `GEMINI_API_KEY` | string | `AIzaSy...` | Google AI Studio API key used for embeddings and chat generation. |
| `EMBEDDING_MODEL` | string | `gemini-embedding-001` | Embedding model identifier. |
| `EMBEDDING_DIMENSION` | int | `768` | Fixed output vector dimension. Must match the database schema column `Vector(768)`. |
| `EMBEDDING_TASK_TYPE_DOCUMENT`| string | `RETRIEVAL_DOCUMENT` | Task type for ingested document chunks. |
| `EMBEDDING_TASK_TYPE_QUERY`| string | `RETRIEVAL_QUERY` | Task type for user search questions. |
| `EMBEDDING_NORMALIZE` | bool | `true` | Normalizes 768-dim embeddings to unit L2 norm for cosine distance. |
| `GEMINI_CHAT_MODEL` | string | `gemini-1.5-flash` | Generative chat model for grounded conversational answers. |
| `GEMINI_TEMPERATURE` | float | `0.2` | Low temperature ensures factual, deterministic grounded generation. |
| `GEMINI_MAX_OUTPUT_TOKENS` | int | `1024` | Maximum length of assistant responses. |
| `DOCUMENT_STORAGE_DIR` | string | `./storage/documents` | Directory where uploaded raw files (PDF, DOCX, TXT) are persisted on disk. |
| `MAX_FILE_SIZE_BYTES` | int | `20971520` (20 MB) | Maximum permitted file upload size. |
| `LOG_LEVEL` | string | `INFO` | Console logging level (`DEBUG`, `INFO`, `WARNING`, `ERROR`). |

---

## 3. PostgreSQL & pgvector Setup

### 1. Install PostgreSQL and pgvector
On Ubuntu / Debian:
```bash
sudo apt update
sudo apt install -y postgresql postgresql-contrib postgresql-server-dev-16
git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git
cd pgvector
make
sudo make install
```

On Windows:
Download the pre-compiled pgvector binaries from the [pgvector GitHub releases](https://github.com/pgvector/pgvector/releases) matching your PostgreSQL major version, and copy the `.dll` and `.control` files into your PostgreSQL `lib/` and `share/extension/` folders.

### 2. Create Database and Enable Extension
Connect as superuser (`postgres`):
```sql
CREATE USER documind WITH PASSWORD 'your_strong_db_password';
CREATE DATABASE documind_db OWNER documind;
\connect documind_db
CREATE EXTENSION IF NOT EXISTS vector;
```

---

## 4. Database Migrations

Database schema revisions are managed through Alembic.

### Apply Migrations (Production / Setup)
```bash
cd backend
# Activate virtual environment
source venv/bin/activate  # On Windows: .\venv\Scripts\Activate.ps1

# Run migrations up to latest revision (004)
alembic upgrade head
```

### Migration History Chain
1. `001_create_documents`: Creates `users` and `documents` tables.
2. `002_add_pgvector_chunks`: Enables `vector` extension and creates `document_chunks` table with `Vector(768)` and HNSW index.
3. `003_add_conversations_and_messages`: Creates `conversations` and `messages` tables with cascade deletion.
4. `004_add_conversation_archive_fields`: Adds `is_archived`, `archived_at`, and compound index `idx_conversations_user_archived_updated`.

---

## 5. File Storage & Permissions

The backend persists raw uploaded documents to disk in `DOCUMENT_STORAGE_DIR`.

### Linux / Unix Directory Setup:
```bash
sudo mkdir -p /var/documind/storage/documents
sudo chown -R documind:documind /var/documind/storage
sudo chmod -R 750 /var/documind/storage
```
Update `.env`:
```env
DOCUMENT_STORAGE_DIR="/var/documind/storage/documents"
```

---

## 6. Running the Backend

### Development Mode (with Hot Reload)
```bash
cd backend
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Production Mode (Gunicorn with Uvicorn Workers)
For production Linux servers, run Gunicorn with `uvicorn.workers.UvicornWorker`:
```bash
gunicorn app.main:app \
  --workers 4 \
  --worker-class uvicorn.workers.UvicornWorker \
  --bind 0.0.0.0:8000 \
  --timeout 120 \
  --keep-alive 5 \
  --access-logfile /var/log/documind/access.log \
  --error-logfile /var/log/documind/error.log
```

---

## 7. Mobile Client Connection Guide

The Flutter client connects to the FastAPI backend over HTTP/HTTPS. Configure the base URL in [`mobile/lib/core/constants/app_constants.dart`](file:///d:/nodejs%20projects/RAG-AI%20Document%20Intelligence/mobile/lib/core/constants/app_constants.dart).

### 1. Android Emulator Loopback
- **Host Loopback**: `http://10.0.2.2:8000/api/v1`
- The Android emulator runs in a QEMU virtual network where `10.0.2.2` routes directly to the development host machine's `127.0.0.1`.
- Backend must listen on `0.0.0.0` or `127.0.0.1`.

### 2. iOS Simulator
- **Host Loopback**: `http://127.0.0.1:8000/api/v1`
- The iOS simulator shares the macOS host network interface directly.

### 3. Physical Devices (Android & iOS)
- When testing on physical mobile devices connected to the local Wi-Fi:
  - Find host machine local LAN IP (e.g., `192.168.1.50`).
  - Configure `AppConstants.defaultAndroidBaseUrl = 'http://192.168.1.50:8000'`.
  - Ensure the host firewall allows inbound connections on TCP port 8000.
  - In Android `AndroidManifest.xml`, `android:usesCleartextTraffic="true"` is enabled for local HTTP development.

---

## 8. Production Architecture & Hardening Checklist

1. **HTTPS / TLS Termination**: Never transmit JWT tokens or documents over unencrypted HTTP in production. Terminate TLS at Nginx or Cloudflare.
2. **Reverse Proxy Nginx Configuration**:
   ```nginx
   server {
       server_name api.documind.example.com;
       client_max_body_size 25M;

       location / {
           proxy_pass http://127.0.0.1:8000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
           proxy_read_timeout 90s;
           proxy_connect_timeout 30s;
       }
   }
   ```
3. **Durable Task Queue Consideration**:
   FastAPI `BackgroundTasks` executes in-process. If the backend process restarts during text extraction or embedding generation, the task will be lost (leaving the document marked as `processing` until retried). For enterprise production deployments, migrating `ProcessingService` execution to a durable worker queue (such as Celery with Redis or ARQ) is recommended.
4. **Secret Management**:
   Do not commit `.env` files into version control. Use environment injection via AWS Secrets Manager, HashiCorp Vault, or Kubernetes Secrets.

