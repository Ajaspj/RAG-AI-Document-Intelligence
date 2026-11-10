import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.session import Base, get_db
from app.main import app

# In-memory SQLite database specifically for test isolation
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_register_user_success():
    payload = {
        "email": "test@documind.ai",
        "full_name": "Test User",
        "password": "SecurePassword123!",
    }
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"
    assert data["user"]["email"] == "test@documind.ai"
    assert data["user"]["full_name"] == "Test User"
    assert "password" not in data["user"]
    assert "hashed_password" not in data["user"]


def test_register_duplicate_email_fails():
    payload = {
        "email": "duplicate@documind.ai",
        "full_name": "First User",
        "password": "Password123!",
    }
    res1 = client.post("/api/v1/auth/register", json=payload)
    assert res1.status_code == 201

    # Attempt to register with the same email
    res2 = client.post("/api/v1/auth/register", json=payload)
    assert res2.status_code == 400
    assert "already exists" in res2.json()["detail"]


def test_login_success():
    # Register first
    reg_payload = {
        "email": "login@documind.ai",
        "full_name": "Login User",
        "password": "Password123!",
    }
    client.post("/api/v1/auth/register", json=reg_payload)

    # Login
    login_payload = {
        "email": "login@documind.ai",
        "password": "Password123!",
    }
    response = client.post("/api/v1/auth/login", json=login_payload)
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["user"]["email"] == "login@documind.ai"


def test_login_invalid_password_fails():
    reg_payload = {
        "email": "wrongpwd@documind.ai",
        "full_name": "User",
        "password": "CorrectPassword123!",
    }
    client.post("/api/v1/auth/register", json=reg_payload)

    login_payload = {
        "email": "wrongpwd@documind.ai",
        "password": "WrongPassword!",
    }
    response = client.post("/api/v1/auth/login", json=login_payload)
    assert response.status_code == 401
    assert "Invalid email or password" in response.json()["detail"]


def test_get_me_unauthorized_without_token():
    response = client.get("/api/v1/auth/me")
    assert response.status_code == 401


def test_get_me_authorized_with_valid_token():
    reg_payload = {
        "email": "me@documind.ai",
        "full_name": "Me User",
        "password": "Password123!",
    }
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    token = reg_res.json()["access_token"]

    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    user_data = response.json()
    assert user_data["email"] == "me@documind.ai"
    assert user_data["full_name"] == "Me User"


def test_refresh_token_success():
    reg_payload = {
        "email": "refresh@documind.ai",
        "full_name": "Refresh User",
        "password": "Password123!",
    }
    reg_res = client.post("/api/v1/auth/register", json=reg_payload)
    refresh_token = reg_res.json()["refresh_token"]

    response = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user"]["email"] == "refresh@documind.ai"


def test_forgot_password():
    response = client.post(
        "/api/v1/auth/forgot-password",
        json={"email": "forgot@documind.ai"},
    )
    assert response.status_code == 200
    assert response.json()["success"] is True
    assert "Password reset instructions" in response.json()["message"]
