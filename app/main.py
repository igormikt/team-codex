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
