"""AI career mentor chatbot: personalizes a system prompt from the user's
Firestore profile, persists conversation history in the `conversations`
collection (userId-scoped, not in the original 8-collection schema doc but
needed for multi-turn context — same access pattern as every other
collection here), and calls the configured AI provider for each reply.
"""
from __future__ import annotations

import uuid
from datetime import datetime, timezone
from typing import Optional

from fastapi import HTTPException, status

from app.ai.providers import AIProviderError, ChatTurn, generate_reply
from app.firebase.firebase_admin_client import get_firestore_client

_SYSTEM_PROMPT_TEMPLATE = """You are the AI Career Mentor inside SkillBridge AI, a career-growth app for \
students, fresh graduates, and junior developers. Answer questions about \
resumes, interview preparation, skill gaps, and learning direction \
professionally, practically, and concisely — a few short paragraphs or a \
tight bullet list at most, never a wall of text. Be encouraging but honest \
about weaknesses. If a question falls outside careers, resumes, interviews, \
skills, or learning, gently steer the conversation back to those topics.

What you know about this user:
{profile_summary}"""

_MAX_HISTORY_MESSAGES = 20


def _profile_summary(profile: dict) -> str:
    lines = []
    if profile.get("careerGoal"):
        lines.append(f"- Career goal: {profile['careerGoal']}")
    if profile.get("experienceLevel"):
        lines.append(f"- Experience level: {profile['experienceLevel']}")
    if profile.get("skills"):
        skills = profile["skills"]
        skills_text = ", ".join(skills) if isinstance(skills, list) else str(skills)
        lines.append(f"- Skills: {skills_text}")
    education = profile.get("degree") or profile.get("education")
    if education:
        lines.append(f"- Education: {education}")
    if not lines:
        return "No profile details yet — ask a clarifying question or two if it would help."
    return "\n".join(lines)


def send_chatbot_message(uid: str, message: str, conversation_id: Optional[str]) -> dict:
    db = get_firestore_client()
    now = datetime.now(timezone.utc)

    if conversation_id:
        conv_ref = db.collection("conversations").document(conversation_id)
        conv_doc = conv_ref.get()
        conv_data = conv_doc.to_dict() if conv_doc.exists else None
        if not conv_data or conv_data.get("userId") != uid:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Conversation not found")
        history: list[ChatTurn] = conv_data.get("messages", [])[-_MAX_HISTORY_MESSAGES:]
        created_at = conv_data.get("createdAt", now)
    else:
        conversation_id = str(uuid.uuid4())
        conv_ref = db.collection("conversations").document(conversation_id)
        history = []
        created_at = now

    profile_doc = db.collection("users").document(uid).get()
    profile = profile_doc.to_dict() or {}
    system_prompt = _SYSTEM_PROMPT_TEMPLATE.format(profile_summary=_profile_summary(profile))

    try:
        reply = generate_reply(system_prompt, history, message)
    except AIProviderError as exc:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)) from exc

    updated_messages = history + [
        {"role": "user", "text": message, "createdAt": now},
        {"role": "assistant", "text": reply, "createdAt": now},
    ]
    conv_ref.set(
        {"userId": uid, "messages": updated_messages, "createdAt": created_at, "updatedAt": now},
        merge=True,
    )

    return {"reply": reply, "conversationId": conversation_id}
