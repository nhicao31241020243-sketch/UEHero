from datetime import date

import pytest
from fastapi.testclient import TestClient

from app import main
from app.knowledge import build_grounding, event_status, select_events, select_interview_questions

client = TestClient(main.app)


def test_health_without_running_ollama():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["backend"] == "ok"


def test_closed_event_cannot_be_called_open():
    events = select_events("Marketing On Air 2026 có còn đăng ký không?", date(2026, 10, 18))
    assert any("Marketing On Air" in e["title"] for e in events)
    event = next(e for e in events if "Marketing On Air" in e["title"])
    assert "Đã qua hạn" in event_status(event, date(2026, 10, 18))


def test_unknown_event_no_claims_from_current_web():
    content = build_grounding("Có cuộc thi BA nào đang mở?", today=date(2026, 10, 18))
    assert "KHÔNG phải lịch sự kiện trực tuyến" in content
    assert "cần xác minh" in content or "không khẳng định đang mở" in content


def test_interview_questions_are_from_app_data():
    career, examples = select_interview_questions("Cho mình luyện phỏng vấn Business Analyst intern")
    assert career == "Business Analyst"
    assert examples and all("q" in q and "hint" in q for q in examples)


def test_input_validation():
    assert client.post("/chat", json={"message": ""}).status_code == 422
    assert client.post("/chat", json={"message": "A" * 3500}).status_code == 422


def test_chat_calls_local_model_with_grounded_events(monkeypatch):
    sent = {}

    async def fake_call(payload):
        sent.update(payload)
        return {"message": {"content": "UEH Career Fair có thông tin mùa trước, cần kiểm tra nguồn chính thức."}}

    monkeypatch.setattr(main, "query_ollama", fake_call)
    response = client.post("/chat", json={
        "message": "UEH Career Fair năm nay diễn ra khi nào?",
        "history": [{"role": "user", "content": "Xin chào"}],
        "app_context": "Mục tiêu: Business Analyst",
    })
    assert response.status_code == 200
    assert "UEH Career Fair" in response.json()["reply"]
    assert sent["messages"][0]["role"] == "system"
    assert "UEH Career Fair" in sent["messages"][1]["content"]
    assert sent["messages"][-1]["content"].startswith("UEH Career Fair")
    assert sent["stream"] is False


def test_ollama_unavailable_returns_useful_error(monkeypatch):
    import httpx

    async def fail(payload):
        raise httpx.ConnectError("connection refused")

    monkeypatch.setattr(main, "query_ollama", fail)
    response = client.post("/chat", json={"message": "Hello"})
    assert response.status_code == 503
    assert "Ollama" in response.json()["detail"]
