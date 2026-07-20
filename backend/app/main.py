"""SkillBridge AI FastAPI application entry point."""
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.config import get_settings
from app.firebase.firebase_admin_client import init_firebase
from app.routes import admin, ai, auth, data_science, jobs, payments, users
from app.utils.rate_limiter import limiter

settings = get_settings()
logger = logging.getLogger("skillbridge")

app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    docs_url="/docs" if not settings.is_production else None,
    redoc_url="/redoc" if not settings.is_production else None,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def on_startup() -> None:
    # /health must stay up even before Firebase credentials are configured
    # (e.g. first local run before .env is filled in) — routes that need
    # Firestore/Auth will fail individually until real credentials exist.
    try:
        init_firebase()
    except Exception as exc:  # noqa: BLE001 - startup should never crash the process
        logger.warning("Firebase not initialized yet: %s", exc)


@app.get("/health", tags=["health"])
async def health_check():
    return {"status": "ok", "env": settings.env}


app.include_router(auth.router, prefix=settings.api_v1_prefix)
app.include_router(users.router, prefix=settings.api_v1_prefix)
app.include_router(ai.router, prefix=settings.api_v1_prefix)
app.include_router(data_science.router, prefix=settings.api_v1_prefix)
app.include_router(jobs.router, prefix=settings.api_v1_prefix)
app.include_router(admin.router, prefix=settings.api_v1_prefix)
app.include_router(payments.router, prefix=settings.api_v1_prefix)
