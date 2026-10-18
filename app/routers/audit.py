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
