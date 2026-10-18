PYTHON ?= python
HOST ?= 0.0.0.0
PORT ?= 8000

.PHONY: install run seed-faq eval

install:
	$(PYTHON) -m pip install -r requirements.txt

run:
	$(PYTHON) -m uvicorn app.main:app --host $(HOST) --port $(PORT) --reload

seed-faq:
	$(PYTHON) scripts/seed_faq.py

eval:
	$(PYTHON) run_eval.py --base-url http://localhost:$(PORT)
