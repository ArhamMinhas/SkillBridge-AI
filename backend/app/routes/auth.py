"""Auth-related routes. Firebase handles actual sign-in/sign-up client-side
(Flutter talks to Firebase Auth directly) — this router only exposes what
the backend needs: verifying who the current caller is.
"""
from fastapi import APIRouter, Depends

from app.firebase.auth import CurrentUser, get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])


@router.get("/me")
async def get_me(current_user: CurrentUser = Depends(get_current_user)):
    """Confirms the caller's Firebase ID token is valid and returns their
    resolved uid/email/role. Useful for the Flutter app to validate a
    session and for role-gated UI decisions."""
    return {
        "uid": current_user.uid,
        "email": current_user.email,
        "role": current_user.role,
    }
