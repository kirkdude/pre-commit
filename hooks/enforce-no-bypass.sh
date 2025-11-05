#!/bin/bash
# Enforce no-bypass policy for git hooks
# Source this from pre-commit hooks in projects
#
# USAGE:
#   Add this to the top of your .git/hooks/pre-commit file:
#   source "$(git rev-parse --show-toplevel)/hooks/enforce-no-bypass.sh" || exit 1
#
# WHY:
#   Using --no-verify bypasses all quality checks including:
#   - Code formatting (black, prettier, etc.)
#   - Linting (flake8, eslint, etc.)
#   - Security scanning (bandit, trufflehog, etc.)
#   - Test coverage enforcement
#   This creates technical debt and security vulnerabilities.
#
# WHAT IT DOES:
#   Detects when git commit --no-verify is used and blocks the commit.
#   Uses process inspection to check the parent process command line.
#
# COMPATIBILITY:
#   - macOS: Uses ps -o args= $PPID (BSD ps)
#   - Linux: Uses ps -o args= $PPID (GNU ps)
#   - Windows Git Bash: Should work with similar ps implementation
#
# FALSE POSITIVES:
#   Minimal. Only triggers on exact --no-verify flag in parent git commit.
#   Does not interfere with:
#   - Normal git commit operations
#   - Git GUI clients (they don't pass --no-verify directly)
#   - Rebases, cherry-picks, or other git operations

# Only check if parent is actually git commit with --no-verify
PARENT_ARGS=$(ps -o args= $PPID 2>/dev/null)
if echo "$PARENT_ARGS" | grep -q 'git.*commit.*\-\-no-verify'; then
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                           ║"
    echo "║  ❌ ERROR: --no-verify detected in git commit command                    ║"
    echo "║                                                                           ║"
    echo "║  This is not allowed per project policy.                                 ║"
    echo "║                                                                           ║"
    echo "║  WHY THIS MATTERS:                                                        ║"
    echo "║  • Bypassing hooks skips security scanning (bandit, trufflehog)          ║"
    echo "║  • Bypassing hooks skips linting (flake8, mypy, eslint)                  ║"
    echo "║  • Bypassing hooks skips test coverage enforcement                       ║"
    echo "║  • This creates technical debt and security vulnerabilities              ║"
    echo "║                                                                           ║"
    echo "║  WHAT TO DO INSTEAD:                                                      ║"
    echo "║  1. Fix the linting issues reported by pre-commit                        ║"
    echo "║  2. If hooks are too slow, optimize them (see performance docs)          ║"
    echo "║  3. If a specific hook is broken, disable it in .pre-commit-config.yaml  ║"
    echo "║  4. If you need urgent bypass, document why in commit message            ║"
    echo "║                                                                           ║"
    echo "║  TARGET: Pre-commit hooks should complete in < 45 seconds                ║"
    echo "║  If slower, see: docs/performance-optimization.md                        ║"
    echo "║                                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════╝"
    echo ""

    # Log bypass attempt for audit trail
    if command -v git &> /dev/null; then
        BYPASS_LOG="$(git rev-parse --show-toplevel)/.git/bypass-attempts.log"
        echo "[$(date -Iseconds)] Bypass attempt blocked by $(git config user.email || echo 'unknown')" >> "$BYPASS_LOG"
    fi

    exit 1
fi

# If we get here, no bypass detected - allow pre-commit to continue
exit 0
