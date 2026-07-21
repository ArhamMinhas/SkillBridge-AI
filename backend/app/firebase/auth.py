"""Firebase ID token verification + role-based access dependencies.

Every protected route depends on `get_current_user`. Admin-only routes
additionally depend on `require_admin`. Never trust a client-supplied role —
always resolve it from the verified token's custom claims or, as a fallback,
the user's Firestore profile document.
"""
from dataclasses import dataclass
from datetime import datetime, timezone

import firebase_admin.auth as firebase_auth
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.firebase.firebase_admin_client import get_firestore_client, init_firebase

_bearer_scheme = HTTPBearer(auto_error=False)


@dataclass
class CurrentUser:
    uid: str
    email: str | None
    role: str


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
) -> CurrentUser:
    if credentials is None or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid Authorization header",
        )

    init_firebase()

    try:
        decoded_token = firebase_auth.verify_id_token(credentials.credentials)
    except firebase_auth.ExpiredIdTokenError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Session expired. Please log in again")
    except firebase_auth.InvalidIdTokenError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication token")
    except Exception:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Could not verify authentication token")

    uid = decoded_token["uid"]
    email = decoded_token.get("email")

    # Register/Google-sign-in only create the Firebase Auth account, not the
    # Firestore users/{uid} doc — that previously only happened at the end
    # of the 3-step Profile Setup wizard, which left the doc (and therefore
    # isPremium/role/every dashboard stat derived from it) missing for any
    # user who signed up but hadn't finished that wizard yet. Since every
    # protected route depends on get_current_user, this is the one place
    # guaranteed to run on a user's very first authenticated request —
    # ensure the baseline doc exists here rather than relying on a
    # multi-step client flow to eventually create it. Profile Setup's own
    # PUT just fills in the rest of the fields afterward.
    db = get_firestore_client()
    doc_ref = db.collection("users").document(uid)
    doc = doc_ref.get()
    if not doc.exists:
        doc_ref.set(
            {
                "uid": uid,
                "email": email,
                "isPremium": False,
                "role": "user",
                "createdAt": datetime.now(timezone.utc),
            }
        )
        role = "user"
    else:
        # Custom claims are the source of truth when present (set via the
        # admin endpoint that promotes a user); otherwise fall back to the
        # Firestore profile's `role` field, defaulting to "user".
        role = decoded_token.get("role") or doc.to_dict().get("role", "user")

    return CurrentUser(uid=uid, email=email, role=role)


async def require_admin(current_user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
    if current_user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin access required")
    return current_user
