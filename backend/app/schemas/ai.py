from typing import List, Optional

from pydantic import BaseModel, Field


class ResumeAnalysisResult(BaseModel):
    atsScore: int
    strengths: List[str]
    weaknesses: List[str]
    missingSkills: List[str]
    suggestions: List[str]


class RoadmapRequest(BaseModel):
    careerGoal: str


class InterviewQuestionsRequest(BaseModel):
    careerPath: str
    count: int = 5


class MockInterviewAnswerRequest(BaseModel):
    interviewId: str
    questionIndex: int
    answerText: str


class ChatbotMessageRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=4000)
    conversationId: Optional[str] = None


class ChatbotMessageResponse(BaseModel):
    reply: str
    conversationId: str
