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
