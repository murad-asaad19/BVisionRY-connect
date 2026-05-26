// Phase 15 — sign-in integration flow.
//
// Run against a local Supabase stack:
//   supabase start
//   flutter test integration_test/sign_in_flow.dart \
//     --dart-define-from-file=env/ci.json \
//     --dart-define=SUPABASE_SERVICE_ROLE_KEY=<service-role>

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_support/fixtures.dart';
import '_support/flow_helpers.dart';
import '_support/seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign in with email+password lands on /home', (tester) async {
    if (!isSeedEnabled) {
      markTestSkipped('SUPABASE_SERVICE_ROLE_KEY/SUPABASE_URL not provided');
      return;
    }
    await bootApp(tester);
    await signInAs(tester, TestUsers.ana);
    expect(find.text('Home'), findsOneWidget);
  });
}
