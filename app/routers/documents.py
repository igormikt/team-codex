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
