from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.audit import track_action
from app.database import get_db
from app.models import FaqEntry
from app.schemas import FaqEntryCreate, FaqEntryUpdate, FaqEntryResponse

router = APIRouter(prefix="/faq", tags=["faq"])


@router.get("/", response_model=list[FaqEntryResponse])
def list_faq(db: Session = Depends(get_db)):
    return db.query(FaqEntry).order_by(FaqEntry.topic, FaqEntry.id).all()


@router.post("/", response_model=FaqEntryResponse, status_code=201)
def create_faq(req: FaqEntryCreate, db: Session = Depends(get_db)):
    with track_action(db, "create_faq", {"question": req.question, "status": req.status}):
        entry = FaqEntry(**req.model_dump())
        db.add(entry)
        db.commit()
        db.refresh(entry)
    return entry


@router.put("/{faq_id}", response_model=FaqEntryResponse)
def update_faq(faq_id: int, req: FaqEntryUpdate, db: Session = Depends(get_db)):
    entry = db.query(FaqEntry).filter_by(id=faq_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="FAQ entry not found")
    changes = req.model_dump(exclude_unset=True)
    with track_action(db, "update_faq", {"faq_id": faq_id, "fields": list(changes.keys())}):
        for field, value in changes.items():
            setattr(entry, field, value)
        db.commit()
        db.refresh(entry)
    return entry


@router.delete("/{faq_id}", response_model=FaqEntryResponse)
def delete_faq(faq_id: int, db: Session = Depends(get_db)):
    entry = db.query(FaqEntry).filter_by(id=faq_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="FAQ entry not found")
    with track_action(db, "delete_faq", {"faq_id": faq_id}):
        entry.is_active = False  # soft delete
        db.commit()
        db.refresh(entry)
    return entry
