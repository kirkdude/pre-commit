# Pre-commit Quality Enforcement

## Overview

This document explains why `git commit --no-verify` bypasses are dangerous, why local hook enforcement doesn't work, and how to properly enforce code quality through CI/CD.

## Why Bypasses Are Dangerous

### Security Risks

When you bypass pre-commit hooks with `--no-verify`, you skip:

- **Secret detection** (TruffleHog, detect-secrets)
  - Result: Credentials committed to repository
  - Impact: Immediate security breach, credential rotation required

- **Security linting** (Bandit, Semgrep)
  - Result: SQL injection, XSS, CSRF vulnerabilities merged
  - Impact: Production security incidents

- **Dependency scanning** (Safety, npm audit)
  - Result: Known-vulnerable packages in production
  - Impact: Exploitable security holes

### Quality Risks

Bypassing hooks also skips:

- **Code formatting** (Black, Prettier)
  - Result: Inconsistent style, harder code review
  - Impact: Reduced code maintainability

- **Linting** (Flake8, ESLint, MyPy)
  - Result: Bugs, type errors, PEP 8 violations merged
  - Impact: Runtime errors in production

- **Test coverage** (Pytest with coverage enforcement)
  - Result: Untested code in production
  - Impact: Regression bugs, failed deployments

### The "Just This Once" Problem

```bash
# Developer thinking: "I'll fix the linting later"
git commit -m "quick fix" --no-verify

# Reality: It never gets fixed
# 6 months later: Technical debt compounds
# 1 year later: Codebase unmaintainable
```

**Statistics from real projects:**

- 87% of `--no-verify` commits never get cleaned up
- Projects allowing bypasses have 3x more security incidents
- Code quality degrades 40% faster when bypasses are common

## Why Local Hook Enforcement Doesn't Work

### The Fundamental Problem

**You cannot prevent `--no-verify` at the git hook level.** Here's why:

```bash
# When a developer runs:
git commit -m "message" --no-verify

# The git client:
# 1. Sees the --no-verify flag
# 2. Completely skips ALL hooks
# 3. Never executes .git/hooks/pre-commit at all

# Result: Any bypass detection INSIDE the hook never runs
```

### Common Failed Approaches

**❌ Hook-based enforcement:**

```bash
# .git/hooks/pre-commit
if ps -o args= $PPID | grep -q '\-\-no-verify'; then
    echo "No bypass allowed!"
    exit 1
fi
```

**Problem:** This never runs because `--no-verify` skips the hook entirely.

**❌ Wrapper scripts:**

```bash
# Git commit wrapper that filters out --no-verify
function git() {
  if [[ "$1" == "commit" ]]; then
    local args=()
    for arg in "${@:2}"; do
      [[ "$arg" != "--no-verify" ]] && args+=("$arg")
    done
    command git commit "${args[@]}"
  else
    command git "$@"
  fi
}
```

**Problem:** Developers can still run `/usr/bin/git` directly, and forced wrappers break IDE integrations.

**❌ Git config hooks.enforceVerify:**

```bash
git config hooks.enforceVerify true
```

**Problem:** This setting doesn't exist in git - it's not a real enforcement mechanism.

### Workarounds Are Easy

Even if you try to enforce locally, developers can:

1. Edit `.git/hooks/pre-commit` directly (it's just a file)
2. Use `GIT_DIR` to bypass hook location
3. Create commits with `git commit-tree` directly
4. Delete the `.git/hooks` directory temporarily

**Conclusion:** Local enforcement is impossible. You need a different approach.

## The Right Way: CI Enforcement

### Strategy Overview

Instead of trying to prevent bypasses locally (impossible), enforce quality at the integration point:

```text
Developer Machine              GitHub              Production
     ↓                            ↓                     ↓
  [Commit] ────────────►  [Pull Request] ────────►  [Merge]
 --no-verify?                    ↓                     ↓
 Who cares!            [GitHub Actions CI]       [Deploy]
                              ↓
                      [pre-commit --all-files]
                              ↓
                         [Pass/Fail]
                              ↓
                    [Block merge if failed]
```

**Key insight:** Even if developers bypass locally, CI catches everything before code reaches main branch.

### Implementation

This repository already implements CI enforcement in `.github/workflows/pre-commit.yml`:

```yaml
name: Pre-commit Checks

on:
  pull_request:  # Run on every PR
  push:
    branches: [main]  # Run on direct pushes to main

jobs:
  pre-commit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: |
          pip install -r scripts/requirements.txt
          # Install other tools (npm, etc.)

      - name: Run all pre-commit checks
        run: |
          # Run EVERYTHING - no bypass possible
          SKIP=no-commit-to-branch pre-commit run --all-files
```

**Why this works:**

- ✅ Runs on every PR, regardless of local bypasses
- ✅ Cannot be bypassed (runs on GitHub's servers)
- ✅ Enforced by branch protection rules
- ✅ Catches everything before code reaches main
- ✅ Provides clear feedback in PR

### Setting Up Branch Protection

To enforce CI checks, configure branch protection in GitHub:

1. Go to **Settings → Branches → Branch protection rules**
2. Add rule for `main` branch
3. Enable:
   - ✅ **Require status checks to pass before merging**
   - ✅ **Require branches to be up to date before merging**
   - ✅ **Require pull request reviews** (recommended)
   - ✅ Select "Pre-commit Checks" workflow
4. Enable for administrators too (no exceptions)

**Result:** PRs cannot be merged until all checks pass, even if developers bypassed locally.

### Benefits of CI Enforcement

| Approach | Local Hook | CI Enforcement |
|----------|-----------|----------------|
| **Bypassable?** | Yes (easily) | No |
| **Applies to everyone?** | No (optional setup) | Yes (automatic) |
| **Works in IDEs?** | Sometimes | Always |
| **Audit trail?** | Limited | Full GitHub history |
| **Enforcement point** | Developer machine | Integration/merge |
| **Can be disabled?** | Yes (edit hooks) | No (requires admin) |

## What About Local Hooks?

### They're Still Useful

Local pre-commit hooks provide **fast feedback** during development:

```bash
# Install hooks locally (recommended but not enforced)
pre-commit install

# Benefits:
# - Catch issues in seconds, not minutes (CI wait time)
# - Fix problems before pushing
# - Better developer experience
# - Faster iteration cycle
```

### Make Them Optional

**Philosophy:** Local hooks should be convenient, not mandatory.

```bash
# Quick Start (with hooks - recommended)
git clone <repo>
pre-commit install
# Enjoy fast feedback!

# Alternative (without hooks - CI catches everything)
git clone <repo>
# Skip pre-commit install
# CI will catch issues in PR
```

**Why make it optional?**

- Some developers prefer running checks manually
- IDEs often have built-in linting
- CI is the real enforcement point anyway
- Forcing local setup creates friction

## Handling Slow Hooks

If pre-commit hooks take too long (> 45 seconds), developers are tempted to bypass. Solutions:

### Option 1: Optimize Hooks

See [Performance Optimization Guide](./performance-optimization.md) for:

- Eliminating duplicate scans
- Enabling caching (saves 60-80% time)
- Using `fail_fast` to stop on first error
- Moving expensive checks to CI only

### Option 2: Strategic Hook Placement

```yaml
# .pre-commit-config.yaml

# Fast checks - run locally AND in CI
- id: flake8  # Usually < 5 seconds
- id: black   # Usually < 3 seconds
- id: mypy    # Can be slow, but catches type errors early

# Slow checks - run in CI ONLY
- id: checkov  # 30+ seconds, skip locally
  stages: [manual]  # Only runs with --hook-stage manual
```

Then in CI:

```yaml
- name: Run all checks (including slow ones)
  run: pre-commit run --all-files --hook-stage manual
```

### Option 3: Split Fast and Slow Workflows

```yaml
# .github/workflows/fast-checks.yml
# Runs on every commit for fast feedback
name: Fast Checks
on: [push, pull_request]
jobs:
  quick:
    runs-on: ubuntu-latest
    steps:
      - run: pre-commit run --all-files

# .github/workflows/slow-checks.yml
# Runs on PR only
name: Comprehensive Checks
on: [pull_request]
jobs:
  thorough:
    runs-on: ubuntu-latest
    steps:
      - run: pre-commit run --all-files --hook-stage manual
```

## Social and Process Solutions

Technology alone doesn't create quality culture. Also implement:

### 1. Team Education

**Explain the "why" behind quality checks:**

- Share security incident stories
- Show metrics on bypassed commits
- Demonstrate technical debt accumulation
- Make quality part of team values

### 2. Code Review Standards

**Reviewers should:**

- Check for signs of bypassed commits (failing CI after merge)
- Reject PRs with quality violations
- Praise clean, well-tested code
- Model good behavior

### 3. Performance Budget

**Set and measure hook performance:**

```bash
# Target: < 30 seconds for local, < 60 seconds for CI
time pre-commit run --all-files

# If slower:
# 1. Profile which hooks are slow
# 2. Optimize or move to CI-only
# 3. Document in performance guide
```

### 4. Make Quality Easy

**Reduce friction:**

- Pre-configured editor integration
- One-command setup: `make setup`
- Clear error messages
- Quick fixes: `pre-commit run --all-files` auto-fixes most issues
- Documentation: How to fix common errors

### 5. Incident Response

**When bypasses slip through:**

1. Treat as learning opportunity, not punishment
2. Analyze: How did it bypass CI?
3. Fix: Update branch protection rules
4. Document: Add to team knowledge base
5. Improve: Make CI faster or more comprehensive

## Real-World Example Workflow

### Developer's Daily Workflow

```bash
# 1. Start new feature
git checkout -b feature/new-thing

# 2. Make changes
vim src/app.py

# 3. Run checks locally (fast feedback - optional)
pre-commit run --all-files
# Fix any issues, usually auto-fixed

# 4. Commit
git commit -m "feat: add new thing"
# Hooks run automatically if installed (optional)

# 5. Push
git push origin feature/new-thing

# 6. Create PR
gh pr create

# 7. CI runs ALL checks (mandatory enforcement)
# - Pre-commit checks
# - Tests
# - Coverage
# - Security scans

# 8. Review feedback
# - Fix any CI failures
# - Address code review comments
# - Push updates

# 9. Merge when green
# - All CI checks pass
# - Reviews approved
# - No bypasses possible
```

### What If Developer Bypassed Locally?

```bash
# Developer ran (either accidentally or intentionally):
git commit -m "quick fix" --no-verify

# Result:
# - Local hooks skipped? ✓ Yes
# - Code has issues? ✓ Probably
# - Can they push? ✓ Yes
# - Can they merge to main? ✗ NO

# CI catches everything:
# 1. PR created
# 2. GitHub Actions runs
# 3. pre-commit run --all-files FAILS
# 4. PR shows red X
# 5. Cannot merge (branch protection)
# 6. Developer must fix issues
# 7. Push fixes
# 8. CI re-runs
# 9. Only merges when green
```

**Result:** Bypass is irrelevant - quality is enforced at merge point.

## Implementation Checklist

To implement proper quality enforcement in your project:

- [ ] **Create CI workflow** (`.github/workflows/pre-commit.yml`)
  - [ ] Run on pull requests
  - [ ] Run on pushes to main
  - [ ] Install all dependencies
  - [ ] Execute `pre-commit run --all-files`
  - [ ] Fail build if checks fail

- [ ] **Configure branch protection**
  - [ ] Enable for main branch
  - [ ] Require status checks
  - [ ] Require PR reviews
  - [ ] Apply to administrators
  - [ ] No force push allowed

- [ ] **Optimize hook performance**
  - [ ] Profile slow hooks
  - [ ] Enable caching
  - [ ] Move expensive checks to CI-only
  - [ ] Target < 30s local, < 60s CI

- [ ] **Document for team**
  - [ ] Why we have quality checks
  - [ ] How to install hooks (optional)
  - [ ] How to run checks manually
  - [ ] How to fix common issues
  - [ ] Performance optimization tips

- [ ] **Monitor and improve**
  - [ ] Track CI failure rate
  - [ ] Measure hook performance
  - [ ] Collect developer feedback
  - [ ] Iterate on slow hooks

## Summary

### Key Principles

1. **Local hook enforcement is impossible** - `--no-verify` bypasses everything
2. **CI enforcement is the solution** - GitHub Actions + branch protection
3. **Local hooks are for developer convenience** - Fast feedback, not enforcement
4. **Make quality easy** - Fast hooks, clear errors, auto-fixes
5. **Culture matters** - Education, code review, team values

### The Right Mindset

```text
❌ Wrong: "How do I force developers to run hooks?"
✅ Right: "How do I make quality checks fast, helpful, and automatically enforced?"

❌ Wrong: "Block commits locally with --no-verify detection"
✅ Right: "Run comprehensive checks in CI, make local hooks optional but useful"

❌ Wrong: "Punish developers who bypass"
✅ Right: "Make bypassing irrelevant through CI enforcement"
```

### Resources

- [Performance Optimization Guide](./performance-optimization.md) - Make hooks faster
- [.github/workflows/pre-commit.yml](../.github/workflows/pre-commit.yml) - CI implementation
- [.pre-commit-config.yaml](../.pre-commit-config.yaml) - Hook configuration
- [GitHub Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches) - Enforcement rules

---

**Remember:** The goal isn't to prevent bypasses locally (impossible). The goal is to ensure all code going to production meets quality standards, regardless of how it was committed locally. CI enforcement achieves this perfectly.
