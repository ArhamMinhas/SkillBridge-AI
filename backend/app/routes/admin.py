"""Admin-only routes: content management (jobs, skills, career roadmaps) and
platform visibility (users, analytics). Every route requires the caller's
resolved role to be "admin" — enforced by the `require_admin` dependency,
which itself builds on verified-token `get_current_user`.
"""
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status

from app.firebase.auth import CurrentUser, require_admin
from app.firebase.firebase_admin_client import get_firestore_client
from app.schemas.career_roadmap import CareerRoadmap
from app.schemas.job import Job
from app.schemas.skill import Skill
from app.utils.firestore_helpers import create_document, delete_document, list_documents, update_document

router = APIRouter(prefix="/admin", tags=["admin"])


# ---- Jobs -------------------------------------------------------------
@router.post("/jobs", response_model=Job)
async def create_job(payload: Job, admin: CurrentUser = Depends(require_admin)):
    data = payload.model_dump(exclude={"id"})
    return create_document(get_firestore_client(), "jobs", data)


@router.put("/jobs/{job_id}", response_model=Job)
async def update_job(job_id: str, payload: Job, admin: CurrentUser = Depends(require_admin)):
    data = payload.model_dump(exclude={"id"}, exclude_unset=True)
    return update_document(get_firestore_client(), "jobs", job_id, data)


@router.delete("/jobs/{job_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_job(job_id: str, admin: CurrentUser = Depends(require_admin)):
    delete_document(get_firestore_client(), "jobs", job_id)


# ---- Skills -------------------------------------------------------------
@router.get("/skills", response_model=List[Skill])
async def list_skills(admin: CurrentUser = Depends(require_admin)):
    return list_documents(get_firestore_client(), "skills")


@router.post("/skills", response_model=Skill)
async def create_skill(payload: Skill, admin: CurrentUser = Depends(require_admin)):
    data = payload.model_dump(exclude={"id"})
    return create_document(get_firestore_client(), "skills", data)


@router.put("/skills/{skill_id}", response_model=Skill)
async def update_skill(skill_id: str, payload: Skill, admin: CurrentUser = Depends(require_admin)):
    data = payload.model_dump(exclude={"id"}, exclude_unset=True)
    return update_document(get_firestore_client(), "skills", skill_id, data)


@router.delete("/skills/{skill_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_skill(skill_id: str, admin: CurrentUser = Depends(require_admin)):
    delete_document(get_firestore_client(), "skills", skill_id)


# ---- Career roadmaps -----------------------------------------------------
@router.get("/career-roadmaps", response_model=List[CareerRoadmap])
async def list_career_roadmaps(admin: CurrentUser = Depends(require_admin)):
    return list_documents(get_firestore_client(), "careerRoadmaps")


@router.post("/career-roadmaps", response_model=CareerRoadmap)
async def create_career_roadmap(payload: CareerRoadmap, admin: CurrentUser = Depends(require_admin)):
    data = payload.model_dump(exclude={"id"})
    return create_document(get_firestore_client(), "careerRoadmaps", data)


@router.put("/career-roadmaps/{roadmap_id}", response_model=CareerRoadmap)
async def update_career_roadmap(
    roadmap_id: str, payload: CareerRoadmap, admin: CurrentUser = Depends(require_admin)
):
    data = payload.model_dump(exclude={"id"}, exclude_unset=True)
    return update_document(get_firestore_client(), "careerRoadmaps", roadmap_id, data)


@router.delete("/career-roadmaps/{roadmap_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_career_roadmap(roadmap_id: str, admin: CurrentUser = Depends(require_admin)):
    delete_document(get_firestore_client(), "careerRoadmaps", roadmap_id)


# ---- Learning resources ---------------------------------------------------
# Currently modeled as CareerRoadmap.resources (see docs/firestore_schema).
# If a dedicated `learningResources` collection is introduced later, add
# CRUD routes here following the same pattern as skills/jobs above.
@router.get("/learning-resources")
async def list_learning_resources(admin: CurrentUser = Depends(require_admin)):
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Learning resources are currently embedded in careerRoadmaps.resources",
    )


# ---- Users & analytics -----------------------------------------------------
@router.get("/users")
async def list_users(admin: CurrentUser = Depends(require_admin)):
    return list_documents(get_firestore_client(), "users")


@router.get("/analytics")
async def get_admin_analytics(admin: CurrentUser = Depends(require_admin)):
    db = get_firestore_client()
    users = list(db.collection("users").stream())
    total_users = len(users)
    premium_users = sum(1 for u in users if (u.to_dict() or {}).get("isPremium"))
    total_jobs = len(list(db.collection("jobs").stream()))

    return {
        "totalUsers": total_users,
        "premiumUsers": premium_users,
        "totalJobs": total_jobs,
    }
