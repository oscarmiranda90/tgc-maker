# TGC Maker

Open-source Flutter framework for creating holographic Trading Card Game cards with parallax and shader effects.

## Features

- **6 holographic shaders** — Holographic, Sparkle, Pixel Foil, Rainbow Foil, Oil Slick, Sequins
- **Layer-based editor** — Background / Art / Layout layer groups, reorderable, per-layer opacity and visibility
- **Parallax engine** — Accelerometer + gyroscope driven. Each layer has a configurable depth factor. Idle orbit animation on web.
- **Card size presets** — Standard (63×88mm / 750×1050px), Japanese (59×86mm / 700×1015px), or custom
- **Card boundary clipping** — GPU `clipRRect` ensures nothing ever bleeds outside the card
- **Export** — PNG capture via `RepaintBoundary` + share sheet

## Getting started

```bash
git clone https://github.com/tgcmaker/tgc-maker.git
cd tgc-maker
flutter pub get
flutter run
```

For the GitHub Pages demo:

```bash
flutter build web --base-href /tgc-maker/
```

## Use as a library

```yaml
# pubspec.yaml
dependencies:
  tgc_maker:
    git: https://github.com/tgcmaker/tgc-maker.git
```

```dart
import 'package:tgc_maker/tgc_maker.dart';

// Render any card with parallax + shaders
CardPreviewWidget(
  document: myCard,
  shaderPrograms: editorModel.shaders,
  maxWidth: 280,
  maxHeight: 400,
)
```

## Architecture

```
lib/
  core/          — CardSize, theme, constants
  models/        — CardDocument, CardLayer (sealed), ShaderConfig
  engine/        — CardPainter, ShaderPainter, GlossPainter, shader registry
  parallax/      — TiltController (accelerometer + ticker), ParallaxCard widget
  state/         — CardModel + EditorModel (ChangeNotifier)
  screens/       — Home, SizePicker, Editor, Export
  widgets/       — CardPreviewWidget, LayerPanel, ShaderPicker, EffectControls
  demo/          — Hardcoded demo presets for GitHub Pages
assets/shaders/  — 6 GLSL fragment shaders
```

## License

MIT
