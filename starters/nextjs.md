## 10. Project-Specific Configuration

### Stack
Next.js + React + TypeScript

### Build & Dev Commands
_(Adjust the package manager prefix to match your project)_
- `dev` — start dev server
- `build` — production build
- `typecheck` — TypeScript strict check
- `lint` — ESLint
- `test` — run tests

### Code Conventions
- TypeScript strict mode — no `any`, use `unknown` and narrow
- Server components by default — `"use client"` only when needed
- Props interfaces, not inline types — no prop drilling past 2 levels
- Use the project's styling approach consistently (Tailwind, CSS Modules, etc.)
- Zod schemas for all API input validation
- Explicit return types on exported functions

### Architecture
```
app/               — Next.js App Router (pages, layouts, API routes)
  (site)/          — Public-facing routes
  (admin)/         — Admin/dashboard routes
  api/             — API route handlers
components/        — Shared React components
lib/               — Utilities, auth, database client
```

- App Router with route groups for layout separation
- Server components render by default, client components for interactivity
- API routes follow: auth → validate → query → respond
- Database via ORM (Drizzle/Prisma) — never raw SQL
