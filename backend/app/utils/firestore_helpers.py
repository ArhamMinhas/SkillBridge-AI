"""Small helpers shared by admin CRUD routes to avoid repeating the same
Firestore add/list/update/delete boilerplate per collection.
"""
from typing import Any, Dict, List

from fastapi import HTTPException, status
from google.cloud.firestore_v1 import Client


def list_documents(db: Client, collection: str) -> List[Dict[str, Any]]:
    return [{"id": doc.id, **doc.to_dict()} for doc in db.collection(collection).stream()]


def create_document(db: Client, collection: str, data: Dict[str, Any]) -> Dict[str, Any]:
    _, doc_ref = db.collection(collection).add(data)
    return {"id": doc_ref.id, **data}


def update_document(db: Client, collection: str, doc_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
    doc_ref = db.collection(collection).document(doc_id)
    if not doc_ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"{collection[:-1]} not found")
    doc_ref.update(data)
    return {"id": doc_id, **doc_ref.get().to_dict()}


def delete_document(db: Client, collection: str, doc_id: str) -> None:
    doc_ref = db.collection(collection).document(doc_id)
    if not doc_ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"{collection[:-1]} not found")
    doc_ref.delete()
