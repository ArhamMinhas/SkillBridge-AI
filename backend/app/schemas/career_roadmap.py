from typing import List, Optional

from pydantic import BaseModel


class CareerRoadmap(BaseModel):
    id: Optional[str] = None
    title: str
    description: str
    requiredSkills: List[str]
    steps: List[str]
    resources: List[str] = []
