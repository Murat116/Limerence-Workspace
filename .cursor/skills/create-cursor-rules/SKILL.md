---
name: create-cursor-rules
description: Creates and improves .cursor/rules MDC files with frontmatter, rule types, and project-specific conventions. Use when starting a new project rules setup, improving existing rules, converting skills/guidelines to Cursor format, or when the user asks about .cursor/rules/, rule types, globs, or alwaysApply.
disable-model-invocation: true
---

# Creating Cursor Rules

You are an expert at creating effective `.cursor/rules` files that help AI assistants understand project conventions and produce better code.

## When to Apply This Skill

**Use when:**
- User is starting a new project and needs `.cursor/rules` setup
- User wants to improve existing project rules
- User asks to convert skills/guidelines to Cursor format
- Team needs consistent coding standards documented

**Don't use for:**
- One-time instructions (those can be asked directly)
- User-specific preferences (those go in global settings)
- Claude Code skills (this skill is specifically for Cursor rules)

## Workflow

1. **Discover** — ask about tech stack, patterns to enforce, mistakes AI currently makes
2. **Design** — pick rule type(s), globs, split by concern if needed
3. **Write** — create `.mdc` files with valid frontmatter and concrete examples
4. **Validate** — test by asking AI to generate code following the new rules

Use AskQuestion when available to gather scope and file patterns efficiently.

## Core Principles

### 1. Be Specific and Actionable

Rules should provide concrete guidance, not vague advice.

**❌ BAD - Vague:**
```markdown
Write clean code with good practices.
Use proper TypeScript types.
```

**✅ GOOD - Specific:**
```markdown
Use functional components with TypeScript.
Define prop types with interfaces, not inline types.
Extract custom hooks when logic exceeds 10 lines.
```

### 2. Focus on Decisions, Not Basics

Don't document what linters handle. Document architectural decisions.

**❌ BAD - Linter territory:**
```markdown
Use semicolons in JavaScript.
Indent with 2 spaces.
Add trailing commas.
```

**✅ GOOD - Decision guidance:**
```markdown
Choose Zustand for global state, React Context for component trees.
Use Zod for runtime validation at API boundaries only.
Prefer server components except for: forms, client-only APIs, animations.
```

### 3. Organize by Concern

Group related rules into clear sections:

```markdown
## Tech Stack
- Next.js 14 with App Router
- TypeScript strict mode
- Tailwind CSS for styling

## Code Style
- Functional components only
- Named exports (no default exports)
- Co-locate tests with source files

## Patterns
- Use React Server Components by default
- Client components: mark with "use client" directive
- Error handling: try/catch + toast notification

## Project Conventions
- API routes in app/api/
- Components in components/ (flat structure)
- Types in types/ (shared), components/*/types.ts (local)
```

## Rule Anatomy

### MDC Format and Metadata

Cursor rules are written in **MDC (.mdc)** format, which supports YAML frontmatter metadata and markdown content. The metadata controls how and when rules are applied.

### Required YAML Frontmatter

Every Cursor rule MUST start with YAML frontmatter between `---` markers:

```yaml
---
description: Brief description of when and how to use this rule
globs: ["**/*.ts", "**/*.tsx"]
alwaysApply: false
---
```

### Frontmatter Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `description` | string | **Yes** | Brief description of the rule's purpose. Used by AI to decide relevance. Never use placeholders like `---` or empty strings. |
| `globs` | array | No | File patterns that trigger auto-attachment (e.g., `["**/*.ts"]`). Leave empty or omit if not using Auto Attached type. |
| `alwaysApply` | boolean | No | If `true`, rule is always included in context. If `false` or omitted, behavior depends on Rule Type. |

### Rule Types

Control how rules are applied using the **type dropdown** in Cursor:

| Rule Type | Description | When to Use |
|-----------|-------------|-------------|
| **Always** | Always included in model context | Core project conventions, tech stack, universal patterns that apply everywhere |
| **Auto Attached** | Included when files matching `globs` pattern are referenced | File-type specific rules (e.g., React components, API routes, test files) |
| **Agent Requested** | Available to AI, which decides whether to include it based on `description` | Contextual patterns, specialized workflows, optional conventions |
| **Manual** | Only included when explicitly mentioned using `@ruleName` | Rarely-used patterns, experimental conventions, legacy documentation |

### Examples by Rule Type

**Always Rule** (Core conventions):
```yaml
---
description: TypeScript and code style conventions for the entire project
alwaysApply: true
---
```

**Auto Attached Rule** (File pattern-specific):
```yaml
---
description: React component patterns and conventions
globs: ["**/components/**/*.tsx", "**/app/**/*.tsx"]
alwaysApply: false
---
```

**Agent Requested Rule** (Contextual):
```yaml
---
description: RPC service boilerplate and patterns for creating new RPC endpoints
globs: []
alwaysApply: false
---
```

**Manual Rule** (Explicit invocation):
```yaml
---
description: Legacy API migration patterns (deprecated, use for reference only)
globs: []
alwaysApply: false
---
```

### Best Practices for Frontmatter

1. **Description is mandatory** - AI uses this to determine relevance. Be specific:
   - ❌ Bad: `Backend code`
   - ✅ Good: `Fastify API route patterns, error handling, and validation using Zod`

2. **Use globs strategically** - Auto-attach to relevant file types:
   - React components: `["**/*.tsx", "**/*.jsx"]`
   - API routes: `["**/api/**/*.ts", "**/routes/**/*.ts"]`
   - Tests: `["**/*.test.ts", "**/*.spec.ts"]`

3. **Avoid always applying everything** - Use `alwaysApply: true` sparingly:
   - ✅ Good for: Tech stack, core conventions, project structure
   - ❌ Bad for: Framework-specific patterns, specialized workflows

4. **Make Agent Requested rules discoverable** - Write descriptions that help AI understand when to use:
   - Include keywords: "boilerplate", "template", "pattern for X"
   - Mention specific use cases: "when creating new API routes"

## Required Sections

Every Cursor rule file should include these sections:

### 1. Tech Stack Declaration

```markdown
## Tech Stack
- Framework: Next.js 14
- Language: TypeScript 5.x (strict mode)
- Styling: Tailwind CSS 3.x
- State: Zustand
- Database: PostgreSQL + Prisma
- Testing: Vitest + Playwright
```

**Why:** Prevents AI from suggesting wrong tools/patterns.

### 2. Code Style Guidelines

```markdown
## Code Style
- **Components**: Functional with TypeScript
- **Props**: Interface definitions, destructure in params
- **Hooks**: Extract when logic > 10 lines
- **Exports**: Named exports only (no default)
- **File naming**: kebab-case.tsx
```

### 3. Common Patterns

Always include code examples, not just descriptions. See [examples.md](examples.md) for full pattern templates.

## What NOT to Include

Avoid these common mistakes:

**❌ Too obvious:**
```markdown
- Write readable code
- Use meaningful variable names
- Add comments when necessary
- Follow best practices
```

**❌ Too restrictive:**
```markdown
- Never use any third-party libraries
- Always write everything from scratch
- Every function must be under 5 lines
```

**❌ Language-agnostic advice:**
```markdown
- Use design patterns
- Think before you code
- Test your code
- Keep it simple
```

## Structure Template

Use this template for new Cursor rules. Full template with Common Tasks: [examples.md](examples.md).

```markdown
# Project Name - Cursor Rules

## Tech Stack
[List all major technologies with versions]

## Code Style
[Specific style decisions]

## Project Structure
[Directory organization]

## Patterns
[Common patterns with code examples]

### Pattern Name
[Description + code example]

## Conventions
[Project-specific conventions]

## Common Tasks
[Frequent operations with step-by-step snippets]

## Anti-Patterns
[What to avoid and why]

## Testing
[Testing approach and patterns with examples]
```

## Best Practices

### Keep Rules Under 500 Lines

- Split large rules into multiple, composable files
- Each rule file should focus on one domain or concern
- Reference other rule files when needed (e.g., "See `backend-api.mdc` for API patterns")
- **Why:** Large files become unmanageable and harder for AI to process effectively

### Split Into Composable Rules

```
.cursor/rules/
  ├── tech-stack.mdc          # Core technologies
  ├── typescript-patterns.mdc # Language-specific patterns
  ├── api-conventions.mdc     # API route standards
  ├── component-patterns.mdc  # React/UI patterns
  └── testing-standards.mdc   # Testing approaches
```

### Provide Concrete Examples or Referenced Files

Instead of vague guidance, always include:
- Complete, runnable code examples
- References to actual project files: `See components/auth/LoginForm.tsx for example`
- Links to internal docs or design system
- Specific file paths and line numbers when relevant

### Write Rules Like Clear Internal Docs

Rules should read like technical documentation, not casual advice:
- Be precise and unambiguous
- Include the "why" behind decisions
- Document exceptions to rules
- Reference architecture decisions
- Link to related rules or documentation

**Think:** "Could a new engineer understand this without asking questions?"

### Reuse Rules When Repeating Prompts

If you find yourself giving the same instructions repeatedly in chat:
1. Document that pattern in `.cursor/rules/`
2. Include the specific guidance you keep repeating
3. Add examples of correct implementation
4. Update existing rule files rather than creating new ones

### Keep It Scannable

- Use clear section headers
- Bold important terms
- Include code examples (not just prose)
- Use tables for comparisons
- Add table of contents for files over 200 lines

### Update Regularly

- Review monthly or after major changes
- Remove outdated patterns
- Add new patterns as they emerge
- Keep examples current with latest framework versions
- Archive deprecated rules rather than deleting (for reference)

### Test with AI

After creating rules, test them:

1. Ask AI: "Create a new API route following our conventions"
2. Ask AI: "Add error handling to this component"
3. Ask AI: "Refactor this to match our patterns"

Verify AI follows rules correctly. Update rules based on gaps found.

## This Project

Existing rule to reference or extend: `.cursor/rules/react-native.mdc` (alwaysApply, project architecture and RN conventions).

When improving it, fix empty `description` and `globs` in frontmatter — both are required for Agent Requested / Auto Attached behavior.

## Checklist for New Cursor Rules

**Project Context:**
- [ ] Tech stack clearly defined with versions
- [ ] Key dependencies listed
- [ ] Deployment platform specified

**Code Style:**
- [ ] Component style specified (functional/class)
- [ ] Export style (named/default)
- [ ] File naming convention
- [ ] Specific to project (not generic advice)

**Patterns:**
- [ ] At least 3-5 code examples
- [ ] Cover most common tasks
- [ ] Include error handling pattern
- [ ] Show project-specific conventions

**Organization:**
- [ ] Logical section headers
- [ ] Scannable (not wall of text)
- [ ] Examples are complete and runnable
- [ ] Anti-patterns included with rationale

**Testing:**
- [ ] Tested with AI assistant
- [ ] AI follows conventions correctly
- [ ] Updated after catching mistakes

## Helpful Prompts for Users

**Discovery:**
- "What's your tech stack?"
- "What patterns do you want AI to follow?"
- "What mistakes does AI currently make?"

**Refinement:**
- "Are there anti-patterns you want documented?"
- "What are your most common coding tasks?"
- "Do you have naming conventions?"

**Validation:**
- "Let me test these rules by asking you to generate code..."
- "Does this match your team's style?"

## Remember

- Cursor rules are **living documents** - update as project evolves
- Focus on **decisions**, not basics
- Include **runnable code examples**, not descriptions
- Test rules with AI to verify effectiveness
- Keep it **scannable** - use headers, bold, lists

**Goal:** Help AI produce code that matches project conventions without constant correction.

## Additional Resources

- Detailed examples, anti-patterns, and common tasks: [examples.md](examples.md)
