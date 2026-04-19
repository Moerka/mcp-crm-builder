# Deployment Guide

## Pre-Deployment Checklist

- [ ] All environment variables configured via `webdev_request_secrets`
- [ ] Database migrations applied (`pnpm db:push`)
- [ ] All tests passing (`pnpm test`)
- [ ] TypeScript checks passing (`pnpm check`)
- [ ] Code formatted (`pnpm format`)
- [ ] Static assets uploaded via `manus-upload-file --webdev`
- [ ] No hardcoded URLs or API keys in code
- [ ] OAuth callback URL configured correctly
- [ ] Database connection string verified

## Environment Variables Setup

### Required System Variables

These are automatically injected by Manus:

```
DATABASE_URL              # MySQL/TiDB connection
JWT_SECRET                # Session signing key
VITE_APP_ID               # OAuth app ID
OAUTH_SERVER_URL          # OAuth backend URL
VITE_OAUTH_PORTAL_URL     # OAuth login portal
OWNER_OPEN_ID             # Owner's user ID
OWNER_NAME                # Owner's name
BUILT_IN_FORGE_API_URL    # Manus APIs URL
BUILT_IN_FORGE_API_KEY    # Manus API key (server)
VITE_FRONTEND_FORGE_API_KEY  # Frontend API key
VITE_FRONTEND_FORGE_API_URL  # Frontend APIs URL
```

### Custom Secrets

Add via Manus UI or `webdev_request_secrets` tool:

```bash
# Example: Adding a custom API key
webdev_request_secrets \
  --key MY_API_KEY \
  --description "API key for external service"
```

Access in code:
```typescript
// Server-side
const apiKey = process.env.MY_API_KEY;

// Frontend-side (must be prefixed with VITE_)
const apiKey = import.meta.env.VITE_MY_API_KEY;
```

## Database Setup

### Initial Migration

```bash
pnpm db:push
```

This command:
1. Generates migrations from schema changes
2. Applies migrations to remote database
3. Creates all tables and indexes

### Verifying Database Connection

```typescript
// server/db.ts
import { db } from "./db";

// Test query
const users = await db.select().from(users).limit(1);
console.log("Database connected:", users);
```

### Backup Strategy

Before major deployments:
1. Request database backup from Manus UI
2. Export critical data if needed
3. Document rollback procedure

## Build & Deployment

### Local Testing

```bash
# Install dependencies
pnpm install

# Start development server
pnpm dev

# Run tests
pnpm test

# Type check
pnpm check

# Format code
pnpm format
```

### Production Build

```bash
# Build frontend + backend
pnpm build

# Output: dist/ directory with bundled app
```

### Deployment via Manus UI

1. Create checkpoint: `webdev_save_checkpoint`
2. Click "Publish" button in Management UI
3. Wait for build to complete
4. Access via generated domain

## Static Assets Management

### Uploading Assets

```bash
# Upload images, videos, documents
manus-upload-file --webdev path/to/image.png path/to/video.mp4

# Returns URLs like:
# /manus-storage/image_a1b2c3d4.png
# /manus-storage/video_e5f6g7h8.mp4
```

### Using in Code

```typescript
// Frontend
<img src="/manus-storage/image_a1b2c3d4.png" alt="Hero" />

// Backend (S3 upload)
const { url } = await storagePut(
  `uploads/document.pdf`,
  fileBuffer,
  "application/pdf"
);
```

### Storage Best Practices

- **Do NOT** store files in `client/public/` (causes deployment timeout)
- **Do** use `manus-upload-file --webdev` for large assets
- **Do** store metadata in database, bytes in S3
- **Do** reference URLs directly in code

## Monitoring & Debugging

### Server Logs

Access via Manus Management UI:
- **Dev Server Output**: Recent server startup messages
- **Browser Console**: Client-side errors and logs
- **Network Requests**: HTTP requests with status codes
- **Session Replay**: User interaction events

### Common Issues

#### Database Connection Failed

```
Error: connect ECONNREFUSED
```

**Solution:**
1. Verify `DATABASE_URL` is set correctly
2. Check database server is running
3. Ensure firewall allows connections
4. Test with `pnpm db:push`

#### OAuth Redirect Loop

**Solution:**
1. Verify `VITE_OAUTH_PORTAL_URL` is correct
2. Check callback URL in OAuth settings
3. Ensure `window.location.origin` is used (not hardcoded)
4. Clear browser cookies and retry

#### Static Assets 404

**Solution:**
1. Verify assets uploaded via `manus-upload-file --webdev`
2. Check URL format: `/manus-storage/{key}`
3. Ensure URLs are referenced correctly in code
4. Do NOT use local file paths

#### TypeScript Errors in Production

**Solution:**
1. Run `pnpm check` locally
2. Fix all type errors before deploying
3. Ensure `tsconfig.json` is correct
4. Check for circular dependencies

### Performance Optimization

#### Frontend Performance

```typescript
// Use React.memo for expensive components
const ExpensiveComponent = React.memo(({ data }) => {
  return <div>{data}</div>;
});

// Use useMemo for expensive calculations
const sorted = useMemo(() => {
  return data.sort((a, b) => a.name.localeCompare(b.name));
}, [data]);

// Use lazy loading for routes
const HeavyPage = lazy(() => import("./HeavyPage"));
```

#### Backend Performance

```typescript
// Add database indexes
export const customers = sqliteTable('customers', {
  id: text('id').primaryKey(),
  email: text('email').notNull(),
  createdAt: integer('created_at').notNull(),
}, (table) => ({
  emailIdx: index('email_idx').on(table.email),
  createdAtIdx: index('created_at_idx').on(table.createdAt),
}));

// Use query pagination
export async function getCustomers(userId: string, page: number = 1, limit: number = 10) {
  return db
    .select()
    .from(customers)
    .where(eq(customers.userId, userId))
    .limit(limit)
    .offset((page - 1) * limit);
}

// Cache frequently-accessed data
const cache = new Map();
export async function getCachedData(key: string) {
  if (cache.has(key)) return cache.get(key);
  const data = await fetchData(key);
  cache.set(key, data);
  return data;
}
```

## Rollback Procedure

### If Deployment Fails

1. Identify the issue from logs
2. Fix the problem locally
3. Create new checkpoint
4. Publish again

### If Database Migration Fails

1. Check migration SQL in `drizzle/migrations/`
2. Verify schema changes in `drizzle/schema.ts`
3. Fix schema and re-run `pnpm db:push`
4. Rollback to previous checkpoint if needed

### Rollback to Previous Version

```bash
# Via Manus UI
# 1. Go to Management UI → Version History
# 2. Click "Rollback" on desired checkpoint
# 3. Confirm rollback

# Via CLI (if available)
webdev_rollback_checkpoint <version_id>
```

## Security Best Practices

### Secrets Management

```typescript
// ✅ Correct: Use environment variables
const apiKey = process.env.MY_API_KEY;

// ❌ Wrong: Hardcode secrets
const apiKey = "sk_live_abc123";

// ❌ Wrong: Commit to git
// .env file should be in .gitignore
```

### Authentication

```typescript
// ✅ Use protectedProcedure for auth-required endpoints
export const appRouter = router({
  sensitiveData: protectedProcedure.query(({ ctx }) => {
    // ctx.user is guaranteed to exist
    return getSensitiveData(ctx.user.id);
  }),
});

// ❌ Don't trust client-provided user ID
export const appRouter = router({
  data: publicProcedure
    .input(z.object({ userId: z.string() }))
    .query(({ input }) => {
      // DANGEROUS: Client can request any user's data
      return getData(input.userId);
    }),
});
```

### CORS & CSRF

```typescript
// CORS is automatically configured by Manus
// CSRF protection via session cookies (HttpOnly)
// No additional configuration needed
```

### Input Validation

```typescript
import { z } from "zod";

// ✅ Validate all inputs
export const appRouter = router({
  create: protectedProcedure
    .input(z.object({
      email: z.string().email(),
      age: z.number().int().min(0).max(150),
      name: z.string().min(1).max(100),
    }))
    .mutation(({ input }) => {
      // Input is guaranteed to be valid
      return createUser(input);
    }),
});
```

## Scaling Considerations

### Database Optimization

- Add indexes on frequently-queried columns
- Implement pagination for large result sets
- Use connection pooling (handled by Manus)
- Monitor query performance

### Frontend Optimization

- Code splitting with lazy routes
- Image optimization and compression
- CSS/JS minification (handled by Vite)
- Caching strategies with React Query

### Backend Optimization

- Implement caching for expensive queries
- Use async/await properly
- Batch database operations
- Monitor memory usage

## Monitoring & Alerts

### Key Metrics to Monitor

- **Response Time**: Track API latency
- **Error Rate**: Monitor failed requests
- **Database Connections**: Check connection pool usage
- **Memory Usage**: Track server memory
- **Disk Space**: Monitor database size

### Setting Up Alerts

Via Manus UI:
1. Go to Management UI → Notifications
2. Configure alert thresholds
3. Set notification recipients
4. Test alert delivery

## Disaster Recovery

### Data Backup

```bash
# Request backup from Manus UI
# Backups are automatically created daily
# Retention: 30 days
```

### Recovery Procedure

1. Request database restore from Manus UI
2. Select backup point in time
3. Confirm restore (this will overwrite current data)
4. Verify data integrity after restore

### Preventing Data Loss

- Regular backups (automatic)
- Code version control (git)
- Database migrations tracked
- Asset storage in S3 (durable)

## Post-Deployment

### Verification Steps

1. Visit deployed URL
2. Test login flow
3. Create test data
4. Verify database persistence
5. Check all features work
6. Monitor logs for errors

### Performance Baseline

After deployment, establish baseline metrics:
- Average response time
- Error rate
- Database query time
- Frontend load time

### Continuous Monitoring

```bash
# Monitor logs in real-time
tail -f .manus-logs/devserver.log
tail -f .manus-logs/browserConsole.log
tail -f .manus-logs/networkRequests.log
```

## Maintenance Schedule

### Daily
- Monitor error logs
- Check database connection health
- Verify backups completed

### Weekly
- Review performance metrics
- Check for security updates
- Test backup restoration

### Monthly
- Update dependencies
- Review and optimize slow queries
- Audit access logs
- Plan capacity upgrades

## Support & Escalation

### Common Support Scenarios

| Issue | Resolution |
|-------|-----------|
| App won't start | Check logs, verify env vars, restart server |
| Database errors | Verify connection, check migrations, restore backup |
| OAuth failures | Check OAuth config, clear cookies, verify URLs |
| Performance issues | Check indexes, implement caching, optimize queries |
| Deployment stuck | Check build logs, verify dependencies, rollback if needed |

### Getting Help

1. Check logs in Management UI
2. Review this deployment guide
3. Consult project architecture documentation
4. Contact Manus support if needed
