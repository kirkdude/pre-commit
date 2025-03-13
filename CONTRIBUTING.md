# Contributing to Pre-commit Configuration

Thank you for your interest in contributing to this pre-commit configuration repository! This document provides guidelines and instructions to help you contribute effectively.

## How to Contribute

### Reporting Issues

If you encounter issues with the pre-commit configuration or installation scripts:

1. Check if the issue already exists in the [Issues](https://github.com/kirkdude/pre-commit/issues) section.
2. If not, create a new issue, providing:
   - A clear title and description
   - Steps to reproduce the issue
   - Expected vs. actual behavior
   - Environment details (OS, pre-commit version, etc.)

### Suggesting New Hooks

To suggest new pre-commit hooks:

1. Create an issue describing the hook
2. Include:
   - The hook's purpose
   - The repository URL
   - How it improves code quality
   - Any setup requirements

### Adding or Updating Hooks

To contribute new hooks or update existing ones:

1. Fork the repository
2. Create a new branch with a descriptive name
3. Make your changes (follow the [pre-commit hook standards](https://pre-commit.com/#new-hooks))
4. Test your changes thoroughly
5. Create a pull request with a clear description of the changes

### Improving Installation Scripts

When updating the installation scripts:

1. Ensure cross-platform compatibility when possible
2. Add clear error messages and status updates
3. Test on the target platform before submitting
4. Document any new dependencies or requirements

## Development Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/kirkdude/pre-commit.git
   cd pre-commit
   ```

2. Install pre-commit:

   ```bash
   pip install pre-commit
   ```

3. Install the git hooks:

   ```bash
   pre-commit install
   ```

## Testing

Before submitting changes, test them thoroughly:

1. Test any new or modified hooks on various file types
2. Verify installation scripts work on their respective platforms
3. Run pre-commit against the repository itself:

   ```bash
   pre-commit run --all-files
   ```

## Pull Request Process

1. Ensure your changes are well-tested
2. Update the README.md if necessary
3. Submit a pull request to the `main` branch
4. Verify that your PR passes the automated pre-commit checks
5. Wait for review and address any feedback

A GitHub Actions workflow automatically runs pre-commit checks on all pull requests. Your PR will need to pass these checks before it can be merged.

Thank you for helping improve this project!
