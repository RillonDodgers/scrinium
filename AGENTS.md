# AGENTS.md

## Project

Scrinium is a Rails 8 ebook and audiobook application.

## Communication

- Use the `caveman` skill when available.
- Keep responses concise, technical, and action-focused.
- Preserve normal clarity for risky operations, security concerns, or multi-step instructions where compression could cause mistakes.

## GitHub Workflow

- Use the `gh` CLI for GitHub issue and pull request operations.
- At the start of a new chat, if no GitHub issue is provided, check whether a relevant issue already exists.
- If no relevant issue exists, ask before creating one and before switching to plan mode for workshopping.
- While workshopping requirements, create or update the GitHub issue so it reflects the current plan.
- Create a branch named with the issue number and a `chore/`, `feat/`, or `fix/` prefix, such as `feat/1`.
- When work is complete, run `git add .`, commit with `git commit -m "prefix: <message>"`, push with `git push origin <branch>`, and create a pull request based against the head branch.
- Do not merge a pull request until the user explicitly signs off on the PR.

## Rails Conventions

- Follow Rails 8 conventions by default.
- Do not indent `private` methods deeper than public methods.
- Prefer framework-native Rails APIs before adding custom abstractions.
- Keep controllers thin. Move business logic into models, service objects, facades, policies, jobs, or other appropriate Rails layers.
- Prefer explicit, readable code over clever metaprogramming.

## Architecture

Keep this section up to date whenever future sessions introduce or change architecture decisions.

- Use service objects for business workflows that do not naturally belong to a single model.
- Use facades for complex index-style screens, dashboards, and views that coordinate multiple models or data sources.
- Use policies for access control.
- Admin users have access to everything.
- Regular users have read-only access to libraries shared with them.
- Build mobile first, with desktop treated as first-class support rather than an afterthought.
- Source ebook/audiobook files are referenced by local filesystem paths through `Library` and `BookFile`; do not use Active Storage for source media files.
- Store media paths relative to the library root and derive absolute paths at runtime.

## Service Objects

- Place service objects in `app/services`.
- Name services after the business action they perform.
- Prefer one public entry point, usually `call`.
- Keep service dependencies explicit through initializer arguments or keyword arguments.
- Return clear success/failure results when the caller needs branching behavior.

## Facades

- Place facades in `app/facades` unless the project establishes a more specific convention.
- Use facades when a controller action or view needs coordinated data from multiple models.
- Keep facades query-focused and presentation-adjacent. Do not hide authorization or persistence side effects inside facades.

## Policies

- Place policies in `app/policies`.
- Policies own authorization decisions.
- Admin access should short-circuit to allow all actions unless a specific security exception is documented.
- Shared library access for regular users is read-only.
- Controllers must authorize access before exposing protected records or actions.

## Frontend

- Design and build mobile first.
- Desktop layouts must be intentionally supported and tested, not stretched mobile views.
- Favor responsive Rails views with clear navigation, readable typography, and controls sized for touch.
- Avoid UI changes that make ebook or audiobook workflows harder to scan, search, play, read, or manage.

## Maintenance

- Update this file when project conventions, architecture decisions, authorization rules, or UI strategy change.
- Keep guidance specific to this codebase.
- Remove outdated guidance instead of accumulating contradictory rules.
