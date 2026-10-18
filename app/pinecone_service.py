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

