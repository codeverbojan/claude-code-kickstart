## 10. Project-Specific Configuration

### Stack
Rust + Clap + Tokio

### Build & Dev Commands
- `cargo run` — run in debug mode
- `cargo check` — fast type check
- `cargo clippy` — lint
- `cargo test` — run tests
- `cargo build --release` — optimized build
- `cargo audit` — vulnerability scan

### Code Conventions
- Use `thiserror` for library errors, `anyhow` for application errors
- Prefer `&str` over `String` in function parameters
- Derive `Debug` on all public types
- Use `clippy::pedantic` — fix all warnings before committing
- Document all public items with `///` doc comments

### Architecture
```
src/
  main.rs          — Entry point, CLI parsing (Clap)
  lib.rs           — Library root, public API
  config.rs        — Configuration loading
  commands/        — CLI subcommand implementations
  core/            — Domain logic
  util/            — Shared utilities
tests/             — Integration tests
```

- CLI parsing in main.rs, logic in lib.rs — keeps the library testable
- Async runtime via Tokio when I/O-bound
- Error propagation with `?` operator — no `.unwrap()` in library code
