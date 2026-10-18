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
