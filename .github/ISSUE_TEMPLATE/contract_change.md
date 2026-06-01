---
name: Contract / stability change
about: Propose a change to the public JSON contract or codec behavior
labels: contract
---

## Summary

Brief one-sentence description of the proposed change.

## Motivation

Why is this change necessary? What integrators does it affect?

## Impact

- [ ] Additive (no version bump required)
- [ ] Breaking (requires a major version bump and migration)

## Proposed migration plan

How will `CardDocumentCodec.migrateAndDecode` handle existing payloads?

## Test plan

What tests will guard against regressions?
