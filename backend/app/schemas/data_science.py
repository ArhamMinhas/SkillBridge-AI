from typing import List

from pydantic import BaseModel


class SkillScoreRequest(BaseModel):
    userSkills: List[str]
    requiredSkills: List[str]


class JobMatchRequest(BaseModel):
    jobId: str


class WeakSkillsRequest(BaseModel):
    assessmentAnswers: dict
    jobRequiredSkills: List[str] = []
