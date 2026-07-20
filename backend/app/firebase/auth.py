"""Firebase ID token verification + role-based access dependencies.

Every protected route depends on `get_current_user`. Admin-only routes
additionally depend on `require_admin`. Never trust a client-supplied role —
always resolve it from the verified token's custom claims or, as a fallback,
the user's Firestore profile document.
"""
from dataclasses import dataclass

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

    # Custom claims are the source of truth when present (set via the admin
    # endpoint that promotes a user); otherwise fall back to the Firestore
    # profile's `role` field, defaulting to "user".
    role = decoded_token.get("role")
    if role is None:
        db = get_firestore_client()
        doc = db.collection("users").document(uid).get()
        role = (doc.to_dict() or {}).get("role", "user") if doc.exists else "user"

    return CurrentUser(uid=uid, email=email, role=role)


async def require_admin(current_user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
    if current_user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin access required")
    return current_user
