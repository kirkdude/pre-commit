# Pre-commit Performance Optimization

## Target Performance

**Pre-commit hooks should complete in < 45 seconds** for typical commits.

Slow hooks frustrate developers and encourage bypassing quality checks. This document provides patterns for optimizing hook performance without sacrificing quality.

## Common Performance Anti-Patterns

### 1. Duplicate Security Scans

**ANTI-PATTERN:**

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/Lucas-C/pre-commit-hooks-safety
    rev: v1.4.2
    hooks:
      - id: python-safety-dependencies-check  # Runs safety

# Makefile
lint:
    safety check --file requirements.txt  # Runs safety AGAIN
    bandit -r src/                        # Runs bandit AGAIN
```

**PROBLEM:** Running safety and bandit twice (pre-commit + Makefile) doubles scan time with zero benefit.

**SOLUTION:** Run security scans ONLY in pre-commit hooks:

```makefile
# Makefile - delegate to pre-commit
lint:
    pre-commit run --all-files
```

**IMPACT:** Saves 10-15 seconds per commit

---

### 2. Missing Cache Flags

**ANTI-PATTERN:**

```yaml
hooks:
  - id: python-safety-dependencies-check
    # No caching - re-downloads vulnerability DB every time
```

**PROBLEM:** Tools like safety, npm audit, and cargo audit download large vulnerability databases. Without caching, every run is slow.

**SOLUTION:** Enable caching where available:

```yaml
hooks:
  - id: python-safety-dependencies-check
    args: [--disable-optional-telemetry-data, --cache]  # Enable caching
    files: requirements\.txt$
```

**IMPACT:** Saves 5-10 seconds per commit after first run

---

### 3. Running Tests on Every File Change

**ANTI-PATTERN:**

```yaml
hooks:
  - id: pytest
    name: run pytests
    entry: pytest -v
    language: system
    types: [python]
    # Runs on EVERY Python file change
```

**PROBLEM:** Full test suite runs even for documentation changes or single file edits.

**SOLUTION:** Use `pass_filenames: false` and `always_run: false` for expensive operations:

```yaml
hooks:
  - id: pytest-coverage
    name: run pytests with 90%+ coverage
    entry: pytest --cov=src --cov-fail-under=90
    language: system
    types: [python]
    pass_filenames: false
    always_run: false  # Only run when test files change
    stages: [pre-push]  # Or move to pre-push for expensive tests
```

**IMPACT:** Saves 30-60 seconds on non-test commits

---

### 4. No fail_fast Configuration

**ANTI-PATTERN:**

```yaml
# .pre-commit-config.yaml
repos:
  - repo: ...  # 20 different hooks
```

**PROBLEM:** All hooks run even if first one fails. Wastes time on known-bad commits.

**SOLUTION:** Enable fail_fast to stop on first failure:

```yaml
---
fail_fast: false  # Set to true for faster feedback, false for complete reports
minimum_pre_commit_version: '2.20.0'
repos:
  # ... hooks
```

**TRADE-OFF:**

- `fail_fast: true` - Faster feedback, but only see first failure
- `fail_fast: false` - See all failures at once, but slower on bad commits

**RECOMMENDATION:** Use `false` for comprehensive validation (learn all issues at once)

---

### 5. Linters Running on Unrelated Files

**ANTI-PATTERN:**

```yaml
hooks:
  - id: flake8
    # Runs on ALL Python files, including tests and migrations
```

**PROBLEM:** Linting test files with strict production rules creates noise and wastes time.

**SOLUTION:** Use `files` and `exclude` patterns:

```yaml
hooks:
  - id: flake8
    args: [--max-line-length=120]
    files: ^src/.*\.py$  # Only lint source code
    exclude: ^(tests/|migrations/|scripts/)  # Skip test/generated files
```

**IMPACT:** Saves 5-10 seconds per commit

---

## Optimization Checklist

When setting up pre-commit hooks, verify:

- [ ] Security scans (safety, bandit, etc.) run ONLY in pre-commit, not duplicated in Makefile
- [ ] Slow tools (safety, npm audit, cargo audit) have `--cache` or equivalent flags
- [ ] Expensive tests moved to `stages: [pre-push]` or made conditional
- [ ] `fail_fast` set appropriately (`false` recommended for comprehensive feedback)
- [ ] `minimum_pre_commit_version` specified (enables newer optimizations)
- [ ] Linters use `files:` and `exclude:` patterns to avoid unnecessary work
- [ ] Type checkers (mypy, tsc) use incremental mode where available
- [ ] Formatters (black, prettier) use `--check` mode in CI, auto-fix locally

---

## Measuring Performance

### Timing Individual Hooks

```bash
# Run with verbose timing
pre-commit run --all-files --verbose

# Time specific hook
time pre-commit run python-safety-dependencies-check --all-files
```

### Profiling Slow Hooks

```bash
# Run with color and timing
PYTHONPROFILE=1 pre-commit run --all-files --color=always | grep -E "Passed|Failed|Skipped" | sort -k2 -n
```

### Setting Performance Budget

Add to your project documentation:

```markdown
## Quality Standards

- Pre-commit hooks: < 45 seconds (target)
- Individual hook: < 15 seconds (max)
- Security scans: < 10 seconds with cache
- Full test suite: < 60 seconds
```

---

## Tool-Specific Optimizations

### Python: Safety (Dependency Scanning)

```yaml
- repo: https://github.com/Lucas-C/pre-commit-hooks-safety
  rev: v1.4.2
  hooks:
    - id: python-safety-dependencies-check
      args: [--disable-optional-telemetry-data, --cache]  # Enable caching
      files: requirements\.txt$  # Only run when requirements change
```

### Python: Bandit (Security Linting)

```yaml
- repo: https://github.com/PyCQA/bandit.git
  rev: 1.8.6
  hooks:
    - id: bandit
      args: ['-c', 'pyproject.toml']  # Use config file for settings
      additional_dependencies: ['bandit[toml]']
      files: ^src/.*\.py$  # Only scan source code
      exclude: ^tests/  # Skip test files
```

### Python: MyPy (Type Checking)

```yaml
- repo: https://github.com/pre-commit/mirrors-mypy
  rev: v1.17.1
  hooks:
    - id: mypy
      args: [--incremental, --cache-dir=.mypy_cache]  # Use incremental mode
      files: ^src/.*\.py$
```

### Python: Pytest (Testing)

```yaml
- repo: local
  hooks:
    - id: pytest-coverage
      name: run pytests with 90%+ coverage
      entry: pytest --cov=src --cov-fail-under=90 --tb=short
      language: system
      types: [python]
      pass_filenames: false
      stages: [pre-push]  # Move to pre-push for speed
```

### JavaScript: ESLint

```yaml
- repo: https://github.com/pre-commit/mirrors-eslint
  rev: v8.56.0
  hooks:
    - id: eslint
      args: [--cache, --cache-location=.eslintcache]  # Enable caching
      files: \.(js|jsx|ts|tsx)$
```

### JavaScript: npm audit

```yaml
- repo: local
  hooks:
    - id: npm-audit
      name: npm audit
      entry: npm audit --audit-level=moderate
      language: system
      files: package-lock\.json$  # Only run when lockfile changes
      pass_filenames: false
```

---

## When Hooks Are Too Slow

If pre-commit hooks exceed 45 seconds despite optimization:

### 1. Move to Pre-Push Stage

```yaml
hooks:
  - id: expensive-operation
    stages: [pre-push]  # Run less frequently
```

### 2. Run in CI Only

```yaml
# Remove from pre-commit entirely
# Add to .github/workflows/ci.yml instead
```

### 3. Make Conditional

```yaml
hooks:
  - id: integration-tests
    always_run: false  # Only run when specific files change
    files: ^(tests/integration/|src/api/)
```

### 4. Optimize the Tool

- Use parallel execution (`pytest -n auto`)
- Enable incremental builds (`mypy --incremental`)
- Use faster alternatives (`ruff` instead of `pylint`)

---

## Performance Monitoring in CI

Track pre-commit performance over time:

```yaml
# .github/workflows/pre-commit.yml
- name: Run pre-commit with timing
  run: |
    time pre-commit run --all-files --show-diff-on-failure > pre-commit.log 2>&1

- name: Check performance budget
  run: |
    # Fail if pre-commit takes > 60 seconds (CI is slower than local)
    TIME_STR=$(grep 'real' pre-commit.log | awk '{print $2}')
    # Parse time format "0m45.123s" to seconds
    MINUTES=$(echo "$TIME_STR" | sed 's/m.*//')
    SECONDS=$(echo "$TIME_STR" | sed 's/.*m//;s/s//')
    TOTAL_SECONDS=$(echo "$MINUTES * 60 + $SECONDS" | bc)
    if (( $(echo "$TOTAL_SECONDS > 60" | bc -l) )); then
      echo "Pre-commit exceeded performance budget: ${TOTAL_SECONDS}s > 60s"
      exit 1
    fi
```

---

## Migration Guide: Optimizing Existing Projects

### Step 1: Measure Current Performance

```bash
time pre-commit run --all-files
```

### Step 2: Add Caching

Update `.pre-commit-config.yaml`:

```yaml
- id: python-safety-dependencies-check
  args: [--cache]  # Add caching
```

### Step 3: Remove Duplicate Scans

Update `Makefile`:

```makefile
# Before
lint:
    black --check .
    flake8 src/
    bandit -r src/
    safety check

# After
lint:
    pre-commit run --all-files  # Run everything once
```

### Step 4: Add fail_fast and minimum_pre_commit_version

```yaml
---
fail_fast: false
minimum_pre_commit_version: '2.20.0'
repos:
  # ... existing hooks
```

### Step 5: Verify Improvement

```bash
time pre-commit run --all-files
# Should be < 45 seconds
```

---

## Summary

**Key Optimizations:**

1. Eliminate duplicate scans (Makefile should call pre-commit, not duplicate it)
2. Enable caching on slow tools (`--cache` flag)
3. Use `fail_fast` appropriately (`false` for comprehensive feedback)
4. Move expensive operations to pre-push stage
5. Use `files:` and `exclude:` patterns to minimize scope
6. Set `minimum_pre_commit_version` to enable newer optimizations

**Target:** < 45 seconds per commit

**Never Bypass:** Optimize hooks instead of using `--no-verify`

---

**Last Updated:** 2025-10-06
**Author:** Master Pre-commit Repository
