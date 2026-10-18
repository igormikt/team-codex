# -*- coding: utf-8 -*-
"""Регрессионный eval для RAG-каскада.

Читает tests_data/kb_questions.jsonl, отправляет каждый вопрос в POST /ask/,
сравнивает фактический status с expected_status и проверяет presence
эталонной цитаты (expected_quote) в ответе/цитатах LLM.

Запуск (сервер должен быть поднят: make run):
    python run_eval.py [--base-url http://localhost:8000]
"""
import argparse
import json
import sys
import uuid
from pathlib import Path

import httpx

EVAL_FILE = Path(__file__).parent / "tests_data" / "kb_questions.jsonl"


def load_cases(path: Path) -> list:
    cases = []
    with path.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                cases.append(json.loads(line))
    return cases


def quote_found(case: dict, result: dict) -> bool:
    quote = case.get("expected_quote")
    if not quote:
        return True
    haystacks = [result.get("answer", "") or ""]
    for c in result.get("citations") or []:
        haystacks.append(c.get("quote", "") or "")
    joined = "\n".join(haystacks).lower()
    return quote.lower() in joined


def run_case(client: httpx.Client, base_url: str, case: dict) -> dict:
    session_id = f"eval-{uuid.uuid4()}"
    resp = client.post(
        f"{base_url.rstrip('/')}/ask/",
        json={"question": case["question"], "session_id": session_id},
        timeout=120,
    )
    resp.raise_for_status()
    body = resp.json()
    result = body["result"]
    expected_status = case["expected_status"]
    status_ok = result["status"] == expected_status
    quote_ok = quote_found(case, result)
    return {
        "question": case["question"],
        "expected_status": expected_status,
        "actual_status": result["status"],
        "source": result.get("source"),
        "status_ok": status_ok,
        "quote_ok": quote_ok,
        "passed": status_ok and quote_ok,
        "expected_quote": case.get("expected_quote"),
    }


def main():
    parser = argparse.ArgumentParser(description="Regression eval for /ask/")
    parser.add_argument("--base-url", default="http://localhost:8000",
                        help="Base URL приложения (default: http://localhost:8000)")
    parser.add_argument("--file", default=str(EVAL_FILE),
                        help="Путь к JSONL с eval-кейсами")
    args = parser.parse_args()

    cases = load_cases(Path(args.file))
    total = len(cases)
    print(f"Eval: {total} вопросов -> {args.base_url}/ask/\n")

    passed, failed = [], []
    with httpx.Client() as client:
        for i, case in enumerate(cases, 1):
            try:
                r = run_case(client, args.base_url, case)
            except Exception as e:
                r = {
                    "question": case["question"],
                    "expected_status": case["expected_status"],
                    "actual_status": "ERROR",
                    "source": None,
                    "status_ok": False,
                    "quote_ok": False,
                    "passed": False,
                    "expected_quote": case.get("expected_quote"),
                    "error": str(e),
                }
            mark = "OK  " if r["passed"] else "FAIL"
            print(f"[{i:02d}/{total}] {mark} {case['question'][:70]}")
            if not r["passed"]:
                reason = r.get("error") or (
                    f"status {r['actual_status']} != {r['expected_status']}"
                    if not r["status_ok"] else
                    f"цитата не найдена: {r['expected_quote']!r}"
                )
                print(f"         -> {reason}")
            (passed if r["passed"] else failed).append(r)

    print("\n" + "=" * 60)
    print(f"Пройдено: {len(passed)}/{total}, Провалено: {len(failed)}/{total}")
    if failed:
        print("\nПроваленные кейсы:")
        for r in failed:
            print(f"  - {r['question'][:80]}")
            print(f"    expected={r['expected_status']}, actual={r['actual_status']}, source={r['source']}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
