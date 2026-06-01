# Post-release feedback loop

This document is the lightweight intake log for integrator feedback after a public release. It exists so the team can:
- Track real adoption patterns.
- Triage contract and runtime friction by severity.
- Decide when (and whether) to start a TypeScript SDK.

## How to collect feedback

- GitHub Discussions: post a weekly prompt asking for top pain points.
- GitHub Issues: use the `integrator-feedback` template.
- Direct contact: copy the relevant pieces into this file under a new entry.

## Log

| Date | Source | Version | Persona | Severity | Summary | Status |
|------|--------|---------|---------|----------|---------|--------|
| yyyy-mm-dd | issue/discussion link | 0.1.x | app maker / tgc fan / game dev / vibecoder / designer | P0..P3 | one line | open |

## Categories to track

- Contract confusion (schema, fields, required vs optional)
- Runtime errors (shader load, asset fallback, codec errors)
- Performance constraints (FPS, startup, web bundle size)
- Documentation gaps (quickstart, advanced, examples)
- Extensibility (custom shaders, custom fonts, custom layers)

## Cadence

- Weekly: skim new issues, tag with `integrator-feedback`.
- Monthly: roll up top 3 themes into CHANGELOG `Unreleased` and any roadmap update.
- Per release: re-evaluate the TS-readiness checklist below.
