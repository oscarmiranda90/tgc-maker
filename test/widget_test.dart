import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tgc_maker/tgc_maker.dart';

void main() {
  testWidgets('CardPreviewWidget renders with minimal document', (
    tester,
  ) async {
    final doc = CardDocument.blank(size: CardSize.standard).copyWith(
      layers: const [
        ColorLayer(
          id: 'bg',
          group: LayerGroup.background,
          zIndex: 0,
          name: 'Background',
          color: Color(0xFF101626),
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: CardPreviewWidget(
            document: doc,
            shaderPrograms: const {},
            enableParallax: false,
          ),
        ),
      ),
    );

    expect(find.byType(CardPreviewWidget), findsOneWidget);
  });
}
