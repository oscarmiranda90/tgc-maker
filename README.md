# TGC Maker

TGC Maker is a Flutter toolkit for building holographic Trading Card Game cards with shader and parallax effects.

It supports two public release use cases:

1. Use it as a package inside your own Flutter app.
2. Run and deploy the `example/` app as a standalone tester.

## Features

- 6 holographic shaders: Holographic, Sparkle, Pixel Foil, Rainbow Foil, Oil Slick, Sequins
- Layer-based card composition (background, art, layout) with ordering controls
- Parallax rendering driven by motion sensors (with web-safe behavior)
- Card size presets plus custom sizes
- GPU card clipping so layers stay inside card bounds
- PNG export and sharing support

## Card JSON contract (stable)

The package exposes a versioned JSON contract for serializing cards so integrators can persist, exchange, and validate them safely.

- Current schema version: `1.0.0` (exposed as `CardDocumentCodec.currentSchemaVersion`)
- Legacy payloads without `schemaVersion` are accepted and reported as migrated from `0.x`.
- Use `CardDocumentCodec.migrateAndDecode(json)` to safely decode any known version.
- The `schemaVersion` field is required for all new payloads.

Required top-level fields:
- `schemaVersion` (string)
- `id` (string)
- `title` (string)
- `size` (object: `preset`, `widthPx`, `heightPx`, `label`)
- `cornerRadius`, `frameWindowInset`, `frameWindowRadius` (number)
- `activeSide` (`front` or `back`)
- `front` and `back` face objects

Compatibility policy:
- Additive optional fields are allowed in minor releases.
- Renaming or removing fields requires a major version bump and a migration.
- New `schemaVersion` values must be supported by `migrateAndDecode` or rejected with a `FormatException`.

## Local development (package + standalone tester)

```bash
git clone https://github.com/tgcmaker/tgc-maker.git
cd tgc-maker
flutter pub get
(cd example && flutter pub get)
```

Run the standalone tester app:

```bash
cd example
flutter run
```

## Use as a package in another Flutter app

Until published to pub.dev, install from GitHub:

```yaml
dependencies:
  tgc_maker:
    git:
      url: https://github.com/tgcmaker/tgc-maker.git
```

Then import the public API:

```dart
import 'package:tgc_maker/tgc_maker.dart';
```

Minimal usage pattern:

```dart
final editorModel = EditorModel();
await editorModel.loadShaders();
await editorModel.loadFonts();

final doc = CardDocument.blank(size: CardSize.standard).copyWith(
  layers: const [
    ColorLayer(
      id: 'bg',
      group: LayerGroup.background,
      zIndex: 0,
      name: 'Background',
      color: Color(0xFF0A0E1C),
      shaderConfig: ShaderConfig(
        shaderAsset: TgcShaders.holographic,
        opacity: 0.9,
      ),
    ),
  ],
);

CardPreviewWidget(
  document: doc,
  shaderPrograms: editorModel.shaders,
  maxWidth: 320,
  maxHeight: 450,
)
```

See the runnable integration sample in `example/`.

## Run the package example

```bash
cd example
flutter pub get
flutter run
```

## Standalone web demo deployment

The standalone tester is deployed from `example/` to **Cloudflare Pages** via Wrangler. See [cloudflare-pages/README.md](cloudflare-pages/README.md) for the one-time setup and deploy commands.

Local verification:

```bash
(cd example && flutter build web --release --base-href "/")
```

## Release checklist

The public maintainer checklist lives in [doc/RELEASE.md](doc/RELEASE.md). Quick verification for any change:

```bash
flutter pub get
flutter analyze
flutter test
(cd example && flutter pub get && flutter analyze)
(cd example && flutter build web --release --base-href "/")
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, the JSON contract policy, and PR expectations. Use the issue and PR templates under [.github/](.github/) to keep changes traceable.

## Post-release feedback and roadmap

- Integrator feedback intake: [doc/FEEDBACK.md](doc/FEEDBACK.md) and the `integrator-feedback` issue template.
- Maintainer release checklist: [doc/RELEASE.md](doc/RELEASE.md).
- TypeScript SDK readiness gates: [doc/TS_READINESS.md](doc/TS_READINESS.md). A TypeScript SDK is not started until the documented gates are met.

## Architecture

```
lib/
  core/          - CardSize, theme, constants
  models/        - CardDocument, CardLayer, ShaderConfig
  engine/        - CardPainter, ShaderPainter, GlossPainter, shader registry
  parallax/      - TiltController and ParallaxCard
  state/         - CardModel and EditorModel
  screens/       - Internal editor/demo screens (not part of public API)
  widgets/       - CardPreviewWidget, LayerPanel, ShaderPicker, controls
  persistence/   - CardDocumentCodec (public JSON contract)
assets/shaders/  - GLSL fragment shaders
example/         - Consumer app that uses package:tgc_maker
```

## License

MIT
