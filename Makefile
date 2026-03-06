.PHONY: setup mobile-run mobile-test mobile-lint mobile-build-apk mobile-build-ios \
       backend-run backend-test backend-lint \
       db-migrate db-reset db-seed \
       docker-up docker-down clean

# ==== Setup ====
setup:
	cd mobile && flutter pub get
	cd backend && pip install -r requirements.txt

# ==== Mobile (Flutter) ====
mobile-run:
	cd mobile && flutter run

mobile-test:
	cd mobile && flutter test

mobile-lint:
	cd mobile && flutter analyze

mobile-build-apk:
	cd mobile && flutter build apk --release

mobile-build-ios:
	cd mobile && flutter build ios --release

# ==== Backend (FastAPI) ====
backend-run:
	cd backend && uvicorn main:app --reload --host 0.0.0.0 --port 8000

backend-test:
	cd backend && pytest -v

backend-lint:
	cd backend && ruff check .

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
	cd mobile && flutter clean
	cd backend && rm -rf __pycache__ .pytest_cache .ruff_cache htmlcov .coverage
