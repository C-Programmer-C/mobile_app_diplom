from datetime import datetime, timedelta
from typing import Any, Optional, Union

from jose import JWTError, ExpiredSignatureError, jwt

from config import settings


def _build_payload(subject: Union[str, Any], expires_delta: Optional[timedelta]) -> dict:
    if expires_delta is not None:
        expire_at = datetime.now() + expires_delta
    else:
        expire_at = datetime.now() + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )

    return {"exp": int(expire_at.timestamp()), "sub": str(subject)}


def create_access_token(
    subject: Union[str, Any], expires_delta: Optional[timedelta] = None
) -> str:
    to_encode = _build_payload(subject, expires_delta)
    encoded_jwt = jwt.encode(
        to_encode, settings.JWT_SECRET_KEY, settings.ALGORITHM
    )
    return encoded_jwt


def decode_access_token(token: str) -> str:
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.ALGORITHM],
        )
    except ExpiredSignatureError:
        raise ValueError("token expired")
    except JWTError:
        raise ValueError("invalid token")

    subject = payload.get("sub")
    if subject is None:
        raise ValueError("invalid token payload")
    return str(subject)


def decode_access_token_allow_expired(token: str) -> str:
    """
    Используется только в /auth/refresh: игнорируем exp,
    чтобы продлить access-token по старому.
    """
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.ALGORITHM],
            options={"verify_exp": False},
        )
    except JWTError:
        raise ValueError("invalid token")

    subject = payload.get("sub")
    if subject is None:
        raise ValueError("invalid token payload")
    return str(subject)

