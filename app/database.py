from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.config import get_settings

settings = get_settings()

connect_args = {}
if settings.database_url.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(settings.database_url, connect_args=connect_args, echo=False)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def ensure_schema_upgrades():
    """Лёгкие апгрейды существующей SQLite-базы (аналог миграций)."""
    from sqlalchemy import text, inspect
    inspector = inspect(engine)
    if "memory_sessions" in inspector.get_table_names():
        cols = {c["name"] for c in inspector.get_columns("memory_sessions")}
        if "summarized_count" not in cols:
            with engine.begin() as conn:
                conn.execute(text("ALTER TABLE memory_sessions ADD COLUMN summarized_count INTEGER DEFAULT 0"))
    if "answers" in inspector.get_table_names():
        cols = {c["name"] for c in inspector.get_columns("answers")}
        with engine.begin() as conn:
            if "reviewed_at" not in cols:
                conn.execute(text("ALTER TABLE answers ADD COLUMN reviewed_at DATETIME"))
            if "review_note" not in cols:
                conn.execute(text("ALTER TABLE answers ADD COLUMN review_note VARCHAR(500)"))
    if "faq_entries" in inspector.get_table_names():
        cols = {c["name"] for c in inspector.get_columns("faq_entries")}
        with engine.begin() as conn:
            if "status" not in cols:
                conn.execute(text("ALTER TABLE faq_entries ADD COLUMN status VARCHAR(50) DEFAULT 'answered_auto'"))
            if "review_reason" not in cols:
                conn.execute(text("ALTER TABLE faq_entries ADD COLUMN review_reason VARCHAR(200)"))
