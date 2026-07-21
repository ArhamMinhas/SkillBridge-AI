"""AI resume analyzer: extracts text from an uploaded PDF resume, asks the
configured AI provider (see providers.py) to score it against ATS
(Applicant Tracking System) conventions, enforces the free-tier 1-analysis
limit, and persists the report to Firestore's `resumeReports` collection.
"""
from __future__ import annotations

import io
from datetime import datetime, timezone

from fastapi import HTTPException, status
from google.cloud.firestore_v1.base_query import FieldFilter
from pypdf import PdfReader

from app.ai.providers import AIProviderError, generate_json
from app.firebase.firebase_admin_client import get_firestore_client

_SYSTEM_PROMPT = """You are an expert resume reviewer and ATS (Applicant \
Tracking System) specialist for SkillBridge AI, a career-growth app for \
students, fresh graduates, and junior developers. Analyze the resume text \
you're given and return a practical, honest, encouraging assessment. Score \
against real ATS conventions: clear section headers, quantified impact \
(numbers/metrics), relevant keywords for the candidate's apparent field, \
consistent formatting cues, and no unparseable elements (tables/graphics \
described only as images). Be specific — reference actual content from the \
resume in your strengths/weaknesses/suggestions, not generic advice."""

_RESPONSE_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "atsScore": {
            "type": "INTEGER",
            "description": "0-100 ATS compatibility + quality score",
        },
        "strengths": {"type": "ARRAY", "items": {"type": "STRING"}},
        "weaknesses": {"type": "ARRAY", "items": {"type": "STRING"}},
        "missingSkills": {
            "type": "ARRAY",
            "items": {"type": "STRING"},
            "description": (
                "Skills/keywords commonly expected for this candidate's "
                "apparent target role that are absent from the resume"
            ),
        },
        "suggestions": {"type": "ARRAY", "items": {"type": "STRING"}},
    },
    "required": ["atsScore", "strengths", "weaknesses", "missingSkills", "suggestions"],
}

_MIN_EXTRACTED_CHARS = 40
_MAX_PROMPT_CHARS = 12000


def _extract_text(pdf_bytes: bytes) -> str:
    try:
        reader = PdfReader(io.BytesIO(pdf_bytes))
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Couldn't read this PDF — it may be corrupted or password-protected",
        ) from exc

    text = "\n".join(page.extract_text() or "" for page in reader.pages)
    text = text.strip()
    if len(text) < _MIN_EXTRACTED_CHARS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Couldn't extract readable text from this PDF — it may be a "
                "scanned image rather than a text-based document"
            ),
        )
    return text


_FREE_TIER_ANALYSIS_LIMIT = 3


def run_resume_analysis(uid: str, pdf_bytes: bytes) -> dict:
    db = get_firestore_client()

    profile_doc = db.collection("users").document(uid).get()
    profile = profile_doc.to_dict() or {}
    is_premium = profile.get("isPremium") is True

    if not is_premium:
        existing = (
            db.collection("resumeReports")
            .where(filter=FieldFilter("userId", "==", uid))
            .limit(_FREE_TIER_ANALYSIS_LIMIT)
            .stream()
        )
        if len(list(existing)) >= _FREE_TIER_ANALYSIS_LIMIT:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=(
                    f"Free plan includes {_FREE_TIER_ANALYSIS_LIMIT} resume "
                    "analyses. Upgrade to Premium for unlimited analyses."
                ),
            )

    text = _extract_text(pdf_bytes)[:_MAX_PROMPT_CHARS]

    try:
        result = generate_json(
            _SYSTEM_PROMPT, f"Resume text:\n\n{text}", _RESPONSE_SCHEMA
        )
    except AIProviderError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)
        ) from exc

    result["atsScore"] = max(0, min(100, int(result.get("atsScore", 0))))
    for key in ("strengths", "weaknesses", "missingSkills", "suggestions"):
        value = result.get(key)
        result[key] = value if isinstance(value, list) else []

    now = datetime.now(timezone.utc)
    doc_data = {
        "userId": uid,
        "atsScore": result["atsScore"],
        "strengths": result["strengths"],
        "weaknesses": result["weaknesses"],
        "missingSkills": result["missingSkills"],
        "suggestions": result["suggestions"],
        "createdAt": now,
    }
    db.collection("resumeReports").add(doc_data)

    return result
