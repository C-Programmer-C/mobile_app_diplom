from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Response, Header, status
from pydantic import BaseModel
from pydantic.networks import EmailStr
from database.auth import (
    authenticate_user,
    create_user,
    create_user_with_role,
    get_user_details_with_activity,
    get_user_by_email,
    get_users_list,
    update_user_by_id,
    update_user_profile,
)
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
    phone: Optional[str] = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RefreshRequest(BaseModel):
    access_token: str


@auth_router.post("/register", summary="Create a new user")
def register(data: RegisterRequest):
    is_exist = create_user(
        data.email,
        data.password,
        data.name,
        phone=data.phone,
    )
    if not is_exist:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="The user already exists"
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


class UpdateMeRequest(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None


class UpdateUserByAdminRequest(BaseModel):
    email: Optional[str] = None
    name: Optional[str] = None
    phone: Optional[str] = None
    role: Optional[str] = None


class CreateUserByAdminRequest(BaseModel):
    email: str
    password: str
    name: str
    role: str = "user"
    phone: Optional[str] = None


@auth_router.get("/me", summary="Текущий пользователь")
def read_me(email: str = Depends(get_current_user_email)):
    user = get_user_by_email(email)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="not found")
    return {
        "id": user.id,
        "email": user.email,
        "name": user.name,
        "role": user.role,
        "phone": user.phone or "",
    }


@auth_router.patch("/me", summary="Обновить профиль")
def patch_me(
    data: UpdateMeRequest,
    email: str = Depends(get_current_user_email),
):
    user = update_user_profile(
        email,
        name=data.name,
        phone=data.phone,
    )
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="not found")
    return {
        "id": user.id,
        "email": user.email,
        "name": user.name,
        "phone": user.phone or "",
    }


@auth_router.get("/users", summary="Список пользователей")
def read_users(
    role: Optional[str] = None,
    q: Optional[str] = None,
    email: str = Depends(get_current_user_email),
):
    current_user = get_user_by_email(email)
    if not current_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="not found")
    if current_user.role not in {"admin", "staff"}:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="insufficient permissions",
        )
    return get_users_list(role=role, q=q)


@auth_router.get("/users/{user_id}/details", summary="Профиль пользователя + активность")
def read_user_details(
    user_id: int,
    email: str = Depends(get_current_user_email),
):
    current_user = get_user_by_email(email)
    if not current_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="not found")
    if current_user.role not in {"admin", "staff"}:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="insufficient permissions",
        )

    payload = get_user_details_with_activity(user_id)
    if not payload:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="not found")
    return payload


@auth_router.patch("/users/{user_id}", summary="Обновить пользователя (admin)")
def patch_user_by_admin(
    user_id: int,
    data: UpdateUserByAdminRequest,
    email: str = Depends(get_current_user_email),
):
    current_user = get_user_by_email(email)
    if not current_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="not found")
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="admin only",
        )

    user = update_user_by_id(
        user_id=user_id,
        email=data.email,
        name=data.name,
        phone=data.phone,
        role=data.role,
    )
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="not found")
    return {
        "id": user.id,
        "email": user.email,
        "name": user.name,
        "role": user.role,
        "phone": user.phone or "",
    }


@auth_router.post("/users", summary="Создать пользователя (admin)")
def create_user_by_admin(
    data: CreateUserByAdminRequest,
    email: str = Depends(get_current_user_email),
):
    current_user = get_user_by_email(email)
    if not current_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="not found")
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="admin only",
        )
    user = create_user_with_role(
        email=data.email,
        password=data.password,
        name=data.name,
        role=data.role,
        phone=data.phone,
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="user already exists",
        )
    return {
        "id": user.id,
        "email": user.email,
        "name": user.name,
        "role": user.role,
        "phone": user.phone or "",
    }

