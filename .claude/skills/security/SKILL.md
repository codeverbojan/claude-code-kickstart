---
name: security
description: >
  Use when writing API routes, handling user input, database queries, or auth.
  Triggered on any server-side code.
---

# Security Skill

## Rules

### Input Validation
- Validate ALL inputs server-side (Zod, joi, or language equivalent)
- Never trust client-side validation alone
- Sanitize HTML content before rendering
- Validate file uploads: type, size, content sniffing
- No eval(), no Function(), no dynamic code from user input

### Authentication & Authorization
- Auth check on EVERY protected route — no exceptions
- Role-based access control where applicable
- Session tokens: httpOnly, secure, sameSite=strict
- CSRF tokens on all mutations (POST, PUT, DELETE)
- Rate limit auth endpoints (login, password reset)
- Lock accounts after N failed attempts

### Database
- Parameterized queries ONLY
- Never interpolate user input into SQL
- Limit query results (pagination)
- Audit log for sensitive operations

### Output
- Escape all rendered content
- No dangerouslySetInnerHTML without sanitization
- Set Content-Security-Policy headers
- Set X-Content-Type-Options: nosniff
- Set X-Frame-Options: DENY (unless iframes needed)
- Set Referrer-Policy: strict-origin-when-cross-origin

### API Route Template (Node.js/Next.js example)

```typescript
import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { getSession } from "@/lib/auth";
import { db } from "@/lib/db";

const schema = z.object({
  name: z.string().min(1).max(200),
  // ... fields
});

export async function POST(req: NextRequest) {
  // 1. Auth check
  const session = await getSession();
  if (!session) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  // 2. CSRF check (typically handled by middleware)

  // 3. Input validation
  const body = await req.json();
  const parsed = schema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 });
  }

  // 4. Business logic with parameterized queries
  const result = await db.insert(table).values(parsed.data).returning();

  // 5. Return
  return NextResponse.json(result);
}
```

### Supply Chain Security
- Pin exact dependency versions (no `^` or `~` in production)
- Run `npm audit` / `pnpm audit` regularly
- Review postinstall scripts in new dependencies
- Verify new packages: check maintainers, download counts, recent changes
- Always use latest stable versions — flag outdated dependencies
- Reference: April 2026 Axios supply chain attack (maintainer account
  takeover, phantom dependency with malicious postinstall hook)
