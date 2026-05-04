import 'package:flutter_test/flutter_test.dart';
import 'package:negativity_absorber/app.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const NegativityAbsorberApp());
    expect(find.text('🗑️ 負能量吸收器'), findsOneWidget);
  });
}
