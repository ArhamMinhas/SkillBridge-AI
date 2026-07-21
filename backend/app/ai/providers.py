"""Thin wrappers around the Gemini and OpenAI SDKs so the rest of app/ai/
only depends on generate_reply() / generate_json() — swapping providers is
a config change (AI_PROVIDER=gemini|openai in .env), not a code change.

Gemini uses the `google-genai` SDK — the actively maintained replacement
for `google-generativeai`, which Google end-of-lifed (no more updates or
bug fixes) and whose pinned 0.7.1 predates the current Gemini model lineup
entirely (gemini-1.5-flash no longer exists as of this project's 2026
timeframe). `gemini-flash-latest` is used rather than a dated model name so
this doesn't need to be updated every time Google ships a new version.

Both SDK clients are configured lazily on first use, not at import time, so
the API server can start and serve /health even before real AI credentials
are filled into .env — the same reasoning as the lazy Firebase getters on
the Flutter side.
"""
from __future__ import annotations

import json
from typing import Any, Dict, List, TypedDict

from app.config import get_settings

_settings = get_settings()

_GEMINI_MODEL = "gemini-flash-latest"
_OPENAI_MODEL = "gpt-4o-mini"


class ChatTurn(TypedDict):
    role: str  # "user" or "assistant"
    text: str


class AIProviderError(RuntimeError):
    """Raised when the configured AI provider has no API key set, or the
    upstream call fails. Routes translate this into a 503, never a bare 500,
    since it reflects missing config or a third-party outage, not a bug."""


_gemini_client = None
_openai_client = None


def _get_gemini_client():
    global _gemini_client
    if _gemini_client is None:
        if not _settings.gemini_api_key:
            raise AIProviderError("GEMINI_API_KEY is not configured")
        from google import genai

        _gemini_client = genai.Client(api_key=_settings.gemini_api_key)
    return _gemini_client


def _get_openai_client():
    global _openai_client
    if _openai_client is None:
        if not _settings.openai_api_key:
            raise AIProviderError("OPENAI_API_KEY is not configured")
        from openai import OpenAI

        _openai_client = OpenAI(api_key=_settings.openai_api_key)
    return _openai_client


def _gemini_history(history: List[ChatTurn]):
    from google.genai import types

    return [
        types.Content(
            role="user" if turn["role"] == "user" else "model",
            parts=[types.Part(text=turn["text"])],
        )
        for turn in history
    ]


def _generate_gemini(system_prompt: str, history: List[ChatTurn], user_message: str) -> str:
    from google.genai import types

    client = _get_gemini_client()
    chat = client.chats.create(
        model=_GEMINI_MODEL,
        config=types.GenerateContentConfig(system_instruction=system_prompt),
        history=_gemini_history(history),
    )
    response = chat.send_message(user_message)
    return (response.text or "").strip()


def _generate_openai(system_prompt: str, history: List[ChatTurn], user_message: str) -> str:
    client = _get_openai_client()
    messages = [{"role": "system", "content": system_prompt}]
    messages.extend(
        {"role": "user" if turn["role"] == "user" else "assistant", "content": turn["text"]}
        for turn in history
    )
    messages.append({"role": "user", "content": user_message})

    response = client.chat.completions.create(
        model=_OPENAI_MODEL,
        messages=messages,
        max_tokens=600,
        temperature=0.7,
    )
    return (response.choices[0].message.content or "").strip()


def generate_reply(system_prompt: str, history: List[ChatTurn], user_message: str) -> str:
    """`history` is oldest-first, excluding `user_message` itself."""
    provider = _settings.ai_provider.lower()
    try:
        if provider == "openai":
            return _generate_openai(system_prompt, history, user_message)
        return _generate_gemini(system_prompt, history, user_message)
    except AIProviderError:
        raise
    except Exception as exc:  # noqa: BLE001 - upstream SDK error types vary by provider
        raise AIProviderError(f"AI provider request failed: {exc}") from exc


def _generate_json_gemini(system_prompt: str, user_message: str, schema: Dict[str, Any]) -> str:
    from google.genai import types

    client = _get_gemini_client()
    response = client.models.generate_content(
        model=_GEMINI_MODEL,
        contents=user_message,
        config=types.GenerateContentConfig(
            system_instruction=system_prompt,
            response_mime_type="application/json",
            response_schema=schema,
            temperature=0.4,
        ),
    )
    return response.text or "{}"


def _generate_json_openai(system_prompt: str, user_message: str, schema: Dict[str, Any]) -> str:
    # OpenAI's json_object mode guarantees valid JSON but not a specific
    # shape, so the schema is spelled out in the prompt itself as a fallback
    # guarantee (Gemini's response_schema above is the stronger guarantee,
    # used since Gemini is this project's primary provider).
    client = _get_openai_client()
    schema_hint = json.dumps(schema)
    response = client.chat.completions.create(
        model=_OPENAI_MODEL,
        messages=[
            {"role": "system", "content": system_prompt},
            {
                "role": "user",
                "content": f"{user_message}\n\nRespond with ONLY JSON matching this "
                f"JSON Schema, no other text:\n{schema_hint}",
            },
        ],
        response_format={"type": "json_object"},
        max_tokens=1200,
        temperature=0.4,
    )
    return response.choices[0].message.content or "{}"


def generate_json(
    system_prompt: str, user_message: str, schema: Dict[str, Any]
) -> Dict[str, Any]:
    """Structured JSON generation for tasks like resume analysis, where the
    caller needs a guaranteed-shape response rather than free chat text.
    `schema` is a JSON Schema dict (Gemini's `response_schema` format)."""
    provider = _settings.ai_provider.lower()
    try:
        raw = (
            _generate_json_openai(system_prompt, user_message, schema)
            if provider == "openai"
            else _generate_json_gemini(system_prompt, user_message, schema)
        )
    except AIProviderError:
        raise
    except Exception as exc:  # noqa: BLE001
        raise AIProviderError(f"AI provider request failed: {exc}") from exc

    try:
        return json.loads(raw)
    except json.JSONDecodeError as exc:
        raise AIProviderError(f"AI provider returned invalid JSON: {exc}") from exc
