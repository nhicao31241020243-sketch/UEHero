"""Deterministic app data retrieval; this is NOT model fine-tuning or live search."""

from __future__ import annotations

import json
import re
import unicodedata
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

ASSETS = Path(__file__).resolve().parents[2] / "assets"
VIETNAM = timezone(timedelta(hours=7))

_EVENT_WORDS = ("su kien", "cuoc thi", "hoi cho", "career fair", "event", "competition", "hackathon", "datathon", "dang ky", "deadline", "cuoc thi", "cuoc dua")
_INTERVIEW_WORDS = ("phong van", "interview", "cau hoi tuyen dung", "mock interview")
_CAREER_ALIASES = {
    "Business Analyst": ("business analyst", "business analysis", "ba intern", "nghiep vu"),
    "Data Analyst": ("data analyst", "data analytics", "da intern", "phan tich du lieu"),
    "Frontend Developer": ("frontend", "front-end", "react", "lap trinh web"),
    "Digital Marketing": ("digital marketing", "marketing"),
    "E-commerce Specialist": ("e-commerce", "ecommerce", "thuong mai dien tu"),
    "Product Manager": ("product manager", "product management", "quan ly san pham"),
}


def normalize(value: str) -> str:
    text = unicodedata.normalize("NFKD", value.lower().replace("đ", "d"))
    return " ".join("".join(ch for ch in text if not unicodedata.combining(ch)).split())


def load_events() -> list[dict]:
    with (ASSETS / "data" / "events.json").open(encoding="utf-8") as handle:
        return json.load(handle)


def load_questions() -> dict:
    with (ASSETS / "interview_questions.json").open(encoding="utf-8") as handle:
        return json.load(handle)


def event_status(event: dict, today: date) -> str:
    opening = event.get("registrationOpen")
    deadline = event.get("registrationDeadline")
    if opening and date.fromisoformat(opening) > today:
        return "Chưa mở đăng ký theo dữ liệu"
    if deadline:
        if date.fromisoformat(deadline) < today:
            return "Đã qua hạn đăng ký theo dữ liệu"
        return "Hạn đăng ký còn trong tương lai theo dữ liệu; cần xác minh nguồn chính thức"
    return "Chưa xác định thời gian đăng ký mùa hiện tại; không khẳng định đang mở"


def _match_careers(question: str) -> list[str]:
    norm = normalize(question)
    return [name for name, aliases in _CAREER_ALIASES.items() if any(a in norm for a in aliases)]


def _event_relevance(question: str, event: dict, careers: list[str]) -> tuple[int, bool]:
    norm = normalize(question)
    title = normalize(event["title"])
    event_id = normalize(event.get("id", ""))
    title_words = [part for part in re.findall(r"[a-z0-9]+", title) if len(part) >= 5]
    matched_title = (title in norm) or (len(event_id) >= 4 and event_id in norm)
    matched_title = matched_title or any(part in norm for part in title_words[:3])
    tagged = any(career in event.get("careerTags", []) for career in careers)
    token_match = len(set(re.findall(r"[a-z0-9]+", norm)) & set(title_words))
    return (15 if matched_title else 0) + (7 if tagged else 0) + min(token_match, 3), matched_title


def select_events(question: str, today: date, limit: int = 7) -> list[dict]:
    norm = normalize(question)
    careers = _match_careers(question)
    all_events = load_events()
    candidates = [(_event_relevance(question, e, careers), e) for e in all_events]
    named = [(score, e) for score, e in candidates if score[1] and score[0] >= 15]
    # A named event gets priority even when its registration has already closed.
    if named:
        return [e for _, e in sorted(named, key=lambda row: -row[0][0])[:limit]]

    if not any(word in norm for word in _EVENT_WORDS):
        return []

    def order(item: tuple[tuple[int, bool], dict]) -> tuple[int, int, str]:
        score, event = item
        deadline = event.get("registrationDeadline")
        expired = bool(deadline and date.fromisoformat(deadline) < today)
        # Active or uncertain listings are shown before expired ones, but never verified as live.
        return (1 if expired else 0, -score[0], deadline or "9999-12-31")

    sorted_events = sorted(candidates, key=order)
    if careers:
        relevant = [row for row in sorted_events if row[0][0] > 0]
        sorted_events = relevant or sorted_events
    return [event for _, event in sorted_events[:limit]]


def select_interview_questions(question: str, limit: int = 6) -> tuple[str, list[dict]]:
    norm = normalize(question)
    if not any(word in norm for word in _INTERVIEW_WORDS):
        return "", []
    careers = _match_careers(question)
    bank = load_questions()
    career = careers[0] if careers else "default"
    level = "fresher" if "fresher" in norm else "behavioral" if "behavioral" in norm else "intern"
    questions = bank.get(career, bank["default"]).get(level, [])[:limit]
    return career, questions


def build_grounding(question: str, user_context: str = "", *, today: date | None = None) -> str:
    today = today or datetime.now(VIETNAM).date()
    lines = [
        f"Ngày hiện tại tại Việt Nam: {today.isoformat()}.",
        "Nguồn dữ liệu: các file local đi kèm UEHero; KHÔNG phải lịch sự kiện trực tuyến.",
        "Dữ liệu việc làm trong UEHero hiện là DEMO, không được mô tả là tin tuyển dụng thật hoặc còn nhận hồ sơ.",
    ]
    if user_context:
        lines.append("Tóm tắt trạng thái trong app (đã gửi từ thiết bị, không phải dữ liệu công khai): " + user_context[:800])
    events = select_events(question, today)
    if events:
        lines.append("DANH SÁCH SỰ KIỆN TRONG APP (chỉ dựa vào dữ liệu có sẵn):")
        for event in events:
            fields = [
                "Tên: " + event["title"],
                "Ban tổ chức: " + event.get("organizer", "chưa rõ"),
                "Loại: " + event.get("type", "chưa rõ"),
                "Phù hợp ngành: " + ", ".join(event.get("careerTags", [])),
                "Trạng thái: " + event_status(event, today),
                "Hạn đăng ký ghi trong app: " + str(event.get("registrationDeadline") or "chưa biết"),
                "Ngày kiểm chứng ghi trong app: " + str(event.get("verifiedAt") or "không có"),
                "Mùa trước: " + str(event.get("lastSeason") or "không có"),
                "Thông tin thêm: " + str(event.get("notes") or "không có"),
                "Nguồn tham khảo: " + str(event.get("sourceUrl") or "không có"),
                "Trang sự kiện: " + str(event.get("officialUrl") or "không có"),
            ]
            lines.append("- " + " | ".join(fields))
    elif any(word in normalize(question) for word in _EVENT_WORDS):
        lines.append("Không tìm thấy bản ghi sự kiện phù hợp trong dữ liệu đã chọn.")
    career, questions = select_interview_questions(question)
    if questions:
        lines.append(f"CÂU HỎI PHỎNG VẤN MẪU TRONG APP, ngành {career}:")
        for sample in questions:
            lines.append(
                "- " + str(sample.get("q", "")) + " | Gợi ý: " + str(sample.get("hint", ""))
                + " | Kỹ năng: " + str(sample.get("skill", ""))
            )
    return "\n".join(lines)
