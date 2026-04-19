# Common Implementation Patterns

## Feature Implementation Checklist

When adding a new feature, follow this sequence:

### 1. Database Schema
```typescript
// drizzle/schema.ts
export const myFeature = sqliteTable('my_feature', {
  id: text('id').primaryKey(),
  userId: text('user_id').notNull(),
  title: text('title').notNull(),
  description: text('description'),
  status: text('status').default('pending'),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
  updatedAt: integer('updated_at', { mode: 'timestamp' }).notNull(),
});
```

Run: `pnpm db:push`

### 2. Query Helpers
```typescript
// server/db.ts
import { myFeature } from '@/drizzle/schema';

export async function getFeatures(userId: string) {
  return db.select().from(myFeature).where(eq(myFeature.userId, userId));
}

export async function createFeature(userId: string, data: { title: string; description?: string }) {
  const [result] = await db
    .insert(myFeature)
    .values({
      id: nanoid(),
      userId,
      ...data,
      createdAt: new Date(),
      updatedAt: new Date(),
    })
    .returning();
  return result;
}

export async function updateFeature(userId: string, id: string, data: Partial<typeof myFeature.$inferInsert>) {
  const [result] = await db
    .update(myFeature)
    .set({ ...data, updatedAt: new Date() })
    .where(and(eq(myFeature.id, id), eq(myFeature.userId, userId)))
    .returning();
  return result;
}

export async function deleteFeature(userId: string, id: string) {
  return db.delete(myFeature).where(and(eq(myFeature.id, id), eq(myFeature.userId, userId)));
}
```

### 3. tRPC Procedures
```typescript
// server/routers.ts
export const appRouter = router({
  myFeature: {
    list: protectedProcedure
      .query(async ({ ctx }) => {
        return db.getFeatures(ctx.user.id);
      }),

    create: protectedProcedure
      .input(z.object({
        title: z.string().min(1),
        description: z.string().optional(),
      }))
      .mutation(async ({ ctx, input }) => {
        return db.createFeature(ctx.user.id, input);
      }),

    update: protectedProcedure
      .input(z.object({
        id: z.string(),
        title: z.string().optional(),
        description: z.string().optional(),
        status: z.enum(['pending', 'in-progress', 'done']).optional(),
      }))
      .mutation(async ({ ctx, input }) => {
        const { id, ...data } = input;
        return db.updateFeature(ctx.user.id, id, data);
      }),

    delete: protectedProcedure
      .input(z.object({ id: z.string() }))
      .mutation(async ({ ctx, input }) => {
        return db.deleteFeature(ctx.user.id, input.id);
      }),
  },
});
```

### 4. Frontend Component
```typescript
// client/src/pages/MyFeature.tsx
import { trpc } from "@/lib/trpc";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { toast } from "sonner";

export default function MyFeaturePage() {
  const utils = trpc.useUtils();
  const { data: features, isLoading } = trpc.myFeature.list.useQuery();
  const createMutation = trpc.myFeature.create.useMutation({
    onSuccess: () => {
      utils.myFeature.list.invalidate();
      toast.success("Feature created!");
    },
  });

  const deleteMutation = trpc.myFeature.delete.useMutation({
    onSuccess: () => {
      utils.myFeature.list.invalidate();
      toast.success("Feature deleted!");
    },
  });

  if (isLoading) return <div>Loading...</div>;

  return (
    <div className="space-y-4">
      <Button onClick={() => createMutation.mutate({ title: "New Feature" })}>
        Add Feature
      </Button>

      {features?.map(feature => (
        <Card key={feature.id} className="p-4">
          <h3>{feature.title}</h3>
          <p className="text-sm text-muted-foreground">{feature.description}</p>
          <Button
            variant="destructive"
            onClick={() => deleteMutation.mutate({ id: feature.id })}
          >
            Delete
          </Button>
        </Card>
      ))}
    </div>
  );
}
```

### 5. Register Route
```typescript
// client/src/App.tsx
import MyFeaturePage from "./pages/MyFeature";

function Router() {
  return (
    <Switch>
      <Route path="/" component={Home} />
      <Route path="/my-feature" component={MyFeaturePage} />
      <Route component={NotFound} />
    </Switch>
  );
}
```

### 6. Write Tests
```typescript
// server/myFeature.test.ts
import { describe, it, expect } from "vitest";
import { db } from "./db";

describe("myFeature", () => {
  it("should create a feature", async () => {
    const feature = await db.createFeature("user-1", {
      title: "Test Feature",
      description: "A test feature",
    });

    expect(feature.title).toBe("Test Feature");
    expect(feature.userId).toBe("user-1");
  });

  it("should list features for user", async () => {
    await db.createFeature("user-1", { title: "Feature 1" });
    await db.createFeature("user-1", { title: "Feature 2" });

    const features = await db.getFeatures("user-1");
    expect(features).toHaveLength(2);
  });

  it("should update feature", async () => {
    const feature = await db.createFeature("user-1", { title: "Original" });
    const updated = await db.updateFeature("user-1", feature.id, { title: "Updated" });

    expect(updated.title).toBe("Updated");
  });

  it("should delete feature", async () => {
    const feature = await db.createFeature("user-1", { title: "To Delete" });
    await db.deleteFeature("user-1", feature.id);

    const features = await db.getFeatures("user-1");
    expect(features).not.toContainEqual(feature);
  });
});
```

Run: `pnpm test`

## Common UI Patterns

### Form with Validation

```typescript
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";

const schema = z.object({
  name: z.string().min(1, "Name is required"),
  email: z.string().email("Invalid email"),
});

export default function MyForm() {
  const form = useForm({ resolver: zodResolver(schema) });
  const mutation = trpc.myFeature.create.useMutation();

  const onSubmit = (data) => {
    mutation.mutate(data);
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Name</FormLabel>
              <FormControl>
                <Input placeholder="Enter name" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input type="email" placeholder="Enter email" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button type="submit" disabled={mutation.isPending}>
          {mutation.isPending ? "Submitting..." : "Submit"}
        </Button>
      </form>
    </Form>
  );
}
```

### Data Table with Sorting & Filtering

```typescript
import { DataTable } from "@/components/ui/data-table";
import { ColumnDef } from "@tanstack/react-table";

const columns: ColumnDef<MyFeature>[] = [
  {
    accessorKey: "title",
    header: "Title",
  },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) => (
      <span className="px-2 py-1 rounded-full text-xs font-medium bg-blue-500/20 text-blue-400">
        {row.getValue("status")}
      </span>
    ),
  },
  {
    accessorKey: "createdAt",
    header: "Created",
    cell: ({ row }) => new Date(row.getValue("createdAt")).toLocaleDateString(),
  },
];

export default function MyFeatureTable() {
  const { data: features } = trpc.myFeature.list.useQuery();

  return <DataTable columns={columns} data={features || []} />;
}
```

### Modal Dialog

```typescript
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";

export default function MyModal() {
  const [open, setOpen] = useState(false);

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>Open Modal</Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Modal Title</DialogTitle>
        </DialogHeader>
        <div>Modal content here</div>
      </DialogContent>
    </Dialog>
  );
}
```

### Loading Skeleton

```typescript
import { Skeleton } from "@/components/ui/skeleton";

export default function MyFeatureLoading() {
  return (
    <div className="space-y-4">
      {Array.from({ length: 3 }).map((_, i) => (
        <div key={i} className="space-y-2">
          <Skeleton className="h-4 w-3/4" />
          <Skeleton className="h-4 w-1/2" />
        </div>
      ))}
    </div>
  );
}
```

## Error Handling Patterns

### Frontend Error Display

```typescript
import { toast } from "sonner";

export default function MyComponent() {
  const mutation = trpc.myFeature.create.useMutation({
    onError: (error) => {
      if (error.code === "NOT_FOUND") {
        toast.error("Feature not found");
      } else if (error.code === "FORBIDDEN") {
        toast.error("You don't have permission");
      } else {
        toast.error(error.message || "Something went wrong");
      }
    },
  });

  return <Button onClick={() => mutation.mutate({})}>Create</Button>;
}
```

### Backend Error Handling

```typescript
import { TRPCError } from "@trpc/server";

export const appRouter = router({
  myFeature: {
    get: protectedProcedure
      .input(z.object({ id: z.string() }))
      .query(async ({ ctx, input }) => {
        const feature = await db.getFeatureById(input.id);

        if (!feature) {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "Feature not found",
          });
        }

        if (feature.userId !== ctx.user.id) {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "You don't have access to this feature",
          });
        }

        return feature;
      }),
  },
});
```

## State Management Patterns

### Using React Query for Caching

```typescript
const utils = trpc.useUtils();

// Invalidate cache after mutation
const mutation = trpc.myFeature.create.useMutation({
  onSuccess: () => {
    utils.myFeature.list.invalidate();
  },
});

// Set cache data directly
const mutation = trpc.myFeature.update.useMutation({
  onSuccess: (updated) => {
    utils.myFeature.get.setData({ id: updated.id }, updated);
  },
});
```

### Using Context for Shared State

```typescript
// contexts/MyContext.tsx
import { createContext, useContext, useState } from "react";

const MyContext = createContext();

export function MyProvider({ children }) {
  const [state, setState] = useState({});

  return (
    <MyContext.Provider value={{ state, setState }}>
      {children}
    </MyContext.Provider>
  );
}

export function useMyContext() {
  return useContext(MyContext);
}

// Usage
export default function MyComponent() {
  const { state, setState } = useMyContext();
  return <div>{state.value}</div>;
}
```

## Performance Patterns

### Memoization

```typescript
import { useMemo } from "react";

export default function MyComponent({ items }) {
  const sorted = useMemo(() => {
    return items.sort((a, b) => a.name.localeCompare(b.name));
  }, [items]);

  return <div>{sorted.map(item => <div key={item.id}>{item.name}</div>)}</div>;
}
```

### Lazy Loading

```typescript
import { lazy, Suspense } from "react";

const HeavyComponent = lazy(() => import("./HeavyComponent"));

export default function MyPage() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <HeavyComponent />
    </Suspense>
  );
}
```

### Pagination

```typescript
export default function MyFeatureList() {
  const [page, setPage] = useState(1);
  const { data } = trpc.myFeature.list.useQuery({ page, limit: 10 });

  return (
    <div>
      {data?.items.map(item => <div key={item.id}>{item.title}</div>)}
      <Button onClick={() => setPage(page - 1)} disabled={page === 1}>
        Previous
      </Button>
      <Button onClick={() => setPage(page + 1)} disabled={!data?.hasMore}>
        Next
      </Button>
    </div>
  );
}
```

## Styling Patterns

### Responsive Design

```typescript
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  {items.map(item => (
    <Card key={item.id}>{item.name}</Card>
  ))}
</div>
```

### Dark Mode

```typescript
// Automatically handled by ThemeProvider
// Use semantic color classes:
<div className="bg-background text-foreground">
  <div className="bg-card text-card-foreground">
    <button className="bg-primary text-primary-foreground">
      Click me
    </button>
  </div>
</div>
```

### Custom Component Styling

```typescript
import { cn } from "@/lib/utils";

interface CardProps {
  className?: string;
  children: React.ReactNode;
}

export function Card({ className, children }: CardProps) {
  return (
    <div
      className={cn(
        "rounded-lg border border-white/8 bg-card p-4",
        className
      )}
    >
      {children}
    </div>
  );
}
```
