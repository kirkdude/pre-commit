# Pre-commit

This repository contains pre-commit configuration that uses a curated set of
linters and security checkers to enhance the quality and security of your
codebase. By integrating these tools into your development workflow, you can
catch issues early, maintain code consistency, and ensure adherence to best
practices.

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

After having many outdated pre-commit configurations in multiple repositories, this project aims to maintain
a single, up-to-date configuration that can be copied to other projects. This repository serves as the
"source of truth" for pre-commit configurations and is regularly updated with the latest hooks and best practices.

## Included Hooks

This pre-commit configuration includes several categories of hooks:

1. **Dockerfile Linting** - Checks Dockerfile for best practices using dockerlint
2. **Python Code Formatting** - Uses Black to format Python code per PEP 8
3. **General Pre-commit Checks** - Various file format, syntax, and security checks
4. **Python Security Linting** - Uses Bandit to find security issues in Python code
5. **Python Linting** - Uses Flake8 to enforce Python style conventions
6. **Terraform Linting and Validation** - Several tools for Terraform files (fmt, docs, validate, tflint, checkov, infracost)
7. **Python Dependency Management** - Uses pip-tools to manage dependencies
8. **AWS CloudFormation Linting** - Uses cfn-python-lint to check CloudFormation templates
9. **Local Testing** - Runs pytest for Python tests
10. **Ansible Linting** - Uses ansible-lint to check Ansible playbooks
11. **Markdown Linting** - Uses markdownlint to ensure consistent Markdown formatting
12. **Java Checks** - Uses PMD, CPD, and Checkstyle for Java code quality
13. **Pre-commit Trailers** - Adds metadata to commits about pre-commit usage
14. **Makefile Checking** - Uses checkmake to validate Makefiles
