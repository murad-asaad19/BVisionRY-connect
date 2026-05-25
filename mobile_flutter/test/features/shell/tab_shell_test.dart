import 'package:connect_mobile/features/shell/presentation/widgets/connect_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ConnectBottomNavBar renders 5 destinations', (tester) async {
    final w = await wrapWithTheme(
      child: Scaffold(
        bottomNavigationBar: ConnectBottomNavBar(
          currentIndex: 0,
          onTap: (_) {},
        ),
      ),
    );
    await pumpWithI18n(tester, w);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    final bar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(bar.items, hasLength(5));
  });
}
