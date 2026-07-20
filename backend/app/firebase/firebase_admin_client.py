"""Firebase Admin SDK initialization.

Named `firebase_admin_client.py` (not `firebase_admin.py`) so it never
shadows the actual `firebase_admin` package on import.
"""
import os

import firebase_admin
from firebase_admin import credentials, firestore, storage

from app.config import get_settings

_settings = get_settings()
_app: firebase_admin.App | None = None


def init_firebase() -> firebase_admin.App:
    """Initializes the Firebase Admin app exactly once. Call from main.py's
    startup event."""
    global _app
    if _app is not None:
        return _app

    if os.path.exists(_settings.firebase_credentials_path):
        cred = credentials.Certificate(_settings.firebase_credentials_path)
    else:
        # Falls back to Application Default Credentials (useful on GCP-hosted
        # environments where a service account file isn't mounted).
        cred = credentials.ApplicationDefault()

    _app = firebase_admin.initialize_app(
        cred,
        {
            "projectId": _settings.firebase_project_id,
            "storageBucket": f"{_settings.firebase_project_id}.appspot.com",
        },
    )
    return _app


def get_firestore_client():
    init_firebase()
    return firestore.client()


def get_storage_bucket():
    init_firebase()
    return storage.bucket()
