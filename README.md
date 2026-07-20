# SkillBridge AI

AI-powered career growth app for students, fresh graduates, and junior
developers — resume analysis, skill-gap detection, personalized learning
roadmaps, job/internship matching, mock interview practice, and progress
analytics.

## Repository layout

```
frontend/   Flutter mobile app (feature-first architecture)
backend/    FastAPI backend (Firebase, AI, data science, Stripe)
docs/       Design spec and reference docs
```

See [`docs/frontend_design_spec.md`](docs/frontend_design_spec.md) for the
full design system (colors, typography, animations, screen specs) and
[`backend/README.md`](backend/README.md) for backend setup, Docker commands,
and current implementation status.

## Tech stack

| Layer | Technology |
| --- | --- |
| Frontend | Flutter + Dart, Riverpod, go_router, fl_chart |
| Backend | FastAPI + Python |
| Auth | Firebase Authentication (email/password + Google) |
| Database | Firebase Firestore |
| Storage | Firebase Storage (resume uploads) |
| Push notifications | Firebase Cloud Messaging + flutter_local_notifications |
| AI | Gemini API / OpenAI API |
| Data science | Pandas, NumPy, scikit-learn |
| Payments | Stripe PaymentSheet + webhooks |
| Containerization | Docker + Docker Compose |

## Current status (scaffolding phase)

This is the initial project skeleton — folder structure, design system,
routing, and core infrastructure are in place on both sides so every
subsequent feature has a consistent home to slot into.

**Frontend (`frontend/`)**
- Flutter project generated with Android + iOS platform folders
- Design system implemented: colors, typography (Outfit/Inter via
  google_fonts), gradients, shared widgets (animated toast manager,
  gradient/outline button with press micro-animation, empty state, shimmer
  skeletons, global loading overlay)
- `core/network` (Dio client with Firebase JWT injection + retry/backoff),
  `core/services` (auth, FCM/local notifications, Stripe PaymentSheet)
- go_router wired with all 23 screens as routes (each currently a
  placeholder screen — real UI is the next phase, feature by feature)
- `flutter analyze` passes with zero issues

**Backend (`backend/`)**
- Full FastAPI folder structure (`routes/`, `services/`, `schemas/`,
  `ml/`, `ai/`, `payments/`, `firebase/`)
- Firebase ID token verification + role-based (`admin`) access control,
  fully working
- User profile CRUD, job listing/filtering, admin CRUD (jobs, skills,
  career roadmaps), admin analytics, and the Stripe subscription flow
  (create/cancel/webhook) are fully implemented against Firestore/Stripe
- AI and ML routes (resume analysis, roadmap generation, interview
  questions/feedback, chatbot, job-match scoring, weak-skill detection,
  recommendations, progress prediction) are wired with request/response
  schemas, auth, and rate limiting, but return `501` pending the actual
  model logic in `app/ai/` and `app/ml/`
- Dockerfile + docker-compose.yml build and run the API in a container

## Getting started

1. **Backend**: see [`backend/README.md`](backend/README.md) — local venv or
   Docker instructions, plus what you need from the Firebase console before
   protected routes will work.
2. **Frontend**: `cd frontend && flutter pub get`, copy `.env.example` to
   `.env` and fill in your Firebase Web config + Stripe publishable key, then
   `flutter run`.

Neither side has real API keys checked in — every secret comes from
`.env` files that are gitignored on both sides (see each `.env.example`).

## What's next

The natural next phases, in order:
1. Build out the real UI for the auth flow (splash → onboarding → login/register → profile setup) against the placeholder routes already wired up.
2. Implement `app/ai/` (resume analyzer, roadmap generator, chatbot, interview feedback) against Gemini or OpenAI.
3. Implement `app/ml/` (skill scoring beyond the basic formula already live, job-match %, weak-skill detection, recommendations, progress prediction).
4. Build out the Home Dashboard, Resume, Skills, Roadmap, and Jobs screens against the now-real backend endpoints.
5. Play Store publishing prep (launcher icon, splash screen, signed AAB) — checklist already captured in project memory and `docs/frontend_design_spec.md` section 10.
