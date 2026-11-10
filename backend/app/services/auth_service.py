from typing import Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models.user import User
from app.schemas.auth import Token, UserCreate, UserLogin, UserResponse


class AuthService:
    @staticmethod
    def register_user(db: Session, user_in: UserCreate) -> Token:
        # Check if email is already registered
        existing_user = db.query(User).filter(User.email == user_in.email.lower().strip()).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="An account with this email address already exists.",
            )

        hashed_password = hash_password(user_in.password)
        user = User(
            email=user_in.email.lower().strip(),
            full_name=user_in.full_name.strip(),
            hashed_password=hashed_password,
            is_active=True,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

        access_token = create_access_token(user.id)
        refresh_token = create_refresh_token(user.id)
        user_response = UserResponse.model_validate(user)

        return Token(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            user=user_response,
        )

    @staticmethod
    def authenticate_user(db: Session, login_data: UserLogin) -> Token:
        user = db.query(User).filter(User.email == login_data.email.lower().strip()).first()
        if not user or not verify_password(login_data.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Inactive user account.",
            )

        access_token = create_access_token(user.id)
        refresh_token = create_refresh_token(user.id)
        user_response = UserResponse.model_validate(user)

        return Token(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            user=user_response,
        )

    @staticmethod
    def refresh_user_token(db: Session, refresh_token: str) -> Token:
        payload = decode_token(refresh_token)
        if not payload or payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired refresh token.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        user_id = payload.get("sub")
        user = db.query(User).filter(User.id == user_id).first()
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        new_access_token = create_access_token(user.id)
        new_refresh_token = create_refresh_token(user.id)
        user_response = UserResponse.model_validate(user)

        return Token(
            access_token=new_access_token,
            refresh_token=new_refresh_token,
            token_type="bearer",
            user=user_response,
        )

    @staticmethod
    def get_user_from_token(db: Session, token: str) -> User:
        payload = decode_token(token)
        if not payload or payload.get("type") != "access":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token subject missing.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        user = db.query(User).filter(User.id == user_id).first()
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        return user

    @staticmethod
    def request_password_reset(db: Session, email: str) -> str:
        user = db.query(User).filter(User.email == email.lower().strip()).first()
        if not user:
            return "If an account with that email exists, Password reset instructions have been logged for development."
        
        return f"Development Mode: Password reset instructions simulated for {user.email}. In production, an email delivery provider (e.g. SMTP/SendGrid) will dispatch the verification link."
