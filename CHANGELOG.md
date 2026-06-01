# Changelog

All notable changes to TGC Maker are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Public `CardDocumentCodec` for stable JSON serialization of card documents.
- `CardDocumentCodec.migrateAndDecode` for safe decoding across schema versions.
- `CardCodecException` typed error for safe, consumer-facing failure handling.
- Contract-shape gate test pinning the required top-level field set.
- Reliability tests for invalid payloads and round-trip stability.
- Example consumer app demonstrating JSON loading + migration + rendering.

## [0.1.0] - Initial public preview

### Added
- Initial Flutter package and standalone web demo.
- 6 holographic shaders (Holographic, Sparkle, Pixel Foil, Rainbow Foil, Oil Slick, Sequins).
- Layer-based card composition with parallax rendering.

[Unreleased]: https://github.com/tgcmaker/tgc-maker/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/tgcmaker/tgc-maker/releases/tag/v0.1.0
