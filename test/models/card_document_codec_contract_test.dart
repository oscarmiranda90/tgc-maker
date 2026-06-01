import 'package:flutter_test/flutter_test.dart';
import 'package:tgc_maker/core/card_sizes.dart';
import 'package:tgc_maker/models/card_document.dart';
import 'package:tgc_maker/persistence/card_document_codec.dart';

void main() {
  test(
    'migrateAndDecode migrates legacy payloads and tags the version',
    () async {
      final legacy = <String, dynamic>{
        'id': 'card_legacy',
        'title': 'Legacy',
        'size': {
          'preset': 'standard',
          'widthPx': 750,
          'heightPx': 1050,
          'label': 'Standard (63x88 mm)',
        },
        'cornerRadius': 18.0,
        'frameWindowInset': 12.0,
        'frameWindowRadius': 10.0,
        'layers': const [],
      };

      final result = await CardDocumentCodec.migrateAndDecode(legacy);
      expect(result.migratedFromVersion, CardDocumentCodec.legacyVersion);
      expect(result.decoded.document.id, 'card_legacy');
    },
  );

  test('migrateAndDecode rejects unsupported future versions', () async {
    final future = <String, dynamic>{
      'schemaVersion': '2.0.0',
      'id': 'card_future',
      'title': 'Future',
      'size': {
        'preset': 'standard',
        'widthPx': 750,
        'heightPx': 1050,
        'label': 'Standard (63x88 mm)',
      },
      'cornerRadius': 18.0,
      'frameWindowInset': 12.0,
      'frameWindowRadius': 10.0,
      'front': const {},
      'back': const {},
      'activeSide': 'front',
    };

    expect(
      () => CardDocumentCodec.migrateAndDecode(future),
      throwsFormatException,
    );
  });

  test(
    'toJson emits the documented stable field set (contract shape gate)',
    () async {
      final doc = CardDocument.blank(size: CardSize.standard);
      final json = await CardDocumentCodec.toJson(doc, const {});

      const requiredTopLevelFields = {
        'schemaVersion',
        'id',
        'title',
        'size',
        'cornerRadius',
        'frameWindowInset',
        'frameWindowRadius',
        'activeSide',
        'front',
        'back',
      };

      for (final field in requiredTopLevelFields) {
        expect(json.containsKey(field), isTrue, reason: 'missing $field');
      }
      expect(json['schemaVersion'], CardDocumentCodec.currentSchemaVersion);
    },
  );
}
