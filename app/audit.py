import time
from contextlib import contextmanager
from sqlalchemy.orm import Session
from app.models import AuditRun
import json


@contextmanager
def track_action(db: Session, action: str, input_data: dict):
    start = time.time()
    status = "success"
    error = None
    output_data = {}
    try:
        yield output_data
    except Exception as e:
        status = "error"
        error = str(e)
        raise
    finally:
        duration_ms = int((time.time() - start) * 1000)
        run = AuditRun(
            action=action,
            input_data=_safe_json(input_data),
            output_data=_safe_json(output_data or None),
            status=status,
            error=error,
            duration_ms=duration_ms,
        )
        db.add(run)
        db.commit()


def _safe_json(obj):
    if obj is None:
        return None
    try:
        return json.loads(json.dumps(obj, default=str))
    except Exception:
        return {"raw": str(obj)[:500]}
