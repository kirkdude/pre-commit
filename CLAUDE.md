# Pre-commit Development Guidelines

## Commands

- Run all checks: `pre-commit run --all-files`
- Run specific hook: `pre-commit run <hook-id> --all-files`
- Run tests: `pytest -v`
- Install hooks: `pre-commit install`
- Install dependencies: `pip install -r scripts/requirements.txt`

## Code Style

- Python: PEP 8 with Black formatter
- Line length: 120 characters (Python, Markdown)
- Python strings: Single quotes (enforced by double-quote-string-fixer)
- Python files: Include UTF-8 encoding pragma
- Tests: Name with *_test.py pattern

## Linting

- Python: flake8 (max-line-length=120), bandit for security
- Terraform: terraform_fmt, terraform_docs, terraform_validate
- Markdown: markdownlint-fix (line length 120)
- Ansible: ansible-lint
- Java: PMD, CPD, Checkstyle

## Contribution Workflow

1. Fork and branch
2. Make changes following style guidelines
3. Test with `pre-commit run --all-files`
4. Submit PR to main branch
5. Address feedback

## CI Pipeline

GitHub Actions workflow runs on PRs and pushes to main, ensuring all pre-commit checks pass.
