# MCP CRM Builder — Architecture Reference

## Project Structure Deep Dive

### Frontend (`client/src/`)

```
client/src/
├── pages/                    # Page-level components
│   ├── Home.tsx             # Landing page (CUSTOMIZE THIS)
│   └── NotFound.tsx         # 404 page
├── components/
│   ├── ui/                  # shadcn/ui components (auto-generated)
│   ├── DashboardLayout.tsx  # Pre-built dashboard with sidebar
│   ├── AIChatBox.tsx        # Pre-built chat interface
│   ├── Map.tsx              # Google Maps integration
│   ├── ErrorBoundary.tsx    # Error handling wrapper
│   └── ManusDialog.tsx      # Manus branding dialog
├── contexts/
│   └── ThemeContext.tsx     # Dark/light theme provider
├── _core/hooks/
│   └── useAuth.ts           # Authentication hook
├── lib/
│   └── trpc.ts              # tRPC client initialization
├── App.tsx                  # Routes & layout wrapper
├── main.tsx                 # React providers & entry
└── index.css                # Global Tailwind + design tokens
```

**Key Points:**
- `pages/` contains route-level components
- `components/ui/` is auto-generated from shadcn/ui
- `_core/` contains framework infrastructure (do not edit)
- `index.css` defines color palette and design tokens

### Backend (`server/`)

```
server/
├── routers.ts               # tRPC procedure definitions (EDIT THIS)
├── db.ts                    # Database query helpers (EDIT THIS)
├── storage.ts               # S3 storage helpers
├── index.ts                 # Server initialization
├── auth.logout.test.ts      # Example Vitest test
└── _core/                   # Framework infrastructure (DO NOT EDIT)
    ├── index.ts             # Express app setup
    ├── context.ts           # tRPC context builder
    ├── oauth.ts             # Manus OAuth flow
    ├── cookies.ts           # Session management
    ├── llm.ts               # LLM integration
    ├── imageGeneration.ts   # Image generation
    ├── voiceTranscription.ts # Audio transcription
    ├── map.ts               # Google Maps backend
    ├── notification.ts      # Owner notifications
    ├── storageProxy.ts      # S3 proxy
    ├── dataApi.ts           # Data API integration
    ├── systemRouter.ts      # System procedures
    ├── env.ts               # Environment variables
    └── trpc.ts              # tRPC initialization
```

**Key Points:**
- `routers.ts` is where you define tRPC procedures
- `db.ts` contains query helpers (reused by procedures)
- `_core/` is framework-level (do not modify)
- Tests go in `*.test.ts` files using Vitest

### Database (`drizzle/`)

```
drizzle/
├── schema.ts                # Table definitions (EDIT THIS)
├── relations.ts             # ORM relationships
├── migrations/              # Auto-generated SQL files
└── meta/                    # Migration metadata
```

**Key Points:**
- Edit `schema.ts` to define tables
- Run `pnpm db:push` to generate and apply migrations
- Never manually edit migration files
- Relationships defined in `relations.ts`

### Shared (`shared/`)

```
shared/
├── const.ts                 # Shared constants (edit as needed)
├── types.ts                 # Shared TypeScript types
└── _core/                   # Framework types (do not edit)
```

## Data Flow Architecture

### Request Flow (Frontend → Backend)

```
User Action (click, form submit)
    ↓
React Component
    ↓
Call tRPC hook: trpc.feature.useQuery() or useMutation()
    ↓
tRPC Client (in lib/trpc.ts)
    ↓
HTTP POST to /api/trpc
    ↓
Express Server (server/_core/index.ts)
    ↓
tRPC Router (server/routers.ts)
    ↓
Middleware: auth check, input validation
    ↓
Procedure Handler
    ↓
Database Query (via server/db.ts)
    ↓
Response (serialized with superjson)
    ↓
HTTP Response
    ↓
React Query Cache Update
    ↓
Component Re-render
```

### Authentication Flow

```
User clicks "Login"
    ↓
Redirected to getLoginUrl() (Manus OAuth portal)
    ↓
User authenticates with Manus
    ↓
Redirected to /api/oauth/callback
    ↓
OAuth handler exchanges code for user info
    ↓
Session cookie created (signed with JWT_SECRET)
    ↓
Redirected back to app
    ↓
Subsequent requests include session cookie
    ↓
tRPC context reads cookie → ctx.user
    ↓
Protected procedures access ctx.user
```

### Database Workflow

```
Edit drizzle/schema.ts
    ↓
Run: pnpm db:push
    ↓
drizzle-kit generates migration SQL
    ↓
Migration applied to remote database
    ↓
Add query helper in server/db.ts
    ↓
Create tRPC procedure in server/routers.ts
    ↓
Call from frontend via trpc hook
```

## tRPC Procedure Patterns

### Public Procedure

```typescript
export const appRouter = router({
  health: publicProcedure
    .query(async () => {
      return { status: "ok" };
    }),
});
```

### Protected Procedure

```typescript
export const appRouter = router({
  me: protectedProcedure
    .query(async ({ ctx }) => {
      return ctx.user;
    }),
});
```

### Procedure with Input Validation

```typescript
export const appRouter = router({
  customers: {
    create: protectedProcedure
      .input(z.object({
        name: z.string().min(1),
        email: z.string().email(),
      }))
      .mutation(async ({ ctx, input }) => {
        return db.createCustomer(ctx.user.id, input);
      }),
  },
});
```

### Procedure with Error Handling

```typescript
import { TRPCError } from "@trpc/server";

export const appRouter = router({
  customers: {
    get: protectedProcedure
      .input(z.object({ id: z.string() }))
      .query(async ({ ctx, input }) => {
        const customer = await db.getCustomerById(input.id);
        if (!customer) {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "Customer not found",
          });
        }
        return customer;
      }),
  },
});
```

## Database Query Patterns

### Simple Query

```typescript
import { db } from "./db";
import { customers } from "@/drizzle/schema";

export async function getCustomers(userId: string) {
  return db
    .select()
    .from(customers)
    .where(eq(customers.userId, userId));
}
```

### Query with Filtering

```typescript
export async function searchCustomers(userId: string, query: string) {
  return db
    .select()
    .from(customers)
    .where(
      and(
        eq(customers.userId, userId),
        or(
          ilike(customers.name, `%${query}%`),
          ilike(customers.email, `%${query}%`)
        )
      )
    );
}
```

### Insert with Returning

```typescript
export async function createCustomer(userId: string, data: { name: string; email: string }) {
  const [result] = await db
    .insert(customers)
    .values({
      id: nanoid(),
      userId,
      ...data,
      createdAt: new Date(),
    })
    .returning();
  return result;
}
```

### Update with Validation

```typescript
export async function updateCustomer(userId: string, id: string, data: Partial<typeof customers.$inferInsert>) {
  const [result] = await db
    .update(customers)
    .set({ ...data, updatedAt: new Date() })
    .where(
      and(
        eq(customers.id, id),
        eq(customers.userId, userId)
      )
    )
    .returning();
  return result;
}
```

## Frontend Component Patterns

### Using tRPC Query

```typescript
import { trpc } from "@/lib/trpc";

export default function CustomersList() {
  const { data, isLoading, error } = trpc.customers.list.useQuery();

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;
  if (!data?.length) return <div>No customers</div>;

  return (
    <div>
      {data.map(customer => (
        <div key={customer.id}>{customer.name}</div>
      ))}
    </div>
  );
}
```

### Using tRPC Mutation

```typescript
import { trpc } from "@/lib/trpc";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";

export default function CreateCustomer() {
  const mutation = trpc.customers.create.useMutation({
    onSuccess: () => {
      toast.success("Customer created!");
    },
    onError: (error) => {
      toast.error(error.message);
    },
  });

  return (
    <Button
      onClick={() => mutation.mutate({ name: "John", email: "john@example.com" })}
      disabled={mutation.isPending}
    >
      {mutation.isPending ? "Creating..." : "Create"}
    </Button>
  );
}
```

### Optimistic Update Pattern

```typescript
export default function UpdateCustomer({ customer }) {
  const utils = trpc.useUtils();
  const mutation = trpc.customers.update.useMutation({
    onMutate: async (newData) => {
      // Cancel ongoing queries
      await utils.customers.list.cancel();

      // Snapshot old data
      const prev = utils.customers.list.getData();

      // Optimistically update cache
      utils.customers.list.setData(undefined, (old) => ({
        ...old,
        customers: old.customers.map(c =>
          c.id === newData.id ? { ...c, ...newData } : c
        ),
      }));

      return { prev };
    },
    onError: (err, newData, ctx) => {
      // Rollback on error
      if (ctx?.prev) {
        utils.customers.list.setData(undefined, ctx.prev);
      }
    },
    onSettled: () => {
      // Refetch after mutation settles
      utils.customers.list.invalidate();
    },
  });

  return (
    <Button onClick={() => mutation.mutate({ id: customer.id, name: "Updated" })}>
      Update
    </Button>
  );
}
```

## Design Token System

### Colors (in `client/src/index.css`)

```css
@layer base {
  :root {
    --background: 15 15 23;      /* #0F0F17 */
    --foreground: 255 255 255;   /* #FFFFFF */
    --card: 22 27 53;            /* #161B35 */
    --card-foreground: 255 255 255;
    --primary: 99 102 241;       /* #6366F1 (Indigo) */
    --primary-foreground: 255 255 255;
    --accent: 16 185 129;        /* #10B981 (Emerald) */
    --accent-foreground: 255 255 255;
    --muted: 255 255 255 / 0.5;
    --muted-foreground: 255 255 255 / 0.7;
  }

  .dark {
    /* Same as :root for dark theme */
  }
}
```

### Using Design Tokens

```tsx
// Background
<div className="bg-background text-foreground">

// Cards
<div className="bg-card text-card-foreground">

// Primary action
<button className="bg-primary text-primary-foreground">

// Accent
<div className="bg-accent text-accent-foreground">

// Muted text
<p className="text-muted-foreground">
```

## Testing Patterns

### Basic Test

```typescript
import { describe, it, expect } from "vitest";
import { db } from "./db";

describe("customers", () => {
  it("should create a customer", async () => {
    const customer = await db.createCustomer("user-1", {
      name: "John",
      email: "john@example.com",
    });

    expect(customer.name).toBe("John");
    expect(customer.email).toBe("john@example.com");
  });
});
```

### Test with Mocking

```typescript
import { describe, it, expect, vi } from "vitest";
import { trpc } from "@/lib/trpc";

describe("auth", () => {
  it("should logout user", async () => {
    const mockFetch = vi.fn();
    global.fetch = mockFetch;

    await trpc.auth.logout.useMutation().mutateAsync();

    expect(mockFetch).toHaveBeenCalledWith(
      expect.stringContaining("/api/trpc"),
      expect.any(Object)
    );
  });
});
```

## Storage Integration

### Upload File

```typescript
import { storagePut } from "@/server/storage";

const { key, url } = await storagePut(
  `uploads/${userId}/document.pdf`,
  fileBuffer,
  "application/pdf"
);

// Save to database
await db.saveDocument(userId, { url, key, fileName: "document.pdf" });
```

### Retrieve File

```typescript
import { storageGet } from "@/server/storage";

const { url } = await storageGet(`uploads/${userId}/document.pdf`);
// url is a presigned URL valid for 1 hour
```

### Frontend Upload

```typescript
export default function UploadForm() {
  const mutation = trpc.documents.upload.useMutation();

  const handleUpload = async (file: File) => {
    const buffer = await file.arrayBuffer();
    mutation.mutate({ fileName: file.name, buffer });
  };

  return (
    <input
      type="file"
      onChange={(e) => handleUpload(e.target.files[0])}
    />
  );
}
```

## Environment Variables

### System-Injected

```
DATABASE_URL              # MySQL connection string
JWT_SECRET                # Session signing secret
VITE_APP_ID               # OAuth app ID
OAUTH_SERVER_URL          # OAuth backend URL
VITE_OAUTH_PORTAL_URL     # OAuth login portal
OWNER_OPEN_ID             # Owner's user ID
OWNER_NAME                # Owner's display name
BUILT_IN_FORGE_API_URL    # Manus APIs URL
BUILT_IN_FORGE_API_KEY    # Manus API key (server-side)
VITE_FRONTEND_FORGE_API_KEY  # Frontend API key
VITE_FRONTEND_FORGE_API_URL  # Frontend APIs URL
```

### Custom Secrets

Add via `webdev_request_secrets` tool. They are injected into `process.env`.

```typescript
// In server code
const apiKey = process.env.MY_CUSTOM_API_KEY;

// In frontend code (if prefixed with VITE_)
const apiKey = import.meta.env.VITE_MY_CUSTOM_API_KEY;
```

## Build & Deployment

### Development

```bash
pnpm dev      # Starts Vite + Express with HMR
```

### Production Build

```bash
pnpm build    # Builds frontend + backend
pnpm start    # Runs production server
```

### Database Migrations

```bash
pnpm db:push  # Generates and applies migrations
```

### Deployment Checklist

- [ ] All environment variables set
- [ ] Database migrations applied
- [ ] Tests passing (`pnpm test`)
- [ ] TypeScript checks passing (`pnpm check`)
- [ ] Static assets uploaded via `manus-upload-file --webdev`
- [ ] Checkpoint created
- [ ] Published via Manus UI
