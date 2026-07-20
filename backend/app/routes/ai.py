"""AI-powered routes: resume analysis, career roadmap generation, mock
interviews, and the chatbot mentor. Actual model calls live in app/ai/ —
these routes are wired and rate-limited but return 501 until app/ai/
implementations land.

Free-tier limits (1 resume analysis, capped interview questions) must be
enforced here by checking `isPremium` on the caller's Firestore profile
before invoking the AI provider — never trust a client-side gate alone.
"""
from fastapi import APIRouter, Depends, HTTPException, Request, status

from app.config import get_settings
from app.firebase.auth import CurrentUser, get_current_user
from app.schemas.ai import (
    ChatbotMessageRequest,
    InterviewQuestionsRequest,
    MockInterviewAnswerRequest,
    ResumeAnalysisRequest,
    RoadmapRequest,
)
from app.utils.rate_limiter import limiter

router = APIRouter(prefix="/ai", tags=["ai"])
_settings = get_settings()
_AI_RATE_LIMIT = f"{_settings.ai_rate_limit_per_minute}/minute"
_NOT_IMPLEMENTED = "AI feature pending app/ai/ implementation for this endpoint"


@router.post("/analyze-resume")
@limiter.limit(_AI_RATE_LIMIT)
async def analyze_resume(
    request: Request,
    payload: ResumeAnalysisRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    # TODO: enforce free-tier 1-analysis limit via Firestore `resumeReports`
    # count when isPremium is False, then call app/ai/resume_analyzer.py.
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail=_NOT_IMPLEMENTED)


@router.post("/career-roadmap")
@limiter.limit(_AI_RATE_LIMIT)
async def generate_career_roadmap(
    request: Request,
    payload: RoadmapRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail=_NOT_IMPLEMENTED)


@router.post("/interview-questions")
@limiter.limit(_AI_RATE_LIMIT)
async def generate_interview_questions(
    request: Request,
    payload: InterviewQuestionsRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail=_NOT_IMPLEMENTED)


@router.post("/mock-interview-answer")
@limiter.limit(_AI_RATE_LIMIT)
async def submit_mock_interview_answer(
    request: Request,
    payload: MockInterviewAnswerRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail=_NOT_IMPLEMENTED)


@router.post("/chatbot")
@limiter.limit(_AI_RATE_LIMIT)
async def chatbot_message(
    request: Request,
    payload: ChatbotMessageRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail=_NOT_IMPLEMENTED)
