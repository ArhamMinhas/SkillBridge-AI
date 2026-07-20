"""User profile + dashboard routes, backed directly by Firestore's `users`
collection. Every route requires a verified Firebase ID token.
"""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status

from app.firebase.auth import CurrentUser, get_current_user
from app.firebase.firebase_admin_client import get_firestore_client
from app.schemas.user import DashboardStats, UserProfile, UserProfileUpdate

router = APIRouter(prefix="/users", tags=["users"])

_PROFILE_FIELDS = ["name", "phone", "education", "degree", "careerGoal"]


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


@router.get("/dashboard-stats", response_model=DashboardStats)
async def get_dashboard_stats(current_user: CurrentUser = Depends(get_current_user)):
    db = get_firestore_client()
    profile_doc = db.collection("users").document(current_user.uid).get()
    profile = profile_doc.to_dict() or {}

    completion_fields = _PROFILE_FIELDS + ["skills", "resumeUrl"]
    filled = sum(1 for f in completion_fields if profile.get(f))
    completion_score = round((filled / len(completion_fields)) * 100)

    # TODO(data-science): replace with real job-match count from app/ml once
    # the job matching engine is implemented.
    return DashboardStats(
        profileCompletionScore=completion_score,
        newJobMatches=0,
        latestAtsScore=None,
        roadmapProgressPercent=None,
    )


@router.get("/progress-analytics")
async def get_progress_analytics(current_user: CurrentUser = Depends(get_current_user)):
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Progress analytics pending app/ml progress-prediction implementation",
    )
