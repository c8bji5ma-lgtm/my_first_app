# OshiLog Development Instructions

## Project
OshiLog is a Ruby on Rails application for recording, reviewing,
and visualizing oshi activities.

Current environment:
- Ruby 4.0.6
- Rails 8.1.4
- PostgreSQL 18.6

## Source of truth
Implementation must follow:
1. GitHub Issues
2. Current requirements documentation
3. ER diagram / table definition
4. Existing code

Do not invent new requirements.

If an Issue conflicts with the current implementation or requirements,
stop and report the conflict before changing code.

## Development rules
- Work on one GitHub Issue at a time.
- Do not implement features outside the current Issue.
- Inspect existing code before editing.
- Prefer the smallest change that satisfies the Issue.
- Do not perform unrelated refactoring.
- Do not change database design without explicit approval.
- Do not change README unless the Issue requires it.
- Do not commit or push unless explicitly instructed.

## Database safety
Never run these without explicit approval:
- db:drop
- db:reset
- db:schema:load
- destructive SQL
- force push

Before migrations, explain what the migration changes.

## Testing
After implementation:
- run the relevant RSpec tests
- run the broader test suite when appropriate
- run RuboCop / project static checks
- report failures instead of hiding them

Do not modify tests only to make a failing implementation pass.

## Reporting
After each task, report:
1. Files changed
2. What was implemented
3. Tests executed
4. Test results
5. Remaining issues or risks

## Scope
MVP centers on:
- recording oshi activities
- reviewing activity history
- data visualization

Do not introduce future features such as public profile URLs,
QR sharing, or social/community features unless explicitly requested.