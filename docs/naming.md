# Naming Conventions

Consistent naming improves discoverability for both humans and AI agents.

## Scripts
- Filenames: lowercase-hyphen-separated (e.g., `setup-projects-idempotent.sh`).
- Categories embedded by path or prefix (avoid redundant words).

## Bash Functions
- snake_case (e.g., `detect_platform`, `get_projects_root`).
- Private helpers may prefix with `_`.

## Environment Variables
- UPPER_SNAKE_CASE; project-scoped variables begin with `DOTFILES_` (e.g., `DOTFILES_PLATFORM`).

## Components
- IDs in `components.yaml`: lowercase_snake or single words; stable once published.

## Docs
- Markdown filenames: lowercase-hyphen (e.g., `env-schema.md`, `wizard.md`).

## Commits
- Conventional type prefixes (see `CONTRIBUTING.md`).

## Rationale
- Hyphenated filenames map well to CLI ergonomics and search.
- snake_case functions reduce ambiguity vs camelCase in shell.
- Consistent prefixes improve vector search recall for AI.

## Migration Guidance
- New files must follow these rules.
- Existing inconsistencies corrected opportunistically; avoid large renames that break user habits without value.
