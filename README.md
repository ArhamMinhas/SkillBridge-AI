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

> The 16-phase roadmap below (as given by the project owner) illustrates a
> `mobile_app/ backend/ docker/ docs/ firebase/ scripts/` layout. This repo
> keeps its existing `frontend/` / `backend/` / `docs/` naming instead of
> renaming folders to match — same content, no disruptive rename for zero
> functional benefit. Docker files live under `backend/` (`Dockerfile`,
> `docker-compose.yml`); there's no separate top-level `docker/` folder.

See [`docs/frontend_design_spec.md`](docs/frontend_design_spec.md) for the
full design system (colors, typography, animations, folder structure) and
[`backend/README.md`](backend/README.md) for backend setup, Docker commands,
and current implementation status.

## Tech stack

| Layer | Technology |
| --- | --- |
| Frontend | Flutter + Dart, Riverpod, go_router, fl_chart |
| Backend | FastAPI + Python |
| Auth | Firebase Authentication (email/password + Google) |
| Database | Firebase Firestore |
| Storage | Backend multipart upload (no Firebase Storage — Spark plan, see below) |
| Push notifications | Firebase Cloud Messaging + flutter_local_notifications |
| AI | Gemini API / OpenAI API, called only from FastAPI, never from Flutter |
| Data science | Pandas, NumPy, scikit-learn |
| Payments | Stripe PaymentSheet + webhooks (test mode until release) |
| Containerization | Docker + Docker Compose |

## Project roadmap (16 phases)

This is the standing development order for the project — read it before
starting a new feature so work lands in the right phase and doesn't
duplicate something already done. Status reflects the repo as of
2026-07-21; re-verify against the actual code before trusting a "done"
label on anything that isn't your immediate task.

| # | Phase | Status |
| --- | --- | --- |
| 1 | Project Planning & Architecture — folder structure, Flutter/FastAPI architecture, Firebase config, env vars, Riverpod setup, API architecture, Docker, git, README, naming/coding standards | ✅ Done |
| 2 | Flutter UI Foundation — Splash, Onboarding, Login, Register, Forgot Password, bottom nav, theme, dark mode, responsive layout, custom widgets (UI only, no backend) | ✅ Done |
| 3 | Firebase Authentication — email login/register, Google login, forgot password, logout, session, role management, security rules | ✅ Done — email + Google login, session, role via custom claims/Firestore fallback, and `firestore.rules` is written **and deployed** to the live project (verified 2026-07-22 with live rule-enforcement tests against a real client token — see `skillbridge-firestore-rules` memory) |
| 4 | User Profile Module — profile setup, edit profile, Firestore integration, avatar upload, resume upload, validation | ✅ Mostly done. Avatar/resume upload go through the FastAPI backend as multipart, **not** Firebase Storage (Spark plan has no Storage — see constraints below) |
| 5 | FastAPI Backend — Docker, Docker Compose, FastAPI, auth middleware, Firebase token verification, REST APIs, Swagger, logging, error handling | ✅ Done (Swagger auto-served at `/docs` outside production) |
| 6 | Resume Upload & AI Analysis — upload PDF, extract text, AI analysis, ATS score, missing skills, suggestions, resume report | ✅ Done (2026-07-22) — `app/ai/resume_analyzer.py`: pypdf text extraction, Gemini-backed structured ATS scoring, free-tier 1-analysis limit, Firestore `resumeReports` persistence |
| 7 | Skill Assessment — quiz, MCQs, score calculation, skill rating, weak-skills detection, skill dashboard | 🟡 Quiz UI + report UI exist; **weak-skills detection backend is a 501 stub** pending `app/ml/` |
| 8 | Data Science Recommendation Engine — skill score, career prediction, job recommendation, learning recommendation, progress prediction | 🟡 Skill-score formula is live (`/data-science/skill-score`); **career prediction, job/learning recommendation, and progress prediction are all 501 stubs** pending `app/ml/` |
| 9 | AI Career Mentor — chat, career advice, resume/coding questions, learning suggestions, context memory | ✅ Done (2026-07-21) — Gemini/OpenAI-backed chatbot with Firestore-persisted conversation history and profile-personalized system prompt |
| 10 | AI Mock Interview — technical + HR interview, AI feedback, score, suggestions, history | 🟡 UI exists; **backend (question generation, answer feedback) is a 501 stub** pending `app/ai/` |
| 11 | Job Portal — listing, search, filters, bookmark, match %, apply link | 🟡 Listing/filtering/UI done against real Firestore data; **match-% scoring is a 501 stub** (depends on Phase 8's job-match engine) |
| 12 | Progress Analytics — dashboard, charts/graphs, skill/learning/resume/interview/career progress | 🟡 Screen + chart widgets exist; **`/users/progress-analytics` is a 501 stub** pending `app/ml/` progress prediction |
| 13 | Notifications — FCM, local notifications, history, settings, reminder scheduler, toasts, snackbars, dialogs, loading states, offline handling | 🟡 FCM/local notification service, toast/snackbar/dialog/loading system, and Firestore-backed notification history (`NotificationService.notificationHistory()`) are all live; **reminder scheduler and a dedicated notification-settings screen not yet confirmed built** — verify before assuming done |
| 14 | Stripe Premium — plans, payment screen, PaymentSheet, webhooks, premium unlock, subscription history | ✅ Done (create/cancel subscription, webhook → Firestore `isPremium` flip). Uses Stripe **test-mode** keys — switch to live only before release |
| 15 | Admin Panel — dashboard, users, jobs, career paths, skills, learning resources, analytics, reports, notifications, premium users | 🟡 Admin CRUD (jobs/skills/roadmaps) + role-gated admin dashboard screen exist; **reports and admin-side notification management not yet confirmed built** |
| 16 | Production & Deployment — Docker, README, testing, Firebase rules, optimization, release build, Play Store assets, AAB, privacy policy, Play Console, deployment, monitoring, Crashlytics, performance monitoring | 🟡 Firestore security rules done (see Phase 3). `firebase_crashlytics`/`firebase_performance` packages are in `pubspec.yaml` but not confirmed wired up; no Play Store assets, no signed release build yet |

**Recommended order**: work top to bottom — each phase assumes the ones
above it are functional. The one deliberate exception so far was pulling
Phase 9 (AI Career Mentor) forward ahead of finishing Phases 6/7/8/10,
per an explicit request; the skipped 501 stubs in those phases are still
outstanding and should be picked up in phase order once mentor work is
stable.

### Firebase Spark (free) plan constraints

This project runs on the Spark plan — no billing account, so **no Blaze
plan and no Firebase Storage**. To stay within the free tier:

- Firestore instead of a SQL database.
- Firebase Authentication (email/password + Google Sign-In) — no other
  providers unless the plan changes.
- **Resumes and profile images upload through the FastAPI backend as
  multipart form data**, not `firebase_storage` — there is no Storage
  bucket on Spark. Don't reintroduce the `firebase_storage` package for
  actual file uploads.
- Firebase Cloud Messaging for push notifications (no cost on Spark).
- Firebase Crashlytics + Performance Monitoring (no cost on Spark).
- AI calls (OpenAI/Gemini) go through FastAPI only — the Flutter app never
  holds an AI provider key.
- Stripe test mode during development; switch to live keys only right
  before release.
- FastAPI deploys to a free tier of Render or Railway (subject to their
  current limits) — Docker support stays in place for portability
  regardless of host.

## Premium UI/UX redesign directive

Standing design mandate — applies to **every screen**, current and future,
not a one-time pass. Read this before touching any screen's UI. See also
[`docs/frontend_design_spec.md`](docs/frontend_design_spec.md) for the
concrete design tokens (colors, typography scale, spacing, folder
structure) this directive is implemented against.

**Brief**: build like a Senior Staff Full-Stack Mobile Engineer / Product
Designer / Motion Designer at Apple, Google, or Airbnb. This is not a
small-UI-tweak job — it's a full redesign into a production-ready, premium
app that belongs in the App Store's featured section. No clarifying
questions about colors/fonts/animations — make the call, have a reason for
it, keep backend functionality and business logic untouched.

**Brand feel**: premium, modern, intelligent, elegant, minimal,
professional, high-tech — a blend of Linear, Notion, Duolingo, Apple,
Google Gemini, ChatGPT, Stripe, and Airbnb.

**App icon** — remove the black background in favor of transparency,
cleaner silhouette, better lighting/gradients/glow, official-App-Store
polish. Keep the bridge concept, the AI concept, the branding, and the
existing colors.

**Splash screen** — no static splash. Animated logo reveal, floating
particles, smooth gradient background, glow effects, Lottie animation,
fade + scale transitions.

**Login / Register** — premium layout, hero/3D illustration, animated
logo, floating AI elements, animated input fields, password
visibility/strength animation, step animations (register), smooth
validation, micro-interactions, premium loading and error states.

**Home dashboard** — gradient cards, glassmorphism/neumorphism where each
fits, Hero animations, AI widgets, floating action buttons, fully
responsive.

**Resume upload** — must not be a boring upload button. Animated
drag-and-drop experience, floating upload icon, AI document illustration,
upload progress + success animation, file preview, beautiful empty state —
should immediately read as "AI Resume Analysis."

**Resume analysis** — AI loading animation, animated ATS score circle,
strength/weakness indicators, improvement suggestions, charts, animated
progress bars, expandable cards.

**Jobs** — modern cards with company logos, salary badges, animated
bookmarks, search animation, filters, smooth transitions, empty states,
loading skeletons.

**Career roadmap** — one of the most visually ambitious screens: timeline
animations, progress indicators, milestones, achievement badges,
interactive cards, smooth scroll animations.

**Profile** — hero header, animated avatar, statistics, settings cards,
career progress, achievements, skill progress.

**Navigation** — bottom nav with a floating active indicator, animated
icons, ripple, haptic feedback, smooth transitions.

**Animation language, everywhere**: Hero/shared-element transitions, fade,
scale, slide, elastic/spring curves, Lottie/Rive where appropriate,
micro-interactions, ripple, floating motion, hover states (web/desktop),
gesture and scroll-driven animation. Nothing should sit static.

**Icons**: replace basic Material defaults with a premium, consistent set
— Material Symbols Rounded, Cupertino, Phosphor, or Lucide — used wherever
it improves clarity, not decoration for its own sake.

**Illustrations**: 3D or modern vector artwork / glass icons on screens
that otherwise feel empty (login, register, resume upload, empty jobs,
career roadmap, AI analysis, settings).

**Design system**: primary/secondary/accent/background/surface/text/
error/warning/success/info colors, both light and dark themes; premium
type family (Inter/SF Pro/Manrope/Plus Jakarta Sans) with a full scale
(display/heading/title/subtitle/body/caption); reusable buttons, cards,
dialogs, bottom sheets, snackbars, search bars, inputs, dropdowns, badges,
tags, progress indicators, shimmers, empty/error states — no duplicated UI
code, theme extensions and design tokens over one-off styling.

**Responsiveness**: small/medium/large phones, foldables, tablets,
landscape, and Flutter Web — zero overflow, zero RenderFlex errors, zero
clipped widgets, zero hardcoded fixed dimensions.

**Accessibility**: large-text support, screen readers, high contrast,
adequate touch targets, semantic labels, keyboard navigation.

**Performance**: 60–120fps animations, minimal rebuilds, efficient state
management, lazy loading, image caching, `RepaintBoundary` around
continuously-animating layers.

**Scope**: every screen — Splash, Onboarding, Login, Register, Forgot
Password, Home Dashboard, Resume Upload, Resume Analysis, Job
Recommendations, Career Roadmap, AI Chat, Notifications, Search, Settings,
Profile, About, Help, Bottom Navigation, and every dialog/bottom
sheet/empty/loading/error/success state and reusable component. Backend
integrations and business logic stay unchanged unless a UI change requires
a minor refactor around them. Work screen by screen, don't stop after a
handful — see the per-screen audit tracked in project memory
(`skillbridge-redesign-audit`) for current progress and priority order.

## Getting started

1. **Backend**: see [`backend/README.md`](backend/README.md) — local venv or
   Docker instructions, plus what you need from the Firebase console before
   protected routes will work.
2. **Frontend**: `cd frontend && flutter pub get`, copy `.env.example` to
   `.env` and fill in your Firebase Web config + Stripe publishable key, then
   `flutter run`.

Neither side has real API keys checked in — every secret comes from
`.env` files that are gitignored on both sides (see each `.env.example`).

## Current status

All 22 screens are real, wired UI (not placeholders) — auth flow, profile,
dashboard, resume, skills, roadmap, jobs, AI features, and subscription are
all built against `go_router` and either live backend endpoints or
graceful "coming soon" states where the backend is still a 501 stub (see
the roadmap table above for exactly which endpoints those are). **Every
screen has now had the full premium-animation redesign pass** (2026-07-21/22)
— aurora headers, Hero-linked avatars, shimmer text, glass cards, animated
score gauges/charts, staggered entrances, and consistent micro-interactions
throughout. Per-screen detail on exactly what technique was used where is
tracked in project memory (`skillbridge-redesign-audit`). Two genuinely new
local-only UI features were added as part of this (Career Roadmap milestone
completion, Job Matching bookmarks) — neither is backend-persisted yet.

## What's next

1. Fill in the remaining 501 stubs in phase order (Phases 6, 7, 8, 10 —
   resume analysis, weak-skill detection, job-match/recommendation engine,
   mock interview) now that Phase 9's AI mentor is done.
2. Decide whether Career Roadmap milestone-completion and Job Matching
   bookmarks should be persisted (new Firestore field + endpoint each) —
   currently both reset on screen rebuild.
4. App icon redesign and a splash-screen Lottie asset — both need real
   source art/asset generation, not just code changes.
5. Phase 16: Play Store publishing prep (signed AAB, Crashlytics/Performance
   wiring, privacy policy).
