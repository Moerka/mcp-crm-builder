# MCP CRM Builder Skill

**Build production-ready MCP server showcase websites with React + tRPC + Tailwind.**

This Manus skill provides a complete, production-ready template for creating professional websites that showcase custom MCP (Model Context Protocol) servers. It combines React 19, tRPC 11, Express 4, and Tailwind CSS 4 with built-in Manus OAuth authentication, database integration, and a modern dark glass-morphism design system.

## What's Included

### Core Features
- **Full-Stack Template**: React frontend + Express backend with tRPC type-safe RPC
- **Authentication**: Manus OAuth built-in with session management
- **Database**: Drizzle ORM with MySQL/TiDB support
- **Design System**: Dark glass-morphism theme with pre-built shadcn/ui components
- **API Explorer**: Interactive request builder for testing endpoints
- **Live Dashboards**: Real-time metrics and data visualization
- **File Storage**: S3-compatible storage with automatic presigned URLs

### Documentation
- **SKILL.md**: Complete skill guide with quick start and workflows
- **references/ARCHITECTURE.md**: Deep dive into project structure and data flows
- **references/PATTERNS.md**: Common implementation patterns and examples
- **references/DEPLOYMENT.md**: Production deployment guide
- **TEST_SCENARIO.md**: Step-by-step test scenario

### Scripts & Templates
- **scripts/init_project.sh**: Interactive initialization checklist
- Pre-built components for dashboards, forms, tables, and modals

## Quick Start

### 1. Read the Documentation
Start with `SKILL.md` for an overview and quick start guide.

### 2. Initialize Your Project
```bash
bash scripts/init_project.sh
```

### 3. Follow the Checklist
The script provides a 15-step checklist to guide you through:
- Creating a Manus webdev project
- Customizing the home page
- Defining your data model
- Building backend procedures
- Creating frontend pages
- Deploying to production

### 4. Reference the Guides
- **Architecture**: `references/ARCHITECTURE.md` for project structure
- **Patterns**: `references/PATTERNS.md` for common implementations
- **Deployment**: `references/DEPLOYMENT.md` for production setup

## Use Cases

This skill is perfect for:
- **MCP Server Documentation**: Showcase your custom MCP server with live examples
- **API Explorers**: Interactive tools for testing API endpoints
- **Integration Dashboards**: Monitor and manage integrations
- **Admin Panels**: Internal tools for managing data
- **SaaS Platforms**: Full-featured web applications

## Project Structure

```
mcp-crm-website/
├── client/src/
│   ├── pages/              # Page components (edit these)
│   ├── components/         # Reusable UI components
│   └── lib/trpc.ts         # tRPC client config
├── server/
│   ├── routers.ts          # tRPC procedures (edit these)
│   ├── db.ts               # Database helpers (edit these)
│   └── _core/              # Framework infrastructure (do not edit)
├── drizzle/
│   ├── schema.ts           # Database tables (edit these)
│   └── migrations/         # Auto-generated migrations
└── shared/
    ├── const.ts            # Shared constants
    └── types.ts            # Shared types
```

**Key files to edit**: `Home.tsx`, `server/routers.ts`, `drizzle/schema.ts`, `client/src/index.css`

## Development Commands

```bash
pnpm install          # Install dependencies
pnpm dev              # Start dev server
pnpm test             # Run tests
pnpm check            # TypeScript type check
pnpm format           # Format code
pnpm db:push          # Apply database migrations
pnpm build            # Build for production
pnpm start            # Run production server
```

## Key Features Explained

### Authentication
Built-in Manus OAuth with automatic session management. Protect endpoints with `protectedProcedure` and access user info via `ctx.user`.

### Database
Drizzle ORM with type-safe queries. Define schemas in `drizzle/schema.ts`, run `pnpm db:push` to migrate, and create query helpers in `server/db.ts`.

### tRPC Procedures
Type-safe API layer. Define procedures in `server/routers.ts` and call from frontend with `trpc.*.useQuery()` or `useMutation()`.

### File Storage
S3-compatible storage with automatic presigned URLs. Upload files via `storagePut()` and reference via `/manus-storage/` URLs.

### Design System
Dark glass-morphism theme with semantic color tokens. Customize colors in `client/src/index.css` and use shadcn/ui components for consistency.

## Common Workflows

### Adding a Feature
1. Define schema in `drizzle/schema.ts`
2. Run `pnpm db:push`
3. Add query helpers in `server/db.ts`
4. Create procedures in `server/routers.ts`
5. Write tests in `server/*.test.ts`
6. Build UI in `client/src/pages/`
7. Call via tRPC hooks

### Deploying
1. Run `pnpm check` and `pnpm test`
2. Create checkpoint via `webdev_save_checkpoint`
3. Click "Publish" in Manus Management UI
4. Access live URL

## Troubleshooting

| Issue | Solution |
|-------|----------|
| TypeScript errors | Run `pnpm check` and fix type issues |
| Database migration fails | Verify schema syntax and DATABASE_URL |
| Tests failing | Check db helpers and procedure logic |
| OAuth login fails | Clear cookies, verify OAUTH_SERVER_URL |
| Deployment timeout | Ensure no large files in client/public/ |

See `references/DEPLOYMENT.md` for more troubleshooting tips.

## Example: Building a Support Ticket System

See `TEST_SCENARIO.md` for a complete step-by-step example of building a support ticket MCP server website using this skill.

## Next Steps

1. **Read SKILL.md** for detailed documentation
2. **Review references/** for architecture and patterns
3. **Run scripts/init_project.sh** to start your project
4. **Follow TEST_SCENARIO.md** for a complete example
5. **Deploy and iterate** on your MCP server website

## Support

- Check the troubleshooting section in `references/DEPLOYMENT.md`
- Review examples in `references/PATTERNS.md`
- Consult `references/ARCHITECTURE.md` for project structure questions
- Read Manus webdev documentation for framework-specific questions

## License

This skill is provided as part of the Manus platform. Use it to create MCP server showcase websites and integration dashboards.

## Version

- **Skill Version**: 1.0.0
- **Template**: React 19 + tRPC 11 + Express 4 + Tailwind CSS 4
- **Last Updated**: April 2026

---

**Ready to build?** Start with `SKILL.md` and follow the quick start guide!
