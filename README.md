# Pre-commit

[![Build Status](https://github.com/kirkdude/pre-commit/actions/workflows/pre-commit.yml/badge.svg)
](https://github.com/kirkdude/pre-commit/actions/workflows/pre-commit.yml)

This repository contains pre-commit configuration that uses a curated set of
linters and security checkers to enhance the quality and security of your
codebase. By integrating these tools into your development workflow, you can
catch issues early, maintain code consistency, and ensure adherence to best
practices.

## Quick Start

**Using this config in any project:**

```bash
# 1. Copy the config to your project
curl -O https://raw.githubusercontent.com/kirkdude/pre-commit/main/.pre-commit-config.yaml

# 2. Install pre-commit framework
pip install pre-commit

# 3. Install hooks
pre-commit install

# 4. Test it
pre-commit run --all-files
```

**Result:** All applicable hooks run automatically on every commit. Language-specific hooks auto-skip if not relevant to your project.

**Note:** Local hooks provide fast feedback but can be bypassed with `--no-verify`. Real enforcement happens in CI/CD (see below).

## Installation

### Mac

- Copy `.pre-commit-config.yaml` to your repo
- Copy the `scripts` directory to your repo, or move the contents
- Run the `install_osx.sh` script to set up the dependencies and tools, and the git hook

### Windows

- Copy `.pre-commit-config.yaml` to your repo
- Copy the `scripts` directory to your repo, or move the contents
- Run the `install_windows.ps1` script to set up dependencies and tools, and the git hook

### Linux

- Copy `.pre-commit-config.yaml` to your repo
- Copy the `scripts` directory to your repo, or move the contents
- Run the `setup_run_pre-commit_linux.sh` script to set up dependencies and tools, and the git hook

Please contribute updates and fixes for these scripts.

## Usage

Once installed, the pre-commit hooks will automatically run whenever you commit
changes to your local repository. If any issues are detected by the linters or
security checkers, the commit will be aborted, allowing you to fix the issues
before proceeding. Additionally, some linters and checkers will modify (or fix)
issues automatically, in these cases, redo the commit to see if the issue is
remediated.

You can also manually run the pre-commit tool at any time by running:

```bash
pre-commit run --all-files
```

## Configuration

You can configure the behavior of the pre-commit hooks by editing the
`.pre-commit-config.yaml` file in your repository. This file defines which hooks
are run and allows you to customize their settings.

For more information on configuring pre-commit, please refer to the [official documentation](https://pre-commit.com/).

## Why This Repository?

After having many outdated pre-commit configurations in multiple repositories, this project
aims to maintain a single, up-to-date configuration that can be copied to other projects.
This repository serves as the "source of truth" for pre-commit configurations and is
regularly updated with the latest hooks and best practices.

## Key Features

### 1. CI Enforcement (GitHub Actions)

**Automatic quality enforcement via GitHub Actions** - no bypasses possible:

- ✅ Runs `pre-commit run --all-files` on every PR
- ✅ Cannot be bypassed with `--no-verify` (runs on GitHub's servers)
- ✅ Enforced via branch protection rules
- ✅ Blocks merging until all checks pass
- ✅ Works for all contributors automatically

**Implementation:** See [.github/workflows/pre-commit.yml](./.github/workflows/pre-commit.yml)

**Why local hooks can't enforce:**

- `git commit --no-verify` skips ALL hooks completely
- Hook-based enforcement is fundamentally impossible
- CI enforcement is the only reliable solution

**Setup branch protection:**

1. Settings → Branches → Branch protection rules
2. Require status checks to pass before merging
3. Select "Pre-commit Checks" workflow
4. Apply to administrators too

**Documentation:** [docs/bypass-enforcement.md](./docs/bypass-enforcement.md)

### 2. Performance Optimizations

Keep pre-commit hooks **under 45 seconds** without sacrificing quality:

**Key Optimizations:**

1. **Eliminate duplicate scans**: Run tools once in pre-commit, not in Makefile too
2. **Enable caching**: Add `--cache` flags to slow tools (safety, npm audit, etc.)
3. **Smart configuration**: Use `fail_fast: false` for comprehensive feedback
4. **File targeting**: Use `files:` and `exclude:` patterns to minimize scope
5. **Stage management**: Move expensive operations to pre-push hooks

**Example optimization:**

```yaml
# Before: 90 seconds
- id: python-safety-dependencies-check

# After: 5 seconds (with cache)
- id: python-safety-dependencies-check
  args: [--disable-optional-telemetry-data, --cache]
  files: requirements\.txt$  # Only run when requirements change
```

**Documentation:** [docs/performance-optimization.md](./docs/performance-optimization.md)

### 3. Universal Language Support

**One config for all languages** - hooks auto-skip when not applicable:

- Python (black, flake8, bandit, mypy, safety)
- JavaScript/TypeScript (eslint, prettier, npm audit)
- Java (PMD, checkstyle, CPD)
- C/C++ (clang-format, cppcheck, cpplint)
- Shell scripts (shellcheck)
- Terraform (fmt, validate, tflint, checkov)
- Docker (dockerlint)
- Ansible (ansible-lint)
- Markdown (markdownlint)

**DRY Principle:** No per-language templates needed. Copy `.pre-commit-config.yaml` to any project.

## Included Hooks

This pre-commit configuration includes several categories of hooks:

1. **Dockerfile Linting** - Checks Dockerfile for best practices using dockerlint
2. **Python Code Formatting** - Uses Black to format Python code per PEP 8
3. **General Pre-commit Checks** - Various file format, syntax, and security checks
4. **Python Security Linting** - Uses Bandit to find security issues in Python code
5. **Python Linting** - Uses Flake8 to enforce Python style conventions
6. **Terraform Linting and Validation** - Several tools for Terraform files
   (fmt, docs, validate, tflint, checkov, infracost)
7. **Python Dependency Management** - Uses pip-tools to manage dependencies
8. **AWS CloudFormation Linting** - Uses cfn-python-lint to check CloudFormation templates
9. **Local Testing** - Runs pytest for Python tests
10. **Ansible Linting** - Uses ansible-lint to check Ansible playbooks
11. **Markdown Linting** - Uses markdownlint to ensure consistent Markdown formatting
12. **Java Checks** - Uses PMD, CPD, and Checkstyle for Java code quality
13. **Pre-commit Trailers** - Adds metadata to commits about pre-commit usage
14. **Makefile Checking** - Uses checkmake to validate Makefiles
15. **C/C++ Code Quality** - clang-format, cppcheck, cpplint for C/C++ projects
16. **Shell Script Linting** - shellcheck for bash/sh script validation
17. **Bison/Flex Validation** - Syntax checking for parser generators

## Troubleshooting

### Hooks Are Too Slow (> 45 seconds)

**Don't use `--no-verify`!** Instead:

1. **Optimize first**: See [docs/performance-optimization.md](./docs/performance-optimization.md)
   - Enable caching on slow tools
   - Remove duplicate scans from Makefile
   - Move expensive operations to pre-push stage

2. **Skip specific hooks temporarily**:

   ```bash
   SKIP=pytest-coverage,integration-tests git commit -m "message"
   ```

3. **Disable broken hooks temporarily**:

   ```yaml
   # .pre-commit-config.yaml
   - id: broken-hook
     exclude: '.*'  # Disabled: ticket PROJECT-123
   ```

### Pre-commit Not Running

```bash
# Verify hooks are installed
ls -la .git/hooks/pre-commit

# Reinstall hooks
pre-commit uninstall
pre-commit install

# Test manually
pre-commit run --all-files
```

### Hooks Failing in CI But Passing Locally

```bash
# Update to latest hook versions
pre-commit autoupdate

# Clear cache
pre-commit clean

# Run exactly as CI does
pre-commit run --all-files --show-diff-on-failure
```

## Documentation

- [Quality Enforcement Guide](./docs/bypass-enforcement.md) - Why local enforcement fails and how CI solves it
- [Performance Optimization](./docs/performance-optimization.md) - Keep hooks under 45 seconds
- [Official pre-commit docs](https://pre-commit.com/) - Framework documentation

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines on:

- Updating hook versions
- Adding new language support
- Reporting issues
- Submitting improvements

## License

See [LICENSE](./LICENSE)
