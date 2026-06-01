# Contributing to TGC Maker

Thanks for your interest in contributing. This guide explains how to set up the project, run checks, and submit changes safely.

## Local setup

```bash
flutter pub get
cd example && flutter pub get
```

## Required checks before opening a pull request

1. `flutter analyze` (root) — must report no new warnings introduced by your change.
2. `flutter test` (root) — all tests must pass.
3. `cd example && flutter analyze` — example must remain clean.
4. If you touched a shader under `assets/shaders/`, run `cd example && flutter build web --release --base-href "/"` to confirm SkSL compatibility.

## JSON contract policy

`CardDocumentCodec` is a public, versioned API.

- Required top-level fields are pinned by a contract-shape gate test. Adding or removing required fields is a breaking change.
- `currentSchemaVersion` is part of the public surface. Bumping it requires:
  - A migration entry in `migrateAndDecode`.
  - A CHANGELOG entry tagged as breaking.
  - An updated test fixture.

## Pull request expectations

1. Use a focused branch and PR title (e.g. `codec: validate size preset`).
2. Include a short summary, screenshots for UI changes, and a note on any contract impact.
3. Reference any related issue.
4. Do not include unrelated formatting or generated files.

## Reporting issues

Use the issue templates (`.github/ISSUE_TEMPLATE`) when available. For contract or stability questions, mention the codec `schemaVersion` you are observing.
