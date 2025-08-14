# ADR 0001: Adopt Component Manifest and Standard Script Headers
Date: 2025-08-13
Status: Accepted

## Context
Historically, component orchestration logic was spread across multiple wizard scripts, and no single machine-readable manifest existed. This hindered AI agent planning and human onboarding. Additionally, script metadata (dependencies, idempotency) was implicit.

## Decision
Introduce a `components.yaml` manifest enumerating each configurable component with script path, dependencies, idempotency, and tests. Standardize a header block for all new/updated scripts capturing description, category, dependencies, idempotency, inputs, outputs, and exit codes.

## Consequences
+ Improved discoverability for humans and tooling
+ Enables automated validation/matrix test generation
+ Reduces duplication in setup wizards
- Requires maintenance discipline to keep manifest in sync

## Alternatives Considered
1. Implicit discovery by scanning scripts (fragile, inconsistent)
2. Using only README documentation (not machine-readable)

## Follow-ups
- Add validation script to ensure every manifest entry script exists
- Auto-generate documentation section from manifest
