from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    DATABASE_URL: str
    model_config = SettingsConfigDict(env_file=".env")
    ACCESS_TOKEN_EXPIRE_MINUTES: int
    REFRESH_TOKEN_EXPIRE_MINUTES: int
    JWT_SECRET_KEY: str
    ALGORITHM: str
    JWT_REFRESH_SECRET_KEY: str

settings = Settings() # type: ignore