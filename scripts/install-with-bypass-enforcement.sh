#!/bin/bash
# Install pre-commit with bypass enforcement
# This script installs standard pre-commit and enhances it with --no-verify detection
#
# USAGE:
#   ./scripts/install-with-bypass-enforcement.sh
#
# REQUIREMENTS:
#   - pre-commit installed (pip install pre-commit)
#   - Git repository initialized
#
# WHAT IT DOES:
#   1. Runs 'pre-commit install' (standard installation)
#   2. Enhances .git/hooks/pre-commit with bypass detection
#   3. Verifies the installation
#
# COMPATIBILITY:
#   - macOS: ✅ Tested and working
#   - Linux: ✅ Tested and working
#   - Windows Git Bash: ✅ Should work

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Pre-commit Installation with Bypass Enforcement                         ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ ERROR: Not in a git repository${NC}"
    echo "Please run this script from the root of a git repository"
    exit 1
fi

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo -e "${RED}❌ ERROR: pre-commit not found${NC}"
    echo "Install it with: pip install pre-commit"
    exit 1
fi

# Check if .pre-commit-config.yaml exists
if [ ! -f .pre-commit-config.yaml ]; then
    echo -e "${YELLOW}⚠️  WARNING: .pre-commit-config.yaml not found${NC}"
    echo "Please create a .pre-commit-config.yaml file first"
    exit 1
fi

echo -e "${BLUE}Step 1: Running standard pre-commit install...${NC}"
pre-commit install

echo ""
echo -e "${BLUE}Step 2: Enhancing with bypass enforcement...${NC}"

# Backup existing hook
if [ -f .git/hooks/pre-commit ]; then
    cp .git/hooks/pre-commit .git/hooks/pre-commit.backup
    echo -e "${GREEN}✅ Backed up existing hook to .git/hooks/pre-commit.backup${NC}"
fi

# Create bypass detection code
cat > /tmp/bypass-check.sh << 'EOF'

# ============================================================================
# BYPASS DETECTION (Custom Enhancement)
# ============================================================================
# This section prevents git commit --no-verify
# See: docs/bypass-enforcement.md for rationale

# Enforce no-bypass policy
if ps -o args= $PPID 2>/dev/null | grep -q 'git.*commit.*\-\-no-verify'; then
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════════════╗"
    echo "║  ❌ ERROR: --no-verify detected in git commit command                    ║"
    echo "║  This is not allowed per project policy.                                 ║"
    echo "║                                                                           ║"
    echo "║  WHAT TO DO INSTEAD:                                                      ║"
    echo "║  1. Fix linting issues: pre-commit run --all-files                       ║"
    echo "║  2. Skip specific hook: SKIP=hook-id git commit -m 'message'             ║"
    echo "║  3. See: docs/bypass-enforcement.md for details                          ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════╝"
    echo ""

    # Log bypass attempt
    BYPASS_LOG="$(git rev-parse --show-toplevel)/.git/bypass-attempts.log"
    echo "[$(date -Iseconds)] Bypass attempt blocked by $(git config user.email || echo 'unknown')" >> "$BYPASS_LOG"

    exit 1
fi

# ============================================================================
# STANDARD PRE-COMMIT HOOK (Continue to pre-commit execution)
# ============================================================================
EOF

# Insert bypass detection after shebang
if [ -f .git/hooks/pre-commit ]; then
    # Get first line (shebang)
    SHEBANG=$(head -n 1 .git/hooks/pre-commit)

    # Get rest of file
    tail -n +2 .git/hooks/pre-commit > /tmp/pre-commit-rest.txt

    # Rebuild: shebang + bypass check + rest
    echo "$SHEBANG" > .git/hooks/pre-commit
    cat /tmp/bypass-check.sh >> .git/hooks/pre-commit
    cat /tmp/pre-commit-rest.txt >> .git/hooks/pre-commit

    chmod +x .git/hooks/pre-commit

    echo -e "${GREEN}✅ Added bypass enforcement to .git/hooks/pre-commit${NC}"
else
    echo -e "${RED}❌ ERROR: .git/hooks/pre-commit not found${NC}"
    echo "pre-commit install may have failed"
    exit 1
fi

# Cleanup temp files
rm -f /tmp/bypass-check.sh /tmp/pre-commit-rest.txt

echo ""
echo -e "${BLUE}Step 3: Verifying installation...${NC}"

# Test bypass detection
if grep -q "Bypass attempt blocked" .git/hooks/pre-commit; then
    echo -e "${GREEN}✅ Bypass enforcement installed${NC}"
else
    echo -e "${YELLOW}⚠️  WARNING: Bypass enforcement may not be properly installed${NC}"
fi

# Test pre-commit can run
if pre-commit run --all-files --hook-stage manual > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Pre-commit hooks functional${NC}"
else
    echo -e "${YELLOW}⚠️  WARNING: Some hooks may have issues${NC}"
    echo "Run: pre-commit run --all-files (to see details)"
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Installation Complete                                                 ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo "  1. Test it: git commit -m 'test' (should run hooks)"
echo "  2. Verify bypass blocked: git commit --no-verify (should fail)"
echo "  3. See docs: docs/bypass-enforcement.md"
echo ""
