# ============================================================
# team-codex - Self-Extracting Bootstrap (fixed)
# Usage: .\bootstrap.ps1
# ============================================================

$ErrorActionPreference = "Stop"
$ProjectRoot = "M:\Projects\team-codex"

$ProjectFiles = @{}

# ============ .env.example ============
$ProjectFiles[".env.example"] = @'
# === ProxyAPI (OpenAI) ===
OPENAI_API_KEY=sk-your-proxyapi-key-here
OPENAI_BASE_URL=https://openai.api.proxyapi.ru/v1
OPENAI_MODEL=openai/gpt-4o-mini
OPENAI_EMBEDDING_MODEL=text-embedding-3-small
EMBEDDING_DIMENSION=1536
LLM_TEMPERATURE=0.1
LLM_TIMEOUT_SECONDS=60

# === Pinecone ===
PINECONE_API_KEY=your-pinecone-api-key
PINECONE_INDEX_NAME=test08

# === Database ===
DATABASE_URL=sqlite:///./team_codex.db

# === Search ===
SEARCH_MODE=vector

# === Memory ===
MEMORY_MAX_MESSAGES=10
MEMORY_LLM_MESSAGES=5

# === App ===
APP_NAME=team-codex
DEBUG=true
SECRET_KEY=change-me-in-production
'@

# ============ .gitignore ============
$ProjectFiles[".gitignore"] = @'
.env
.venv/
venv/
__pycache__/
*.pyc
*.pyo
*.db
team_codex.db
.vscode/settings.json
.idea/
*.log
.DS_Store
'@

# ============ .dockerignore ============
$ProjectFiles[".dockerignore"] = @'
# Секреты — только через --env-file / compose env_file
.env

# Зависимости
.venv
__pycache__
*.py[cod]

# Системное / IDE
.git
.gitignore
.vscode

# Документация и утилиты (в образ не нужны)
docs
*.md
License
bootstrap.ps1
bootstrap1.ps1
'@

# ============ requirements.txt ============
$ProjectFiles["requirements.txt"] = @'
fastapi==0.143.3
uvicorn[standard]==0.54.0
python-multipart==0.0.32
jinja2==3.1.6
aiofiles==24.1.0
sqlalchemy==2.0.35
alembic==1.13.2
psycopg2-binary==2.9.9
openai==1.51.0
pinecone-client==5.0.1
tiktoken==0.8.0
pydantic==2.14.1
pydantic-settings==2.16.0
python-dotenv==1.2.4
httpx==0.27.2
python-dateutil==2.9.0
rank-bm25==0.2.2
'@

# ============ requirements-dev.txt ============
$ProjectFiles["requirements-dev.txt"] = @'
# Дев-зависимости: не входят в Docker-образ (в Dockerfile ставится только requirements.txt).
# Нужны только при локальной разработке: pytest — тесты, httpie — ручная отладка API.
-r requirements.txt
pytest==9.0.3
httpie==3.2.4
'@

# ============ Makefile ============
$ProjectFiles["Makefile"] = @'
PYTHON ?= python
HOST ?= 0.0.0.0
PORT ?= 8000

.PHONY: install run seed-faq eval

install:
	$(PYTHON) -m pip install -r requirements.txt

run:
	$(PYTHON) -m uvicorn app.main:app --host $(HOST) --port $(PORT) --reload

seed-faq:
	$(PYTHON) scripts/seed_faq.py

eval:
	$(PYTHON) run_eval.py --base-url http://localhost:$(PORT)
'@

# ============ Dockerfile ============
$ProjectFiles["Dockerfile"] = @'
FROM python:3.11-slim

WORKDIR /app
RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools \
    && pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
'@

# ============ docker-compose.yml ============
$ProjectFiles["docker-compose.yml"] = @'
version: "3.9"
services:
  app:
    build: .
    ports:
      - "8000:8000"
    env_file:
      - .env
    volumes:
      - ./team_codex.db:/app/team_codex.db
    restart: unless-stopped
'@

# ============ .vscode/settings.json ============
$ProjectFiles[".vscode/settings.json"] = @'
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/Scripts/python.exe",
  "terminal.integrated.defaultProfile.windows": "PowerShell",
  "python.terminal.activateEnvironment": true,
  "editor.formatOnSave": true
}
'@

# ============ License ============
$ProjectFiles["License"] = @'
MIT License

Copyright (c) 2026 team-codex

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
'@

# ============ app/__init__.py ============
$ProjectFiles["app/__init__.py"] = @'
"""team-codex - Team Knowledge Base with AI."""
__version__ = "1.0.0"
'@

# ============ app/config.py ============
$ProjectFiles["app/config.py"] = @'
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
'@

# ============ app/database.py ============
$ProjectFiles["app/database.py"] = @'
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.config import get_settings

settings = get_settings()

connect_args = {}
if settings.database_url.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(settings.database_url, connect_args=connect_args, echo=False)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def ensure_schema_upgrades():
    """Лёгкие апгрейды существующей SQLite-базы (аналог миграций)."""
    from sqlalchemy import text, inspect
    inspector = inspect(engine)
    if "memory_sessions" in inspector.get_table_names():
        cols = {c["name"] for c in inspector.get_columns("memory_sessions")}
        if "summarized_count" not in cols:
            with engine.begin() as conn:
                conn.execute(text("ALTER TABLE memory_sessions ADD COLUMN summarized_count INTEGER DEFAULT 0"))
    if "answers" in inspector.get_table_names():
        cols = {c["name"] for c in inspector.get_columns("answers")}
        with engine.begin() as conn:
            if "reviewed_at" not in cols:
                conn.execute(text("ALTER TABLE answers ADD COLUMN reviewed_at DATETIME"))
            if "review_note" not in cols:
                conn.execute(text("ALTER TABLE answers ADD COLUMN review_note VARCHAR(500)"))
    if "faq_entries" in inspector.get_table_names():
        cols = {c["name"] for c in inspector.get_columns("faq_entries")}
        with engine.begin() as conn:
            if "status" not in cols:
                conn.execute(text("ALTER TABLE faq_entries ADD COLUMN status VARCHAR(50) DEFAULT 'answered_auto'"))
            if "review_reason" not in cols:
                conn.execute(text("ALTER TABLE faq_entries ADD COLUMN review_reason VARCHAR(200)"))
'@

# ============ app/models.py ============
$ProjectFiles["app/models.py"] = @'
from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, ForeignKey, JSON, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base


class Document(Base):
    __tablename__ = "documents"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    source = Column(String(100), default="manual")
    topic = Column(String(100), nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())
    chunks = relationship("DocumentChunk", back_populates="document", cascade="all, delete-orphan")


class DocumentChunk(Base):
    __tablename__ = "document_chunks"
    id = Column(Integer, primary_key=True, index=True)
    document_id = Column(Integer, ForeignKey("documents.id", ondelete="CASCADE"), nullable=False)
    chunk_text = Column(Text, nullable=False)
    chunk_index = Column(Integer, nullable=False)
    metadata_json = Column(JSON, nullable=True)
    pinecone_id = Column(String(100), nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    document = relationship("Document", back_populates="chunks")


class Answer(Base):
    __tablename__ = "answers"
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String(64), nullable=False, index=True)
    question = Column(Text, nullable=False)
    answer_json = Column(JSON, nullable=False)
    status = Column(String(50), nullable=False)
    confidence = Column(Float, nullable=True)
    needs_review = Column(Boolean, default=False)
    review_reason = Column(String(100), nullable=True)
    reviewed_at = Column(DateTime, nullable=True)
    review_note = Column(String(500), nullable=True)
    created_at = Column(DateTime, server_default=func.now())


class AuditRun(Base):
    __tablename__ = "audit_runs"
    id = Column(Integer, primary_key=True, index=True)
    action = Column(String(100), nullable=False)
    input_data = Column(JSON, nullable=False)
    output_data = Column(JSON, nullable=True)
    status = Column(String(50), nullable=False)
    error = Column(Text, nullable=True)
    duration_ms = Column(Integer, nullable=True)
    created_at = Column(DateTime, server_default=func.now())


class MemorySession(Base):
    __tablename__ = "memory_sessions"
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String(64), unique=True, nullable=False, index=True)
    summary = Column(Text, nullable=True)
    summarized_count = Column(Integer, default=0)
    created_at = Column(DateTime, server_default=func.now())
    last_active_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    messages = relationship("MemoryMessage", back_populates="session", cascade="all, delete-orphan")


class MemoryMessage(Base):
    __tablename__ = "memory_messages"
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("memory_sessions.id", ondelete="CASCADE"), nullable=False)
    role = Column(String(20), nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, server_default=func.now())
    session = relationship("MemorySession", back_populates="messages")


class KnowledgeGap(Base):
    __tablename__ = "knowledge_gaps"
    id = Column(Integer, primary_key=True, index=True)
    question = Column(Text, nullable=False)
    session_id = Column(String(64), nullable=True)
    status = Column(String(50), default="new")
    created_at = Column(DateTime, server_default=func.now())


class FaqEntry(Base):
    __tablename__ = "faq_entries"
    id = Column(Integer, primary_key=True, index=True)
    question = Column(Text, nullable=False)
    answer = Column(Text, nullable=False)
    topic = Column(String(100), nullable=True)
    keywords = Column(Text, nullable=True)
    status = Column(String(50), default="answered_auto")
    review_reason = Column(String(200), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, onupdate=func.now())


class UserFact(Base):
    __tablename__ = "user_facts"
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String(64), nullable=False, index=True)
    fact = Column(Text, nullable=False)
    created_at = Column(DateTime, server_default=func.now())
'@

# ============ app/schemas.py ============
$ProjectFiles["app/schemas.py"] = @'
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class DocumentCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    content: str = Field(..., min_length=1)
    topic: Optional[str] = None


class DocumentResponse(BaseModel):
    id: int
    title: str
    topic: Optional[str]
    chunks_count: int
    created_at: datetime
    class Config:
        from_attributes = True


class Citation(BaseModel):
    document_id: int
    chunk_id: int
    quote: str


class LLMAnswerResponse(BaseModel):
    found: bool
    topic: Optional[str] = None
    answer: str
    citations: List[Citation] = Field(default_factory=list)
    confidence: float = Field(ge=0.0, le=1.0)
    status: str
    needs_review: bool
    review_reason: Optional[str] = None
    source: Optional[str] = None


class FaqEntryCreate(BaseModel):
    question: str = Field(..., min_length=1, max_length=1000)
    answer: str = Field(..., min_length=1)
    topic: Optional[str] = None
    keywords: Optional[str] = None
    status: Optional[str] = "answered_auto"
    review_reason: Optional[str] = None


class FaqEntryUpdate(BaseModel):
    question: Optional[str] = Field(None, min_length=1, max_length=1000)
    answer: Optional[str] = Field(None, min_length=1)
    topic: Optional[str] = None
    keywords: Optional[str] = None
    status: Optional[str] = None
    review_reason: Optional[str] = None
    is_active: Optional[bool] = None


class FaqEntryResponse(BaseModel):
    id: int
    question: str
    answer: str
    topic: Optional[str]
    keywords: Optional[str]
    status: Optional[str]
    review_reason: Optional[str]
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime]
    class Config:
        from_attributes = True


class AskRequest(BaseModel):
    question: str = Field(..., min_length=1, max_length=2000)
    session_id: Optional[str] = None


class AskResponse(BaseModel):
    id: int
    question: str
    result: LLMAnswerResponse
    created_at: datetime


class AuditResponse(BaseModel):
    id: int
    action: str
    status: str
    duration_ms: Optional[int]
    created_at: datetime
    needs_review_flag: Optional[bool] = None


class GapResponse(BaseModel):
    id: int
    question: str
    status: str
    created_at: datetime


class AnswerReviewRequest(BaseModel):
    action: str = Field(..., pattern="^(approve|reject)$")
    note: Optional[str] = Field(None, max_length=500)


class AnswerReviewResponse(BaseModel):
    id: int
    status: str
    needs_review: bool
    review_reason: Optional[str]
    review_note: Optional[str]
    reviewed_at: Optional[datetime]
'@

# ============ app/pinecone_service.py ============
$ProjectFiles["app/pinecone_service.py"] = @'
from pinecone import Pinecone, ServerlessSpec
from openai import OpenAI
from app.config import get_settings
import logging

logger = logging.getLogger(__name__)
settings = get_settings()

pc = Pinecone(api_key=settings.pinecone_api_key)
openai_client = OpenAI(api_key=settings.openai_api_key, base_url=settings.openai_base_url)


def ensure_index_exists():
    if settings.pinecone_index_name not in pc.list_indexes().names():
        logger.info("Creating Pinecone index: %s", settings.pinecone_index_name)
        pc.create_index(
            name=settings.pinecone_index_name,
            dimension=settings.embedding_dimension,
            metric="cosine",
            spec=ServerlessSpec(cloud="aws", region="us-east-1"),
        )


def get_index():
    ensure_index_exists()
    return pc.Index(settings.pinecone_index_name)


def get_embedding(text: str):
    response = openai_client.embeddings.create(
        model=settings.openai_embedding_model,
        input=text,
    )
    return response.data[0].embedding


def upsert_chunks(chunks: list):
    index = get_index()
    for i in range(0, len(chunks), 100):
        batch = chunks[i : i + 100]
        index.upsert(vectors=batch)
    logger.info("Upserted %d chunks to Pinecone", len(chunks))


def delete_chunks_for_document(document_id: int):
    index = get_index()
    index.delete(filter={"document_id": {"$eq": document_id}})


def query_similar(query_embedding, top_k: int = 5, min_score: float = 0.1):
    index = get_index()
    result = index.query(vector=query_embedding, top_k=top_k, include_metadata=True)
    matches = []
    for match in result.matches:
        if match.score >= min_score:
            matches.append({
                "pinecone_id": match.id,
                "score": match.score,
                "chunk_id": match.metadata.get("chunk_id"),
                "document_id": match.metadata.get("document_id"),
                "document_title": match.metadata.get("title"),
                "chunk_text": match.metadata.get("chunk_text", ""),
            })
    return matches


def _normalize_scores(items: list, score_key: str) -> list:
    if not items:
        return items
    scores = [i[score_key] for i in items]
    lo, hi = min(scores), max(scores)
    if hi - lo < 1e-9:
        for i in items:
            i[score_key] = 1.0
    else:
        for i in items:
            i[score_key] = (i[score_key] - lo) / (hi - lo)
    return items


def _load_chunks_from_db() -> list:
    from app.database import SessionLocal
    from app.models import DocumentChunk, Document
    db = SessionLocal()
    try:
        rows = (
            db.query(DocumentChunk.id, DocumentChunk.document_id, DocumentChunk.chunk_text,
                     Document.title, Document.topic)
            .join(Document, Document.id == DocumentChunk.document_id)
            .all()
        )
        return [
            {"chunk_id": r.id, "document_id": r.document_id,
             "chunk_text": r.chunk_text, "document_title": r.title, "topic": r.topic}
            for r in rows
        ]
    finally:
        db.close()


_bm25_cache = {"signature": None, "bm25": None, "chunks": None}


def bm25_search(query: str, top_k: int = 15) -> list:
    """Полнотекстовый BM25-поиск по чанкам из SQLite."""
    from rank_bm25 import BM25Okapi
    from app.faq_service import tokenize

    chunks = _load_chunks_from_db()
    signature = len(chunks)
    if _bm25_cache["signature"] != signature:
        tokenized = [tokenize(c["chunk_text"]) for c in chunks]
        _bm25_cache["bm25"] = BM25Okapi(tokenized) if tokenized else None
        _bm25_cache["chunks"] = chunks
        _bm25_cache["signature"] = signature
    bm25 = _bm25_cache["bm25"]
    if bm25 is None:
        return []
    chunks = _bm25_cache["chunks"]

    scores = bm25.get_scores(tokenize(query))
    ranked = sorted(zip(chunks, scores), key=lambda x: x[1], reverse=True)
    results = []
    for chunk, score in ranked[:top_k]:
        if score <= 0:
            continue
        results.append({
            "pinecone_id": f"doc_{chunk['document_id']}_chunk_{chunk['chunk_id']}",
            "score": float(score),
            "chunk_id": chunk["chunk_id"],
            "document_id": chunk["document_id"],
            "document_title": chunk["document_title"],
            "chunk_text": chunk["chunk_text"],
        })
    return results


def hybrid_search(query: str, query_embedding, top_k: int = 5) -> list:
    """Каскадный гибрид: Pinecone (векторы) + BM25 (ключи), min-max нормализация,
    буст x1.5 за совпадение обоих методов, возврат топ-N по hybrid_score."""
    vector_matches = []
    try:
        vector_matches = query_similar(query_embedding, top_k=15, min_score=0.0)
    except Exception as e:
        logger.warning("Vector search failed, falling back to BM25 only: %s", e)

    keyword_matches = bm25_search(query, top_k=15)

    _normalize_scores(vector_matches, "score")
    _normalize_scores(keyword_matches, "score")

    merged = {}
    for m in vector_matches:
        key = m["chunk_id"]
        merged[key] = {**m, "vector_score": m["score"], "bm25_score": 0.0, "hybrid_score": m["score"]}
    for m in keyword_matches:
        key = m["chunk_id"]
        if key in merged:
            merged[key]["bm25_score"] = m["score"]
            merged[key]["hybrid_score"] = (merged[key]["vector_score"] + m["score"]) * 1.5
        else:
            merged[key] = {**m, "vector_score": 0.0, "bm25_score": m["score"], "hybrid_score": m["score"]}

    results = sorted(merged.values(), key=lambda x: x["hybrid_score"], reverse=True)[:top_k]

    # Догрузка полного текста чанка из SQLite (в Pinecone metadata обрезан до 400 символов)
    full_texts = {c["chunk_id"]: c["chunk_text"] for c in _load_chunks_from_db()}
    for r in results:
        r["chunk_text"] = full_texts.get(r["chunk_id"], r.get("chunk_text", ""))
    return results
'@

# ============ app/llm_service.py ============
$ProjectFiles["app/llm_service.py"] = @'
from openai import OpenAI
import json
import logging
from app.config import get_settings
from app.schemas import LLMAnswerResponse

logger = logging.getLogger(__name__)
settings = get_settings()
client = OpenAI(api_key=settings.openai_api_key, base_url=settings.openai_base_url)

NO_TOPIC_ANSWER = "По этой теме пока нет информации в базе знаний."

SYSTEM_PROMPT = """Ты — ассистент базы знаний производственной компании.

ПРАВИЛА:
1. Отвечай ТОЛЬКО на основе предоставленного контекста (фрагментов базы знаний).
2. Если информации нет — скажи "По этой теме пока нет информации в базе знаний"
   и верни статус no_topic.
3. Не выдумывай факты, даты, имена, числа.
4. Приведи цитату из контекста с document_id и chunk_id.
5. Верни ТОЛЬКО валидный JSON по схеме ниже.
6. Отвечай на том же языке, что и вопрос (по умолчанию — русский).

СХЕМА:
{
  "found": true/false,
  "topic": "название темы или null",
  "answer": "развёрнутый ответ или 'По этой теме пока нет информации в базе знаний'",
  "citations": [{"document_id": int, "chunk_id": int, "quote": "точная цитата"}],
  "confidence": 0.0-1.0,
  "status": "answered_auto" | "needs_review" | "no_topic",
  "needs_review": bool,
  "review_reason": "причина или null"
}

КРИТЕРИИ СТАТУСА:
- answered_auto: ответ есть, confidence >= 0.75, есть цитаты
- needs_review: низкая уверенность, противоречия или неоднозначность
- no_topic: информации нет во фрагментах
"""


def generate_answer(question: str, context_chunks: list, history: list = None,
                    memory_summary: str = None, user_facts: list = None) -> LLMAnswerResponse:
    context_text = ""
    for i, c in enumerate(context_chunks, 1):
        context_text += (
            f"\n[Fragment {i}] document_id={c['document_id']}, chunk_id={c['chunk_id']}\n"
            f"Source: {c.get('document_title', 'unknown')}\n"
            f"Text: {c['chunk_text']}\n"
        )

    memory_block = ""
    if memory_summary:
        memory_block += f"\nSUMMARY OF EARLIER DIALOGUE: {memory_summary}"
    if user_facts:
        memory_block += "\nKNOWN FACTS ABOUT USER: " + "; ".join(user_facts)

    user_msg = f"QUESTION: {question}\n\nFRAGMENTS FROM KB:{context_text}"
    if memory_block:
        user_msg += f"\n\nMEMORY:{memory_block}"
    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    if history:
        for m in history[-settings.memory_llm_messages:]:
            messages.append({"role": m["role"], "content": m["content"]})
    messages.append({"role": "user", "content": user_msg})

    try:
        response = client.chat.completions.create(
            model=settings.openai_model,
            messages=messages,
            temperature=settings.llm_temperature,
            response_format={"type": "json_object"},
            timeout=settings.llm_timeout_seconds,
        )
        raw = response.choices[0].message.content
        data = json.loads(raw)
        return LLMAnswerResponse(**data)
    except json.JSONDecodeError as e:
        logger.error("LLM returned invalid JSON: %s", e)
        return LLMAnswerResponse(
            found=False, topic=None,
            answer="Ошибка: модель вернула невалидный JSON.",
            citations=[], confidence=0.0,
            status="needs_review", needs_review=True,
            review_reason="invalid_llm_json",
        )
    except Exception as e:
        logger.error("LLM error: %s", e)
        return LLMAnswerResponse(
            found=False, topic=None,
            answer="Сервис временно недоступен.",
            citations=[], confidence=0.0,
            status="needs_review", needs_review=True,
            review_reason=f"llm_error: {str(e)[:50]}",
        )
'@

# ============ app/faq_service.py ============
$ProjectFiles["app/faq_service.py"] = @'
import re
from typing import Optional
from sqlalchemy.orm import Session
from app.models import FaqEntry

_WORD_RE = re.compile(r"[a-zа-яё0-9]+")

_STOPWORDS = {
    "как", "что", "где", "когда", "ли", "а", "и", "или", "в", "на", "с", "со",
    "по", "для", "до", "от", "у", "о", "об", "из", "к", "не", "ни", "же", "бы",
    "мне", "мой", "моя", "это", "этот", "эта", "можно", "можно ли", "есть",
    "the", "of", "to", "in", "is", "are",
}


def tokenize(text: str) -> list[str]:
    return [t for t in _WORD_RE.findall((text or "").lower()) if t not in _STOPWORDS]


def search_faq(db: Session, query: str) -> Optional[FaqEntry]:
    """ШАГ 1 каскада: точное совпадение, затем нечеткий поиск по keywords (>=2 общих слова)."""
    q = (query or "").strip()
    if not q:
        return None

    exact = (
        db.query(FaqEntry)
        .filter(FaqEntry.question == q, FaqEntry.is_active.is_(True))
        .first()
    )
    if exact:
        return exact

    query_words = set(tokenize(q))
    if len(query_words) < 2:
        return None

    best, best_overlap = None, 0
    entries = db.query(FaqEntry).filter(FaqEntry.is_active.is_(True)).all()
    for entry in entries:
        kw_words = set(tokenize(entry.keywords or ""))
        overlap = len(query_words & kw_words)
        if overlap > best_overlap:
            best, best_overlap = entry, overlap

    if best is not None and best_overlap >= 2:
        return best
    return None
'@

# ============ app/memory_service.py ============
$ProjectFiles["app/memory_service.py"] = @'
import json
import logging
from sqlalchemy.orm import Session
from sqlalchemy import desc
from app.models import MemorySession, MemoryMessage, UserFact
from app.config import get_settings
from app.llm_service import client

logger = logging.getLogger(__name__)
settings = get_settings()

SUMMARIZE_PROMPT = """Ты — система памяти корпоративного ассистента.
Сожми приведённую переписку в краткое содержание (3-6 предложений) на русском языке.
Сохрани: темы вопросов, ключевые ответы, решения, предпочтения пользователя.
Верни ТОЛЬКО JSON: {"summary": "..."}"""

FACTS_PROMPT = """Ты — система памяти корпоративного ассистента.
Извлек из сообщений пользователя факты о нём (роль, подразделение, интересы,
предпочтения, контекст задач). Игнорируй фиктивные/служебные строки.
Верни ТОЛЬКО JSON: {"facts": ["факт 1", "факт 2"]}"""


def get_history(db: Session, session: MemorySession, limit: int = None) -> list:
    limit = limit or settings.memory_max_messages
    msgs = (
        db.query(MemoryMessage)
        .filter_by(session_id=session.id)
        .order_by(desc(MemoryMessage.created_at))
        .limit(limit)
        .all()
    )
    return [{"role": m.role, "content": m.content} for m in reversed(msgs)]


def get_memory_context(db: Session, session: MemorySession) -> dict:
    """Сводка + факты пользователя для передачи в LLM."""
    facts = [
        f.fact
        for f in db.query(UserFact)
        .filter_by(session_id=session.session_id)
        .order_by(desc(UserFact.created_at))
        .limit(10)
        .all()
    ]
    return {"summary": session.summary, "facts": list(reversed(facts))}


def _call_llm_json(system: str, user: str) -> dict:
    try:
        resp = client.chat.completions.create(
            model=settings.openai_model,
            messages=[{"role": "system", "content": system},
                      {"role": "user", "content": user}],
            temperature=0.0,
            response_format={"type": "json_object"},
            timeout=settings.llm_timeout_seconds,
        )
        return json.loads(resp.choices[0].message.content)
    except Exception as e:
        logger.warning("Memory LLM call failed: %s", e)
        return {}


def update_session_memory(db: Session, session: MemorySession):
    """Суммаризация истории старше memory_max_messages + извлечение фактов пользователя.

    Сообщения свежее окна (последние N) хранятся дословно и уходят в LLM как есть;
    всё, что старше, сворачивается в MemorySession.summary и не хранится дословно.
    """
    total = db.query(MemoryMessage).filter_by(session_id=session.id).count()
    keep = settings.memory_max_messages
    summarized = session.summarized_count or 0

    # Сколько старых сообщений накопилось сверх окна
    old_count = total - keep - summarized
    if old_count <= 0:
        return

    old_msgs = (
        db.query(MemoryMessage)
        .filter_by(session_id=session.id)
        .order_by(MemoryMessage.created_at)
        .offset(summarized)
        .limit(old_count)
        .all()
    )
    if not old_msgs:
        return

    transcript = "\n".join(f"{m.role}: {m.content}" for m in old_msgs)

    # 1. Суммаризация старой истории
    data = _call_llm_json(SUMMARIZE_PROMPT, transcript[:8000])
    new_summary = (data.get("summary") or "").strip()
    if new_summary:
        session.summary = (session.summary + "\n---\n" + new_summary) if session.summary else new_summary

    # 2. Факты пользователя (только из сообщений пользователя)
    user_text = "\n".join(m.content for m in old_msgs if m.role == "user")
    if user_text:
        facts_data = _call_llm_json(FACTS_PROMPT, user_text[:4000])
        existing = {f.fact.lower() for f in db.query(UserFact).filter_by(session_id=session.session_id).all()}
        for fact in (facts_data.get("facts") or []):
            fact = fact.strip()
            if fact and fact.lower() not in existing:
                db.add(UserFact(session_id=session.session_id, fact=fact))
                existing.add(fact.lower())

    session.summarized_count = summarized + old_count
    db.commit()
'@

# ============ app/audit.py ============
$ProjectFiles["app/audit.py"] = @'
import time
from contextlib import contextmanager
from sqlalchemy.orm import Session
from app.models import AuditRun
import json


@contextmanager
def track_action(db: Session, action: str, input_data: dict):
    start = time.time()
    status = "success"
    error = None
    output_data = {}
    try:
        yield output_data
    except Exception as e:
        status = "error"
        error = str(e)
        raise
    finally:
        duration_ms = int((time.time() - start) * 1000)
        run = AuditRun(
            action=action,
            input_data=_safe_json(input_data),
            output_data=_safe_json(output_data or None),
            status=status,
            error=error,
            duration_ms=duration_ms,
        )
        db.add(run)
        db.commit()


def _safe_json(obj):
    if obj is None:
        return None
    try:
        return json.loads(json.dumps(obj, default=str))
    except Exception:
        return {"raw": str(obj)[:500]}
'@

# ============ app/routers/__init__.py ============
$ProjectFiles["app/routers/__init__.py"] = @'

'@

# ============ app/routers/documents.py ============
$ProjectFiles["app/routers/documents.py"] = @'
from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.models import Document, DocumentChunk
from app.schemas import DocumentResponse
from app.pinecone_service import get_embedding, upsert_chunks, delete_chunks_for_document
from app.audit import track_action
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/documents", tags=["documents"])

CHUNK_SIZE = 800
CHUNK_OVERLAP = 100


def split_into_chunks(text: str):
    if len(text) <= CHUNK_SIZE:
        return [text]
    chunks = []
    start = 0
    while start < len(text):
        end = min(start + CHUNK_SIZE, len(text))
        chunks.append(text[start:end])
        start += CHUNK_SIZE - CHUNK_OVERLAP
    return chunks


@router.post("/", response_model=DocumentResponse)
def create_document(
    title: str = Form(...),
    content: str = Form(...),
    topic: str = Form(None),
    db: Session = Depends(get_db),
):
    with track_action(db, "create_document", {"title": title, "topic": topic}):
        doc = Document(title=title, content=content, topic=topic)
        db.add(doc)
        db.commit()
        db.refresh(doc)

        chunks = split_into_chunks(content)
        pinecone_vectors = []

        for idx, chunk_text in enumerate(chunks):
            chunk = DocumentChunk(
                document_id=doc.id,
                chunk_text=chunk_text,
                chunk_index=idx,
                pinecone_id=f"doc_{doc.id}_chunk_{idx}",
                metadata_json={"title": doc.title, "topic": doc.topic},
            )
            db.add(chunk)
            db.commit()
            db.refresh(chunk)

            try:
                embedding = get_embedding(chunk_text)
                pinecone_vectors.append({
                    "id": chunk.pinecone_id,
                    "values": embedding,
                    "metadata": {
                        "document_id": doc.id,
                        "chunk_id": chunk.id,
                        "title": doc.title,
                        "topic": doc.topic or "",
                        "chunk_text": chunk_text[:400],
                    },
                })
            except Exception as e:
                logger.error("Embedding error for chunk %s: %s", chunk.id, e)

        if pinecone_vectors:
            upsert_chunks(pinecone_vectors)

        return DocumentResponse(
            id=doc.id, title=doc.title, topic=doc.topic,
            chunks_count=len(chunks), created_at=doc.created_at,
        )


@router.post("/upload", response_model=DocumentResponse)
async def upload_document(
    file: UploadFile = File(...),
    title: str = Form(None),
    topic: str = Form(None),
    db: Session = Depends(get_db),
):
    if not file.filename.endswith((".txt", ".md")):
        raise HTTPException(400, "Only .txt and .md supported")
    content = (await file.read()).decode("utf-8")
    if not content.strip():
        raise HTTPException(400, "File is empty")
    final_title = title or file.filename
    return create_document(title=final_title, content=content, topic=topic, db=db)


@router.get("/", response_model=list[DocumentResponse])
def list_documents(db: Session = Depends(get_db)):
    docs = db.query(Document).order_by(Document.created_at.desc()).all()
    result = []
    for d in docs:
        count = db.query(func.count(DocumentChunk.id)).filter_by(document_id=d.id).scalar()
        result.append(DocumentResponse(
            id=d.id, title=d.title, topic=d.topic,
            chunks_count=count, created_at=d.created_at,
        ))
    return result


@router.put("/{document_id}")
def update_document(
    document_id: int,
    title: str = Form(None),
    topic: str = Form(None),
    db: Session = Depends(get_db),
):
    doc = db.query(Document).filter_by(id=document_id).first()
    if not doc:
        raise HTTPException(404, "Document not found")
    with track_action(db, "update_document", {"document_id": document_id, "title": title, "topic": topic}):
        if title is not None:
            doc.title = title
        if topic is not None:
            doc.topic = topic
        db.commit()
    return {"status": "updated", "id": document_id, "title": doc.title, "topic": doc.topic}


@router.delete("/{document_id}")
def delete_document(document_id: int, db: Session = Depends(get_db)):
    doc = db.query(Document).filter_by(id=document_id).first()
    if not doc:
        raise HTTPException(404, "Document not found")
    with track_action(db, "delete_document", {"document_id": document_id}):
        delete_chunks_for_document(document_id)
        db.delete(doc)
        db.commit()
    return {"status": "deleted", "id": document_id}
'@

# ============ app/routers/ask.py ============
$ProjectFiles["app/routers/ask.py"] = @'
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import desc
import time
import uuid
from app.database import get_db
from app.models import Answer, MemorySession, MemoryMessage, KnowledgeGap
from app.schemas import AskRequest, AskResponse, LLMAnswerResponse
from app.pinecone_service import get_embedding, hybrid_search
from app.llm_service import generate_answer, NO_TOPIC_ANSWER
from app.faq_service import search_faq
from app.memory_service import get_history, get_memory_context, update_session_memory
from app.audit import track_action

router = APIRouter(prefix="/ask", tags=["ask"])


@router.post("/", response_model=AskResponse)
def ask_question(req: AskRequest, db: Session = Depends(get_db)):
    session_id = req.session_id or str(uuid.uuid4())
    start = time.time()

    with track_action(db, "ask_question", {"question": req.question, "session_id": session_id}) as action_result:
        session = db.query(MemorySession).filter_by(session_id=session_id).first()
        if not session:
            session = MemorySession(session_id=session_id)
            db.add(session)
            db.commit()
            db.refresh(session)

        # ШАГ 1: FAQ / кэш — мгновенный ответ без ИИ
        faq_entry = search_faq(db, req.question)
        if faq_entry:
            faq_status = faq_entry.status or "answered_auto"
            faq_needs_review = faq_status == "needs_review"
            result = LLMAnswerResponse(
                found=True, topic=faq_entry.topic,
                answer=faq_entry.answer,
                citations=[],
                confidence=0.8 if faq_needs_review else 1.0,
                status=faq_status,
                needs_review=faq_needs_review,
                review_reason=faq_entry.review_reason if faq_needs_review else None,
                source="faq_cache",
            )
        else:
            # ШАГ 2: гибридный поиск (Pinecone + BM25)
            context_chunks = []
            try:
                query_embedding = get_embedding(req.question)
                search_results = hybrid_search(req.question, query_embedding, top_k=5)
                for r in search_results:
                    context_chunks.append({
                        "document_id": r["document_id"],
                        "chunk_id": r["chunk_id"],
                        "chunk_text": r["chunk_text"],
                        "document_title": r["document_title"],
                        "score": r["hybrid_score"],
                    })
            except Exception:
                context_chunks = []

            if not context_chunks:
                result = LLMAnswerResponse(
                    found=False, topic=None,
                    answer=NO_TOPIC_ANSWER,
                    citations=[], confidence=0.0,
                    status="no_topic", needs_review=False, review_reason=None,
                    source="hybrid_search",
                )
                db.add(KnowledgeGap(question=req.question, session_id=session_id))
            else:
                # ШАГ 3: генерация ответа через LLM с контекстом памяти
                memory = get_memory_context(db, session)
                history = get_history(db, session)
                result = generate_answer(
                    req.question, context_chunks, history,
                    memory_summary=memory["summary"],
                    user_facts=memory["facts"],
                )
                result.source = "hybrid_search+llm"

                if result.status == "answered_auto" and result.confidence < 0.75:
                    result.status = "needs_review"
                    result.needs_review = True
                    result.review_reason = "low_confidence"

                if result.status == "answered_auto" and not result.citations:
                    result.status = "needs_review"
                    result.needs_review = True
                    result.review_reason = "missing_citation"

                if result.status == "no_topic":
                    result.answer = NO_TOPIC_ANSWER
                    db.add(KnowledgeGap(question=req.question, session_id=session_id))

        answer_record = Answer(
            session_id=session_id,
            question=req.question,
            answer_json=result.model_dump(),
            status=result.status,
            confidence=result.confidence,
            needs_review=result.needs_review,
            review_reason=result.review_reason,
        )
        db.add(answer_record)
        db.add(MemoryMessage(session_id=session.id, role="user", content=req.question))
        if result.status != "needs_review":
            db.add(MemoryMessage(session_id=session.id, role="assistant", content=result.answer))

        db.commit()
        db.refresh(answer_record)

        # Память: суммаризация истории старше окна + факты пользователя
        try:
            update_session_memory(db, session)
        except Exception:
            pass

        action_result["status"] = result.status
        action_result["needs_review"] = result.needs_review
        action_result["source"] = result.source
        action_result["duration_ms"] = int((time.time() - start) * 1000)

        return AskResponse(
            id=answer_record.id, question=req.question,
            result=result, created_at=answer_record.created_at,
        )


@router.get("/needs-review")
def list_needs_review(db: Session = Depends(get_db)):
    records = db.query(Answer).filter_by(needs_review=True).order_by(desc(Answer.created_at)).all()
    return [{
        "id": r.id, "question": r.question, "status": r.status,
        "review_reason": r.review_reason, "created_at": r.created_at,
    } for r in records]
'@

# ============ app/routers/audit.py ============
$ProjectFiles["app/routers/audit.py"] = @'
import csv
import io
import json
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import Response
from sqlalchemy.orm import Session
from sqlalchemy import desc, func
from app.audit import track_action
from app.database import get_db
from app.models import AuditRun, Answer, KnowledgeGap, Document, DocumentChunk, FaqEntry
from app.schemas import AuditResponse, GapResponse, AnswerReviewRequest, AnswerReviewResponse

router = APIRouter(prefix="/audit", tags=["audit"])

EXPORT_FIELDS = {
    "runs": ["id", "action", "status", "duration_ms", "error", "created_at"],
    "gaps": ["id", "question", "status", "created_at"],
    "answers": ["id", "session_id", "question", "status", "confidence",
                "needs_review", "review_reason", "review_note", "reviewed_at", "created_at"],
    "documents": ["id", "title", "topic", "source", "chunks_count", "content", "created_at", "updated_at"],
    "faq": ["id", "question", "answer", "topic", "keywords", "status",
            "review_reason", "is_active", "created_at", "updated_at"],
}


@router.get("/runs", response_model=list[AuditResponse])
def list_audit(db: Session = Depends(get_db), limit: int = 100):
    runs = db.query(AuditRun).order_by(desc(AuditRun.created_at)).limit(limit).all()
    return [AuditResponse(
        id=r.id, action=r.action, status=r.status,
        duration_ms=r.duration_ms, created_at=r.created_at,
    ) for r in runs]


@router.get("/gaps", response_model=list[GapResponse])
def list_gaps(db: Session = Depends(get_db)):
    gaps = db.query(KnowledgeGap).order_by(desc(KnowledgeGap.created_at)).all()
    return [GapResponse(id=g.id, question=g.question, status=g.status, created_at=g.created_at) for g in gaps]


@router.post("/answers/{answer_id}/review", response_model=AnswerReviewResponse)
def review_answer(answer_id: int, payload: AnswerReviewRequest, db: Session = Depends(get_db)):
    answer = db.query(Answer).filter_by(id=answer_id).first()
    if not answer:
        raise HTTPException(status_code=404, detail="Answer not found")
    with track_action(db, "review_answer", {"answer_id": answer_id, "action": payload.action}):
        answer.status = "answered_auto" if payload.action == "approve" else "rejected"
        answer.needs_review = False
        answer.review_note = payload.note
        answer.reviewed_at = datetime.utcnow()
        db.commit()
    return AnswerReviewResponse(
        id=answer.id,
        status=answer.status,
        needs_review=answer.needs_review,
        review_reason=answer.review_reason,
        review_note=answer.review_note,
        reviewed_at=answer.reviewed_at,
    )


def _rows_to_response(rows: list[dict], fields: list[str], fmt: str, filename: str) -> Response:
    if fmt == "csv":
        buf = io.StringIO()
        writer = csv.DictWriter(buf, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
        body = "\ufeff" + buf.getvalue()
        media = "text/csv; charset=utf-8"
    else:
        body = json.dumps(rows, ensure_ascii=False, indent=2, default=str)
        media = "application/json"
    return Response(
        content=body,
        media_type=media,
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.get("/export/{dataset}")
def export_dataset(dataset: str, format: str = "json", db: Session = Depends(get_db)):
    if dataset not in EXPORT_FIELDS:
        raise HTTPException(status_code=404, detail=f"Unknown dataset. Use: {', '.join(EXPORT_FIELDS)}")
    if format not in ("json", "csv"):
        raise HTTPException(status_code=400, detail="Unknown format. Use: json, csv")
    fields = EXPORT_FIELDS[dataset]
    with track_action(db, "export", {"dataset": dataset, "format": format}):
        if dataset == "runs":
            data = [{
                "id": r.id, "action": r.action, "status": r.status,
                "duration_ms": r.duration_ms, "error": r.error, "created_at": r.created_at,
            } for r in db.query(AuditRun).order_by(desc(AuditRun.created_at)).all()]
        elif dataset == "gaps":
            data = [{
                "id": g.id, "question": g.question, "status": g.status, "created_at": g.created_at,
            } for g in db.query(KnowledgeGap).order_by(desc(KnowledgeGap.created_at)).all()]
        elif dataset == "documents":
            count_sub = db.query(func.count(DocumentChunk.id)) \
                .filter(DocumentChunk.document_id == Document.id).scalar_subquery()
            data = [{
                "id": d.id, "title": d.title, "topic": d.topic, "source": d.source,
                "chunks_count": cnt, "content": d.content,
                "created_at": d.created_at, "updated_at": d.updated_at,
            } for d, cnt in db.query(Document, count_sub.label("chunks_count"))
                .order_by(desc(Document.created_at)).all()]
        elif dataset == "faq":
            data = [{
                "id": f.id, "question": f.question, "answer": f.answer, "topic": f.topic,
                "keywords": f.keywords, "status": f.status, "review_reason": f.review_reason,
                "is_active": f.is_active, "created_at": f.created_at, "updated_at": f.updated_at,
            } for f in db.query(FaqEntry).order_by(FaqEntry.topic, FaqEntry.id).all()]
        else:  # answers
            data = [{
                "id": a.id, "session_id": a.session_id, "question": a.question,
                "status": a.status, "confidence": a.confidence, "needs_review": a.needs_review,
                "review_reason": a.review_reason, "review_note": a.review_note,
                "reviewed_at": a.reviewed_at, "created_at": a.created_at,
            } for a in db.query(Answer).order_by(desc(Answer.created_at)).all()]
    if not data:
        raise HTTPException(status_code=404, detail="No data to export")
    return _rows_to_response(data, fields, format, f"team_codex_{dataset}.{format}")
'@

# ============ app/routers/faq.py ============
$ProjectFiles["app/routers/faq.py"] = @'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.audit import track_action
from app.database import get_db
from app.models import FaqEntry
from app.schemas import FaqEntryCreate, FaqEntryUpdate, FaqEntryResponse

router = APIRouter(prefix="/faq", tags=["faq"])


@router.get("/", response_model=list[FaqEntryResponse])
def list_faq(db: Session = Depends(get_db)):
    return db.query(FaqEntry).order_by(FaqEntry.topic, FaqEntry.id).all()


@router.post("/", response_model=FaqEntryResponse, status_code=201)
def create_faq(req: FaqEntryCreate, db: Session = Depends(get_db)):
    with track_action(db, "create_faq", {"question": req.question, "status": req.status}):
        entry = FaqEntry(**req.model_dump())
        db.add(entry)
        db.commit()
        db.refresh(entry)
    return entry


@router.put("/{faq_id}", response_model=FaqEntryResponse)
def update_faq(faq_id: int, req: FaqEntryUpdate, db: Session = Depends(get_db)):
    entry = db.query(FaqEntry).filter_by(id=faq_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="FAQ entry not found")
    changes = req.model_dump(exclude_unset=True)
    with track_action(db, "update_faq", {"faq_id": faq_id, "fields": list(changes.keys())}):
        for field, value in changes.items():
            setattr(entry, field, value)
        db.commit()
        db.refresh(entry)
    return entry


@router.delete("/{faq_id}", response_model=FaqEntryResponse)
def delete_faq(faq_id: int, db: Session = Depends(get_db)):
    entry = db.query(FaqEntry).filter_by(id=faq_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="FAQ entry not found")
    with track_action(db, "delete_faq", {"faq_id": faq_id}):
        entry.is_active = False  # soft delete
        db.commit()
        db.refresh(entry)
    return entry
'@

# ============ app/main.py ============
$ProjectFiles["app/main.py"] = @'
from fastapi import FastAPI, Request, Depends
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session
from sqlalchemy import desc, func

from app.database import engine, Base, get_db, ensure_schema_upgrades
from app.models import Document, DocumentChunk, Answer, AuditRun, KnowledgeGap, FaqEntry
from app.routers import documents, ask, audit, faq
from app.config import get_settings
import logging

logging.basicConfig(level=logging.INFO)
settings = get_settings()

Base.metadata.create_all(bind=engine)
ensure_schema_upgrades()

app = FastAPI(
    title="team-codex",
    description="Team Knowledge Base with AI, semantic search and manual review",
    version="1.0.0",
)

app.include_router(documents.router)
app.include_router(ask.router)
app.include_router(audit.router)
app.include_router(faq.router)
app.mount("/static", StaticFiles(directory="app/static"), name="static")
templates = Jinja2Templates(directory="app/templates")


@app.get("/", response_class=HTMLResponse)
def home(request: Request, db: Session = Depends(get_db)):
    docs = db.query(Document).order_by(desc(Document.created_at)).all()
    docs_with_count = []
    for d in docs:
        chunk_count = db.query(func.count(DocumentChunk.id)).filter_by(document_id=d.id).scalar()
        docs_with_count.append({
            "id": d.id, "title": d.title, "topic": d.topic,
            "chunks_count": chunk_count, "created_at": d.created_at,
        })
    return templates.TemplateResponse(request, "documents.html", {"documents": docs_with_count})


@app.post("/documents/{doc_id}")
def delete_doc_form(doc_id: int, db: Session = Depends(get_db)):
    from app.pinecone_service import delete_chunks_for_document
    from app.audit import track_action
    doc = db.query(Document).filter_by(id=doc_id).first()
    if doc:
        with track_action(db, "delete_document", {"document_id": doc_id, "source": "web_form"}):
            delete_chunks_for_document(doc_id)
            db.delete(doc)
            db.commit()
    return RedirectResponse("/", status_code=303)


@app.get("/ask", response_class=HTMLResponse)
def ask_page(request: Request):
    return templates.TemplateResponse(request, "ask.html")


@app.get("/audit", response_class=HTMLResponse)
def audit_page(request: Request, db: Session = Depends(get_db)):
    runs = db.query(AuditRun).order_by(desc(AuditRun.created_at)).limit(50).all()
    needs_review = db.query(Answer).filter_by(needs_review=True).order_by(desc(Answer.created_at)).limit(20).all()
    gaps = db.query(KnowledgeGap).order_by(desc(KnowledgeGap.created_at)).limit(20).all()
    return templates.TemplateResponse(request, "audit.html", {
        "runs": runs, "needs_review": needs_review, "gaps": gaps
    })


@app.get("/admin/faq", response_class=HTMLResponse)
def faq_admin_page(request: Request, db: Session = Depends(get_db)):
    entries = db.query(FaqEntry).order_by(FaqEntry.topic, FaqEntry.id).all()
    return templates.TemplateResponse(request, "faq.html", {"entries": entries})


@app.get("/health")
def health():
    return {"status": "ok", "app": settings.app_name, "model": settings.openai_model}
'@

# ============ app/static/styles.css ============
$ProjectFiles["app/static/styles.css"] = @'
mark { padding: 2px 6px; border-radius: 4px; }
pre { background: #f4f4f4; padding: 1rem; overflow-x: auto; font-size: 0.85rem; }
nav ul { gap: 1rem; }
'@

# ============ app/templates/base.html ============
$ProjectFiles["app/templates/base.html"] = @'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <title>team-codex — База знаний команды</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
  <link rel="stylesheet" href="/static/styles.css">
</head>
<body>
  <nav class="container">
    <ul><li><strong>team-codex</strong></li></ul>
    <ul>
      <li><a href="/">Документы</a></li>
      <li><a href="/ask">Спросить ИИ</a></li>
      <li><a href="/audit">Аудит</a></li>
      <li><a href="/admin/faq">FAQ</a></li>
      <li><a href="/docs" target="_blank">Swagger</a></li>
    </ul>
  </nav>
  <main class="container">
    {% block content %}{% endblock %}
  </main>
</body>
</html>
'@

# ============ app/templates/documents.html ============
$ProjectFiles["app/templates/documents.html"] = @'
{% extends "base.html" %}
{% block content %}
<h2>Экран 1: Витрина документов</h2>
<article>
  <h3>Загрузить документ</h3>
  <form action="/documents/upload" method="post" enctype="multipart/form-data">
    <input type="text" name="title" placeholder="Название (необязательно)">
    <input type="text" name="topic" placeholder="Тема (например, Отпуска)">
    <input type="file" name="file" accept=".txt,.md" required>
    <button type="submit">Загрузить</button>
  </form>
</article>
<article>
  <h3>Документы в базе ({{ documents|length }})</h3>
  <table>
    <thead><tr><th>ID</th><th>Название</th><th>Тема</th><th>Фрагментов</th><th>Дата</th><th></th></tr></thead>
    <tbody>
      {% for d in documents %}
      <tr>
        <td>{{ d.id }}</td><td>{{ d.title }}</td><td>{{ d.topic or '—' }}</td>
        <td>{{ d.chunks_count }}</td>
        <td>{{ d.created_at.strftime('%d.%m.%Y %H:%M') }}</td>
        <td>
          <button type="button" class="secondary outline edit-btn"
                  data-id="{{ d.id }}"
                  data-title="{{ d.title }}"
                  data-topic="{{ d.topic or '' }}">Редактировать</button>
          <form action="/documents/{{ d.id }}" method="post" style="display:inline">
            <button type="submit" class="secondary outline">Удалить</button>
          </form>
        </td>
      </tr>
      {% else %}
      <tr><td colspan="6">Документов пока нет</td></tr>
      {% endfor %}
    </tbody>
  </table>
</article>

<script>
document.querySelectorAll('.edit-btn').forEach(function (btn) {
  btn.addEventListener('click', function () {
    var id = btn.getAttribute('data-id');
    var title = btn.getAttribute('data-title');
    var topic = btn.getAttribute('data-topic');

    var newTitle = prompt('Новое название:', title);
    if (newTitle === null) return;
    var newTopic = prompt('Новая тема:', topic);
    if (newTopic === null) return;

    fetch('/documents/' + id, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'title=' + encodeURIComponent(newTitle) + '&topic=' + encodeURIComponent(newTopic)
    })
    .then(function () { location.reload(); })
    .catch(function (err) { alert('Ошибка: ' + err); });
  });
});
</script>

{% endblock %}
'@

# ============ app/templates/documents1.html ============
$ProjectFiles["app/templates/documents1.html"] = @'
{% extends "base.html" %}
{% block content %}
<h2>Screen 1: Documents Showcase</h2>
<article>
  <h3>Upload document</h3>
  <form action="/documents/upload" method="post" enctype="multipart/form-data">
    <input type="text" name="title" placeholder="Title (optional)">
    <input type="text" name="topic" placeholder="Topic (e.g. Vacation)">
    <input type="file" name="file" accept=".txt,.md" required>
    <button type="submit">Upload</button>
  </form>
</article>
<article>
  <h3>Documents in DB ({{ documents|length }})</h3>
  <table>
    <thead><tr><th>ID</th><th>Title</th><th>Topic</th><th>Chunks</th><th>Date</th><th></th></tr></thead>
    <tbody>
      {% for d in documents %}
      <tr>
        <td>{{ d.id }}</td><td>{{ d.title }}</td><td>{{ d.topic or '-' }}</td>
        <td>{{ d.chunks_count }}</td>
        <td>{{ d.created_at.strftime('%Y-%m-%d %H:%M') }}</td>
        <td>
          <form action="/documents/{{ d.id }}" method="post" style="display:inline">
            <button type="submit" class="secondary outline">Delete</button>
          </form>
        </td>
      </tr>
      {% else %}
      <tr><td colspan="6">No documents yet</td></tr>
      {% endfor %}
    </tbody>
  </table>
</article>
{% endblock %}
'@

# ============ app/templates/ask.html ============
$ProjectFiles["app/templates/ask.html"] = @'
{% extends "base.html" %}
{% block content %}
<h2>Экран 2: Спросить ИИ</h2>
<article>
  <form id="ask-form">
    <label>Ваш вопрос:
      <textarea name="question" rows="3" required placeholder="За сколько дней нужно уведомить о переносе отпуска?"></textarea>
    </label>
    <button type="submit">Спросить</button>
  </form>
</article>
<article id="result" style="display:none">
  <h3>Результат</h3>
  <div id="result-content"></div>
</article>
<script>
document.getElementById('ask-form').onsubmit = async (e) => {
  e.preventDefault();
  const question = e.target.question.value;
  if (!localStorage.getItem('sid')) localStorage.setItem('sid', crypto.randomUUID());
  const res = await fetch('/ask/', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({question: question, session_id: localStorage.getItem('sid')})
  });
  const data = await res.json();
  const r = data.result;
  const reviewBadge = r.needs_review ? '<mark style="background:#ffb700;color:black">ТРЕБУЕТ ПРОВЕРКИ: ' + (r.review_reason || '') + '</mark>' : 'ОК';
  const citationsHtml = r.citations.map(c => '<li>Документ №' + c.document_id + ', фрагмент №' + c.chunk_id + ': <em>"' + c.quote + '"</em></li>').join('');
  const html = '<p><strong>Статус:</strong> ' + r.status + ' ' + reviewBadge + '</p>' +
    '<p><strong>Ответ:</strong> ' + r.answer + '</p>' +
    '<p><strong>Уверенность:</strong> ' + (r.confidence * 100).toFixed(1) + '%</p>' +
    '<p><strong>Цитаты (' + r.citations.length + '):</strong></p>' +
    '<ul>' + citationsHtml + '</ul>' +
    '<details><summary>Сырой JSON</summary><pre>' + JSON.stringify(data, null, 2) + '</pre></details>';
  document.getElementById('result-content').innerHTML = html;
  document.getElementById('result').style.display = 'block';
};
</script>
{% endblock %}
'@

# ============ app/templates/audit.html ============
$ProjectFiles["app/templates/audit.html"] = @'
{% extends "base.html" %}
{% block content %}
<h2>Экран 3: Аудит и ручная проверка</h2>
<article>
  <h3>Записи, требующие проверки ({{ needs_review|length }})</h3>
  <table>
    <thead><tr><th>ID</th><th>Вопрос</th><th>Причина</th><th>Дата</th><th></th></tr></thead>
    <tbody>
      {% for r in needs_review %}
      <tr>
        <td>{{ r.id }}</td><td>{{ r.question[:80] }}</td>
        <td><mark>{{ r.review_reason }}</mark></td>
        <td>{{ r.created_at.strftime('%H:%M:%S') }}</td>
        <td>
          <button type="button" class="secondary outline review-action"
                  data-id="{{ r.id }}" data-action="approve">Принять</button>
          <button type="button" class="secondary outline review-action"
                  data-id="{{ r.id }}" data-action="reject">Отклонить</button>
        </td>
      </tr>
      {% else %}<tr><td colspan="5">Все ответы автоматические</td></tr>{% endfor %}
    </tbody>
  </table>
</article>
<article>
  <h3>Журнал запусков</h3>
  <p>
    Экспорт (CSV / JSON):
    <a href="/audit/export/runs?format=csv" role="button" class="secondary outline">Журнал</a>
    <a href="/audit/export/answers?format=csv" role="button" class="secondary outline">Ответы</a>
    <a href="/audit/export/gaps?format=csv" role="button" class="secondary outline">Пробелы</a>
    <a href="/audit/export/documents?format=csv" role="button" class="secondary outline">Документы</a>
    <a href="/audit/export/faq?format=csv" role="button" class="secondary outline">FAQ</a>
  </p>
  <p>
    <small>Для JSON замените <code>format=csv</code> на <code>format=json</code> в адресе ссылки.</small>
  </p>
  <table>
    <thead><tr><th>ID</th><th>Действие</th><th>Статус</th><th>Длительность (мс)</th><th>Дата</th></tr></thead>
    <tbody>
      {% for r in runs %}
      <tr>
        <td>{{ r.id }}</td><td>{{ r.action }}</td>
        <td>{{ r.status }}</td><td>{{ r.duration_ms }}</td>
        <td>{{ r.created_at.strftime('%H:%M:%S') }}</td>
      </tr>
      {% endfor %}
    </tbody>
  </table>
</article>
<article>
  <h3>Пробелы в знаниях</h3>
  <ul>
    {% for g in gaps %}<li>{{ g.question }} <small>({{ g.created_at.strftime('%d.%m') }})</small></li>{% endfor %}
  </ul>
</article>

<script>
async function auditApi(url, body) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
  if (!res.ok) {
    let detail = res.status;
    try { detail = (await res.json()).detail || detail; } catch (e) {}
    alert('Ошибка: ' + detail);
    return false;
  }
  return true;
}

document.querySelectorAll('.review-action').forEach(function (btn) {
  btn.addEventListener('click', async function () {
    const action = btn.dataset.action;
    const note = prompt(action === 'approve'
      ? 'Комментарий к принятию (необязательно):'
      : 'Причина отклонения (необязательно):', '');
    if (note === null) return;
    const ok = await auditApi('/audit/answers/' + btn.dataset.id + '/review',
      { action: action, note: note.trim() || null });
    if (ok) location.reload();
  });
});
</script>
{% endblock %}
'@

# ============ app/templates/faq.html ============
$ProjectFiles["app/templates/faq.html"] = @'
{% extends "base.html" %}
{% block content %}
<h2>Экран 4: Админка FAQ</h2>
<article>
  <h3>Добавить запись</h3>
  <form id="faq-form">
    <input type="text" name="question" placeholder="Вопрос (ключ, обязательно)" required>
    <input type="text" name="answer" placeholder="Ответ (обязательно)" required>
    <input type="text" name="topic" placeholder="Тема (например, Кадры)">
    <input type="text" name="keywords" placeholder="Ключевые слова через запятую">
    <select name="status">
      <option value="answered_auto">answered_auto</option>
      <option value="needs_review">needs_review</option>
    </select>
    <button type="submit">Добавить</button>
  </form>
</article>
<article>
  <h3>Записи FAQ ({{ entries|length }})</h3>
  <table>
    <thead>
      <tr><th>ID</th><th>Тема</th><th>Вопрос</th><th>Ответ</th><th>Ключевые слова</th><th>Статус</th><th>Активна</th><th></th></tr>
    </thead>
    <tbody>
      {% for e in entries %}
      <tr>
        <td>{{ e.id }}</td>
        <td>{{ e.topic or '—' }}</td>
        <td>{{ e.question }}</td>
        <td>{{ e.answer }}</td>
        <td>{{ e.keywords or '—' }}</td>
        <td>{% if e.status == 'needs_review' %}<mark>needs_review</mark>{% else %}{{ e.status or 'answered_auto' }}{% endif %}</td>
        <td>{% if e.is_active %}&#10003;{% else %}&mdash;{% endif %}</td>
        <td>
          <button type="button" class="secondary outline faq-edit"
                  data-id="{{ e.id }}"
                  data-question="{{ e.question }}"
                  data-answer="{{ e.answer }}"
                  data-topic="{{ e.topic or '' }}"
                  data-keywords="{{ e.keywords or '' }}"
                  data-status="{{ e.status or 'answered_auto' }}">Редактировать</button>
          <button type="button" class="secondary outline faq-toggle"
                  data-id="{{ e.id }}"
                  data-active="{{ 'true' if e.is_active else 'false' }}">{% if e.is_active %}Отключить{% else %}Включить{% endif %}</button>
          <button type="button" class="secondary outline faq-delete" data-id="{{ e.id }}">Удалить</button>
        </td>
      </tr>
      {% else %}
      <tr><td colspan="8">Записей пока нет</td></tr>
      {% endfor %}
    </tbody>
  </table>
  <small>«Удалить» выполняет мягкое удаление (is_active = false); запись остаётся в базе и её можно включить обратно.</small>
</article>

<script>
async function faqApi(url, method, body) {
  const res = await fetch(url, {
    method: method,
    headers: { 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined
  });
  if (!res.ok) {
    let detail = res.status;
    try { detail = (await res.json()).detail || detail; } catch (e) {}
    alert('Ошибка: ' + detail);
    return false;
  }
  return true;
}

document.getElementById('faq-form').onsubmit = async function (e) {
  e.preventDefault();
  const f = e.target;
  const ok = await faqApi('/faq/', 'POST', {
    question: f.question.value.trim(),
    answer: f.answer.value.trim(),
    topic: f.topic.value.trim() || null,
    keywords: f.keywords.value.trim() || null,
    status: f.status.value
  });
  if (ok) location.reload();
};

document.querySelectorAll('.faq-edit').forEach(function (btn) {
  btn.addEventListener('click', async function () {
    const question = prompt('Вопрос:', btn.dataset.question);
    if (question === null) return;
    const answer = prompt('Ответ:', btn.dataset.answer);
    if (answer === null) return;
    const topic = prompt('Тема:', btn.dataset.topic);
    if (topic === null) return;
    const keywords = prompt('Ключевые слова через запятую:', btn.dataset.keywords);
    if (keywords === null) return;
    const status = prompt('Статус (answered_auto / needs_review):', btn.dataset.status || 'answered_auto');
    if (status === null) return;
    const ok = await faqApi('/faq/' + btn.dataset.id, 'PUT', {
      question: question,
      answer: answer,
      topic: topic || null,
      keywords: keywords || null,
      status: status || 'answered_auto'
    });
    if (ok) location.reload();
  });
});

document.querySelectorAll('.faq-toggle').forEach(function (btn) {
  btn.addEventListener('click', async function () {
    const isActive = btn.dataset.active === 'true';
    const ok = await faqApi('/faq/' + btn.dataset.id, 'PUT', { is_active: !isActive });
    if (ok) location.reload();
  });
});

document.querySelectorAll('.faq-delete').forEach(function (btn) {
  btn.addEventListener('click', async function () {
    if (!confirm('Отключить запись (мягкое удаление, is_active = false)?')) return;
    const ok = await faqApi('/faq/' + btn.dataset.id, 'DELETE');
    if (ok) location.reload();
  });
});
</script>
{% endblock %}
'@

# ============ scripts/seed_faq.py ============
$ProjectFiles["scripts/seed_faq.py"] = @'
# -*- coding: utf-8 -*-
"""Сид базы знаний FAQ: 50 частых вопросов (answered_auto) + 5 вопросов на ручную проверку (needs_review).

Источники: tests_data/kadry_i_svyaz.txt (КД-005),
tests_data/skladskaya_logistika.txt (СКЛ-006), tests_data/toir.txt (ТОиР-007).

Запуск: python scripts/seed_faq.py
"""
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import engine, Base, SessionLocal, ensure_schema_upgrades
from app.models import FaqEntry

FAQ_DATA = [
    # ===== Кадры и связь (КД-005) =====
    {"topic": "Кадры", "question": "Сколько дней ежегодный основной отпуск?",
     "answer": "Ежегодный основной оплачиваемый отпуск — 28 календарных дней (регламент КД-005, п. 3.1).",
     "keywords": "отпуск, дней, основной, 28, календарных, длительность"},
    {"topic": "Кадры", "question": "Какие дополнительные отпуска положены?",
     "answer": "Дополнительные отпуска: за вредные условия труда — до 7 дней (по результатам СОУТ), за ненормированный рабочий день — до 3 дней, за работу в районах Крайнего Севера — 24 дня (КД-005, п. 3.2).",
     "keywords": "отпуск, дополнительный, вредные, условия, саут, саут, север, ненормированный"},
    {"topic": "Кадры", "question": "Когда утверждается график отпусков?",
     "answer": "График отпусков утверждается до 17 декабря на следующий год (КД-005, п. 3.3).",
     "keywords": "график, отпусков, утверждение, декабрь, 17"},
    {"topic": "Кадры", "question": "За сколько дней подавать заявление на отпуск?",
     "answer": "Заявление на отпуск подаётся через HR-портал не позднее чем за 14 дней до предполагаемой даты начала (КД-005, п. 3.4).",
     "keywords": "заявление, отпуск, hr, портал, 14, дней, срок"},
    {"topic": "Кадры", "question": "Когда выплачиваются отпускные?",
     "answer": "Отпускные выплачиваются не позднее чем за 3 дня до начала отпуска (ст. 136 ТК РФ, КД-005, п. 3.5).",
     "keywords": "отпускные, выплата, когда, срок, 3, дня, тк"},
    {"topic": "Кадры", "question": "Можно ли разделить отпуск на части?",
     "answer": "Да, разделение отпуска допускается, при условии что одна из частей не менее 14 календарных дней (ст. 125 ТК РФ, КД-005, п. 3.6).",
     "keywords": "отпуск, разделить, части, части отпуска, 14, дней"},
    {"topic": "Кадры", "question": "Как уведомить о переносе отпуска?",
     "answer": "По инициативе работника — не позднее чем за 14 дней; по инициативе работодателя — с письменного согласия работника и не позднее чем за 2 недели до начала (КД-005, п. 3.7).",
     "keywords": "перенос, отпуска, уведомление, 14, дней, 2, недели, согласие"},
    {"topic": "Кадры", "question": "Что делать при больничном листе?",
     "answer": "В первый день болезни уведомить непосредственного руководителя, обратиться в медицинское учреждение, после закрытия больничного предоставить его в отдел кадров в течение 5 рабочих дней (КД-005, п. 4.1).",
     "keywords": "больничный, лист, нетрудоспособность, уведомить, руководитель, кадры, 5, рабочих, дней"},
    {"topic": "Кадры", "question": "Кто оплачивает больничный лист?",
     "answer": "Первые 3 дня больничного — за счёт работодателя, последующие дни — за счёт ФСС (КД-005, п. 4.3).",
     "keywords": "больничный, пособие, оплата, работодатель, фсс, 3, дня"},
    {"topic": "Кадры", "question": "Какой процент пособия по больничному зависит от стажа?",
     "answer": "Размер пособия зависит от страхового стажа: до 5 лет — 60% среднего заработка, от 5 до 8 лет — 80%, более 8 лет — 100% (КД-005, п. 4.4).",
     "keywords": "пособие, больничный, стаж, процент, 60, 80, 100, заработок"},
    {"topic": "Кадры", "question": "Когда выплачивается зарплата?",
     "answer": "Заработная плата выплачивается 2 раза в месяц: аванс — 25 число текущего месяца, окончательный расчёт — 10 число следующего месяца (КД-005, п. 5.1).",
     "keywords": "зарплата, выплата, аванс, 25, 10, число, когда, расчёт"},
    {"topic": "Кадры", "question": "Где посмотреть расчётный листок по зарплате?",
     "answer": "Расчётный листок доступен в HR-портале (раздел «Мои выплаты») или в отделе кадров (каб. 102) по запросу (КД-005, п. 5.2).",
     "keywords": "расчётный, листок, зарплата, hr, портал, выплаты, кадры, 102"},
    {"topic": "Кадры", "question": "Кто начисляет зарплату и где бухгалтерия?",
     "answer": "Вопросы по начислениям — бухгалтерия, каб. 210, тел. 210; удержания — отдел кадров, каб. 102, тел. 102; премии и надбавки — непосредственный руководитель (КД-005, п. 5.3).",
     "keywords": "зарплата, начисления, бухгалтерия, удержания, премии, надбавки, 210, 102"},
    {"topic": "Кадры", "question": "Какой формат корпоративной почты?",
     "answer": "Формат корпоративной электронной почты: фамилия.имя@promtekno.ru; выдаётся в первый рабочий день в отделе ИТ (каб. 305) (КД-005, п. 7.1).",
     "keywords": "почта, электронная, корпоративная, промтехно, promtekno, формат, ит, 305"},
    {"topic": "Кадры", "question": "Какие экстренные номера телефонов?",
     "answer": "Экстренные номера: пожарная — 101, диспетчерская — 102, служба безопасности — 103, скорая помощь — 104, отдел кадров — вн. 202, отдел ИТ — вн. 305 (КД-005, п. 7.3).",
     "keywords": "телефон, номера, экстренные, пожарная, 101, диспетчерская, 102, безопасность, 103, скорая, 104"},
    {"topic": "Кадры", "question": "Как проходит адаптация нового сотрудника?",
     "answer": "Программа адаптации рассчитана на 3 месяца: 1-я неделя — вводный инструктаж и наставник, 1-й месяц — обучение на рабочем месте, 2-й месяц — расширение зоны ответственности, 3-й месяц — итоговая оценка испытательного срока (КД-005, п. 8.1–8.2).",
     "keywords": "адаптация, новый, сотрудник, испытательный, срок, 3, месяца, наставник"},
    {"topic": "Кадры", "question": "Кто может быть наставником и сколько длится наставничество?",
     "answer": "Наставник — сотрудник со стажем не менее 3 лет. Срок наставничества: рабочие профессии — от 2 до 4 недель, ИТР — от 1 до 3 месяцев, руководители — от 3 до 6 месяцев (КД-005, п. 6.1–6.2).",
     "keywords": "наставник, наставничество, стаж, 3, года, рабочие, итр, руководители, срок"},
    {"topic": "Кадры", "question": "Как отправить предложение по улучшению процессов?",
     "answer": "Предложения принимаются через ящик предложений (корпус А, 1 этаж), форму на интранете (раздел «Предложения») или непосредственного руководителя. Все предложения рассматриваются в течение 10 рабочих дней; за внедрённые с экономическим эффектом выплачивается вознаграждение до 10% от годового эффекта (КД-005, п. 9.1–9.3).",
     "keywords": "предложение, улучшение, ящик, интранет, обратная, связь, 10, рабочих, дней, вознаграждение"},

    # ===== Складская логистика (СКЛ-006) =====
    {"topic": "Складская логистика", "question": "Какие склады есть на предприятии?",
     "answer": "Склады: № 1 — сырьё и основные материалы (корпус В), № 2 — комплектующие и полуфабрикаты (корпус В), № 3 — инструмент и оснастка (корпус В, пом. 018), № 4 — готовая продукция (корпус Г), № 5 — вспомогательные материалы и ГСМ (территория Б) (СКЛ-006, п. 1.3).",
     "keywords": "склад, склады, номер, сырьё, комплектующие, инструмент, продукция, гсм"},
    {"topic": "Складская логистика", "question": "Что такое лимитно-заборная карта?",
     "answer": "Лимитно-заборная карта (ЛЗК) — документ, определяющий предельное количество материалов, которое может быть выдано в цех за определённый период (СКЛ-006, п. 2.2).",
     "keywords": "лзк, лимитно, заборная, карта, документ, лимит, выдача, цех"},
    {"topic": "Складская логистика", "question": "Что такое требование-накладная М-11?",
     "answer": "Требование-накладная (форма М-11) — документ на разовую выдачу материалов сверх лимита или для хозяйственных нужд (СКЛ-006, п. 2.3).",
     "keywords": "м, 11, требование, накладная, документ, выдача, сверх, лимита, хозяйственных"},
    {"topic": "Складская логистика", "question": "В какой срок принимаются материалы на склад?",
     "answer": "Приёмка материалов производится кладовщиком в течение: 24 часов — отечественные поставщики, 48 часов — импортные материалы, 4 часа — срочные поставки (помеченные «СРОЧНО») (СКЛ-006, п. 3.1).",
     "keywords": "приёмка, материалы, срок, 24, 48, часов, срочно, импорт, поставщики"},
    {"topic": "Складская логистика", "question": "Как оформляются расхождения при приёмке?",
     "answer": "Расхождения фиксируются в акте формы ТОРГ-2 (при недостаче) или ТОРГ-3 (при пересортице). Акт составляется в трёх экземплярах и подписывается комиссией: кладовщик, представитель поставщика, представитель отдела качества (СКЛ-006, п. 3.3).",
     "keywords": "расхождения, приёмка, акт, торг, 2, 3, недостача, пересортица, комиссия"},
    {"topic": "Складская логистика", "question": "Какой принцип хранения материалов FIFO?",
     "answer": "Материалы хранятся по принципу FIFO (First In — First Out): первыми расходуются материалы, поступившие ранее. Для материалов с ограниченным сроком годности применяется FEFO (First Expired — First Out) (СКЛ-006, п. 4.1–4.2).",
     "keywords": "fifo,fefo, хранение, принцип, первый, вход, выход, срок, годности"},
    {"topic": "Складская логистика", "question": "Какие условия хранения электроники?",
     "answer": "Электроника хранится при температуре +15…+25°C, влажности 40–60% в антистатической упаковке (СКЛ-006, п. 4.3).",
     "keywords": "электроника, хранение, температура, влажность, антистатическая, упаковка"},
    {"topic": "Складская логистика", "question": "Какие условия хранения ГСМ?",
     "answer": "ГСМ хранятся при температуре не выше +30°C с противопожарными мерами (СКЛ-006, п. 4.3).",
     "keywords": "гсм, хранение, температура, 30, противопожарные, меры"},
    {"topic": "Складская логистика", "question": "Когда проводится инвентаризация?",
     "answer": "Инвентаризация проводится: полная — 1 раз в год (декабрь), выборочная — ежеквартально по отдельным категориям, внезапная — по распоряжению финансового директора (СКЛ-006, п. 4.4).",
     "keywords": "инвентаризация, полная, выборочная, внезапная, декабрь, год, квартал"},
    {"topic": "Складская логистика", "question": "В какое время выдаются материалы в цех?",
     "answer": "График выдачи: понедельник–четверг 08:00–12:00 и 13:00–17:00, пятница 08:00–12:00 и 13:00–16:00; суббота и воскресенье — только по аварийным заявкам с согласованием начальника склада (СКЛ-006, п. 5.2).",
     "keywords": "выдача, материалы, цех, график, время, часы, понедельник, пятница, выходные, аварийные"},
    {"topic": "Складская логистика", "question": "Какие документы нужны для получения материалов?",
     "answer": "Для получения материалов представитель цеха предъявляет лимитно-заборную карту (форма М-8) или требование-накладную (М-11), постоянный пропуск и тару для транспортировки (СКЛ-006, п. 5.3).",
     "keywords": "получение, материалы, документы, м, 8, м, 11, пропуск, тара, лзк"},
    {"topic": "Складская логистика", "question": "Как оформляется выдача сверх лимита?",
     "answer": "Выдача сверх лимита производится по требованию-накладной (М-11), подписанной мастером смены, начальником цеха и начальником производства при сумме свыше 50 000 руб. (СКЛ-006, п. 5.5).",
     "keywords": "сверх, лимита, выдача, м, 11, подпись, мастер, начальник, цеха, производства, 50000"},
    {"topic": "Складская логистика", "question": "В какой срок возвращаются неиспользованные материалы?",
     "answer": "Неиспользованные материалы подлежат возврату на склад в течение 24 часов после окончания смены или производственного задания. Возврат оформляется накладной формы М-15 в двух экземплярах (СКЛ-006, п. 6.1–6.2).",
     "keywords": "возврат, материалы, неиспользованные, 24, часа, м, 15, накладная, срок"},
    {"topic": "Складская логистика", "question": "Как перевозить грузы по территории предприятия?",
     "answer": "Перемещение материалов: электропогрузчиками — грузы свыше 50 кг, гидравлическими тележками — до 2000 кг на поддонах, вручную — до 30 кг. Скорость: не более 10 км/ч в помещениях, 20 км/ч на улице (СКЛ-006, п. 7.1–7.2).",
     "keywords": "перевозка, транспортировка, погрузчик, тележка, кг, груз, скорость, 10, 20, км"},
    {"topic": "Складская логистика", "question": "Что запрещается при транспортировке грузов?",
     "answer": "Запрещается: перевозить людей на погрузчиках и тележках, оставлять груз в проходах и на путях эвакуации, превышать грузоподъёмность транспортного средства (СКЛ-006, п. 7.3).",
     "keywords": "запрет, транспортировка, погрузчик, люди, проходы, эвакуация, грузоподъёмность"},
    {"topic": "Складская логистика", "question": "Кто несёт материальную ответственность на складе?",
     "answer": "Кладовщик несёт полную материальную ответственность за сохранность ТМЦ на вверенном складе (договор о полной материальной ответственности). За недостачу, порчу или хищение виновные несут материальную, дисциплинарную и уголовную ответственность (СКЛ-006, п. 9.1–9.2).",
     "keywords": "ответственность, кладовщик, материальная, тмц, недостача, порча, хищение"},
    {"topic": "Складская логистика", "question": "Какие отчёты формирует склад?",
     "answer": "Кладовщик ежедневно формирует отчёт об остатках, отчёт о движениях (приход/расход) и отчёт о расхождениях. Ежемесячно проводится анализ оборачиваемости запасов, неликвидов (без движения более 180 дней) и потерь от брака (СКЛ-006, п. 8.2, 8.4).",
     "keywords": "отчёт, отчёты, остатки, движения, расхождения, неликвиды, 180, дней, анализ"},

    # ===== ТОиР (ТОиР-007) =====
    {"topic": "ТОиР", "question": "Какие категории ремонтной сложности оборудования?",
     "answer": "Оборудование разделено на 4 категории: А — главные производственные линии (критичная), Б — вспомогательное оборудование (высокая), В — инструмент и оснастка (средняя), Г — бытовое оборудование (низкая) (ТОиР-007, п. 3.1).",
     "keywords": "категория, сложность, а, б, в, г, критичность, оборудование"},
    {"topic": "ТОиР", "question": "Какое время реагирования на отказ оборудования категории А?",
     "answer": "Оборудование категории «А» имеет высший приоритет; время реагирования на отказ — не более 15 минут (ТОиР-007, п. 3.2).",
     "keywords": "реагирование, отказ, категория, а, 15, минут, приоритет, критичная"},
    {"topic": "ТОиР", "question": "Какая периодичность ТО-1 и ТО-2?",
     "answer": "ТО-1 проводится каждые 250 моточасов (слесарь-ремонтник), ТО-2 — каждые 1000 моточасов (слесарь-ремонтник 4–5 разряда) (ТОиР-007, п. 4.1).",
     "keywords": "то, 1, то, 2, периодичность, моточасы, 250, 1000, обслуживание"},
    {"topic": "ТОиР", "question": "Когда утверждается график ППР?",
     "answer": "График ППР утверждается главным механиком на год вперёд до 25 декабря предыдущего года; отклонение допускается не более чем на 10% по времени и только по согласованию с главным механиком (ТОиР-007, п. 4.2–4.3).",
     "keywords": "ппр, график, утверждение, главный, механик, 25, декабрь, отклонение, 10"},
    {"topic": "ТОиР", "question": "Что входит в ежесменное обслуживание (ЕО)?",
     "answer": "ЕО проводится оператором в начале и конце каждой смены. Утром: внешнее состояние, системы безопасности, смазка, давление пневмосистемы 6–8 бар, температура подшипников не выше 70°C, отсутствие шумов. В конце смены: очистка, смазка по карте, запись в журнале (форма ОЖ-1), сообщение о неисправностях мастеру (ТОиР-007, п. 5.1–5.3).",
     "keywords": "ео, ежесменное, обслуживание, оператор, смена, давление, бар, подшипники, 70, ож, 1"},
    {"topic": "ТОиР", "question": "Что входит в работы ТО-1?",
     "answer": "Состав работ ТО-1: замена фильтров (масляных, воздушных, топливных), проверка и регулировка натяжения ремней и цепей, проверка тормозных систем, подтяжка электрических клемм, замена изношенных уплотнений, проверка точности станков с ЧПУ (ТОиР-007, п. 6.2).",
     "keywords": "то, 1, состав, работы, фильтры, ремни, цепи, тормоза, клеммы, уплотнения, чпу"},
    {"topic": "ТОиР", "question": "Что добавляется в ТО-2 по сравнению с ТО-1?",
     "answer": "ТО-2 включает все работы ТО-1 плюс: замена масла в редукторах и гидросистемах, виброакустическая диагностика подшипников, проверка геометрической точности, калибровка измерительных приборов, проверка систем охлаждения и вентиляции (ТОиР-007, п. 6.3).",
     "keywords": "то, 2, замена, масло, редукторы, гидросистемы, диагностика, подшипники, калибровка, охлаждение"},
    {"topic": "ТОиР", "question": "Как оформляется акт после ТО-1 и ТО-2?",
     "answer": "После выполнения ТО-1 и ТО-2 составляется акт (форма ТО-1/ТО-2), который подписывают исполнитель и мастер смены (ТОиР-007, п. 6.4).",
     "keywords": "акт, то, 1, то, 2, форма, подпись, исполнитель, мастер, смены"},
    {"topic": "ТОиР", "question": "Как проводится капитальный ремонт (КР)?",
     "answer": "КР проводится специализированной бригадой с полной разборкой оборудования: дефектация узлов, замена или восстановление деталей, сборка с соблюдением заводских допусков, испытания. После КР оборудование принимается комиссией (главный механик, начальник цеха, технолог) с актом приёмки формы АП-1 (ТОиР-007, п. 7.3–7.5).",
     "keywords": "кр, капитальный, ремонт, разборка, дефектация, допуски, комиссия, ап, 1, приёмка"},
    {"topic": "ТОиР", "question": "Что делать при аварийном отказе оборудования?",
     "answer": "При внезапном отказе оборудования категории «А»: оператор немедленно останавливает оборудование, сообщает мастеру смены и диспетчеру (тел. 103); диспетчер вызывает аварийную бригаду (прибытие не более 15 минут). Если восстановление более 4 часов — главный механик уведомляет начальника производства и директора по производству. Акт аварии (форма АА-1) составляется в течение 24 часов (ТОиР-007, п. 8.1–8.4).",
     "keywords": "аварийный, ремонт, отказ, остановить, диспетчер, 103, бригада, 15, минут, 4, часа, акт, аа, 1, 24"},
    {"topic": "ТОиР", "question": "Какие KPI надёжности оборудования?",
     "answer": "KPI: коэффициент готовности (Кг) ≥ 0.95 (факт 0.93), коэффициент технического использования (Кти) ≥ 0.85 (факт 0.82), MTBF ≥ 500 часов (факт 480), MTTR ≤ 2 часов (факт 2.5). Учёт ведётся в 1С:ТОиР (ТОиР-007, п. 9.1–9.2).",
     "keywords": "kpi, надёжность, кг, кти, mtbf, mttr, показатели, готовность, 0, 95, 500, часов"},
    {"topic": "ТОиР", "question": "Какие документы нужны для ремонтных работ по охране труда?",
     "answer": "Все ремонтные работы проводятся по наряду-допуску (форма НД-1), который оформляет мастер ремонтной бригады. Работы на высоте свыше 1.8 м — только со страховочными системами и по отдельному наряду-допуску; сварочные работы — только при наличии удостоверения сварщика и разрешения на огневые работы (ТОиР-007, п. 10.1, 10.3–10.4).",
     "keywords": "наряд, допуск, нд, 1, охрана, труда, высота, 1, 8, м, страховка, сварка, огневые, удостоверение"},
    {"topic": "ТОиР", "question": "Что такое Lockout/Tagout при ремонте?",
     "answer": "Перед началом ремонта оборудование должно быть остановлено, обесточено (с вывешиванием плаката «НЕ ВКЛЮЧАТЬ — РАБОТАЮТ ЛЮДИ»), заблокировано (система Lockout/Tagout), освобождено от давления в пневмо- и гидросистемах и охлаждено до безопасной температуры (ТОиР-007, п. 10.2).",
     "keywords": "lockout, tagout, блокировка, обесточивание, плакат, не, включать, ремонт, давление, безопасность"},
    {"topic": "ТОиР", "question": "Кто отвечает за график ППР и надёжность оборудования?",
     "answer": "Главный механик несёт ответственность за разработку и выполнение графика ППР, надёжность оборудования и безопасность ремонтных работ (ТОиР-007, п. 11.1).",
     "keywords": "главный, механик, ответственность, ппр, график, надёжность, безопасность"},
    {"topic": "ТОиР", "question": "Что такое текущий ремонт (ТР)?",
     "answer": "Текущий ремонт (ТР) проводится по плану ППР или по результатам диагностики. Состав работ: замена изношенных узлов и деталей, восстановление геометрической точности, замена электрооборудования при необходимости, покраска и восстановление защитных покрытий (ТОиР-007, п. 7.1–7.2).",
     "keywords": "тр, текущий, ремонт, ппр, диагностика, узлы, геометрическая, точность, покраска"},
]

# Вопросы, требующие ручной проверки (status=needs_review).
# Ключевые слова намеренно пустые: срабатывают только по точному совпадению,
# чтобы не перехватывать обычные answered_auto-вопросы при нечётком поиске.
FAQ_REVIEW_DATA = [
    {"topic": "Складская логистика",
     "question": "Кто утверждает лимитно-заборные карты, если начальник производства в отпуске?",
     "answer": "В регламенте СКЛ-006 (п. 5.1) указано, что ЛЗК утверждает начальник производства, но порядок утверждения в его отсутствие не определён. Требуется уточнение ответственного — вопрос направлен на ручную проверку.",
     "review_reason": "В регламенте не указан порядок утверждения ЛЗК при отсутствии начальника производства"},
    {"topic": "Складская логистика",
     "question": "Кто инициирует внезапную инвентаризацию, если финансовый директор в отпуске?",
     "answer": "По регламенту СКЛ-006 (п. 4.4) внезапная инвентаризация проводится по распоряжению финансового директора, но кто инициирует её в его отсутствие — не указано. Требуется уточнение — вопрос направлен на ручную проверку.",
     "review_reason": "В регламенте не указан инициатор внезапной инвентаризации при отсутствии финансового директора"},
    {"topic": "Кадры",
     "question": "Кто утверждает график смен, если мастер в отпуске?",
     "answer": "По регламенту КД-005 (п. 2.2) график смен утверждает мастер на месяц вперёд, однако порядок утверждения в его отсутствие не определён. Требуется уточнение — вопрос направлен на ручную проверку.",
     "review_reason": "В регламенте не указан порядок утверждения графика смен при отсутствии мастера"},
    {"topic": "Кадры",
     "question": "Кто отвечает за обновление телефонного справочника, если отв. сотрудник уволился?",
     "answer": "Телефонный справочник (КД-005, п. 7.3) обновляется ежемесячно, но ответственный за обновление и порядок передачи обязанностей при увольнении сотрудника в регламенте не указаны. Требуется уточнение — вопрос направлен на ручную проверку.",
     "review_reason": "В регламенте не указан ответственный за обновление телефонного справочника при увольнении сотрудника"},
    {"topic": "Кадры",
     "question": "Кто отвечает за обновление телефонного справочника, если отв. сотрудник на больничном?",
     "answer": "Телефонный справочник (КД-005, п. 7.3) обновляется ежемесячно, но ответственный за обновление и порядок замещения на время больничного в регламенте не указаны. Требуется уточнение — вопрос направлен на ручную проверку.",
     "review_reason": "В регламенте не указан ответственный за обновление телефонного справочника на время больничного"},
]


def seed_faq():
    Base.metadata.create_all(bind=engine)
    ensure_schema_upgrades()
    db = SessionLocal()
    try:
        added = 0
        for item in FAQ_DATA:
            exists = db.query(FaqEntry).filter_by(question=item["question"]).first()
            if not exists:
                db.add(FaqEntry(
                    question=item["question"],
                    answer=item["answer"],
                    topic=item["topic"],
                    keywords=item["keywords"],
                    status="answered_auto",
                    is_active=True,
                ))
                added += 1
        review_added = 0
        for item in FAQ_REVIEW_DATA:
            exists = db.query(FaqEntry).filter_by(question=item["question"]).first()
            if not exists:
                db.add(FaqEntry(
                    question=item["question"],
                    answer=item["answer"],
                    topic=item["topic"],
                    keywords="",
                    status="needs_review",
                    review_reason=item["review_reason"],
                    is_active=True,
                ))
                review_added += 1
        db.commit()
        total = db.query(FaqEntry).count()
        print(f"FAQ seed done: answered_auto added={added}, needs_review added={review_added}, total={total} "
              f"(из {len(FAQ_DATA)} + {len(FAQ_REVIEW_DATA)} в файле)")
    finally:
        db.close()


if __name__ == "__main__":
    seed_faq()
'@

# ============ tests_data/kb_documents.jsonl ============
$ProjectFiles["tests_data/kb_documents.jsonl"] = @'
{"title": "Политика отпусков", "content": "Ежегодный основной отпуск — 28 календарных дней. Отпуск можно разделить на части, при этом одна часть — не менее 14 дней. Перенос отпуска требует уведомления руководителя не позднее чем за 14 дней. Заявление подаётся через HR-портал.", "topic": "Отпуска"}
{"title": "Доступ к тестовому стенду", "content": "Для получения доступа к тестовому стенду создайте заявку на внутреннем портале в разделе «Заявки в ИТ». Доступ предоставляется в течение 2 рабочих дней. Токены действуют 30 дней.", "topic": "Доступ"}
{"title": "Больничные листы", "content": "Больничный лист оформляется в день обращения к врачу. Работник обязан уведомить руководителя в первый день болезни. Больничный лист сдаётся в бухгалтерию в течение 5 дней после закрытия.", "topic": "Больничные"}
{"title": "Код-ревью", "content": "Каждый pull request проверяется как минимум одним ревьюером. Критические изменения требуют двух ревьюеров. Время ревью — не более 24 часов. Для фича-веток используется squash merge.", "topic": "Разработка"}
{"title": "Командировки", "content": "Командировка согласуется с руководителем за 5 рабочих дней. Суточные по России — 700 рублей. Отчёт о расходах сдаётся в течение 3 дней после возвращения.", "topic": "Командировки"}
'@

# ============ tests_data/kb_questions.jsonl ============
$ProjectFiles["tests_data/kb_questions.jsonl"] = @'
{"question": "Сколько дней ежегодный основной отпуск?", "expected_status": "answered_auto", "expected_quote": "28 календарных дней"}
{"question": "Какие дополнительные отпуска положены?", "expected_status": "answered_auto", "expected_quote": "до 7 дней"}
{"question": "Когда утверждается график отпусков?", "expected_status": "answered_auto", "expected_quote": "до 17 декабря"}
{"question": "За сколько дней подавать заявление на отпуск?", "expected_status": "answered_auto", "expected_quote": "за 14 дней"}
{"question": "Когда выплачиваются отпускные?", "expected_status": "answered_auto", "expected_quote": "за 3 дня до начала отпуска"}
{"question": "Можно ли разделить отпуск на части?", "expected_status": "answered_auto", "expected_quote": "не менее 14 календарных дней"}
{"question": "Как уведомить о переносе отпуска?", "expected_status": "answered_auto", "expected_quote": "не позднее чем за 14 дней"}
{"question": "Что делать при больничном листе?", "expected_status": "answered_auto", "expected_quote": "5 рабочих дней"}
{"question": "Кто оплачивает больничный лист?", "expected_status": "answered_auto", "expected_quote": "за счёт работодателя"}
{"question": "Какой процент пособия по больничному зависит от стажа?", "expected_status": "answered_auto", "expected_quote": "60%"}
{"question": "Когда выплачивается зарплата?", "expected_status": "answered_auto", "expected_quote": "2 раза в месяц"}
{"question": "Где посмотреть расчётный листок по зарплате?", "expected_status": "answered_auto", "expected_quote": "Мои выплаты"}
{"question": "Кто начисляет зарплату и где бухгалтерия?", "expected_status": "answered_auto", "expected_quote": "каб. 210"}
{"question": "Какой формат корпоративной почты?", "expected_status": "answered_auto", "expected_quote": "фамилия.имя@promtekno.ru"}
{"question": "Какие экстренные номера телефонов?", "expected_status": "answered_auto", "expected_quote": "пожарная — 101"}
{"question": "Как проходит адаптация нового сотрудника?", "expected_status": "answered_auto", "expected_quote": "3 месяца"}
{"question": "Кто может быть наставником и сколько длится наставничество?", "expected_status": "answered_auto", "expected_quote": "не менее 3 лет"}
{"question": "Как отправить предложение по улучшению процессов?", "expected_status": "answered_auto", "expected_quote": "10 рабочих дней"}
{"question": "Какие склады есть на предприятии?", "expected_status": "answered_auto", "expected_quote": "сырьё и основные материалы"}
{"question": "Что такое лимитно-заборная карта?", "expected_status": "answered_auto", "expected_quote": "ЛЗК"}
{"question": "Что такое требование-накладная М-11?", "expected_status": "answered_auto", "expected_quote": "хозяйственных нужд"}
{"question": "В какой срок принимаются материалы на склад?", "expected_status": "answered_auto", "expected_quote": "24 часов"}
{"question": "Как оформляются расхождения при приёмке?", "expected_status": "answered_auto", "expected_quote": "ТОРГ-2"}
{"question": "Какой принцип хранения материалов FIFO?", "expected_status": "answered_auto", "expected_quote": "First In — First Out"}
{"question": "Какие условия хранения электроники?", "expected_status": "answered_auto", "expected_quote": "+15…+25°C"}
{"question": "Когда проводится инвентаризация?", "expected_status": "answered_auto", "expected_quote": "1 раз в год (декабрь)"}
{"question": "В какое время выдаются материалы в цех?", "expected_status": "answered_auto", "expected_quote": "08:00–12:00"}
{"question": "Какие документы нужны для получения материалов?", "expected_status": "answered_auto", "expected_quote": "постоянный пропуск"}
{"question": "Как оформляется выдача сверх лимита?", "expected_status": "answered_auto", "expected_quote": "50 000 руб"}
{"question": "В какой срок возвращаются неиспользованные материалы?", "expected_status": "answered_auto", "expected_quote": "24 часов"}
{"question": "Как перевозить грузы по территории предприятия?", "expected_status": "answered_auto", "expected_quote": "свыше 50 кг"}
{"question": "Кто несёт материальную ответственность на складе?", "expected_status": "answered_auto", "expected_quote": "полную материальную ответственность"}
{"question": "Какие отчёты формирует склад?", "expected_status": "answered_auto", "expected_quote": "более 180 дней"}
{"question": "Какие категории ремонтной сложности оборудования?", "expected_status": "answered_auto", "expected_quote": "4 категории"}
{"question": "Какое время реагирования на отказ оборудования категории А?", "expected_status": "answered_auto", "expected_quote": "не более 15 минут"}
{"question": "Какая периодичность ТО-1 и ТО-2?", "expected_status": "answered_auto", "expected_quote": "каждые 250 моточасов"}
{"question": "Когда утверждается график ППР?", "expected_status": "answered_auto", "expected_quote": "до 25 декабря"}
{"question": "Что входит в ежесменное обслуживание (ЕО)?", "expected_status": "answered_auto", "expected_quote": "6–8 бар"}
{"question": "Что входит в работы ТО-1?", "expected_status": "answered_auto", "expected_quote": "замена фильтров"}
{"question": "Что добавляется в ТО-2 по сравнению с ТО-1?", "expected_status": "answered_auto", "expected_quote": "замена масла"}
{"question": "Как оформляется акт после ТО-1 и ТО-2?", "expected_status": "answered_auto", "expected_quote": "исполнитель и мастер смены"}
{"question": "Как проводится капитальный ремонт (КР)?", "expected_status": "answered_auto", "expected_quote": "полной разборкой оборудования"}
{"question": "Что делать при аварийном отказе оборудования?", "expected_status": "answered_auto", "expected_quote": "форма АА-1"}
{"question": "Какие KPI надёжности оборудования?", "expected_status": "answered_auto", "expected_quote": "MTBF ≥ 500 часов"}
{"question": "Какие документы нужны для ремонтных работ по охране труда?", "expected_status": "answered_auto", "expected_quote": "форма НД-1"}
{"question": "Что такое Lockout/Tagout при ремонте?", "expected_status": "answered_auto", "expected_quote": "НЕ ВКЛЮЧАТЬ — РАБОТАЮТ ЛЮДИ"}
{"question": "Как получить ипотеку?", "expected_status": "no_topic", "expected_quote": null}
{"question": "Когда повысят зарплату?", "expected_status": "no_topic", "expected_quote": null}
{"question": "Расскажи всё о компании", "expected_status": "answered_auto", "expected_quote": null}
{"question": "Какой пароль от корпоративного Wi-Fi?", "expected_status": "no_topic", "expected_quote": null}
{"question": "Кто утверждает лимитно-заборные карты, если начальник производства в отпуске?", "expected_status": "needs_review", "expected_quote": null}
{"question": "Кто инициирует внезапную инвентаризацию, если финансовый директор в отпуске?", "expected_status": "needs_review", "expected_quote": null}
{"question": "Кто утверждает график смен, если мастер в отпуске?", "expected_status": "needs_review", "expected_quote": null}
{"question": "Кто отвечает за обновление телефонного справочника, если отв. сотрудник уволился?", "expected_status": "needs_review", "expected_quote": null}
{"question": "Кто отвечает за обновление телефонного справочника, если отв. сотрудник на больничном?", "expected_status": "needs_review", "expected_quote": null}
'@

# ============ tests_data/brak_i_neispravnosti.txt ============
$ProjectFiles["tests_data/brak_i_neispravnosti.txt"] = @'
📄 Документ 4. Действия при обнаружении брака или неисправности оборудования

РЕГЛАМЕНТ № БР-004
УТВЕРЖДЕН приказом генерального директора № 130 от 15.03.2024
ДЕЙСТВУЕТ с 01.04.2024

ДЕЙСТВИЯ ПРИ ОБНАРУЖЕНИИ БРАКА ИЛИ НЕИСПРАВНОСТИ ОБОРУДОВАНИЯ

1. ОБЩИЕ ПОЛОЖЕНИЯ

1.1. Регламент устанавливает порядок действий работников при
обнаружении бракованной продукции, отклонений в технологическом
процессе и неисправностей оборудования.

1.2. Цель регламента — минимизация потерь, предотвращение выпуска
некондиционной продукции, обеспечение безопасности работников.

2. КЛАССИФИКАЦИЯ БРАКА

2.1. По степени дефекта:
— исправимый брак — дефект может быть устранён без потери
  потребительских свойств (подлежит доработке);
— неисправимый брак — дефект не может быть устранён или его
  устранение экономически нецелесообразно (подлежит утилизации).

2.2. По моменту выявления:
— внутренний брак — выявлен в процессе производства;
— внешний брак — выявлен у потребителя (рекламация).

2.3. По объёму:
— единичный брак — до 3 единиц продукции;
— групповой брак — от 3 до 20 единиц;
— массовый брак — более 20 единиц или целая партия.

3. ДЕЙСТВИЯ ПРИ ОБНАРУЖЕНИИ БРАКА

3.1. Работник, обнаруживший брак, обязан:
— НЕМЕДЛЕННО остановить операцию (если продолжает выпуск брака);
— изолировать бракованную продукцию в специально отведённом месте
  (красная зона, стеллаж «Брак»);
— на каждую единицу прикрепить бирку (форма БР-1) с указанием:
  • даты и времени обнаружения;
  • ФИО обнаружившего;
  • наименования продукции и номера партии;
  • описания дефекта;
— сообщить мастеру смены (по внутр. тел. или лично);
— сделать запись в сменном журнале.

3.2. Мастер смены обязан в течение 15 минут:
— осмотреть бракованную продукцию;
— принять решение о дальнейшей судьбе (доработка / утилизация /
  возврат поставщику);
— при групповом или массовом браке — немедленно уведомить:
  • начальника цеха;
  • отдел технического контроля (ОТК);
  • отдел качества.

3.3. При внешнем браке (рекламация от потребителя):
— работник, получивший информацию, передаёт её в отдел качества;
— отдел качества регистрирует рекламацию в журнале (форма РК-1)
  в течение 2 часов;
— в течение 24 часов создаётся комиссия для расследования;
— в течение 5 рабочих дней готовится ответ потребителю.

4. ИЗОЛЯЦИЯ БРАКОВАННОЙ ПРОДУКЦИИ

4.1. Для изоляции брака на каждом участке предусмотрена красная зона
площадью не менее 2 м², обозначенная разметкой и знаком «Брак».

4.2. Доступ в красную зону имеют только:
— мастер смены;
— контролёр ОТК;
— работник, изолирующий брак (под контролем мастера).

4.3. Хранение брака в красной зоне — не более 24 часов.
Дальнейшая судьба определяется актом (форма АБ-1).

5. НЕИСПРАВНОСТИ ОБОРУДОВАНИЯ

5.1. Признаки неисправности, при которых работа должна быть
НЕМЕДЛЕННО остановлена:
— посторонние шумы, вибрация, стуки;
— запах гари, дым;
— утечки масла, охлаждающей жидкости, газа;
— перегрев узлов выше допустимых значений;
— срабатывание аварийной сигнализации;
— отказ систем безопасности (блокировок, аварийных остановов).

5.2. Порядок действий при неисправности:
— нажать кнопку «АВАРИЙНЫЙ СТОП» (красная, с жёлтой каймой);
— обесточить оборудование (если это безопасно);
— сообщить мастеру смены и механику (тел. 103);
— повесить табличку «НЕ РАБОТАТЬ — АВАРИЯ» на пульт управления;
— сделать запись в журнале оборудования (форма ОЖ-1);
— не предпринимать попыток самостоятельного ремонта.

5.3. Ремонт производится только аттестованными специалистами
службы главного механика по наряду-допуску (форма НД-1).

6. РАССЛЕДОВАНИЕ И УЧЁТ

6.1. По каждому случаю брака составляется акт (форма АБ-1) в
течение 24 часов.

6.2. Акт подписывают:
— мастер смены;
— контролёр ОТК;
— технолог;
— при массовом браке — начальник цеха и директор по качеству.

6.3. Данные о браке вносятся в базу данных системы учёта качества
(1С:Предприятие, модуль «Качество»).

6.4. Ежемесячно отдел качества готовит отчёт по браку с указанием:
— объёма и стоимости брака по подразделениям;
— основных причин (диаграмма Исикавы);
— корректирующих и предупреждающих действий.

7. ОТВЕТСТВЕННОСТЬ

7.1. Работник, скрывший факт брака или неисправности, несёт
дисциплинарную ответственность вплоть до увольнения.

7.2. Работник, допустивший брак по своей вине, может быть привлечён
к материальной ответственности в пределах среднего месячного заработка
(ст. 241 ТК РФ).

7.3. Работник, своевременно сообщивший о браке и принявший меры
по его локализации, от ответственности освобождается.
'@

# ============ tests_data/kadry_i_svyaz.txt ============
$ProjectFiles["tests_data/kadry_i_svyaz.txt"] = @'
📄 Документ 5. Кадровые вопросы, график и внутренние каналы связи

РЕГЛАМЕНТ № КД-005
УТВЕРЖДЕН приказом генерального директора № 131 от 15.03.2024
ДЕЙСТВУЕТ с 01.04.2024

КАДРОВЫЕ ВОПРОСЫ, ГРАФИК РАБОТЫ И ВНУТРЕННИЕ КАНАЛЫ СВЯЗИ
(Памятка для новых сотрудников)

1. ОБЩИЕ СВЕДЕНИЯ О ПРЕДПРИЯТИИ

1.1. ООО «ПромТехно» — производственное предприятие полного цикла,
основано в 2008 году. Численность персонала — 487 человек.

1.2. Основные подразделения:
— производственный комплекс (цеха № 1–5);
— служба главного механика;
— служба главного энергетика;
— отдел технического контроля (ОТК);
— отдел качества;
— склад готовой продукции;
— административно-управленческий персонал.

2. РАБОЧЕЕ ВРЕМЯ И ГРАФИК

2.1. Для административного персонала:
— пятидневная рабочая неделя;
— рабочие дни: понедельник–пятница;
— время работы: 09:00–18:00, перерыв 13:00–14:00;
— выходные: суббота, воскресенье.

2.2. Для производственного персонала:
— сменный график (1-я, 2-я, 3-я смены);
— продолжительность смены — 8 часов;
— перерыв — 30 минут;
— график смен утверждается мастером на месяц вперёд
  (до 25 числа предыдущего месяца).

2.3. Учёт рабочего времени ведётся в системе «1С:ЗУП» по электронным
пропускам (турникеты на КПП-1 и КПП-2).

3. ОТПУСКА

3.1. Ежегодный основной оплачиваемый отпуск — 28 календарных дней.

3.2. Дополнительные отпуска:
— за работу во вредных условиях труда — до 7 дней (по результатам
  СОУТ);
— за ненормированный рабочий день — до 3 дней;
— за работу в районах Крайнего Севера — 24 дня.

3.3. График отпусков утверждается до 17 декабря на следующий год.

3.4. Заявление на отпуск подаётся через HR-портал не позднее чем
за 14 дней до предполагаемой даты начала.

3.5. Отпускные выплачиваются не позднее чем за 3 дня до начала
отпуска (ст. 136 ТК РФ).

3.6. Разделение отпуска на части: допускается, при условии что
одна из частей не менее 14 календарных дней (ст. 125 ТК РФ).

3.7. Перенос отпуска:
— по инициативе работника — не позднее чем за 14 дней;
— по инициативе работодателя — с письменного согласия работника
  и не позднее чем за 2 недели до начала.

4. БОЛЬНИЧНЫЕ ЛИСТЫ

4.1. При временной нетрудоспособности работник обязан:
— в первый день болезни уведомить непосредственного руководителя
  (по телефону или через мессенджер);
— обратиться в медицинское учреждение;
— после закрытия больничного листа предоставить его в отдел кадров
  в течение 5 рабочих дней.

4.2. Больничный лист принимается в электронном виде (номер ЭЛН)
или на бумажном носителе.

4.3. Пособие по временной нетрудоспособности выплачивается:
— первые 3 дня — за счёт работодателя;
— последующие дни — за счёт ФСС.

4.4. Размер пособия зависит от страхового стажа:
— до 5 лет — 60% среднего заработка;
— от 5 до 8 лет — 80%;
— более 8 лет — 100%.

5. ЗАРАБОТНАЯ ПЛАТА

5.1. Заработная плата выплачивается 2 раза в месяц:
— аванс — 25 число текущего месяца (за первую половину);
— окончательный расчёт — 10 число следующего месяца.

5.2. Расчётный листок доступен:
— в HR-портале (раздел «Мои выплаты»);
— в отделе кадров (каб. 102) по запросу.

5.3. Вопросы по заработной плате:
— начисления — бухгалтерия, каб. 210, тел. 210;
— удержания — отдел кадров, каб. 102, тел. 102;
— премии и надбавки — непосредственный руководитель.

6. НАСТАВНИЧЕСТВО

6.1. За каждым новым работником закрепляется наставник из числа
опытных сотрудников (стаж не менее 3 лет).

6.2. Срок наставничества:
— рабочие профессии — от 2 до 4 недель;
— ИТР — от 1 до 3 месяцев;
— руководители — от 3 до 6 месяцев.

6.3. Наставник обязан:
— ознакомить нового работника с рабочим местом и оборудованием;
— передать практические навыки выполнения работ;
— контролировать соблюдение требований охраны труда;
— еженедельно отчитываться перед руководителем о прогрессе
  адаптации.

6.4. По окончании срока наставничества составляется отчёт
(форма Н-1), который подписывают наставник, работник и руководитель.

7. ВНУТРЕННИЕ КАНАЛЫ СВЯЗИ

7.1. Корпоративная электронная почта:
— формат адреса: фамилия.имя@promtekno.ru;
— выдаётся в первый рабочий день в отделе ИТ (каб. 305);
— обязательна к использованию для служебной переписки.

7.2. Корпоративный мессенджер (MS Teams):
— используется для оперативной связи;
— общие каналы по подразделениям;
— личные чаты — только в рабочее время.

7.3. Телефонный справочник:
— размещён на внутреннем портале (intranet.promtekno.ru/phones);
— обновляется ежемесячно;
— экстренные номера:
  • пожарная охрана — 101;
  • диспетчерская — 102;
  • служба безопасности — 103;
  • скорая помощь — 104;
  • отдел кадров — 102 (вн. 202);
  • отдел ИТ — 105 (вн. 305).

7.4. Внутренний портал (интранет):
— адрес: intranet.promtekno.ru;
— разделы: новости, документы, HR-портал, заявки в ИТ,
  бронирование переговорных, меню столовой.

7.5. Доски объявлений:
— расположены у входа в каждый корпус;
— обновляются еженедельно по понедельникам;
— официальная информация дублируется на интранете.

8. АДАПТАЦИЯ НОВОГО СОТРУДНИКА

8.1. Программа адаптации рассчитана на 3 месяца.

8.2. Этапы адаптации:
— 1-я неделя: вводный инструктаж, знакомство с подразделением,
  наставник;
— 1-й месяц: обучение на рабочем месте, первые самостоятельные
  задачи под контролем;
— 2-й месяц: расширение зоны ответственности;
— 3-й месяц: итоговая оценка прохождения испытательного срока.

8.3. Встречи с HR:
— через 1 неделю после выхода;
— через 1 месяц;
— через 3 месяца (итоговая).

8.4. По окончании испытательного срока (3 месяца) принимается
решение о продолжении трудовых отношений.

9. ОБРАТНАЯ СВЯЗЬ И ПРЕДЛОЖЕНИЯ

9.1. Работники могут направлять предложения по улучшению
производственных процессов через:
— ящик предложений (корпус А, 1 этаж);
— форму на интранете (раздел «Предложения»);
— непосредственного руководителя.

9.2. Все предложения регистрируются и рассматриваются в течение
10 рабочих дней.

9.3. За внедрённые предложения, дающие экономический эффект,
выплачивается вознаграждение (до 10% от годового эффекта).
'@

# ============ tests_data/ohrana_truda.txt ============
$ProjectFiles["tests_data/ohrana_truda.txt"] = @'
📄 Документ 1. Охрана труда, техника безопасности и пропускной режим
РЕГЛАМЕНТ № ОТ-001
УТВЕРЖДЕН приказом генерального директора № 127 от 15.03.2024
ДЕЙСТВУЕТ с 01.04.2024

ОХРАНА ТРУДА, ТЕХНИКА БЕЗОПАСНОСТИ И ПРОПУСКНОЙ РЕЖИМ
(Инструкция для новых сотрудников)

1. ОБЛАСТЬ ПРИМЕНЕНИЯ

1.1. Настоящий регламент обязателен для исполнения всеми работниками
ООО «ПромТехно», а также лицами, находящимися на территории предприятия
по служебным или личным делам.

1.2. Регламент разработан в соответствии с Трудовым кодексом РФ,
Федеральным законом № 181-ФЗ «Об основах охраны труда», Правилами
по охране труда при эксплуатации промышленного транспорта (ПОТ РМ-008-99).

2. ТЕРМИНЫ И ОПРЕДЕЛЕНИЯ

2.1. Инструктаж — мероприятие по ознакомлению работника с требованиями
охраны труда. Виды: вводный, первичный на рабочем месте, повторный,
внеплановый, целевой.

2.2. СИЗ — средства индивидуальной защиты (каска, очки, перчатки,
спецодежда, спецобувь, респиратор, наушники).

2.3. Опасная зона — территория, на которой возможно воздействие
опасных производственных факторов (движущиеся механизмы, токопроводящие
части, зоны погрузки/разгрузки).

3. ВВОДНЫЙ ИНСТРУКТАЖ

3.1. Все вновь принимаемые работники проходят вводный инструктаж
в течение первого рабочего дня до начала выполнения трудовых обязанностей.

3.2. Инструктаж проводит инженер по охране труда (каб. 215, корпус А).

3.3. Продолжительность вводного инструктажа — не менее 2 часов.

3.4. По окончании инструктажа работник расписывается в журнале
регистрации вводных инструктажей (форма ОТ-1).

4. ПЕРВИЧНЫЙ ИНСТРУКТАЖ НА РАБОЧЕМ МЕСТЕ

4.1. Проводится непосредственным руководителем (мастером смены)
в течение первых 3 рабочих дней.

4.2. Включает:
— ознакомление с технологическим процессом;
— изучение устройств и принципа работы оборудования;
— изучение безопасных методов и приёмов выполнения работ;
— изучение мест расположения средств пожаротушения и аптечек;
— изучение путей эвакуации.

4.3. Стажировка под руководством наставника — от 2 до 14 смен
в зависимости от категории работ.

5. ОБЩИЕ ТРЕБОВАНИЯ БЕЗОПАСНОСТИ

5.1. Работник обязан:
— соблюдать правила внутреннего трудового распорядка;
— выполнять только ту работу, которая поручена непосредственным
  руководителем;
— применять выданные СИЗ в течение всего рабочего времени;
— немедленно сообщать руководителю о любой ситуации, угрожающей
  жизни и здоровью людей;
— проходить обязательные медицинские осмотры в установленные сроки.

5.2. Работнику ЗАПРЕЩАЕТСЯ:
— находиться на территории предприятия в состоянии алкогольного,
  наркотического или токсического опьянения;
— курить вне специально отведённых мест (площадки у корпусов Б и В);
— пользоваться открытым огнём в производственных помещениях;
— снимать или изменять предохранительные устройства оборудования;
— работать при неисправном оборудовании или освещении;
— заходить в опасные зоны без разрешения мастера смены.

6. ПРОПУСКНОЙ РЕЖИМ

6.1. Доступ на территорию предприятия осуществляется по постоянным
или разовым пропускам.

6.2. Постоянный пропуск оформляется в отделе кадров (каб. 102)
в первый рабочий день. Для оформления необходимы:
— паспорт;
— фото 3×4 (2 шт.);
— направление от руководителя подразделения.

6.3. Пропуск носится на видном месте в течение всего времени
нахождения на территории.

6.4. При утере пропуска работник обязан немедленно сообщить
в службу безопасности (тел. 101, вн. 200). Изготовление дубликата —
в течение 1 рабочего дня, стоимость удерживается из заработной платы.

6.5. Посетители оформляются по разовым пропускам через КПП-1
с предъявлением документа, удостоверяющего личность.

7. ДЕЙСТВИЯ ПРИ АВАРИЙНЫХ СИТУАЦИЯХ

7.1. При обнаружении пожара:
— немедленно сообщить в пожарную охрану по тел. 101 и диспетчеру
  по тел. 102;
— принять меры к эвакуации людей;
— приступить к тушению пожара первичными средствами, если это
  не угрожает жизни.

7.2. При несчастном случае:
— оказать первую помощь пострадавшему;
— сообщить руководителю и в службу охраны труда;
— сохранить обстановку на месте происшествия (если это не угрожает
  другим лицам).

8. ОТВЕТСТВЕННОСТЬ

8.1. За нарушение требований настоящего регламента работники
несут дисциплинарную, административную и уголовную ответственность
в соответствии с действующим законодательством РФ.

8.2. Повторное нарушение в течение 12 месяцев является основанием
для расторжения трудового договора по инициативе работодателя
(п. 5 ч. 1 ст. 81 ТК РФ).

9. ПРИЛОЖЕНИЯ

Приложение 1. Форма журнала регистрации вводных инструктажей (ОТ-1).
Приложение 2. Схема эвакуации с территории предприятия.
Приложение 3. Перечень СИЗ по профессиям.
'@

# ============ tests_data/sdacha_priemka_smen.txt ============
$ProjectFiles["tests_data/sdacha_priemka_smen.txt"] = @'
📄 Документ 3. Порядок сдачи и приёмки производственных смен

РЕГЛАМЕНТ № ПС-003
УТВЕРЖДЕН приказом генерального директора № 129 от 15.03.2024
ДЕЙСТВУЕТ с 01.04.2024

ПОРЯДОК СДАЧИ И ПРИЁМКИ ПРОИЗВОДСТВЕННЫХ СМЕН

1. ОБЩИЕ ПОЛОЖЕНИЯ

1.1. Регламент устанавливает единый порядок передачи производственных
смен на предприятии ООО «ПромТехно».

1.2. На предприятии действует трёхсменный режим работы:
— 1-я смена: 08:00–16:00;
— 2-я смена: 16:00–00:00;
— 3-я смена: 00:00–08:00.

1.3. Перерыв для отдыха и питания — 30 минут в середине смены.

2. ПОДГОТОВКА К СМЕНЕ

2.1. Работник обязан прибыть на предприятие не позднее чем за
15 минут до начала смены.

2.2. До начала смены работник:
— проходит через КПП, предъявляя пропуск;
— переодевается в спецодежду в раздевалке своего подразделения;
— получает СИЗ (при необходимости);
— проходит предрейсовый/предсменный медосмотр (для отдельных
  категорий работников);
— расписывается в журнале учёта рабочего времени.

2.3. Опоздание более чем на 15 минут без уважительной причины
рассматривается как нарушение трудовой дисциплины.

3. ПЛАНЁРКА ПЕРЕД СМЕНОЙ

3.1. Ежедневно перед началом смены мастер проводит планёрку
продолжительностью не более 10 минут.

3.2. На планёрке доводятся:
— производственное задание на смену (форма ПЗ-1);
— изменения в технологическом процессе;
— замечания по охране труда;
— информация о бракованной продукции предыдущей смены;
— кадровые изменения (отсутствующие, новые работники).

3.3. Работники расписываются в листе ознакомления с заданием.

4. ПРИЁМКА СМЕНЫ

4.1. Приёмка смены производится непосредственно на рабочем месте
присутствующим представителем сдающей смены (не менее чем за 10 минут
до её окончания).

4.2. При приёмке проверяется:
— техническое состояние оборудования (по чек-листу ТО-1);
— наличие и исправность инструмента и оснастки;
— количество и качество незавершённого производства;
— санитарное состояние рабочего места;
— наличие записей в сменном журнале.

4.3. Все замечания фиксируются в сменном журнале (форма СЖ-1)
с подписями сдающего и принимающего работника.

4.4. При наличии критических замечаний (неисправность оборудования,
нарушение технологии) принимающий работник вправе отказаться от
приёмки смены. Вопрос решается через мастера и начальника цеха.

5. ВЕДЕНИЕ СМЕННОГО ЖУРНАЛА

5.1. Сменный журнал ведётся в течение всей смены.

5.2. В журнал вносятся:
— время начала и окончания смены;
— ФИО работников, заступивших на смену;
— производственное задание и факт его выполнения;
— параметры технологического процесса (температура, давление,
  скорость и т.д.) — каждые 2 часа;
— случаи простоя оборудования с указанием причины и длительности;
— случаи выпуска бракованной продукции;
— Происшествия и нарушения;
— замечания и распоряжения руководства.

5.3. Записи ведутся разборчиво, без исправлений. При необходимости
исправления — зачёркивание одной чертой с указанием даты, подписи
и пояснения.

5.4. По окончании смены журнал подписывается мастером смены
и сдаётся в технический архив цеха.

6. СДАЧА СМЕНЫ

6.1. За 30 минут до окончания смены работник:
— завершает текущую операцию (если это безопасно);
— приводит в порядок рабочее место (система 5S);
— готовит отчёт о выполнении задания;
— заполняет сменный журнал.

6.2. За 10 минут до окончания смены — передача смены принимающему
работнику в соответствии с разделом 4 настоящего регламента.

6.3. После сдачи смены работник:
— сдаёт инструмент на склад инструмента (если выдавался под роспись);
— сдаёт спецодежду в шкафчик;
— проходит через КПП.

6.4. Задерживаться на территории предприятия после окончания смены
без разрешения руководителя запрещается.

7. ОСОБЫЕ СЛУЧАИ

7.1. При неявке принимающей смены:
— сдающий работник продолжает работу до прибытия замены;
— уведомляет мастера и диспетчера;
— время сверхурочной работы оплачивается в соответствии с ТК РФ.

7.2. При аварийной ситуации во время сдачи смены:
— сдача смены приостанавливается;
— все работники участвуют в ликвидации аварии по плану ЛА-1;
— после ликвидации — полная внеплановая сдача смены с составлением
  акта (форма АС-1).

8. ОТВЕТСТВЕННОСТЬ

8.1. Мастер смены несёт персональную ответственность за:
— своевременное проведение планёрки;
— полноту и достоверность записей в сменном журнале;
— качество передачи смены.

8.2. Работники несут ответственность за:
— соблюдение графика смен;
— полноту информации при передаче смены;
— состояние рабочего места.
'@

# ============ tests_data/siz_i_rabochie_mesta.txt ============
$ProjectFiles["tests_data/siz_i_rabochie_mesta.txt"] = @'
📄 Документ 2. Выдача СИЗ и организация рабочего места
РЕГЛАМЕНТ № СИЗ-002
УТВЕРЖДЕН приказом генерального директора № 128 от 15.03.2024
ДЕЙСТВУЕТ с 01.04.2024

ВЫДАЧА СРЕДСТВ ИНДИВИДУАЛЬНОЙ ЗАЩИТЫ И ОРГАНИЗАЦИЯ РАБОЧЕГО МЕСТА

1. ОБЩИЕ ПОЛОЖЕНИЯ

1.1. Регламент устанавливает порядок обеспечения работников СИЗ,
правила их хранения, использования и списания.

1.2. СИЗ выдаются бесплатно за счёт средств работодателя в соответствии
с «Типовыми нормами бесплатной выдачи сертифицированных СИЗ»
(Приказ Минтруда РФ № 767н от 29.10.2021).

2. НОРМЫ ВЫДАЧИ СИЗ

2.1. Основные нормы выдачи (на 1 работника в год):

Профессия                 | Костюм | Ботинки | Перчатки | Каска | Очки
--------------------------|--------|---------|----------|-------|-----
Слесарь МСР               | 1 шт.  | 1 пара  | 12 пар   | 1 шт. | 1 шт.
Оператор станков с ЧПУ    | 1 шт.  | 1 пара  | 6 пар    | 1 шт. | 1 шт.
Электромонтёр             | 1 шт.  | 1 пара  | 6 пар    | 1 шт. | 1 шт.
Кладовщик                 | 1 шт.  | 1 пара  | 12 пар   | —     | —
Инженер-технолог          | 1 шт.  | 1 пара  | 2 пары   | 1 шт. | 1 шт.

2.2. Дополнительные СИЗ (по результатам СОУТ):
— респираторы (при работе с лакокрасочными материалами);
— противошумные наушники (при уровне шума свыше 80 дБА);
— диэлектрические перчатки и коврики (для электромонтёров);
— страховочные системы (для работ на высоте свыше 1,8 м).

3. ПОРЯДОК ПОЛУЧЕНИЯ СИЗ

3.1. Выдача СИЗ производится на складе СИЗ (корпус В, помещение 014)
по личным карточкам учёта выдачи СИЗ (форма МБ-7).

3.2. График работы склада СИЗ:
— понедельник–четверг: 08:00–17:00, перерыв 12:00–13:00;
— пятница: 08:00–16:00, перерыв 12:00–13:00;
— суббота, воскресенье: выходной.

3.3. Для получения СИЗ работник предъявляет:
— постоянный пропуск;
— направление от мастера смены (форма СИЗ-1);
— личную карточку учёта выдачи СИЗ.

3.4. При получении работник обязан:
— проверить комплектность и исправность СИЗ;
— примерить и убедиться в соответствии размера;
— расписаться в карточке и журнале выдачи.

4. ХРАНЕНИЕ И УХОД ЗА СИЗ

4.1. Работник обязан хранить СИЗ в индивидуальном шкафчике
в раздевалке своего подразделения.

4.2. Запрещается хранить СИЗ:
— в производственных помещениях (кроме случаев, предусмотренных
  технологической картой);
— вместе с личной одеждой и обувью;
— в местах, подверженных воздействию влаги, химических веществ,
  прямых солнечных лучей.

4.3. Спецодежда сдаётся в стирку и химчистку еженедельно
(понедельник, среда, пятница) через мастера смены.

4.4. Работник обязан ежедневно осматривать СИЗ перед началом работы.
При обнаружении дефектов — заменить через склад СИЗ.

5. ОРГАНИЗАЦИЯ РАБОЧЕГО МЕСТА

5.1. Рабочее место должно соответствовать требованиям системы 5S:
— Сортировка (Seiri): на рабочем месте только необходимые предметы;
— Соблюдение порядка (Seiton): каждый предмет имеет своё место;
— Содержание в чистоте (Seiso): ежедневная уборка;
— Стандартизация (Seiketsu): единые стандарты для всех смен;
— Совершенствование (Shitsuke): постоянное улучшение.

5.2. На рабочем месте обязательно наличие:
— инструкции по охране труда для данной профессии;
— схемы безопасного выполнения работ;
— аптечки первой помощи;
— огнетушителя (тип ОП-5 или ОУ-3);
— знака «Рабочее место» с ФИО работника.

5.3. Проходы к рабочему месту должны быть свободными, ширина —
не менее 1,2 м. Загромождение проходов запрещается.

6. СПИСАНИЕ И ВОЗВРАТ СИЗ

6.1. СИЗ подлежат замене при:
— истечении срока носки;
— утрате защитных свойств;
— механическом повреждении, не подлежащем ремонту;
— изменении роста или размера работника.

6.2. При увольнении работник обязан сдать все выданные СИЗ
на склад. Невозврат оценивается по остаточной стоимости и
удерживается из final pay.

7. ОТВЕТСТВЕННОСТЬ

7.1. Работодатель несёт ответственность за своевременное обеспечение
работников СИЗ в соответствии с нормами.

7.2. Работник несёт ответственность за:
— использование СИЗ по назначению;
— своевременное сообщение о необходимости замены;
— бережное хранение.

7.3. Невыдача СИЗ работодателем является основанием для отстранения
работника от выполнения обязанностей с сохранением среднего заработка
(ст. 212 ТК РФ).
'@

# ============ tests_data/skladskaya_logistika.txt ============
$ProjectFiles["tests_data/skladskaya_logistika.txt"] = @'
РЕГЛАМЕНТ № СКЛ-006
УТВЕРЖДЕН приказом генерального директора № 132 от 15.03.2024
ДЕЙСТВУЕТ с 01.04.2024

СКЛАДСКАЯ ЛОГИСТИКА И ВЫДАЧА МАТЕРИАЛОВ В ЦЕХ

1. ОБЩИЕ ПОЛОЖЕНИЯ

1.1. Регламент устанавливает порядок приёмки, хранения, учёта и
выдачи материалов, комплектующих и инструмента со складов предприятия
в производственные цеха.

1.2. Регламент обязателен для исполнения всеми работниками складского
хозяйства, мастерами смен, кладовщиками цехов и сотрудниками отдела
снабжения.

1.3. На предприятии функционируют следующие склады:
— склад сырья и основных материалов (Склад № 1, корпус В);
— склад комплектующих и полуфабрикатов (Склад № 2, корпус В);
— склад инструмента и оснастки (Склад № 3, корпус В, пом. 018);
— склад готовой продукции (Склад № 4, корпус Г);
— склад вспомогательных материалов и ГСМ (Склад № 5, территория Б).

2. ТЕРМИНЫ И ОПРЕДЕЛЕНИЯ

2.1. Материально-ответственное лицо (МОЛ) — работник, несущий
персональную ответственность за сохранность ТМЦ (товарно-материальных
ценностей).

2.2. Лимитно-заборная карта (ЛЗК) — документ, определяющий предельное
количество материалов, которое может быть выдано в цех за определённый
период.

2.3. Требование-накладная (форма М-11) — документ на разовую выдачу
материалов сверх лимита или для хозяйственных нужд.

2.4. Адресное хранение — система, при которой каждая ячейка склада
имеет уникальный код (зона-ряд-полка-место).

3. ПРИЁМКА МАТЕРИАЛОВ НА СКЛАД

3.1. Приёмка материалов производится кладовщиком в течение:
— 24 часов — для материалов отечественных поставщиков;
— 48 часов — для импортных материалов;
— 4 часов — для срочных поставок (помеченных «СРОЧНО»).

3.2. При приёмке проверяется:
— соответствие количества и ассортимента сопроводительным документам
  (накладная, счёт-фактура, УПД);
— качество (визуальный осмотр, при необходимости — выборочные
  замеры, лабораторный анализ);
— целостность упаковки и маркировки;
— сроки годности (для материалов с ограниченным сроком хранения).

3.3. Расхождения фиксируются в акте формы ТОРГ-2 (при недостаче)
или ТОРГ-3 (при пересортице). Акт составляется в трёх экземплярах
и подписывается комиссией (кладовщик, представитель поставщика,
представитель отдела качества).

3.4. После приёмки материалы размещаются по адресам хранения
в системе 1С:Предприятие (модуль «Склад»).

4. ХРАНЕНИЕ МАТЕРИАЛОВ

4.1. Материалы хранятся по принципу FIFO (First In — First Out):
первыми расходуются материалы, поступившие ранее.

4.2. Для материалов с ограниченным сроком годности применяется
принцип FEFO (First Expired — First Out): первыми расходуются
материалы с ближайшим сроком годности.

4.3. Условия хранения по категориям:

Категория          | Температура | Влажность | Особые условия
-------------------|-------------|-----------|----------------
Металлопрокат      | не норм.    | не норм.  | Защита от коррозии
Электроника        | +15…+25°C   | 40-60%    | Антистатическая упаковка
ГСМ                | не выше +30 | не норм.  | Противопожарные меры
Лакокрасочные      | +5…+20°C    | не выше 70| Отдельное помещение
Пищевые (для столовой)| +2…+8°C  | не норм.  | Санитарные книжки персонала

4.4. Инвентаризация проводится:
— полная — 1 раз в год (декабрь);
— выборочная — ежеквартально по отдельным категориям;
— внезапная — по распоряжению финансового директора.

5. ВЫДАЧА МАТЕРИАЛОВ В ЦЕХ

5.1. Выдача материалов производится по лимитно-заборным картам (ЛЗК),
утверждённым на месяц начальником производства.

5.2. График выдачи материалов:
— понедельник–четверг: 08:00–12:00 и 13:00–17:00;
— пятница: 08:00–12:00 и 13:00–16:00;
— суббота, воскресенье: только по аварийным заявкам
  (согласование с начальником склада).

5.3. Для получения материалов представитель цеха (кладовщик цеха
или мастер смены) предъявляет:
— лимитно-заборную карту (форма М-8) или требование-накладную (М-11);
— постоянный пропуск;
— тару для транспортировки (ящики, поддоны, контейнеры).

5.4. При выдаче кладовщик склада:
— отбирает материалы в соответствии с документом;
— проверяет качество (визуально);
— взвешивает/пересчитывает в присутствии получателя;
— делает отметку в ЛЗК о факте выдачи (дата, количество, подпись);
— передаёт материалы получателю.

5.5. Выдача материалов сверх лимита производится только по
требованию-накладной (М-11), подписанной:
— мастером смены (заявитель);
— начальником цеха;
— начальником производства (при сумме свыше 50 000 руб.).

6. ВОЗВРАТ НЕИСПОЛЬЗОВАННЫХ МАТЕРИАЛОВ

6.1. Неиспользованные материалы подлежат возврату на склад в
течение 24 часов после окончания смены или производственного задания.

6.2. Возврат оформляется накладной на возврат (форма М-15) в
двух экземплярах.

6.3. При возврате проверяется:
— количество;
— качество (не должно быть следов использования, повреждений);
— соответствие номенклатуре.

6.4. Материалы, бывшие в употреблении и пригодные для повторного
использования, принимаются на склад с пометкой «Б/У» и учитываются
отдельно.

7. ТРАНСПОРТИРОВКА ВНУТРИ ПРЕДПРИЯТИЯ

7.1. Перемещение материалов между складами и цехами производится:
— электропогрузчиками (для грузов свыше 50 кг);
— гидравлическими тележками (для грузов до 2000 кг на поддонах);
— вручную (для грузов до 30 кг).

7.2. Водители погрузчиков обязаны:
— иметь удостоверение на право управления погрузчиком;
— проходить предрейсовый осмотр ежедневно;
— соблюдать скоростной режим на территории (не более 10 км/ч
  в помещениях, 20 км/ч на улице);
— уступать дорогу пешеходам.

7.3. Запрещается:
— перевозить людей на погрузчиках и тележках;
— оставлять груз в проходах и на путях эвакуации;
— превышать грузоподъёмность транспортного средства.

8. УЧЁТ И ОТЧЁТНОСТЬ

8.1. Учёт ТМЦ ведётся в системе 1С:Предприятие (модуль «Склад»).

8.2. Кладовщик ежедневно формирует:
— отчёт об остатках на конец дня;
— отчёт о движениях за день (приход/расход);
— отчёт о расхождениях (если есть).

8.3. Еженедельно начальник склада формирует сводный отчёт
для финансового директора и начальника производства.

8.4. Ежемесячно проводится анализ:
— оборачиваемости запасов по категориям;
— неликвидов (материалы без движения более 180 дней);
— потерь от брака и порчи.

9. ОТВЕТСТВЕННОСТЬ

9.1. Кладовщик несёт полную материальную ответственность за
сохранность ТМЦ на вверенном складе (договор о полной материальной
ответственности).

9.2. За недостачу, порчу или хищение ТМЦ виновные лица несут
материальную, дисциплинарную и уголовную ответственность.

9.3. Выдача материалов без надлежащего оформления документов
запрещается и является грубым нарушением трудовой дисциплины.
'@

# ============ tests_data/toir.txt ============
$ProjectFiles["tests_data/toir.txt"] = @'
РЕГЛАМЕНТ № ТОиР-007
УТВЕРЖДЕН приказом генерального директора № 133 от 15.03.2024
ДЕЙСТВУЕТ с 01.04.2024

ТЕХНИЧЕСКОЕ ОБСЛУЖИВАНИЕ И РЕМОНТ ОБОРУДОВАНИЯ (ТОиР)

1. ОБЩИЕ ПОЛОЖЕНИЯ

1.1. Регламент устанавливает единую систему технического обслуживания
и ремонта оборудования предприятия ООО «ПромТехно».

1.2. Цель регламента — обеспечение надёжной и безопасной работы
оборудования, предотвращение аварийных остановок, продление срока
службы основных средств.

1.3. Регламент разработан на основе:
— Положения о планово-предупредительном ремонте (ППР);
— ГОСТ 18322-2016 «Система технического обслуживания и ремонта
  техники»;
— рекомендаций заводов-изготовителей оборудования.

2. ТЕРМИНЫ И ОПРЕДЕЛЕНИЯ

2.1. Техническое обслуживание (ТО) — комплекс операций по поддержанию
работоспособности оборудования.

2.2. Ремонт — комплекс операций по восстановлению работоспособности
оборудования после отказа или для предотвращения отказа.

2.3. Планово-предупредительный ремонт (ППР) — система плановых
мероприятий по обслуживанию и ремонту оборудования.

2.4. Аварийный ремонт — внеплановый ремонт, проводимый при внезапном
отказе оборудования.

2.5. Наработка — время работы оборудования в часах или количество
выпущенных единиц продукции.

3. КАТЕГОРИИ РЕМОНТНОЙ СЛОЖНОСТИ

3.1. Всё оборудование предприятия разделено на 4 категории:

Категория | Примеры                          | Критичность
----------|----------------------------------|------------
А         | Главные производственные линии   | Критичная
Б         | Вспомогательное оборудование     | Высокая
В         | Инструмент, оснастка             | Средняя
Г         | Бытовое оборудование             | Низкая

3.2. Оборудование категории «А» имеет высший приоритет при
обслуживании и ремонте. Время реагирования на отказ — не более
15 минут.

4. СИСТЕМА ПЛАНОВО-ПРЕДУПРЕДИТЕЛЬНОГО РЕМОНТА (ППР)

4.1. ППР включает следующие виды работ:

Вид работ      | Периодичность        | Исполнитель
---------------|----------------------|------------------
ЕО (ежесменное)| Каждый день          | Оператор оборудования
ТО-1           | Каждые 250 моточасов | Слесарь-ремонтник
ТО-2           | Каждые 1000 моточасов| Слесарь-ремонтник 4-5 разряда
ТР (текущий)   | По плану (1 раз в год)| Бригада ремонтников
КР (капитальный)| По плану (1 раз в 5-8 лет)| Специализированная бригада

4.2. График ППР утверждается главным механиком на год вперёд
до 25 декабря предыдущего года.

4.3. Отклонение от графика допускается не более чем на 10%
по времени и только по согласованию с главным механиком.

5. ЕЖЕСМЕННОЕ ТЕХНИЧЕСКОЕ ОБСЛУЖИВАНИЕ (ЕО)

5.1. ЕО проводится оператором оборудования в начале и в конце
каждой смены.

5.2. В начале смены оператор проверяет:
— внешнее состояние оборудования (отсутствие повреждений, утечек);
— работу систем безопасности (аварийные остановы, блокировки);
— уровень смазки в редукторах и подшипниковых узлах;
— давление в пневмосистеме (норма: 6-8 бар);
— температуру нагрева подшипников (не выше 70°C);
— отсутствие посторонних шумов и вибрации.

5.3. В конце смены оператор:
— очищает оборудование от стружки, пыли, загрязнений;
— смазывает трущиеся поверхности (согласно карте смазки);
— делает запись в журнале оборудования (форма ОЖ-1);
— сообщает мастеру о выявленных неисправностях.

5.4. Карта смазки для каждого типа оборудования размещается
на рабочем месте оператора.

6. ТЕХНИЧЕСКОЕ ОБСЛУЖИВАНИЕ ТО-1 И ТО-2

6.1. ТО-1 проводится слесарем-ремонтником по графику ППР.

6.2. Состав работ ТО-1:
— замена фильтров (масляных, воздушных, топливных);
— проверка и регулировка натяжения ремней и цепей;
— проверка состояния тормозных систем;
— проверка электрических соединений (подтяжка клемм);
— замена изношенных уплотнений;
— проверка точности оборудования (для станков с ЧПУ).

6.3. ТО-2 включает все работы ТО-1 плюс:
— замена масла в редукторах и гидросистемах;
— проверка состояния подшипников (виброакустическая диагностика);
— проверка геометрической точности (для станков);
— калибровка измерительных приборов;
— проверка систем охлаждения и вентиляции.

6.4. После выполнения ТО-1 и ТО-2 составляется акт (форма ТО-1/ТО-2),
который подписывают исполнитель и мастер смены.

7. ТЕКУЩИЙ И КАПИТАЛЬНЫЙ РЕМОНТ

7.1. Текущий ремонт (ТР) проводится по плану ППР или по результатам
диагностики.

7.2. Состав работ ТР:
— замена изношенных узлов и деталей;
— восстановление геометрической точности;
— замена электрооборудования (при необходимости);
— покраска и восстановление защитных покрытий.

7.3. Капитальный ремонт (КР) проводится специализированной бригадой
с полной разборкой оборудования.

7.4. Состав работ КР:
— полная разборка оборудования;
— дефектация всех узлов и деталей;
— замена или восстановление изношенных деталей;
— сборка с соблюдением заводских допусков;
— испытания и сдача в эксплуатацию.

7.5. После КР оборудование принимается комиссией (главный механик,
начальник цеха, технолог) с составлением акта приёмки (форма АП-1).

8. АВАРИЙНЫЙ РЕМОНТ

8.1. При внезапном отказе оборудования категории «А»:
— оператор немедленно останавливает оборудование;
— сообщает мастеру смены и диспетчеру (тел. 103);
— диспетчер вызывает аварийную бригаду (время прибытия — не более
  15 минут);
— мастер делает запись в журнале оборудования.

8.2. Аварийная бригада проводит диагностику и устраняет неисправность.

8.3. Если время восстановления превышает 4 часа, главный механик
уведомляет начальника производства и директора по производству
для принятия решения о переводе производства на резервное оборудование
или изменении графика.

8.4. После аварийного ремонта в течение 24 часов составляется акт
аварии (форма АА-1) с указанием:
— времени отказа;
— причины отказа;
— времени восстановления;
— виновных лиц (если есть);
— корректирующих действий для предотвращения повторения.

9. УЧЁТ И АНАЛИЗ НАДЁЖНОСТИ

9.1. Учёт работы оборудования ведётся в системе 1С:ТОиР
(модуль «Управление ремонтами»).

9.2. Ключевые показатели надёжности (KPI):

Показатель                    | Целевое значение | Факт (2024)
------------------------------|------------------|------------
Коэффициент готовности (Кг)   | ≥ 0.95           | 0.93
Коэффициент технического использования (Кти)| ≥ 0.85 | 0.82
Среднее время между отказами (MTBF)| ≥ 500 часов | 480 часов
Среднее время восстановления (MTTR)| ≤ 2 часов   | 2.5 часа

9.3. Ежемесячно служба главного механика готовит отчёт по надёжности
с анализом причин отказов (диаграмма Парето) и планом мероприятий
по улучшению.

10. ОХРАНА ТРУДА ПРИ РЕМОНТНЫХ РАБОТАХ

10.1. Все ремонтные работы проводятся по наряду-допуску (форма НД-1),
который оформляет мастер ремонтной бригады.

10.2. Перед началом ремонта оборудование должно быть:
— остановлено;
— обесточено (с вывешиванием плаката «НЕ ВКЛЮЧАТЬ — РАБОТАЮТ ЛЮДИ»);
— заблокировано (система Lockout/Tagout);
— освобождено от давления в пневмо- и гидросистемах;
— охлаждено до безопасной температуры.

10.3. Работы на высоте свыше 1.8 м проводятся только с применением
страховочных систем и по отдельному наряду-допуску.

10.4. Сварочные работы проводятся только при наличии удостоверения
сварщика и после оформления разрешения на огневые работы.

11. ОТВЕТСТВЕННОСТЬ

11.1. Главный механик несёт ответственность за:
— разработку и выполнение графика ППР;
— надёжность оборудования;
— безопасность ремонтных работ.

11.2. Мастера ремонтных бригад несут ответственность за:
— качество выполненных работ;
— соблюдение сроков ремонта;
— охрану труда в бригаде.

11.3. Операторы оборудования несут ответственность за:
— проведение ежесменного обслуживания;
— своевременное сообщение о неисправностях;
— соблюдение правил эксплуатации.
'@

# ============ README.md ============
$ProjectFiles["README.md"] = @'
# team-codex

**База знаний команды с ИИ.** Сотрудник задаёт вопрос по внутренним регламентам — система находит ответ, показывает цитату из документа или честно говорит «информации нет». Ничего не выдумывает: каждый ответ проходит контроль качества, пишется в аудит, а сомнительные случаи уходят на ручную проверку.

![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?logo=fastapi&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)

> **Зачем это нужно.** Знания компании разбросаны по десяткам регламентов. Новый сотрудник ищет ответ вручную ~15 минут и дёргает наставника. team-codex отвечает за ~1 минуту, с точной цитатой, а если темы в базе нет — не придумывает, а фиксирует пробел.

---

## Содержание

- [Что умеет](#что-умеет)
- [Как это работает](#как-это-работает)
- [Поиск пользователем: что происходит после вопроса](#поиск-пользователем-что-происходит-после-вопроса)
- [Память диалога](#память-диалога)
- [Экраны системы](#экраны-системы)
- [Админка FAQ](#админка-faq)
- [Ручная проверка и экспорт](#ручная-проверка-и-экспорт)
- [Демонстрация (видео)](#демонстрация-видео)
- [Быстрый старт](#быстрый-старт)
- [Переменные окружения](#переменные-окружения)
- [API](#api)
- [Примеры запросов](#примеры-запросов)
- [Тесты и eval-набор](#тесты-и-eval-набор)
- [Структура проекта](#структура-проекта)
- [Тестовые данные](#тестовые-данные)
- [Безопасность](#безопасность)
- [Лицензия](#лицензия)

---

## Что умеет

| Возможность | Описание |
|---|---|
| **FAQ без ИИ** | Готовые «вопрос → ответ» отвечают мгновенно и бесплатно, без обращения к модели |
| **Умный поиск** | Гибрид: смысловой поиск (Pinecone) + поиск по точным словам (BM25) |
| **Ответы с цитатой** | ИИ отвечает строго по найденным фрагментам документов и приводит цитату |
| **Честное «не знаю»** | Если темы нет — статус `no_topic` и запись в список пробелов |
| **Память диалога** | Понимает уточняющие вопросы, помнит контекст и факты о пользователе |
| **Контроль качества** | Неуверенные ответы уходят на ручную проверку, всё пишется в аудит |
| **Eval-набор** | 55 тестовых вопросов для проверки качества ответов одной командой |

**Стек:** Python 3.11 · FastAPI · Pydantic v2 · SQLAlchemy · SQLite (локально) / PostgreSQL (план) · Pinecone · rank-bm25 · OpenAI GPT-4o-mini через ProxyAPI · Jinja2 + Pico CSS · Docker.

---

## Как это работает

Один вопрос проходит через короткий каскад — от самого дешёвого к самому умному:

```mermaid
flowchart TD
    Q["Пользователь задаёт вопрос"] --> F["1. FAQ-кэш (без ИИ)"]
    F -->|совпадение| R1["Мгновенный ответ<br/>source = faq_cache"]
    F -->|нет| H["2. Гибридный поиск<br/>Pinecone + BM25"]
    H -->|пусто| R2["no_topic<br/>запись в пробелы"]
    H -->|найдено top-5| L["3. ИИ: GPT-4o-mini<br/>строгий JSON"]
    L --> P{"Пост-контроль"}
    P -->|уверенно и есть цитаты| R3["answered_auto"]
    P -->|низкая уверенность<br/>нет цитат / ошибка| R4["needs_review<br/>на ручную проверку"]
```

Три исхода ответа:

| Статус | Что значит |
|---|---|
| `answered_auto` | Ответ найден, уверенность ≥ 0.75, есть цитата |
| `needs_review` | Система не уверена — ответ проверяет человек |
| `no_topic` | В базе нет такой темы — честный отказ, без выдумок |

---

## Поиск пользователем: что происходит после вопроса

Пользователь открывает экран **«Спросить ИИ»**, вводит вопрос и нажимает кнопку. Дальше всё происходит автоматически:

1. **Браузер запоминает пользователя.** При первом визите генерируется случайный номер диалога (`session_id`) и хранится в браузере. По нему система узнаёт, что вопросы идут от одного человека.

2. **Шаг 1 — FAQ-кэш (без ИИ).** Вопрос сверяется с таблицей частых вопросов `faq_entries`:
   - сначала ищется точное совпадение вопроса;
   - если нет — нечёткий поиск по ключевым словам (достаточно 2 общих слов).

   Нашли — ответ отдаётся **мгновенно**, ИИ не вызывается, токены не тратятся.

3. **Шаг 2 — гибридный поиск.** Если в FAQ ничего нет, вопрос превращается в вектор (эмбеддинг) и ищется сразу двумя способами:
   - **по смыслу** — в векторной базе Pinecone;
   - **по точным словам** — BM25 (важно для терминов вроде «ЕО», «СИЗ», номеров регламентов).

   Результаты объединяются: оценки обоих методов приводятся к одной шкале, а фрагменту, найденному сразу двумя способами, даётся бонус. Берётся топ-5 фрагментов.
   Ничего не нашлось — статус `no_topic` и запись в список пробелов.

4. **Шаг 3 — ответ ИИ.** Найденные фрагменты, память диалога и вопрос уходят в GPT-4o-mini. Модель обязана отвечать **только по этим фрагментам**, приводить цитату и возвращать строгий JSON.

5. **Контроль качества.** Прежде чем показать ответ, система проверяет: если уверенность низкая, цитат нет или модель ошиблась — ответ помечается `needs_review` и уходит в очередь ручной проверки на экране «Аудит». Владелец базы знаний разбирает очередь кнопками «Принять»/«Отклонить» (с комментарием): принятие возвращает статус `answered_auto`, отклонение — `rejected`; действие фиксируется в журнале запусков.

6. **Что видит пользователь.** Статус, текст ответа, процент уверенности и список цитат с номером документа и фрагмента. Плюс раскрывающийся «сырой JSON» для полного доверия.

---

## Память диалога

Память нужна, чтобы система понимала уточняющие вопросы («а сколько это дней?») и не теряла контекст в длинных диалогах. Работает в три слоя:

```mermaid
flowchart LR
    Q["Новый вопрос"] --> S["Последние 10 сообщений<br/>(дословно)"]
    Q --> SUM["Сводка старой истории"]
    Q --> FACTS["Факты о пользователе"]
    S --> P["Промпт для ИИ"]
    SUM --> P
    FACTS --> P
```

- **Свежая память.** Последние 10 сообщений сессии хранятся дословно. В ИИ уходят только последние 5 — чтобы не переполнять модель и не платить лишнее.
- **Сводка.** Когда сообщений становится больше 10, самые старые автоматически сжимаются в короткий пересказ (3–6 предложений) и дописываются в сводку сессии. Дословно они больше не хранятся.
- **Факты о пользователе.** Из старых сообщений извлекаются устойчивые факты (роль, подразделение, интересы) и складываются отдельным списком без повторов.

> **Важно:** память — это только контекст. Факты для ответа берутся исключительно из документов базы с цитатами, память поиск не подменяет.

---

## Экраны системы

| Адрес | Экран | Что там |
|---|---|---|
| `/` | **Документы** | Загрузка регламентов и витрина: список, темы, число фрагментов, кнопки «Редактировать» и «Удалить» |
| `/ask` | **Спросить ИИ** | Поле вопроса, ответ со статусом, уверенностью и цитатами |
| `/audit` | **Аудит** | Очередь ручной проверки с кнопками «Принять»/«Отклонить», журнал запусков, пробелы в знаниях и экспорт (JSON/CSV) |
| `/admin/faq` | **Админка FAQ** | Управление базой частых вопросов и ответов |
| `/docs` | **Swagger** | Все API-методы, можно тестировать прямо в браузере |

---

## Админка FAQ

База частых вопросов живёт в таблице `faq_entries`. Это первый и самый быстрый уровень поиска — работает без ИИ, поэтому её полезно пополнять типовыми вопросами.

Откройте **`http://127.0.0.1:8000/admin/faq`** (или пункт меню **FAQ**). Там можно:

- **Добавить** запись: вопрос, ответ, тема, ключевые слова, статус;
- **Редактировать** любую запись;
- **Включить / отключить** запись (`is_active`) — отключённые не участвуют в поиске;
- **Удалить** — это мягкое удаление (`is_active = false`), запись остаётся в базе и её можно вернуть.

По умолчанию запись отдаёт статус `answered_auto`. Если у записи задан `status = needs_review`, ответ из FAQ сразу уходит на ручную проверку (с причиной `review_reason`) — так можно заранее пометить заведомо неоднозначные вопросы.

Наполнить базу более 50 готовыми вопросами из регламентов (Кадры, Склад, ТОИР) и 5 вопросами на ручную проверку (`needs_review`):

```powershell
python scripts/seed_faq.py
```

Те же действия доступны через API `GET/POST/PUT/DELETE /faq/`.

---

## Ручная проверка и экспорт

Когда ответ уходит на ручную проверку (`needs_review`), он попадает в очередь на экране **`/audit`**. Там же доступны действия и выгрузки.

### Разбор очереди

В блоке «Записи, требующие проверки» у каждой записи две кнопки:

- **Принять** — снимает флаг `needs_review`, статус становится `answered_auto`;
- **Отклонить** — снимает флаг, статус становится `rejected`.

Обе кнопки спрашивают комментарий (можно оставить пустым). Комментарий и время проверки сохраняются в полях `review_note` / `reviewed_at`, а само решение пишется в журнал запусков (`audit_runs`, действие `review_answer`).

То же через API:

```bash
curl.exe -X POST http://127.0.0.1:8000/audit/answers/5/review -H "Content-Type: application/json" -d "{\"action\":\"approve\",\"note\":\"ответ подтверждён регламентом\"}"
```

`action` — только `approve` или `reject` (иначе `422`), несуществующий id — `404`.

> Записи не удаляются — они остаются в таблице `answers`, просто исчезают из очереди. Чтобы «вернуть» запись в очередь, поменяйте `needs_review` в базе вручную.

### Экспорт (JSON / CSV)

`GET /audit/export/{dataset}` отдаёт файлом (`Content-Disposition: attachment`) с пятью наборами данных:

| dataset | Что выгружается |
|---|---|
| `runs` | Журнал запусков (`audit_runs`) |
| `gaps` | Пробелы в знаниях (`knowledge_gaps`) |
| `answers` | Ответы системы, включая поля ручной проверки |
| `documents` | Документы с количеством фрагментов и полным текстом |
| `faq` | Записи FAQ со статусом и активностью |

Формат — `?format=json` или `?format=csv` (по умолчанию `json`). CSV кодируется с BOM, чтобы кириллица корректно открывалась в Excel. Кнопки выгрузки есть прямо на экране `/audit`.

```bash
curl.exe "http://127.0.0.1:8000/audit/export/answers?format=csv" --output answers.csv
curl.exe "http://127.0.0.1:8000/audit/export/documents?format=json" --output documents.json
```

Ошибки: `404` — неизвестный dataset или нет данных, `400` — неверный формат. Сам экспорт тоже фиксируется в `audit_runs` (действие `export`).

---

## Демонстрация (видео)

Демо (2–4 мин): https://<ссылка-после-загрузки>

Формат: запись экрана, 10 сцен, хронометраж ~3:15; возможны короткие версии на 2:00 и 60 сек.

Сценарий: загрузка регламента → ответ с цитатой → типовой вопрос из FAQ → «темы нет» → вопрос про пароль (ручная проверка) → разбор очереди на экране аудита («Принять»/«Отклонить») → экспорт `answers.csv` → `make eval`.

---

## Быстрый старт

**Windows 11, PowerShell.**

### 1. Однокомандный bootstrap

```powershell
cd M:\Projects\team-codex
.\bootstrap.ps1
```

Скрипт создаст `.venv`, установит зависимости, скопирует `.env.example` в `.env` и подготовит базу SQLite.

### 2. Добавьте ключи API

```powershell
notepad .env
```

Заполните две строки:

```
OPENAI_API_KEY=sk-ваш-ключ-proxyapi
PINECONE_API_KEY=ваш-ключ-pinecone
```

### 3. Запустите сервер

```powershell
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --reload
```

Сервер готов, когда в консоли появится `Application startup complete.`

### 4. Откройте в браузере

- Веб-панель — http://127.0.0.1:8000
- Swagger — http://127.0.0.1:8000/docs
- Health — http://127.0.0.1:8000/health

<details>
<summary><b>Ручная установка (без bootstrap) и Docker</b></summary>

```powershell
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
# опционально для разработки: тесты (pytest) и отладка API (httpie)
pip install -r requirements-dev.txt
copy .env.example .env
# откройте .env и впишите ключи
uvicorn app.main:app --reload
```

Docker:

```bash
docker compose up --build
```

Или пошагово:

```bash
docker build -t team-codex:latest .
docker run -d --name team-codex -p 8000:8000 --env-file .env team-codex:latest
docker rm -f team-codex          # остановить и удалить контейнер
```

Файл `.dockerignore` исключает из контекста сборки `.venv`, `.env` и служебные файлы. Поэтому в образ не попадают ни виртуальное окружение, ни ключи — работает только `--env-file .env` во время запуска. Проверено: образ ~545 МБ, `/app/.env` внутри отсутствует, все экраны и `/health` отвечают `200`.

**Уязвимости.** Базовый образ обновлён до свежего `python:3.11-slim` (Debian 13) с `apt-get upgrade`, `pip` и `setuptools` подняты до актуальных версий, а пакеты с известными CVE в `requirements.txt` обновлены. Dev-инструменты (`pytest`, `httpie`) вынесены в `requirements-dev.txt` и в образ не ставятся. Итог: `pip-audit` внутри контейнера отвечает «No known vulnerabilities found», обновляемых системных пакетов нет.

</details>

---

## Переменные окружения

| Переменная | Назначение | Пример |
|---|---|---|
| `OPENAI_API_KEY` | Ключ API ProxyAPI | `sk-...` |
| `OPENAI_BASE_URL` | Адрес провайдера модели | `https://openai.api.proxyapi.ru/v1` |
| `OPENAI_MODEL` | Модель ИИ | `openai/gpt-4o-mini` |
| `OPENAI_EMBEDDING_MODEL` | Модель эмбеддингов | `text-embedding-3-small` |
| `EMBEDDING_DIMENSION` | Размерность вектора | `1536` |
| `LLM_TEMPERATURE` | «Температура» ИИ (0 — строго) | `0.1` |
| `LLM_TIMEOUT_SECONDS` | Таймаут запроса к ИИ | `60` |
| `PINECONE_API_KEY` | Ключ Pinecone | `pcsk_...` |
| `PINECONE_INDEX_NAME` | Имя векторного индекса | `test08` |
| `DATABASE_URL` | Подключение к БД | `sqlite:///./team_codex.db` |
| `SEARCH_MODE` | Задел на будущее (сейчас всегда работает гибридный каскад) | `vector` |
| `MEMORY_MAX_MESSAGES` | Сколько сообщений хранить дословно | `10` |
| `MEMORY_LLM_MESSAGES` | Сколько последних сообщений отправлять в ИИ | `5` |
| `APP_NAME` | Имя приложения | `team-codex` |
| `DEBUG` | Режим отладки | `true` |
| `SECRET_KEY` | Секрет приложения | случайная строка |

Полный шаблон — в `.env.example` (без реальных секретов).

> **Подсказка для Windows.** В PowerShell команда `curl` — это псевдоним `Invoke-WebRequest`. Используйте `curl.exe` либо команды `Invoke-RestMethod` из примеров ниже.

---

## API

| Метод | Путь | Назначение |
|---|---|---|
| `POST` | `/documents/` | Создать документ и проиндексировать его в Pinecone |
| `POST` | `/documents/upload` | Загрузить файл `.txt` / `.md` |
| `GET` | `/documents/` | Витрина документов |
| `PUT` | `/documents/{id}` | Изменить название или тему |
| `DELETE` | `/documents/{id}` | Удалить документ и его векторы |
| `POST` | `/ask/` | Задать вопрос (каскад FAQ → поиск → ИИ) |
| `GET` | `/ask/needs-review` | Очередь ручной проверки |
| `GET` | `/faq/` | Список записей FAQ |
| `POST` | `/faq/` | Добавить запись FAQ |
| `PUT` | `/faq/{id}` | Изменить запись FAQ |
| `DELETE` | `/faq/{id}` | Отключить запись FAQ (мягкое удаление) |
| `GET` | `/audit/runs` | Журнал запусков |
| `GET` | `/audit/gaps` | Пробелы в знаниях |
| `POST` | `/audit/answers/{id}/review` | Принять/отклонить ответ из очереди ручной проверки |
| `GET` | `/audit/export/{dataset}?format=json\|csv` | Выгрузка данных (datasets: `runs`, `gaps`, `answers`, `documents`, `faq`) |
| `GET` | `/health` | Проверка работоспособности |

Веб-страницы: `/`, `/ask`, `/audit`, `/admin/faq`. Документация: `/docs`.

---

## Примеры запросов

### Загрузить документ

```bash
curl.exe -X POST "http://127.0.0.1:8000/documents/" ^
  -F "title=Регламент отпусков" ^
  -F "topic=Отпуска" ^
  -F "content=Ежегодный отпуск — 28 календарных дней. Перенос отпуска требует уведомления руководителя не позднее чем за 14 дней."
```

Ответ:

```json
{"id":1,"title":"Регламент отпусков","topic":"Отпуска","chunks_count":1,"created_at":"..."}
```

### Загрузить файл

```bash
curl.exe -X POST "http://127.0.0.1:8000/documents/upload" ^
  -F "title=Охрана труда" ^
  -F "topic=Охрана труда" ^
  -F "file=@tests_data/ohrana_truda.txt"
```

### Задать вопрос

```bash
curl.exe -X POST "http://127.0.0.1:8000/ask/" ^
  -H "Content-Type: application/json" ^
  -d "{\"question\":\"За сколько дней нужно уведомить о переносе отпуска?\",\"session_id\":\"demo-1\"}"
```

Ответ:

```json
{
  "id": 1,
  "question": "За сколько дней нужно уведомить о переносе отпуска?",
  "result": {
    "found": true,
    "topic": "Отпуска",
    "answer": "О переносе отпуска необходимо уведомить руководителя не позднее чем за 14 дней.",
    "citations": [{"document_id":1,"chunk_id":1,"quote":"Перенос отпуска требует уведомления руководителя не позднее чем за 14 дней."}],
    "confidence": 0.92,
    "status": "answered_auto",
    "needs_review": false,
    "review_reason": null,
    "source": "faq_cache"
  },
  "created_at": "..."
}
```

Поле `source` подсказывает, откуда пришёл ответ: `faq_cache`, `hybrid_search` или `hybrid_search+llm`.

### Служебные запросы

```bash
curl.exe http://127.0.0.1:8000/documents/        # витрина
curl.exe http://127.0.0.1:8000/audit/runs        # журнал аудита
curl.exe http://127.0.0.1:8000/ask/needs-review  # очередь ручной проверки
curl.exe http://127.0.0.1:8000/audit/gaps        # пробелы в знаниях
curl.exe -X DELETE http://127.0.0.1:8000/documents/1

curl.exe "http://127.0.0.1:8000/audit/export/answers?format=csv" --output answers.csv  # экспорт очереди проверки
curl.exe "http://127.0.0.1:8000/audit/export/runs?format=json" --output runs.json    # экспорт журнала запусков
```

> На PowerShell русский текст в `-d` может «поехать» из-за кодировки. Надёжнее `Invoke-RestMethod` с явной UTF-8 (см. примеры ниже).

---

## Тесты и eval-набор

В проекте есть набор из **55 вопросов** с ожидаемым статусом и эталонной цитатой — это регрессионный тест качества. Он отправляет вопросы на работающий сервер и сравнивает результат.

```powershell
# сервер должен быть запущен
python run_eval.py
# или
make eval
```

Отчёт выводит «пройдено / провалено» по каждому вопросу и возвращает ненулевой код при провале — готово к подключению в CI/CD.

`pytest` и `httpie` лежат отдельно, в `requirements-dev.txt`: в Docker-образ они не ставятся, чтобы рантайм-контейнер не тянул пакеты с известными CVE.

<details>
<summary><b>Ручная проверка ключевых сценариев</b></summary>

Успешный ответ (PowerShell, UTF-8):

```powershell
$body = @{ question = "За сколько дней нужно уведомить о переносе отпуска?"; session_id = "check-1" } | ConvertTo-Json
$r = Invoke-RestMethod -Uri "http://127.0.0.1:8000/ask/" -Method Post -ContentType "application/json; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
$r.result
```

Ожидаемо: `status = "answered_auto"`, есть цитаты, `confidence >= 0.75`.

Честное «не знаю»:

```powershell
$body = @{ question = "Как получить ипотеку?"; session_id = "check-2" } | ConvertTo-Json
$r = Invoke-RestMethod -Uri "http://127.0.0.1:8000/ask/" -Method Post -ContentType "application/json; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
$r.result
```

Ожидаемо: `status = "no_topic"`, `answer = "По этой теме пока нет информации в базе знаний."`

Ручная проверка (нет данных про пароль):

```powershell
$body = @{ question = "Какой пароль от корпоративного Wi-Fi?"; session_id = "check-3" } | ConvertTo-Json
$r = Invoke-RestMethod -Uri "http://127.0.0.1:8000/ask/" -Method Post -ContentType "application/json; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
$r.result.status; $r.result.needs_review; $r.result.review_reason
```

Ожидаемо: `needs_review`, `True`, `low_confidence`.

Разбор очереди (кнопки «Принять»/«Отклонить» на `/audit`, либо API):

```powershell
# id из очереди GET /ask/needs-review
Invoke-RestMethod -Uri "http://127.0.0.1:8000/audit/answers/1/review" -Method Post -ContentType "application/json" -Body '{"action":"approve","note":"ответ подтверждён"}'
```

Ожидаемо: запись исчезает из очереди, в `GET /audit/runs` появляется действие `review_answer`.

Экспорт:

```powershell
curl.exe "http://127.0.0.1:8000/audit/export/answers?format=csv" --output answers.csv
curl.exe "http://127.0.0.1:8000/audit/export/runs?format=json" --output runs.json
```

Ожидаемо: скачиваются файлы, CSV открывается в Excel с корректной кириллицей, в `audit_runs` появляется действие `export`.

</details>

Команды Makefile: `make install`, `make run`, `make seed-faq`, `make eval`.

---

## Структура проекта

```
team-codex/
├── app/
│   ├── main.py              Точка входа FastAPI + веб-страницы
│   ├── config.py            Настройки (pydantic-settings)
│   ├── database.py          Движок SQLAlchemy и апгрейды схемы
│   ├── models.py            Таблицы базы данных
│   ├── schemas.py           Pydantic-схемы (строгий JSON)
│   ├── pinecone_service.py  Векторный поиск + гибрид (BM25)
│   ├── faq_service.py       Поиск по FAQ-кэшу
│   ├── memory_service.py    Память: сводка истории и факты
│   ├── llm_service.py       Вызовы ИИ и системный промпт
│   ├── audit.py             Запись действий в audit_runs
│   ├── routers/             documents, ask, audit, faq
│   ├── templates/           Экраны панели (Jinja2)
│   └── static/styles.css
├── tests_data/              Тестовые данные и eval-набор
├── scripts/seed_faq.py      Наполнение FAQ-кэша
├── run_eval.py              Запуск eval-набора
├── bootstrap.ps1            Установщик для Windows
├── requirements.txt
├── requirements-dev.txt     Тесты и отладка (не попадает в Docker-образ)
├── .env.example             Шаблон переменных (без секретов)
├── Dockerfile / docker-compose.yml
├── .dockerignore           Не тащит .venv и .env в Docker-образ
├── Makefile
└── README.md
```

---

## Тестовые данные

В папке `tests_data/`:

- `kb_documents.jsonl` — 5 коротких документов для быстрой загрузки;
- `kb_questions.jsonl` — 55 вопросов для eval-набора (47 `answered_auto`, 3 `no_topic`, 5 `needs_review`);
- 7 полных регламентов ООО «ПромТехно»: охрана труда, СИЗ, сдача-приёмка смен, брак, кадры, складская логистика, ТОиР.

Быстрая загрузка документов пачкой (PowerShell):

```powershell
Get-Content tests_data\kb_documents.jsonl -Encoding UTF8 | ForEach-Object {
  $d = $_ | ConvertFrom-Json
  $body = @{ title = $d.title; topic = $d.topic; content = $d.content }
  Invoke-RestMethod -Uri "http://127.0.0.1:8000/documents/" -Method Post -Body $body
}
```

---

## Безопасность

- `.env` в `.gitignore` — секреты не попадают в репозиторий.
- В репозитории лежит только `.env.example` с заглушками.
- При подозрении на утечку — смените ключи.

---

## Лицензия

MIT
'@

# ============ run_eval.py ============
$ProjectFiles["run_eval.py"] = @'
# -*- coding: utf-8 -*-
"""Регрессионный eval для RAG-каскада.

Читает tests_data/kb_questions.jsonl, отправляет каждый вопрос в POST /ask/,
сравнивает фактический status с expected_status и проверяет presence
эталонной цитаты (expected_quote) в ответе/цитатах LLM.

Запуск (сервер должен быть поднят: make run):
    python run_eval.py [--base-url http://localhost:8000]
"""
import argparse
import json
import sys
import uuid
from pathlib import Path

import httpx

EVAL_FILE = Path(__file__).parent / "tests_data" / "kb_questions.jsonl"


def load_cases(path: Path) -> list:
    cases = []
    with path.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                cases.append(json.loads(line))
    return cases


def quote_found(case: dict, result: dict) -> bool:
    quote = case.get("expected_quote")
    if not quote:
        return True
    haystacks = [result.get("answer", "") or ""]
    for c in result.get("citations") or []:
        haystacks.append(c.get("quote", "") or "")
    joined = "\n".join(haystacks).lower()
    return quote.lower() in joined


def run_case(client: httpx.Client, base_url: str, case: dict) -> dict:
    session_id = f"eval-{uuid.uuid4()}"
    resp = client.post(
        f"{base_url.rstrip('/')}/ask/",
        json={"question": case["question"], "session_id": session_id},
        timeout=120,
    )
    resp.raise_for_status()
    body = resp.json()
    result = body["result"]
    expected_status = case["expected_status"]
    status_ok = result["status"] == expected_status
    quote_ok = quote_found(case, result)
    return {
        "question": case["question"],
        "expected_status": expected_status,
        "actual_status": result["status"],
        "source": result.get("source"),
        "status_ok": status_ok,
        "quote_ok": quote_ok,
        "passed": status_ok and quote_ok,
        "expected_quote": case.get("expected_quote"),
    }


def main():
    parser = argparse.ArgumentParser(description="Regression eval for /ask/")
    parser.add_argument("--base-url", default="http://localhost:8000",
                        help="Base URL приложения (default: http://localhost:8000)")
    parser.add_argument("--file", default=str(EVAL_FILE),
                        help="Путь к JSONL с eval-кейсами")
    args = parser.parse_args()

    cases = load_cases(Path(args.file))
    total = len(cases)
    print(f"Eval: {total} вопросов -> {args.base_url}/ask/\n")

    passed, failed = [], []
    with httpx.Client() as client:
        for i, case in enumerate(cases, 1):
            try:
                r = run_case(client, args.base_url, case)
            except Exception as e:
                r = {
                    "question": case["question"],
                    "expected_status": case["expected_status"],
                    "actual_status": "ERROR",
                    "source": None,
                    "status_ok": False,
                    "quote_ok": False,
                    "passed": False,
                    "expected_quote": case.get("expected_quote"),
                    "error": str(e),
                }
            mark = "OK  " if r["passed"] else "FAIL"
            print(f"[{i:02d}/{total}] {mark} {case['question'][:70]}")
            if not r["passed"]:
                reason = r.get("error") or (
                    f"status {r['actual_status']} != {r['expected_status']}"
                    if not r["status_ok"] else
                    f"цитата не найдена: {r['expected_quote']!r}"
                )
                print(f"         -> {reason}")
            (passed if r["passed"] else failed).append(r)

    print("\n" + "=" * 60)
    print(f"Пройдено: {len(passed)}/{total}, Провалено: {len(failed)}/{total}")
    if failed:
        print("\nПроваленные кейсы:")
        for r in failed:
            print(f"  - {r['question'][:80]}")
            print(f"    expected={r['expected_status']}, actual={r['actual_status']}, source={r['source']}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
'@

# ============================================================
# MAIN LOGIC: extract + setup environment
# ============================================================

Write-Host ""
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host "  team-codex - Self-Extracting Bootstrap       " -ForegroundColor Magenta
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Target folder: $ProjectRoot" -ForegroundColor Cyan
Write-Host "  Files to extract: $($ProjectFiles.Count)" -ForegroundColor Cyan
Write-Host ""

Write-Host "[Step 1/5] Creating project structure..." -ForegroundColor Cyan
if (Test-Path $ProjectRoot) {
    Write-Host "  Folder already exists: $ProjectRoot" -ForegroundColor Yellow
    $confirm = Read-Host "  Overwrite files? (y/N)"
    if ($confirm -notmatch "^[yY]") {
        Write-Host "  Cancelled." -ForegroundColor Red
        exit 0
    }
} else {
    New-Item -ItemType Directory -Path $ProjectRoot -Force | Out-Null
}

Write-Host "[Step 2/5] Extracting files..." -ForegroundColor Cyan
foreach ($filePath in $ProjectFiles.Keys) {
    $fullPath = Join-Path $ProjectRoot $filePath
    $dir = Split-Path -Parent $fullPath
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $ProjectFiles[$filePath] | Set-Content -Path $fullPath -Encoding UTF8
    Write-Host "  + $filePath" -ForegroundColor Gray
}
Write-Host "  All files extracted: $($ProjectFiles.Count)" -ForegroundColor Green

Set-Location $ProjectRoot

Write-Host "[Step 3/5] Creating virtual environment..." -ForegroundColor Cyan
if (Test-Path ".venv") {
    Write-Host "  .venv already exists" -ForegroundColor Gray
} else {
    $pyVersion = & py -3.11 --version 2>$null
    if ($pyVersion) {
        py -3.11 -m venv .venv
    } else {
        python -m venv .venv
    }
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  .venv created" -ForegroundColor Green
    } else {
        Write-Host "  Failed to create .venv" -ForegroundColor Red
        exit 1
    }
}

Write-Host "[Step 4/5] Installing dependencies..." -ForegroundColor Cyan
& .\.venv\Scripts\Activate.ps1
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "  Dependencies install failed" -ForegroundColor Red
}

Write-Host "[Step 5/5] Configuring .env..." -ForegroundColor Cyan
if (Test-Path ".env") {
    Write-Host "  .env already exists" -ForegroundColor Gray
} else {
    Copy-Item ".env.example" ".env"
    Write-Host "  .env created from template" -ForegroundColor Green
    Write-Host ""
    Write-Host "  IMPORTANT: open .env and fill in your keys:" -ForegroundColor Yellow
    Write-Host "      OPENAI_API_KEY=sk-..." -ForegroundColor Yellow
    Write-Host "      PINECONE_API_KEY=..." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "[DB Init] Initializing database..." -ForegroundColor Cyan
python -c "import sys; sys.path.insert(0, '.'); from app.database import engine, Base, ensure_schema_upgrades; import app.models; Base.metadata.create_all(bind=engine); ensure_schema_upgrades(); print('Tables created.')" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Database ready" -ForegroundColor Green
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "  Project fully deployed!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Go to project folder:" -ForegroundColor White
Write-Host "     cd $ProjectRoot" -ForegroundColor Yellow
Write-Host ""
Write-Host "  2. Activate environment:" -ForegroundColor White
Write-Host "     .\.venv\Scripts\Activate.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "  3. Fill in .env with your keys:" -ForegroundColor White
Write-Host "     notepad .env" -ForegroundColor Yellow
Write-Host ""
Write-Host "  4. Start server:" -ForegroundColor White
Write-Host "     uvicorn app.main:app --reload" -ForegroundColor Yellow
Write-Host ""
Write-Host "  5. Open browser:" -ForegroundColor White
Write-Host "     http://127.0.0.1:8000          (web panel)" -ForegroundColor Yellow
Write-Host "     http://127.0.0.1:8000/docs     (Swagger)" -ForegroundColor Yellow
Write-Host ""
