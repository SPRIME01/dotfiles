# Maintenance Schedule

Defines cadence for reviewing and updating dotfiles components.

## Weekly
- Review Dependabot PRs (GitHub Actions updates).
- Run `just test` locally on latest main.

## Monthly
- Audit new scripts for header compliance and strict mode.
- Refresh pinned versions (oh-my-posh) if security advisories exist.
- Review open technical debt items; close resolved ones.

## Quarterly
- Evaluate adding/removing components.
- Update documentation index and ADRs.
- Re-measure performance baseline (see `tools/measure-startup.sh`).

## As Needed
- Security patches for dependencies.
- Add new environment variables to `env-schema.md`.

## Roles
- Maintainer (you): triage PRs, approve Dependabot, curate backlog.
- Contributors: follow `CONTRIBUTING.md` and submit focused changes.

## Tracking
Record decisions via ADRs (`docs/adr/`). Keep technical debt report synchronized after each remediation.
