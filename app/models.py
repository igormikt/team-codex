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
