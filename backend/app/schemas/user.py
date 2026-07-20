"""Pydantic schemas for the `users` Firestore collection.

Field names intentionally mirror the Firestore document exactly (see
docs/firestore_schema.md) so Flutter models and backend schemas stay in
sync without a translation layer.
"""
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class UserProfile(BaseModel):
    uid: str
    name: str
    email: str
    phone: Optional[str] = None
    education: Optional[str] = None
    degree: Optional[str] = None
    skills: List[str] = Field(default_factory=list)
    experienceLevel: Optional[str] = None  # "junior" | "mid" | "senior"
    careerGoal: Optional[str] = None
    resumeUrl: Optional[str] = None
    isPremium: bool = False
    role: str = "user"  # "user" | "admin"
    createdAt: Optional[datetime] = None


class UserProfileUpdate(BaseModel):
    """All fields optional — partial update (PATCH-style via PUT)."""

    name: Optional[str] = None
    phone: Optional[str] = None
    education: Optional[str] = None
    degree: Optional[str] = None
    skills: Optional[List[str]] = None
    experienceLevel: Optional[str] = None
    careerGoal: Optional[str] = None


class DashboardStats(BaseModel):
    profileCompletionScore: int
    newJobMatches: int
    latestAtsScore: Optional[int] = None
    roadmapProgressPercent: Optional[int] = None
