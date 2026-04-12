.PHONY: setup bootstrap analyze test \
       online-run online-test online-analyze online-build-apk \
       offline-run offline-test offline-analyze offline-build-apk \
       backend-run backend-test backend-lint \
       web-setup web-dev web-build web-test web-lint \
       db-migrate db-reset db-seed \
       docker-up docker-down clean

# ==== Setup (Melos) ====
setup:
	dart pub get
	dart run melos bootstrap
	cd backend && pip install -r requirements.txt
	cd web && npm install

bootstrap:
	dart pub get
	dart run melos bootstrap

# ==== Shared Package ====
shared-analyze:
	cd packages/shared && flutter analyze --no-fatal-infos

# ==== Online App ====
online-run:
	cd apps/online && flutter run

online-test:
	cd apps/online && flutter test

online-analyze:
	cd apps/online && flutter analyze --no-fatal-infos

online-build-apk:
	cd apps/online && flutter build apk --release

# ==== Offline App ====
offline-run:
	cd apps/offline && flutter run

offline-test:
	cd apps/offline && flutter test

offline-analyze:
	cd apps/offline && flutter analyze --no-fatal-infos

offline-build-apk:
	cd apps/offline && flutter build apk --release

# ==== Analyze All ====
analyze: shared-analyze online-analyze offline-analyze

# ==== Test All ====
test: offline-test backend-test

# ==== Backend (FastAPI) ====
backend-run:
	cd backend && uvicorn main:app --reload --host 0.0.0.0 --port 8000

backend-test:
	cd backend && pytest -v

backend-lint:
	cd backend && ruff check .

# ==== Web (Next.js) ====
web-setup:
	cd web && npm install

web-dev:
	cd web && npm run dev

web-build:
	cd web && npm run build

web-test:
	cd web && npm test

web-lint:
	cd web && npm run lint

# ==== Database (Supabase) ====
db-migrate:
	npx supabase db push

db-reset:
	npx supabase db reset

db-seed:
	npx supabase db reset --seed-only

# ==== Docker ====
docker-up:
	docker compose up -d

docker-down:
	docker compose down

# ==== Clean ====
clean:
	cd apps/online && flutter clean
	cd apps/offline && flutter clean
	cd packages/shared && flutter clean
	cd backend && rm -rf __pycache__ .pytest_cache .ruff_cache htmlcov .coverage
	cd web && rm -rf .next node_modules
