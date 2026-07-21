"""User profile + dashboard routes, backed directly by Firestore's `users`
collection. Every route requires a verified Firebase ID token.
"""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from google.cloud.firestore_v1.base_query import FieldFilter

from app.firebase.auth import CurrentUser, get_current_user
from app.firebase.firebase_admin_client import get_firestore_client
from app.schemas.user import DashboardStats, UserProfile, UserProfileUpdate

router = APIRouter(prefix="/users", tags=["users"])

_PROFILE_FIELDS = ["name", "phone", "education", "degree", "careerGoal"]

# How many jobs to scan when computing the dashboard's "new job matches"
# count — bounds the read cost until Phase 8's real job-match/ml engine
# replaces this with a proper indexed/precomputed score.
_JOB_MATCH_SCAN_LIMIT = 200
_JOB_MATCH_MIN_OVERLAP = 1


@router.get("/profile", response_model=UserProfile)
async def get_profile(current_user: CurrentUser = Depends(get_current_user)):
    db = get_firestore_client()
    doc = db.collection("users").document(current_user.uid).get()
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")
    return {"uid": current_user.uid, **doc.to_dict()}


@router.put("/profile", response_model=UserProfile)
async def upsert_profile(
    payload: UserProfileUpdate,
    current_user: CurrentUser = Depends(get_current_user),
):
    db = get_firestore_client()
    doc_ref = db.collection("users").document(current_user.uid)
    existing = doc_ref.get()

    update_data = {k: v for k, v in payload.model_dump(exclude_unset=True).items() if v is not None}

    if not existing.exists:
        update_data.update(
            {
                "uid": current_user.uid,
                "email": current_user.email,
                "isPremium": False,
                "role": current_user.role,
                "createdAt": datetime.now(timezone.utc),
            }
        )
        doc_ref.set(update_data)
    else:
        doc_ref.update(update_data)

    return {"uid": current_user.uid, **doc_ref.get().to_dict()}


def _latest_ats_score(db, uid: str) -> int | None:
    # A single-field equality filter (no order_by) needs no composite
    # index; report counts per user are small (bounded by the free-tier
    # analysis limit anyway), so picking the max createdAt in Python here
    # is cheap and avoids a Firestore index deployment for this.
    reports = [
        doc.to_dict()
        for doc in db.collection("resumeReports")
        .where(filter=FieldFilter("userId", "==", uid))
        .stream()
    ]
    if not reports:
        return None
    latest = max(
        reports, key=lambda r: r.get("createdAt") or datetime.min.replace(tzinfo=timezone.utc)
    )
    return latest.get("atsScore")


def _new_job_match_count(db, skills: list[str]) -> int:
    if not skills:
        return 0
    user_skills = {s.lower() for s in skills}

    count = 0
    for job in db.collection("jobs").limit(_JOB_MATCH_SCAN_LIMIT).stream():
        required = job.to_dict().get("requiredSkills") or []
        required_skills = {s.lower() for s in required}
        if len(user_skills & required_skills) >= _JOB_MATCH_MIN_OVERLAP:
            count += 1
    return count


@router.get("/dashboard-stats", response_model=DashboardStats)
async def get_dashboard_stats(current_user: CurrentUser = Depends(get_current_user)):
    db = get_firestore_client()
    profile_doc = db.collection("users").document(current_user.uid).get()
    profile = profile_doc.to_dict() or {}

    completion_fields = _PROFILE_FIELDS + ["skills", "resumeUrl"]
    filled = sum(1 for f in completion_fields if profile.get(f))
    completion_score = round((filled / len(completion_fields)) * 100)

    # Job-match count is a simple "shares at least one required skill"
    # heuristic over a bounded scan — a real ranked score (per Phase 8) is
    # still pending app/ml; this is deliberately just "real, not zero"
    # rather than a full recommendation engine.
    return DashboardStats(
        profileCompletionScore=completion_score,
        newJobMatches=_new_job_match_count(db, profile.get("skills") or []),
        latestAtsScore=_latest_ats_score(db, current_user.uid),
        roadmapProgressPercent=None,
    )


@router.get("/progress-analytics")
async def get_progress_analytics(current_user: CurrentUser = Depends(get_current_user)):
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Progress analytics pending app/ml progress-prediction implementation",
    )
