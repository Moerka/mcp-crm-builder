# MCP CRM Builder - Test Scenario

This document provides a step-by-step test scenario to validate the skill functionality.

## Scenario: Build a Customer Support MCP Server Website

### Objective
Create a website showcasing a custom MCP server that manages support tickets, using the mcp-crm-builder skill.

### Prerequisites
- Manus account with webdev capability
- Basic understanding of React and TypeScript
- Familiarity with SQL/databases

### Test Steps

#### Phase 1: Project Setup (10 minutes)

1. **Create new Manus webdev project**
   - Go to Manus dashboard
   - Create new project with "web-db-user" template
   - Note the project URL

2. **Initialize the skill**
   - Read `SKILL.md` for overview
   - Run `bash scripts/init_project.sh` to see checklist

3. **Verify project structure**
   - Check `client/src/pages/Home.tsx` exists
   - Verify `server/routers.ts` exists
   - Confirm `drizzle/schema.ts` is present

**Expected Result**: Project structure matches skill documentation

#### Phase 2: Customization (20 minutes)

4. **Customize Home page**
   - Edit `client/src/pages/Home.tsx`
   - Replace hero section with "Support Ticket MCP Server"
   - Update description to: "Manage support tickets via AI with real-time status updates"
   - Save file

5. **Update design tokens**
   - Edit `client/src/index.css`
   - Change primary color from indigo to emerald (for support theme)
   - Verify changes in dev server

6. **Define data model**
   - Edit `drizzle/schema.ts`
   - Add table for support tickets:
   ```typescript
   export const tickets = sqliteTable('tickets', {
     id: text('id').primaryKey(),
     userId: text('user_id').notNull(),
     title: text('title').notNull(),
     description: text('description'),
     status: text('status').default('open'),
     priority: text('priority').default('medium'),
     createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
   });
   ```

7. **Apply migrations**
   - Run: `pnpm db:push`
   - Verify migration succeeds

**Expected Result**: Home page customized, database schema updated

#### Phase 3: Backend Implementation (15 minutes)

8. **Add query helpers**
   - Edit `server/db.ts`
   - Add functions:
     - `getTickets(userId)` - list all tickets
     - `createTicket(userId, data)` - create new ticket
     - `updateTicketStatus(userId, id, status)` - update status

9. **Create tRPC procedures**
   - Edit `server/routers.ts`
   - Add procedures:
     - `tickets.list` - protected query
     - `tickets.create` - protected mutation
     - `tickets.updateStatus` - protected mutation

10. **Write tests**
    - Create `server/tickets.test.ts`
    - Test each procedure with valid/invalid inputs
    - Run: `pnpm test`

**Expected Result**: All tests pass (3/3)

#### Phase 4: Frontend Implementation (15 minutes)

11. **Create Tickets page**
    - Create `client/src/pages/Tickets.tsx`
    - Use `trpc.tickets.list.useQuery()` to fetch tickets
    - Implement create form with `trpc.tickets.create.useMutation()`
    - Add status update buttons

12. **Add routing**
    - Edit `client/src/App.tsx`
    - Add route: `<Route path="/tickets" component={Tickets} />`
    - Add navigation link in header

13. **Test UI**
    - Run: `pnpm dev`
    - Navigate to `/tickets`
    - Create a test ticket
    - Verify it appears in list
    - Update ticket status

**Expected Result**: Tickets page works, data persists

#### Phase 5: Deployment (10 minutes)

14. **Prepare for deployment**
    - Run: `pnpm check` (verify no TypeScript errors)
    - Run: `pnpm format` (format code)
    - Review changes

15. **Create checkpoint**
    - Use `webdev_save_checkpoint` tool
    - Description: "Support ticket MCP server website - initial version"

16. **Deploy**
    - Click "Publish" in Manus Management UI
    - Wait for build to complete
    - Access live URL

**Expected Result**: Website live and accessible

#### Phase 6: Validation (10 minutes)

17. **Test deployed site**
    - Visit live URL
    - Test login flow
    - Create support ticket
    - Verify data persists
    - Check performance

18. **Verify documentation**
    - Read `references/ARCHITECTURE.md`
    - Verify it matches project structure
    - Check `references/PATTERNS.md` for examples

19. **Test rollback**
    - Go to Management UI → Version History
    - Click "Rollback" on previous checkpoint
    - Verify rollback works
    - Restore to latest version

**Expected Result**: All features work, documentation accurate

### Success Criteria

- ✅ Project initializes without errors
- ✅ Home page customization works
- ✅ Database schema applies successfully
- ✅ All tests pass
- ✅ Frontend components render correctly
- ✅ Data persists across page reloads
- ✅ Deployment completes successfully
- ✅ Live site is accessible and functional
- ✅ Documentation matches implementation
- ✅ Rollback functionality works

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| `pnpm db:push` fails | Check schema syntax, verify DATABASE_URL |
| Tests fail | Review test code, ensure db helpers are correct |
| UI not rendering | Check component imports, verify routes in App.tsx |
| Deployment timeout | Ensure no large files in client/public/, use manus-upload-file |
| OAuth login fails | Clear cookies, verify OAUTH_SERVER_URL |

### Time Estimate
Total: ~80 minutes (including troubleshooting)

### Deliverables
1. Customized mcp-crm-builder project
2. Support ticket MCP server website
3. Live deployed URL
4. Checkpoint for version control
5. Test results documentation

### Next Steps After Test
1. Add more features (search, filtering, sorting)
2. Implement advanced styling
3. Add real MCP server integration
4. Set up monitoring and analytics
5. Create user documentation

### Feedback
After completing this test scenario, provide feedback on:
- Clarity of documentation
- Ease of customization
- Quality of examples
- Completeness of references
- Suggestions for improvement
