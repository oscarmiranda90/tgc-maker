import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tgc_maker/persistence/card_document_codec.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> minimalValid() => {
    'schemaVersion': '1.0.0',
    'id': 'card_1',
    'title': 't',
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
  };

  test('fromJson raises CardCodecException for missing id', () async {
    final payload = minimalValid()..remove('id');

    await expectLater(
      CardDocumentCodec.fromJson(payload),
      throwsA(isA<CardCodecException>()),
    );
  });

  test(
    'fromJson raises CardCodecException for non-numeric cornerRadius',
    () async {
      final payload = minimalValid()..['cornerRadius'] = 'oops';

      await expectLater(
        CardDocumentCodec.fromJson(payload),
        throwsA(
          isA<CardCodecException>().having(
            (e) => e.field,
            'field',
            'cornerRadius',
          ),
        ),
      );
    },
  );

  test('fromJson raises CardCodecException for unknown size preset', () async {
    final payload = minimalValid();
    (payload['size'] as Map)['preset'] = 'mythic';

    await expectLater(
      CardDocumentCodec.fromJson(payload),
      throwsA(
        isA<CardCodecException>().having(
          (e) => e.field,
          'field',
          'size.preset',
        ),
      ),
    );
  });

  test('round-trip is stable through jsonEncode/jsonDecode', () async {
    final firstPass = await CardDocumentCodec.fromJson(minimalValid());
    final encoded = await CardDocumentCodec.toJson(
      firstPass.document,
      const {},
    );
    final secondPass = await CardDocumentCodec.fromJson(
      jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>,
    );

    expect(secondPass.document.id, firstPass.document.id);
    expect(secondPass.document.title, firstPass.document.title);
    expect(
      secondPass.document.front.layers.length,
      firstPass.document.front.layers.length,
    );
  });
}
