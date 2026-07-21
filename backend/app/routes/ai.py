"""AI-powered routes: resume analysis, career roadmap generation, mock
interviews, and the chatbot mentor. Actual model calls live in app/ai/.
Roadmap/interview routes are wired and rate-limited but still return 501
until their app/ai/ implementations land; the chatbot mentor
(app/ai/chatbot.py) and resume analyzer (app/ai/resume_analyzer.py) are
fully implemented and return 503 instead if no AI provider API key is
configured yet.

Free-tier limits (1 resume analysis, capped interview questions) must be
enforced here by checking `isPremium` on the caller's Firestore profile
before invoking the AI provider — never trust a client-side gate alone.
"""
from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile, status

from app.ai.chatbot import send_chatbot_message
from app.ai.resume_analyzer import run_resume_analysis
from app.config import get_settings
from app.firebase.auth import CurrentUser, get_current_user
from app.schemas.ai import (
    ChatbotMessageRequest,
    ChatbotMessageResponse,
    InterviewQuestionsRequest,
    MockInterviewAnswerRequest,
    ResumeAnalysisResult,
    RoadmapRequest,
)
from app.utils.rate_limiter import limiter

router = APIRouter(prefix="/ai", tags=["ai"])
_settings = get_settings()
_AI_RATE_LIMIT = f"{_settings.ai_rate_limit_per_minute}/minute"
_NOT_IMPLEMENTED = "AI feature pending app/ai/ implementation for this endpoint"
_MAX_RESUME_BYTES = 10 * 1024 * 1024


@router.post("/analyze-resume", response_model=ResumeAnalysisResult)
@limiter.limit(_AI_RATE_LIMIT)
async def analyze_resume(
    request: Request,
    resume: UploadFile = File(...),
    current_user: CurrentUser = Depends(get_current_user),
):
    # No Firebase Storage on the Spark plan — the PDF arrives directly as
    # multipart form data instead of a resumeUrl, and is read into memory
    # rather than persisted; only the resulting report is saved.
    if resume.content_type != "application/pdf":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Only PDF resumes are supported")

    contents = await resume.read()
    if len(contents) > _MAX_RESUME_BYTES:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Resume must be under 10MB")

    return run_resume_analysis(current_user.uid, contents)


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


@router.post("/chatbot", response_model=ChatbotMessageResponse)
@limiter.limit(_AI_RATE_LIMIT)
async def chatbot_message(
    request: Request,
    payload: ChatbotMessageRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    return send_chatbot_message(current_user.uid, payload.message, payload.conversationId)
