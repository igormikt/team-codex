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
