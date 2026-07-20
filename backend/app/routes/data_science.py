"""Data science routes backed by app/ml/ (pandas/numpy/scikit-learn logic).

Formulas (see docs / project memory):
- skill score = matched skills / required skills * 100
- job match % = f(required skills, experience, career goal, education)
- weak skill detection = assessment answers + missing job skills
- progress prediction = completed roadmap steps + assessment scores
"""
from fastapi import APIRouter, Depends, HTTPException, status

from app.firebase.auth import CurrentUser, get_current_user
from app.schemas.data_science import JobMatchRequest, SkillScoreRequest, WeakSkillsRequest

router = APIRouter(prefix="/data-science", tags=["data-science"])

_NOT_IMPLEMENTED = "Pending app/ml/ implementation for this endpoint"


@router.post("/skill-score")
async def calculate_skill_score(
    payload: SkillScoreRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    matched = set(s.lower() for s in payload.userSkills) & set(s.lower() for s in payload.requiredSkills)
    if not payload.requiredSkills:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="requiredSkills must not be empty")
    score = round((len(matched) / len(payload.requiredSkills)) * 100)
    return {"skillScore": score, "matchedSkills": sorted(matched)}


@router.post("/weak-skills")
async def detect_weak_skills(
    payload: WeakSkillsRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail=_NOT_IMPLEMENTED)


@router.post("/job-match")
async def calculate_job_match(
    payload: JobMatchRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail=_NOT_IMPLEMENTED)


@router.get("/career-path-recommendation")
async def recommend_career_path(current_user: CurrentUser = Depends(get_current_user)):
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail=_NOT_IMPLEMENTED)


@router.get("/learning-resources-recommendation")
async def recommend_learning_resources(current_user: CurrentUser = Depends(get_current_user)):
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail=_NOT_IMPLEMENTED)


@router.get("/progress-prediction")
async def predict_progress_level(current_user: CurrentUser = Depends(get_current_user)):
    raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED, detail=_NOT_IMPLEMENTED)
