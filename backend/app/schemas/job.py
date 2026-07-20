from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel


class Job(BaseModel):
    id: str
    title: str
    company: str
    location: str
    jobType: str  # "full-time" | "internship" | "part-time" | "contract"
    requiredSkills: List[str]
    experienceLevel: str  # "junior" | "mid" | "senior"
    description: str
    applyLink: str
    createdAt: Optional[datetime] = None
