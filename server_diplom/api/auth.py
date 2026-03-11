from fastapi import APIRouter, HTTPException, Response, Header, status
from pydantic import BaseModel
from pydantic.networks import EmailStr
from database.auth import authenticate_user, create_user, get_user_by_email
from utils.auth import (
    create_access_token,
    decode_access_token,
    decode_access_token_allow_expired,
)

auth_router = APIRouter()


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RefreshRequest(BaseModel):
    access_token: str


@auth_router.post("/register", summary="Create a new user")
def register(data: RegisterRequest):
    is_exist = create_user(data.email, data.password, data.name)
    if not is_exist:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="The user already exists"
        )
    return Response(status_code=status.HTTP_201_CREATED)


@auth_router.post("/login", summary="Create access token for user")
def login(data: LoginRequest):
    user = authenticate_user(data.email, data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid email or password"
        )
    return {
        "access_token": create_access_token(user.email),
        "name": user.name,
    }


@auth_router.post("/refresh", summary="Refresh access token using old access token")
def refresh_access_token(data: RefreshRequest):
    try:
        email = decode_access_token_allow_expired(data.access_token)
    except ValueError as exc:
        detail = str(exc)
        if detail == "token expired":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="token expired",
            ) from exc
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="invalid refresh token",
        ) from exc

    user = get_user_by_email(email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="user not found",
        )

    return {
        "access_token": create_access_token(user.email),
        "name": user.name,
    }


def get_current_user_email(authorization: str | None = Header(default=None)) -> str:
    """
    Простая зависимость для Protected эндпоинтов:
    ожидает заголовок Authorization: Bearer <access_token>.
    """
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="missing Authorization header",
        )

    try:
        scheme, token = authorization.split(" ")
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="invalid Authorization header format",
        )

    if scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="invalid auth scheme",
        )

    try:
        email = decode_access_token(token)
    except ValueError as exc:
        detail = str(exc)
        if detail == "token expired":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="token expired",
            ) from exc
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="invalid access token",
        ) from exc

    return email

