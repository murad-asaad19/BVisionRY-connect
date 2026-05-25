import 'package:flutter_test/flutter_test.dart';

import 'package:connect_mobile/main.dart';

void main() {
  testWidgets('App boots and renders foundation placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(const FoundationApp());
    expect(find.text('Foundation OK'), findsOneWidget);
  });
}
