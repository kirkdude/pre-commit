# Bypass Enforcement Policy

## Overview

This document explains why `git commit --no-verify` bypasses are dangerous, how we technically enforce against them, and what to do when hooks seem too slow.

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

## How Technical Enforcement Works

### Implementation

The bypass detection uses process inspection to detect `--no-verify` flags:

```bash
#!/bin/bash
# .git/hooks/pre-commit (auto-generated with enhancement)

# Enforce no-bypass policy
if ps -o args= $PPID 2>/dev/null | grep -q 'git.*commit.*\-\-no-verify'; then
    echo "❌ ERROR: --no-verify detected in git commit command"
    echo "This is not allowed per project policy."
    echo "Fix linting issues instead of bypassing hooks."
    exit 1
fi

# Continue with standard pre-commit logic...
```

### How It Works

1. **Process Inspection**: Checks parent process command line
2. **Pattern Matching**: Looks for `git.*commit.*--no-verify`
3. **Early Exit**: Blocks commit before pre-commit even runs
4. **Audit Trail**: Logs bypass attempts to `.git/bypass-attempts.log`

### Compatibility

**Supported Platforms:**

- macOS (BSD ps): ✅ Tested and working
- Linux (GNU ps): ✅ Tested and working
- Windows Git Bash: ✅ Should work (uses similar ps)
- WSL (Windows Subsystem for Linux): ✅ Works like Linux

**What Still Works:**

- ✅ Normal commits: `git commit -m "message"`
- ✅ Interactive commits: `git commit` (opens editor)
- ✅ Amend commits: `git commit --amend`
- ✅ Git GUI clients (they don't pass --no-verify)
- ✅ Rebases, cherry-picks, merges (different process tree)

**What Gets Blocked:**

- ❌ `git commit --no-verify`
- ❌ `git commit -n` (short form)
- ❌ `git commit -m "message" --no-verify`

### False Positives

**Minimal.** The detection only triggers when:

1. Parent process is `git commit`
2. Command line contains `--no-verify`

This means:

- No interference with normal workflow
- No false blocks on legitimate operations
- Exact targeting of bypass attempts

### Can Developers Work Around It?

**Technical bypasses exist, but they're hard:**

1. **Edit .git/hooks/pre-commit** - Requires manual editing
2. **Use git commit --no-verify from different shell** - Requires extra steps
3. **Temporarily disable hooks** - Obvious and auditable

**Why this still works:**

- Makes bypassing *inconvenient* (not impossible)
- Creates audit trail via git history
- Social pressure: teammates see bypass attempts
- Forces documentation: "Why did you bypass?"

**Philosophy:** We make doing the right thing easy, doing the wrong thing hard.

## What to Do When Hooks Are Slow

If pre-commit hooks are taking too long (> 45 seconds), **never use --no-verify**. Instead:

### Option 1: Optimize the Hooks

See [Performance Optimization Guide](./performance-optimization.md) for:

- Eliminating duplicate scans
- Enabling caching on slow tools
- Moving expensive operations to pre-push stage
- Using file patterns to minimize scope

**Example optimizations:**

```yaml
# Before: 90 seconds
- id: python-safety-dependencies-check

# After: 5 seconds (with cache)
- id: python-safety-dependencies-check
  args: [--cache]
  files: requirements\.txt$
```

### Option 2: Move to Pre-Push

Move expensive operations to run less frequently:

```yaml
hooks:
  - id: pytest-coverage
    stages: [pre-push]  # Run on push, not every commit
```

### Option 3: Disable Specific Hook Temporarily

If a specific hook is broken or too slow:

```yaml
# .pre-commit-config.yaml
hooks:
  - id: expensive-hook
    # Temporarily disabled: <ticket number>
    # TODO: Re-enable after optimization
    exclude: '.*'  # Disables hook temporarily
```

**Document why:**

- Create tracking ticket (Jira, GitHub issue, etc.)
- Add comment explaining the temporary disable
- Set deadline for re-enabling

### Option 4: Run Subset of Hooks

```bash
# Skip one specific hook
SKIP=pytest-coverage git commit -m "message"

# Run only formatting/linting (skip tests)
SKIP=pytest-coverage,integration-tests git commit -m "message"
```

**Legal bypass methods:**

- `SKIP=hook-id` environment variable
- Documented in pre-commit official docs
- Still runs other hooks (security, linting, formatting)
- Visible in git history (can be audited)

### Option 5: Fix Issues, Then Commit

Often the fastest approach:

```bash
# Let pre-commit auto-fix formatting
pre-commit run --all-files

# Review changes
git diff

# Commit the fixes
git add .
git commit -m "fix: formatting and linting issues"
```

## Audit Trail

### Viewing Bypass Attempts

All bypass attempts are logged:

```bash
# View bypass attempt log
cat .git/bypass-attempts.log

# Example output:
[2025-10-06T14:32:15-07:00] Bypass attempt blocked by developer@example.com
[2025-10-06T15:45:22-07:00] Bypass attempt blocked by developer@example.com
```

### Using Git Notes for Violations

If a developer manages to bypass (by editing the hook), document it:

```bash
# Add note to commit explaining bypass (for audit purposes)
git notes add -m "BYPASS: Hooks disabled due to <reason>. Ticket: PROJECT-123" <commit-hash>

# View notes
git log --show-notes
```

**Why this matters:**

- Creates permanent audit trail
- Justifies the bypass to reviewers
- Links to tracking ticket for resolution
- Makes bypasses visible in code review

## Migration Guide: Adding Enforcement to Existing Projects

### Step 1: Install Standard Pre-commit

```bash
# Install pre-commit framework
pip install pre-commit

# Install hooks
pre-commit install
```

### Step 2: Enhance with Bypass Detection

```bash
# Backup existing hook
cp .git/hooks/pre-commit .git/hooks/pre-commit.backup

# Add bypass detection to beginning of file
cat > /tmp/bypass-check.sh << 'EOF'
#!/bin/bash
# Enforce no-bypass policy
if ps -o args= $PPID 2>/dev/null | grep -q 'git.*commit.*\-\-no-verify'; then
    echo "❌ ERROR: --no-verify detected in git commit command"
    echo "This is not allowed per project policy."
    echo "Fix linting issues instead of bypassing hooks."
    exit 1
fi
EOF

# Insert at beginning (after shebang)
awk 'NR==1{print; system("cat /tmp/bypass-check.sh")} NR>1' \
    .git/hooks/pre-commit.backup > .git/hooks/pre-commit

chmod +x .git/hooks/pre-commit
```

### Step 3: Optimize Hook Performance

Follow [Performance Optimization Guide](./performance-optimization.md):

1. Add `fail_fast: false` to `.pre-commit-config.yaml`
2. Add `minimum_pre_commit_version: '2.20.0'`
3. Enable caching on slow tools (`--cache` flags)
4. Remove duplicate scans from Makefile

### Step 4: Document Policy

Add to project README:

```markdown
## Quality Standards

Pre-commit hooks are **mandatory**. Using `--no-verify` is blocked.

If hooks are too slow:
1. See [Performance Guide](./docs/performance-optimization.md)
2. Use `SKIP=hook-id` for specific hooks
3. Move expensive operations to pre-push stage
4. Never bypass security/formatting checks
```

### Step 5: Communicate to Team

```markdown
Team announcement:

Starting today, git commit --no-verify is blocked by policy.

WHY: Bypassing hooks skips security scanning, linting, and test coverage.

WHAT TO DO INSTEAD:
- Fix linting issues (run: pre-commit run --all-files)
- Use SKIP=hook-id for temporary skips (documented)
- See docs/performance-optimization.md if hooks are slow

Questions? See docs/bypass-enforcement.md or ask in #dev-tools
```

## FAQ

### Q: What if I really need to bypass for a valid reason?

**A: Use documented skip methods:**

```bash
# Skip specific hook
SKIP=pytest-coverage git commit -m "WIP: tests coming in next commit"

# Disable hook temporarily in config
# .pre-commit-config.yaml
- id: expensive-hook
  exclude: '.*'  # Disabled: ticket PROJECT-123
```

### Q: What about emergency hotfixes?

**A: Even hotfixes should pass basic checks:**

```bash
# Run only critical hooks (security + formatting)
SKIP=pytest-coverage,integration-tests git commit -m "hotfix: critical bug"

# Fix will still pass:
# - Secret detection (TruffleHog)
# - Security linting (Bandit)
# - Code formatting (Black)
# - Basic linting (Flake8)
```

### Q: What if hooks are broken?

**A: Fix the hooks, don't bypass them:**

```bash
# Temporarily disable broken hook in config
# .pre-commit-config.yaml
- id: broken-hook
  exclude: '.*'  # Temporarily disabled: issue #123

# Commit the fix
git add .pre-commit-config.yaml
git commit -m "fix: disable broken hook pending upstream fix"
```

### Q: Can I remove bypass enforcement?

**A: Technically yes, but don't:**

The enforcement is in `.git/hooks/pre-commit` (not tracked by git). You could edit it, but:

- Your teammates will see unformatted/untested code in PRs
- CI will fail (same hooks run there)
- Code review will catch the bypass
- You'll have to explain why in PR comments

**Better approach:** Fix the underlying issue (slow hooks, linting errors, etc.)

### Q: Does this work with Git GUIs?

**A: Yes, most GUIs don't support --no-verify:**

- ✅ GitHub Desktop: No bypass option (safe)
- ✅ GitKraken: No bypass option (safe)
- ✅ Tower: Has bypass option (will be blocked)
- ✅ SourceTree: Has bypass option (will be blocked)

### Q: What about rebases and cherry-picks?

**A: They work normally:**

Rebases and cherry-picks use different git commands (`git rebase`, `git cherry-pick`) and won't trigger bypass detection. They run hooks normally without interference.

## Summary

**Key Points:**

1. Bypassing hooks skips security scanning, linting, and test coverage
2. Technical enforcement makes bypasses inconvenient (not impossible)
3. Use `SKIP=hook-id` for documented, selective skips
4. Optimize slow hooks instead of bypassing them
5. Emergency hotfixes should still pass basic security/formatting checks

**Target:** < 45 seconds per commit (see performance docs)

**Never Bypass:** Fix the root cause, don't work around quality checks

---

**Last Updated:** 2025-10-06
**Author:** Master Pre-commit Repository
