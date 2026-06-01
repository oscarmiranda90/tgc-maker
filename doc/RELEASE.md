# Release checklist (maintainers)

Run this checklist before tagging a new public release.

## Pre-release

1. Update `CHANGELOG.md` with all notable changes since the last tag.
2. Confirm `CardDocumentCodec.currentSchemaVersion` is correct. If it changes, follow the JSON contract policy in `CONTRIBUTING.md`.
3. Confirm the example app still matches the documented integrator flow.

## Validation

1. `flutter pub get` on root and example.
2. `flutter analyze` on root and example (no new issues).
3. `flutter test` on root (all tests pass).
4. `cd example && flutter build web --release --base-href "/"` (web deploy artifact builds).
5. Manual smoke: run the example app and load `assets/integrator_sample_card.json` end to end.

## Tag and publish

1. Bump `version` in `pubspec.yaml` following semver.
2. Tag the commit: `git tag vX.Y.Z`.
3. Push the tag to trigger the release workflow.
4. If publishing to pub.dev, run `flutter pub publish` after the tag is published.

## Post-release

1. Deploy the web demo to Cloudflare Pages:
   ```bash
   cd example
   flutter build web --release --base-href "/"
   wrangler pages deploy build/web --project-name tgc-maker-web
   ```
2. Open a short release note summarizing the headline change(s) and any contract impact.
