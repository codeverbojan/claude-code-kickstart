## 10. Project-Specific Configuration

### Stack
Python + FastAPI + SQLAlchemy/SQLModel + Postgres

### Build & Dev Commands
- `uvicorn main:app --reload` — start dev server
- `mypy .` — type check
- `ruff check .` — lint
- `ruff format --check .` — format check
- `pytest` — run tests
- `alembic upgrade head` — run database migrations

### Code Conventions
- Type hints on all functions — no untyped public APIs
- Pydantic models for all request/response schemas
- Dependency injection via FastAPI's Depends()
- Async endpoints by default — sync only for CPU-bound work
- Alembic for all schema migrations — never raw ALTER TABLE

### Architecture
```
app/
  main.py          — FastAPI app, middleware, startup
  api/             — Route modules (auth, users, etc.)
  models/          — SQLAlchemy/SQLModel ORM models
  schemas/         — Pydantic request/response models
  services/        — Business logic (no HTTP concerns)
  core/            — Config, security, database session
migrations/        — Alembic migration files
tests/             — pytest tests mirroring app/ structure
```

- Routes call services, services call models — never skip layers
- All endpoints require auth unless explicitly public
- Background tasks via FastAPI BackgroundTasks or Celery
