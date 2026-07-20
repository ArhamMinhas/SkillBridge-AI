from typing import Optional

from pydantic import BaseModel


class Skill(BaseModel):
    id: Optional[str] = None
    name: str
    category: str
    difficulty: str  # "beginner" | "intermediate" | "advanced"
