#!/bin/bash

# MCP CRM Builder - Project Initialization Script
# This script provides a checklist for setting up a new MCP CRM showcase website

set -e

echo "🚀 MCP CRM Builder - Project Initialization Checklist"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Checklist items
declare -a CHECKLIST=(
  "1. Create new Manus webdev project with 'web-db-user' features"
  "2. Clone/copy mcp-crm-website template to your project"
  "3. Customize Home.tsx with your MCP server details"
  "4. Update drizzle/schema.ts with your data model"
  "5. Add query helpers to server/db.ts"
  "6. Create tRPC procedures in server/routers.ts"
  "7. Build frontend pages in client/src/pages/"
  "8. Update client/src/index.css with your color palette"
  "9. Add custom environment variables via webdev_request_secrets"
  "10. Run pnpm db:push to apply migrations"
  "11. Run pnpm test to verify all tests pass"
  "12. Run pnpm check for TypeScript errors"
  "13. Upload static assets via manus-upload-file --webdev"
  "14. Create checkpoint via webdev_save_checkpoint"
  "15. Publish via Manus Management UI"
)

echo -e "${BLUE}Project Setup Checklist:${NC}"
echo ""

for item in "${CHECKLIST[@]}"; do
  echo "[ ] $item"
done

echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Read SKILL.md for overview and quick start"
echo "2. Review references/ARCHITECTURE.md for project structure"
echo "3. Check references/PATTERNS.md for common patterns"
echo "4. Consult references/DEPLOYMENT.md for deployment guide"
echo ""

echo -e "${GREEN}Development Commands:${NC}"
echo "  pnpm install       # Install dependencies"
echo "  pnpm dev           # Start dev server"
echo "  pnpm test          # Run tests"
echo "  pnpm check         # Type check"
echo "  pnpm format        # Format code"
echo "  pnpm db:push       # Apply migrations"
echo "  pnpm build         # Build for production"
echo ""

echo -e "${BLUE}Key Files to Edit:${NC}"
echo "  client/src/pages/Home.tsx              # Landing page"
echo "  server/routers.ts                      # API procedures"
echo "  drizzle/schema.ts                      # Database schema"
echo "  client/src/index.css                   # Design tokens"
echo ""

echo -e "${YELLOW}Files to Avoid:${NC}"
echo "  server/_core/*                         # Framework infrastructure"
echo "  shared/_core/*                         # Shared framework code"
echo "  client/src/_core/*                     # Core hooks/utilities"
echo ""

echo "✅ Initialization checklist complete!"
echo "Start with Step 1 above and follow the checklist."
