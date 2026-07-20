"""Job/internship listing routes, backed by Firestore's `jobs` collection.
Write access (create/edit/delete) is admin-only — see app/routes/admin.py.
"""
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.firebase.auth import CurrentUser, get_current_user
from app.firebase.firebase_admin_client import get_firestore_client
from app.schemas.job import Job

router = APIRouter(prefix="/jobs", tags=["jobs"])


@router.get("", response_model=List[Job])
async def list_jobs(
    skill: Optional[str] = Query(None, description="Filter by a required skill"),
    location: Optional[str] = Query(None),
    job_type: Optional[str] = Query(None, alias="jobType"),
    experience_level: Optional[str] = Query(None, alias="experienceLevel"),
    current_user: CurrentUser = Depends(get_current_user),
):
    db = get_firestore_client()
    query = db.collection("jobs")

    if location:
        query = query.where("location", "==", location)
    if job_type:
        query = query.where("jobType", "==", job_type)
    if experience_level:
        query = query.where("experienceLevel", "==", experience_level)

    docs = query.stream()
    jobs = [{"id": doc.id, **doc.to_dict()} for doc in docs]

    # requiredSkills membership filter applied in-memory since Firestore
    # doesn't support arbitrary array-contains combined with other filters
    # without a composite index per skill.
    if skill:
        jobs = [j for j in jobs if skill.lower() in [s.lower() for s in j.get("requiredSkills", [])]]

    return jobs


@router.get("/{job_id}", response_model=Job)
async def get_job(job_id: str, current_user: CurrentUser = Depends(get_current_user)):
    db = get_firestore_client()
    doc = db.collection("jobs").document(job_id).get()
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")
    return {"id": doc.id, **doc.to_dict()}


@router.get("/{job_id}/match")
async def get_job_match(job_id: str, current_user: CurrentUser = Depends(get_current_user)):
    # TODO: delegate to app/ml job-match scoring once implemented — see
    # app/routes/data_science.py's /job-match endpoint for the shared logic.
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Job match scoring pending app/ml/ implementation",
    )
