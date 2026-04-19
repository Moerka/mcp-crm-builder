---
name: mcp-crm-builder
description: Build production-ready MCP server showcase websites with React + tRPC + Tailwind. Use when creating custom MCP server documentation sites, API explorers, or integration showcases that need authentication, live dashboards, and professional design.
---

# MCP CRM Builder

## Overview

This skill enables rapid creation of professional MCP (Model Context Protocol) server showcase websites. It provides a complete, production-ready template combining React 19, tRPC 11, Express 4, and Tailwind CSS 4 with built-in Manus OAuth authentication, database integration, and a dark glass-morphism design system.

Use this skill when you need to:
- Build a website showcasing a custom MCP server
- Create an API explorer or integration dashboard
- Document server capabilities with live examples
- Demonstrate authentication flows and role-based access
- Deploy a full-stack web application with minimal setup

## Core Capabilities

### 1. Full-Stack Web Application Template
A production-ready scaffold with React frontend and Express backend pre-configured with tRPC type-safe RPC layer. Includes OAuth authentication, database integration, and deployment-ready build process.

### 2. Database Integration
Drizzle ORM with MySQL/TiDB support. Define schemas, auto-generate migrations, and access type-safe query helpers. Includes user management table and authentication context.

### 3. Authentication & Authorization
Manus OAuth built-in. Automatic session management, protected procedures, role-based access control (admin/user), and secure cookie handling.

### 4. Design System
Dark glass-morphism theme with indigo/emerald/amber accents. Pre-built shadcn/ui components, Tailwind utilities, and consistent typography (Space Grotesk + Fira Code + Inter).

### 5. API Explorer & Live Dashboards
Interactive request builder for testing endpoints. Real-time metrics display, status monitoring, and live data visualization with Recharts.

### 6. Storage Integration
S3-compatible file storage with automatic presigned URLs. Upload files from frontend, store metadata in database, retrieve via `/manus-storage/` proxy.

## Quick Start

### Prerequisites
- Manus account with webdev project capability
- Basic familiarity with React, TypeScript, and SQL

### Step 1: Initialize Project
Create a new Manus webdev project with database and server features enabled. This skill assumes you're starting with the tRPC + Manus Auth + Database template.

### Step 2: Customize the Home Page
Edit `client/src/pages/Home.tsx` to showcase your MCP server:
- Replace hero section with your server name and description
- Update API tools list with your actual endpoints
- Modify use cases to match your domain
- Customize colors in `client/src/index.css` if desired

### Step 3: Define Your Data Model
Edit `drizzle/schema.ts` to add tables for your domain:
```typescript
export const customers = sqliteTable('customers', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  email: text('email').notNull(),
  notes: text('notes'),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
});
```

Run `pnpm db:push` to migrate.

### Step 4: Create Backend Procedures
Add tRPC procedures in `server/routers.ts`:
```typescript
export const appRouter = router({
  customers: {
    list: protectedProcedure
      .query(async ({ ctx }) => {
        return db.getCustomers(ctx.user.id);
      }),
    create: protectedProcedure
      .input(z.object({ name: z.string(), email: z.string().email() }))
      .mutation(async ({ ctx, input }) => {
        return db.createCustomer(ctx.user.id, input);
      }),
  },
});
```

### Step 5: Build Frontend UI
Create pages in `client/src/pages/` using shadcn/ui components:
```typescript
import { trpc } from "@/lib/trpc";
import { Button } from "@/components/ui/button";

export default function CustomersPage() {
  const { data, isLoading } = trpc.customers.list.useQuery();
  const createMutation = trpc.customers.create.useMutation();

  return (
    <div>
      {data?.map(c => <div key={c.id}>{c.name}</div>)}
      <Button onClick={() => createMutation.mutate({ name: "New", email: "test@example.com" })}>
        Add Customer
      </Button>
    </div>
  );
}
```

### Step 6: Deploy
Save a checkpoint and click Publish in the Manus UI. Your site is live at the generated domain.

## Project Structure

```
mcp-crm-website/
├── client/src/
│   ├── pages/              # Page components (Home, Dashboard, etc.)
│   ├── components/         # Reusable UI components
│   │   └── ui/            # shadcn/ui components
│   ├── contexts/          # React contexts (Theme, Auth)
│   ├── _core/hooks/       # Custom hooks (useAuth)
│   ├── lib/trpc.ts        # tRPC client config
│   └── index.css          # Global Tailwind + design tokens
├── server/
│   ├── routers.ts         # tRPC procedures (EDIT HERE)
│   ├── db.ts              # Database query helpers
│   ├── storage.ts         # S3 storage helpers
│   └── _core/             # Framework infrastructure (DO NOT EDIT)
├── drizzle/
│   ├── schema.ts          # Database tables (EDIT HERE)
│   └── migrations/        # Auto-generated migrations
└── shared/
    ├── const.ts           # Shared constants
    └── types.ts           # Shared TypeScript types
```

**Files to edit**: `Home.tsx`, `server/routers.ts`, `drizzle/schema.ts`, `client/src/index.css`

**Files to avoid**: Anything in `server/_core/`, `shared/_core/`, or `client/src/_core/`

## Design System

### Color Palette
- **Background**: `#0F1117` (slate)
- **Card Surface**: `#161B27` (elevated slate)
- **Primary**: `#6366F1` (indigo) — buttons, highlights
- **Success**: `#10B981` (emerald) — live status, checkmarks
- **Warning**: `#F59E0B` (amber) — cautions, secondary actions

Customize in `client/src/index.css` using CSS variables.

### Typography
- **Headings**: Space Grotesk (bold, tight letter-spacing)
- **Code**: Fira Code (monospace, technical labels)
- **Body**: Inter (regular, relaxed line-height)

### Components
Use shadcn/ui components from `client/src/components/ui/`:
- `Button`, `Card`, `Dialog`, `Form`, `Input`, `Select`, `Table`
- All pre-styled with Tailwind and theme variables

## Common Workflows

### Adding a New Feature

1. **Define schema** in `drizzle/schema.ts`
2. **Run migration**: `pnpm db:push`
3. **Add query helpers** in `server/db.ts`
4. **Create procedures** in `server/routers.ts`
5. **Write tests** in `server/*.test.ts` (Vitest)
6. **Build UI** in `client/src/pages/` or `client/src/components/`
7. **Call via tRPC**: `trpc.feature.useQuery()` / `useMutation()`

### Handling Authentication

```typescript
import { useAuth } from "@/_core/hooks/useAuth";

export default function Dashboard() {
  const { user, isAuthenticated, logout } = useAuth();

  if (!isAuthenticated) {
    return <LoginPrompt />;
  }

  return (
    <div>
      Welcome, {user.name}!
      <button onClick={logout}>Logout</button>
    </div>
  );
}
```

### Uploading Files

```typescript
import { storagePut } from "@/server/storage";

// In a tRPC procedure
const { key, url } = await storagePut(
  `uploads/${userId}/document.pdf`,
  fileBuffer,
  "application/pdf"
);

// Save url to database
await db.saveDocument(userId, { url, key });
```

### Optimistic UI Updates

```typescript
const utils = trpc.useUtils();
const mutation = trpc.customers.update.useMutation({
  onMutate: async (newData) => {
    await utils.customers.list.cancel();
    const prev = utils.customers.list.getData();
    utils.customers.list.setData(undefined, (old) => ({
      ...old,
      customers: old.customers.map(c =>
        c.id === newData.id ? newData : c
      ),
    }));
    return { prev };
  },
  onError: (err, newData, ctx) => {
    utils.customers.list.setData(undefined, ctx.prev);
  },
});
```

## Development Commands

```bash
pnpm install          # Install dependencies
pnpm dev              # Start dev server (Vite + Express)
pnpm test             # Run Vitest suite
pnpm check            # TypeScript type check
pnpm format           # Format with Prettier
pnpm db:push          # Generate and apply migrations
pnpm build            # Build for production
pnpm start            # Run production server
```

## Best Practices

### Frontend
- Use tRPC hooks for all backend calls (no Axios/fetch)
- Implement optimistic updates for instant feedback
- Handle loading/error/empty states in every component
- Leverage shadcn/ui components for consistency
- Keep components under 300 lines
- Use CSS variables from `index.css` for theming

### Backend
- Define query helpers in `server/db.ts` for reusability
- Use `protectedProcedure` for auth-required endpoints
- Validate inputs with Zod schemas
- Return raw Drizzle rows (superjson handles serialization)
- Write tests for critical procedures
- Log errors for production debugging

### Database
- Schema-first: edit schema → migrate → write queries
- Never manually alter production schema
- Index frequently-queried columns
- Store metadata in database, file bytes in S3

## Troubleshooting

| Issue | Solution |
|-------|----------|
| TypeScript errors | Run `pnpm check` and fix type issues |
| Database migration fails | Verify `DATABASE_URL` and schema syntax |
| tRPC hooks not working | Check `trpc.Provider` wraps app in `main.tsx` |
| Tailwind styles missing | Verify `index.css` design tokens are loaded |
| OAuth login fails | Ensure `window.location.origin` is used (not hardcoded) |
| Images not loading | Use `manus-upload-file --webdev` and reference returned URL |

## Environment Variables

System-injected (do not edit):
- `DATABASE_URL` — MySQL/TiDB connection
- `JWT_SECRET` — Session cookie signing
- `VITE_APP_ID`, `OAUTH_SERVER_URL`, `VITE_OAUTH_PORTAL_URL` — OAuth config
- `BUILT_IN_FORGE_API_URL`, `BUILT_IN_FORGE_API_KEY` — Manus APIs

Add custom secrets via `webdev_request_secrets` tool.

## Resources

This skill includes:

### scripts/
- `init_project.sh` — Scaffolding checklist
- `customize_design.py` — Color palette generator

### references/
- `ARCHITECTURE.md` — Detailed project structure
- `PATTERNS.md` — Common implementation patterns
- `DEPLOYMENT.md` — Production deployment guide

### templates/
- `home-page-template.tsx` — Customizable hero section
- `dashboard-template.tsx` — Dashboard layout example
- `api-explorer-template.tsx` — Interactive API tester

## Next Steps

1. Read `references/ARCHITECTURE.md` for deep dive into project structure
2. Review `references/PATTERNS.md` for common implementation patterns
3. Check `templates/` for example components to customize
4. Start with Step 1 of Quick Start above
5. Refer to this skill as you build features

## Support

For issues or questions:
- Check Troubleshooting section above
- Review `references/DEPLOYMENT.md` for deployment issues
- Consult Manus webdev documentation for framework-specific questions
