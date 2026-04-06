## 10. Project-Specific Configuration

### Stack
Go + Chi/Gin/stdlib + Postgres

### Build & Dev Commands
- `go run .` — start dev server
- `go vet ./...` — static analysis
- `golangci-lint run` — lint
- `go test ./...` — run tests
- `go build -o bin/app .` — production build

### Code Conventions
- Accept interfaces, return structs
- Errors are values — handle every error, no blank `_` on error returns
- Table-driven tests with `t.Run()` subtests
- Context propagation — pass `context.Context` as first argument
- No globals — inject dependencies via constructor functions

### Architecture
```
cmd/               — Entry points (main.go)
internal/
  handler/         — HTTP handlers (request/response only)
  service/         — Business logic (no HTTP concerns)
  repository/      — Database access (queries, transactions)
  model/           — Domain types and structs
  middleware/      — Auth, logging, rate limiting
pkg/               — Reusable libraries (safe for external import)
migrations/        — SQL migration files
```

- Handlers call services, services call repositories
- Database via `sqlx` or `pgx` — parameterized queries only
- Structured logging with `slog`
