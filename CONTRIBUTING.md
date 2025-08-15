# Contributing to Godspeed

We love your input! We want to make contributing to Godspeed as easy and transparent as possible.

## Development Process

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

## Pull Requests

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that pull request!

## Code Style

* Use 2 spaces for indentation
* Follow existing naming conventions
* Add comments for complex logic
* Use descriptive variable and function names

### Bash Style Guide

Functions: snake_case
install_nodejs() { … }
Variables: snake_case
local project_name=“my-app”
Constants: UPPER_SNAKE_CASE
readonly GS_DIR=”$HOME/.godspeed”
Use safe commands for optional operations
safe_cmd npm cache clean
Always check for command availability
command -v node >/dev/null || { echo “Node.js required”; return 1; }

## Testing

Run all tests
./test/run-tests.sh
Test specific functionality
./test/test-installation.sh.
/test/test-templates.sh
./test/test-ai-integration.sh

## Issues

We use GitHub issues to track public bugs. Report a bug by opening a new issue.

### Bug Reports

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening)

## Feature Requests

We're always looking for suggestions to make Godspeed better. Feature requests should include:

- Clear description of the feature
- Use cases and benefits
- Any implementation ideas

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
