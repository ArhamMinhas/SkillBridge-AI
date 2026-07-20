# SkillBridge AI — FastAPI Backend

## Folder structure

```
app/
  main.py        Application entry point, CORS, router registration, rate limiting
  config.py      Pydantic Settings loaded from environment variables
  routes/        API route handlers, one file per resource
  services/      Business logic shared across routes (grows as features land)
  models/        (reserved for ORM-style models if a relational DB is ever added)
  schemas/       Pydantic request/response models
  utils/         Shared helpers (Firestore CRUD helpers, rate limiter)
  ml/            Data science logic (pandas/numpy/scikit-learn) — app/routes/data_science.py's implementation home
  ai/            AI provider calls (Gemini/OpenAI) — app/routes/ai.py's implementation home
  payments/      Stripe client wrapper
  firebase/      Firebase Admin SDK init + auth verification dependency
requirements.txt
Dockerfile
docker-compose.yml
.dockerignore
.env.example
```

## Current status

Fully wired and working: Firebase ID token verification, role-based admin
access, user profile CRUD, job listing/filtering, admin CRUD for
jobs/skills/career roadmaps, admin analytics, Stripe subscription
create/cancel + webhook, and the `skill-score` data-science formula.

Routes still returning `501 Not Implemented` (their signatures, request/response
schemas, and auth/rate-limit wiring are in place — only the model logic in
`app/ai/` and `app/ml/` is pending): resume analysis, career roadmap
generation, interview questions, mock interview feedback, chatbot, job-match
scoring, weak-skill detection, career path / learning resource
recommendation, progress prediction.

## Local setup (without Docker)

`numpy`/`pandas`/`scikit-learn` in requirements.txt only ship prebuilt
wheels up to a certain Python version. If your default `python` is newer
than that (e.g. 3.13+), `pip install` will try to compile scikit-learn from
source and fail unless you have MSVC build tools installed. Use a Python
3.11 or 3.12 interpreter for this venv instead — check what's available
with `py -0p` (Windows) before creating it.

```bash
cd backend
python3.12 -m venv .venv         # or: py -3.12 -m venv .venv (Windows)
.venv\Scripts\activate           # Windows
# source .venv/bin/activate      # macOS/Linux

pip install -r requirements.txt
copy .env.example .env           # Windows: copy, macOS/Linux: cp
# fill in .env with your Firebase project id, AI keys, Stripe keys

uvicorn app.main:app --reload --port 8000
```

Visit http://localhost:8000/docs for interactive API docs (disabled automatically when `ENV=production`).

Without a valid `FIREBASE_CREDENTIALS_PATH` file, `/health` still responds,
but every route that touches Firestore/Auth will fail until you add:
1. A Firebase project (console.firebase.google.com)
2. A downloaded service account key (Project settings → Service accounts → Generate new private key)
3. `FIREBASE_PROJECT_ID` and `FIREBASE_CREDENTIALS_PATH` set in `.env`

## Docker

```bash
# Build the image
docker build -t skillbridge-api .

# Run directly
docker run -p 8000:8000 --env-file .env \
  -v "$(pwd)/firebase-service-account.json:/app/firebase-service-account.json:ro" \
  skillbridge-api

# Or, with docker-compose (recommended — reads .env and mounts the service account automatically)
# 1. Place your Firebase service account JSON at backend/firebase-service-account.json (gitignored)
# 2. Fill in backend/.env
docker compose up          # start
docker compose up -d       # start detached
docker compose down        # stop and remove containers
```

Works identically on Windows, macOS, and Linux — Docker abstracts the OS.

## Security notes

- Stripe secret key, AI provider keys, and the Firebase service account never
  leave this backend — the Flutter app only ever gets the Stripe
  *publishable* key and short-lived PaymentSheet secrets returned per-request.
- Every route except `/health` and `/payments/webhook` requires a verified
  Firebase ID token (`Authorization: Bearer <token>`); admin routes
  additionally require the resolved role to be `admin`.
- `/payments/webhook` is authenticated via Stripe's signature verification
  instead of a bearer token, since Stripe calls it directly.
- AI routes are rate-limited per `AI_RATE_LIMIT_PER_MINUTE` (default 10/min per IP).
