# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AI Photographer - a mobile app combining photo capture with AI-powered content generation (hashtags/captions via Google Gemini API) for social media posting. Monorepo with Flutter mobile app and FastAPI backend, using Supabase for database/auth/storage.

## Common Commands

### Setup
```bash
make setup              # Install all dependencies (Flutter + Python)
```

### Backend (FastAPI, Python 3.12+)
```bash
make backend-run        # Start dev server (uvicorn, port 8000, auto-reload)
make backend-test       # Run tests (pytest -v)
make backend-lint       # Lint (ruff check .)
cd backend && pytest tests/test_auth.py -v          # Run single test file
cd backend && pytest tests/test_auth.py::test_name  # Run single test
```

### Mobile (Flutter, Dart SDK ^3.8.1)
```bash
make mobile-run         # Run Flutter app
make mobile-test        # Run Flutter tests
make mobile-lint        # Static analysis (flutter analyze)
cd mobile && dart run build_runner build --delete-conflicting-outputs  # Code gen (freezed/json_serializable)
```

### Database (Supabase)
```bash
make db-migrate         # Push migrations (npx supabase db push)
make db-reset           # Reset database
```

### Docker
```bash
make docker-up          # Start backend + postgres (port 8000, 5432)
make docker-down        # Stop containers
```

## Architecture

### Three-tier system
- **Flutter mobile app** (iOS/Android) → REST API → **FastAPI backend** (Python) → **Supabase** (PostgreSQL + Auth + Storage) + **Google Gemini API**

### Backend (`backend/`)
Layered architecture: API routes (`api/v1/`) → Services (`services/`) → Supabase Client (`config/database.py`)

- **Dependency injection** via FastAPI `Depends`: `get_current_user` (JWT auth), `get_supabase` (anon client, RLS enforced), `get_admin_supabase` (service role, RLS bypass), `get_settings_dep`
- **Middleware chain**: RequestLoggingMiddleware → CORSMiddleware → HTTPBearer JWT auth (per-endpoint)
- **Settings**: pydantic-settings with `.env` file (`config/settings.py`), singleton `settings` instance
- **Tests**: pytest-asyncio with `httpx.AsyncClient` + ASGI transport. Auth mocked via `app.dependency_overrides[get_current_user]`. Supabase mocked with `MagicMock` chain pattern (see `tests/conftest.py`)
- **Ruff config**: target py312, line-length 88, rules E/F/I/N/W/UP (`pyproject.toml`)

### Mobile (`mobile/`)
Feature-based Clean Architecture with Riverpod state management.

- **Feature structure**: `features/<name>/{data, domain, presentation}` — each feature has entities, repositories (interface + impl), datasources, providers (StateNotifier), screens, widgets
- **Features**: auth, camera, ai_generate, album, settings
- **State management**: flutter_riverpod v2 with StateNotifier pattern
- **Navigation**: go_router with auth guard redirects, ShellRoute for bottom nav (Camera/Photos/Albums/Settings)
- **Services** (cross-feature): `api_client.dart` (Dio), `supabase_service.dart`, `admob_service.dart`, `purchase_service.dart`, `share_service.dart`
- **Code generation**: freezed + json_serializable for immutable models, requires `build_runner`

### Key Data Flows
- **Auth**: Mobile → FastAPI → Supabase Auth → JWT issued → stored in flutter_secure_storage → sent as Bearer token
- **Photo upload**: multipart/form-data → FastAPI validates (JPEG/PNG/WebP/HEIC, 10MB max) → Supabase Storage (`{user_id}/photos/`) → metadata in `photos` table → signed URL returned
- **AI generation**: JWT + usage check (Free: 10/day, Premium: unlimited) → fetch photo from Storage → Gemini API → result saved to `ai_generations` table

### Environment Variables
- Backend: copy `backend/.env.example` to `backend/.env` (Supabase URL/keys, Gemini API key, SECRET_KEY, CORS_ORIGINS)
- Mobile: copy `mobile/.env.example` to `mobile/.env` (Supabase URL/anon key, API base URL, AdMob app IDs)

## Language

Project documentation is in Japanese. Code and API are in English.
