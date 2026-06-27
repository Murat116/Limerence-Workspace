# Cursor Rules — Examples

## Example Sections

### Tech Stack Section

```markdown
## Tech Stack

**Framework:** Next.js 14 (App Router)
**Language:** TypeScript 5.x (strict mode enabled)
**Styling:** Tailwind CSS 3.x with custom design system
**State:** Zustand for global, React Context for component trees
**Forms:** React Hook Form + Zod validation
**Database:** PostgreSQL with Prisma ORM
**Testing:** Vitest (unit), Playwright (E2E)
**Deployment:** Vercel

**Key Dependencies:**
- `@tanstack/react-query` for server state
- `date-fns` for date manipulation (not moment.js)
- `clsx` + `tailwind-merge` for conditional classes
```

### Anti-Patterns Section

```markdown
## Anti-Patterns

### ❌ Don't: Default Exports
```typescript
// ❌ BAD
export default function Button() { }

// ✅ GOOD
export function Button() { }
```

**Why:** Named exports are more refactor-friendly and enable better tree-shaking.

### ❌ Don't: Inline Type Definitions
```typescript
// ❌ BAD
function UserCard({ user }: { user: { name: string; email: string } }) { }

// ✅ GOOD
interface User {
  name: string;
  email: string;
}

function UserCard({ user }: { user: User }) { }
```

**Why:** Reusability and discoverability.
```

## Pattern Examples

### Error Handling

```typescript
try {
  const result = await operation();
  toast.success('Operation completed');
  return result;
} catch (error) {
  const message = error instanceof Error ? error.message : 'Unknown error';
  toast.error(message);
  throw error; // Re-throw for caller to handle
}
```

### API Route Structure

```typescript
// app/api/users/route.ts
export async function GET(request: Request) {
  try {
    // 1. Parse/validate input
    // 2. Check auth/permissions
    // 3. Perform operation
    // 4. Return Response
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Message' }), {
      status: 500
    });
  }
}
```

### Concrete vs Vague Guidance

**❌ BAD - Vague:**
```markdown
Use proper error handling in API routes.
```

**✅ GOOD - Concrete:**
```markdown
API routes must use try/catch with typed errors. Example:
```typescript
// app/api/users/route.ts (lines 10-25)
export async function POST(request: Request) {
  try {
    const data = await request.json();
    return Response.json({ success: true });
  } catch (error) {
    return handleApiError(error); // See lib/errors.ts
  }
}
```
See `app/api/products/route.ts` for complete implementation.
```

## Common Tasks

### Adding a New API Route

1. Create `app/api/[route]/route.ts`
2. Define HTTP method exports (GET, POST, etc.)
3. Validate input with Zod schema
4. Use try/catch for error handling
5. Return `Response` object

```typescript
import { z } from 'zod';

const schema = z.object({
  name: z.string().min(1)
});

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const data = schema.parse(body);

    // Process...

    return Response.json({ success: true });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return Response.json(
        { error: error.errors },
        { status: 400 }
      );
    }
    return Response.json(
      { error: 'Internal error' },
      { status: 500 }
    );
  }
}
```

## Real-World Reference

The PRPM registry `.cursor/rules` demonstrates:
- Clear tech stack declaration (Fastify, TypeScript, PostgreSQL)
- Specific TypeScript patterns
- Fastify-specific conventions
- Error handling standards
- API route patterns
- Database query patterns

In this repo, see `.cursor/rules/react-native.mdc` for the always-applied project conventions pattern.
