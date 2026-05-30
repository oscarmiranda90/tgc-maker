// TGC Maker — public library API
// Import this in your Flutter project to use the engine.
//
// Example:
//   import 'package:tgc_maker/tgc_maker.dart';
//
//   CardPreviewWidget(
//     document: myCard,
//     shaderPrograms: myEditorModel.shaders,
//   )

export 'core/card_sizes.dart';
export 'engine/card_painter.dart';
export 'engine/gloss_painter.dart';
export 'engine/shader_painter.dart';
export 'engine/shader_registry.dart';
export 'models/card_document.dart';
export 'models/card_layer.dart';
export 'models/layer_group.dart';
export 'models/shader_config.dart';
export 'parallax/parallax_card.dart';
export 'parallax/tilt_controller.dart';
export 'parallax/tilt_state.dart';
export 'state/card_model.dart';
export 'state/editor_model.dart';
export 'widgets/card_preview_widget.dart';
