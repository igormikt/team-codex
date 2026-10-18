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
