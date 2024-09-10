# Pre-commit

This repository contains pre-commit configuration that use a curated set of
linters and security checkers to enhance the quality and security of your
codebase. By integrating these tools into your development workflow, you can
catch issues early, maintian code consistency, and ensure adherence to best
practices.

## Installlation

### Mac

- Copy .pre-commit-config.yaml to your repo
- Copy the .../scripts directory to your repo, or move the contents
- Run the install_osx.sh to setup the dependencies and tools, and the git hook*

### Windows

- Copy .pre-commit-config.yaml to your repo
- Copy the .../scripts directory to your repo, or move the contents
- Run the install_windows.ps1 to setup and tools, and the git hook*

- Please contribute updates and fixes for these script

## Usage

Once installed, the pre-commit hooks will automatically run whenever you commit
changes to your local repository.  If any issues are detected by the linters or
security checkers, the commit will be aborted, allowing you to fix the issues
before proceding.  Additionally some linters and checkers will modify (or fix)
issues automaticly, in these cases, redo the commit to see if the issue is
remediated.

You can also manually run the pre-commit tool at anytime by running:

`pre-commit run --all-files`

## Configuration

You can configure the behavior of the pre-commit hooks by editing the
.pre-commit-config.yaml file in your repository.  This file defines which hooks
are run and allows you to customize their settings.

For more information on configuring pre-commit, please refer to the official documentation.

## The Why?

After having many outdated versions in all my repos, lets just keep this
current in one place, and copy everywhere.  This repo is diff'd with other
repos, but this is considered a "master" configuration repo for my updates to
pre-commit.
