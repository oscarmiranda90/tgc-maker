import 'package:flutter_test/flutter_test.dart';
import 'package:tgc_maker/app.dart';

void main() {
  testWidgets('App renders HomeScreen', (tester) async {
    await tester.pumpWidget(const TgcMakerApp());
    expect(find.text('TGC MAKER'), findsOneWidget);
  });
}
