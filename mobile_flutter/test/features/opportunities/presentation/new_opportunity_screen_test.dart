import 'package:connect_mobile/features/auth/providers/session_provider.dart';
import 'package:connect_mobile/features/opportunities/data/opportunities_service.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_kind.dart';
import 'package:connect_mobile/features/opportunities/presentation/new_opportunity_screen.dart';
import 'package:connect_mobile/features/opportunities/presentation/opportunity_form.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/pump.dart';

class _FakeService extends Mock implements OpportunitiesService {}

void main() {
  setUpAll(() => registerFallbackValue(OpportunityKind.hiring));

  testWidgets('NewOpportunityScreen renders the OpportunityForm',
      (tester) async {
    final _FakeService fake = _FakeService();
    await tester.pumpWidget(
      await wrapWithTheme(
        child: const NewOpportunityScreen(),
        overrides: <Override>[
          opportunitiesServiceProvider.overrideWithValue(fake),
          sessionProvider.overrideWith((_) => const Stream<Session?>.empty()),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OpportunityForm), findsOneWidget);
  });
}
