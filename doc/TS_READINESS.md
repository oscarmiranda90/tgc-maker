# TypeScript SDK readiness checklist

This checklist guards the start of a TypeScript SDK workstream. It exists so the team does not split effort prematurely. Do not start TS implementation until every gate below is met.

## Stability gates (required to start)

- [ ] `CardDocumentCodec.currentSchemaVersion` is published in **two consecutive releases** without further changes.
- [ ] No breaking-contract issues opened in the previous 30 days.
- [ ] All required top-level fields have been stable for at least one minor release.
- [ ] The contract-shape gate test passes on every PR for the last 30 days.
- [ ] Round-trip + reliability tests pass on CI for the last 30 days with no skipped or quarantined tests.

## Documentation gates (required to start)

- [ ] Public JSON contract section in [README.md](README.md) is current.
- [ ] At least one non-trivial integrator example is shipped (the consumer app).
- [ ] Migration policy is documented (additive-only in minor, major bump required for breaking).

## Adoption gates (recommended to start)

- [ ] At least 3 real integrator feedback entries in [doc/FEEDBACK.md](doc/FEEDBACK.md) labeled `web` or `node`.
- [ ] At least one explicit user request for an npm package in issues or discussions.
- [ ] No open P0 contract or runtime bugs.

## Scope gates (must be defined before kickoff)

- [ ] Renderer backend decision documented: Canvas 2D first, WebGL later, or both.
- [ ] Effect parity matrix drafted (which effects are exact ports vs fallbacks).
- [ ] Node.js support scope decided (yes / no, and how).
- [ ] Package layout agreed: monorepo alongside Flutter SDK, or new repo.

## Process gates

- [ ] Owner assigned for the TS SDK workstream.
- [ ] Telemetry or manual signal in place to measure TS-specific adoption.
- [ ] Rollback plan: if TS churns the contract, the Flutter SDK remains the source of truth.

## Exit criteria for the TS MVP

- [ ] `npm install <pkg>` works in a clean Vite + React app.
- [ ] Renderer consumes the same JSON fixture as the Flutter example and produces a non-empty output.
- [ ] Public types mirror the codec schema (breaking changes require a Flutter SDK release first).
- [ ] Web demo reuses the TS package for the standalone app.
