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
