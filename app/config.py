from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    openai_api_key: str
    openai_base_url: str = "https://openai.api.proxyapi.ru/v1"
    openai_model: str = "openai/gpt-4o-mini"
    openai_embedding_model: str = "text-embedding-3-small"
    embedding_dimension: int = 1536
    llm_temperature: float = 0.1
    llm_timeout_seconds: int = 60

    pinecone_api_key: str
    pinecone_index_name: str = "test08"

    database_url: str = "sqlite:///./team_codex.db"
    search_mode: str = "vector"
    memory_max_messages: int = 10
    memory_llm_messages: int = 5

    app_name: str = "team-codex"
    debug: bool = True
    secret_key: str = "change-me"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    return Settings()
