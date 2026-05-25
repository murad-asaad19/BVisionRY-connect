import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/discovery/data/discovery_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeClient extends Mock implements SupabaseClient {}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  group('DiscoveryService', () {
    late _FakeClient client;
    late DiscoveryService service;

    setUp(() {
      client = _FakeClient();
      service = DiscoveryService(client);
    });

    test('fetchDailyMatches calls get_daily_matches with optional p_for_date', () async {
      when(
        () => client.rpc<List<Map<String, dynamic>>>(
          'get_daily_matches',
          params: any(named: 'params'),
        ),
      ).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'a',
            'pick_user_id': 'u',
            'match_reason': 'Daily pick',
            'for_date_local': '2026-05-25',
            'viewed_at': null,
            'created_at': '2026-05-25T04:00:00Z',
            'name': null,
            'handle': 'u',
            'photo_url': null,
            'headline': null,
            'bio': null,
            'city': null,
            'country': null,
            'primary_role': null,
            'roles': const <String>[],
            'goal_type': null,
          },
        ],
      );

      final res = await service.fetchDailyMatches(
        date: DateTime.utc(2026, 5, 25),
      );
      expect(res, hasLength(1));
      expect(res.first.profile.handle, 'u');
      verify(
        () => client.rpc<List<Map<String, dynamic>>>(
          'get_daily_matches',
          params: <String, dynamic>{'p_for_date': '2026-05-25'},
        ),
      ).called(1);
    });

    test('markMatchViewed swallows errors (idempotent)', () async {
      when(
        () => client.rpc<void>(
          'mark_match_viewed',
          params: any(named: 'params'),
        ),
      ).thenThrow(
        const PostgrestException(message: 'forbidden', code: '42501'),
      );
      await service.markMatchViewed('id-1'); // must not throw
    });

    test('isMutualMatch returns boolean from RPC', () async {
      when(
        () =>
            client.rpc<bool>('is_mutual_match', params: any(named: 'params')),
      ).thenAnswer((_) async => true);
      expect(await service.isMutualMatch('other-id'), isTrue);
    });

    test(
      'searchDiscoverableProfiles passes cursor, query, roles, goal_types, country, limit',
      () async {
        when(
          () => client.rpc<List<Map<String, dynamic>>>(
            'search_discoverable_profiles',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        await service.searchDiscoverableProfiles(
          query: 'omar',
          roles: const <String>['builder'],
          goalTypes: const <String>['find_advisor'],
          country: 'UK',
          cursor: DateTime.utc(2026, 5, 24, 12),
          limit: 20,
        );
        final captured = verify(
          () => client.rpc<List<Map<String, dynamic>>>(
            'search_discoverable_profiles',
            params: captureAny(named: 'params'),
          ),
        ).captured.single as Map<String, dynamic>;
        expect(captured['p_query'], 'omar');
        expect(captured['p_roles'], <String>['builder']);
        expect(captured['p_goal_types'], <String>['find_advisor']);
        expect(captured['p_country'], 'UK');
        expect(captured['p_cursor'], '2026-05-24T12:00:00.000Z');
        expect(captured['p_limit'], 20);
      },
    );

    test('searchDiscoverableProfiles uses sentinel cursor on first page', () async {
      when(
        () => client.rpc<List<Map<String, dynamic>>>(
          'search_discoverable_profiles',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);

      await service.searchDiscoverableProfiles();
      final captured = verify(
        () => client.rpc<List<Map<String, dynamic>>>(
          'search_discoverable_profiles',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_cursor'], '9999-12-31T00:00:00.000Z');
    });

    test('fetchDailyMatches maps PostgrestException via error_map', () async {
      when(
        () => client.rpc<List<Map<String, dynamic>>>(
          'get_daily_matches',
          params: any(named: 'params'),
        ),
      ).thenThrow(const PostgrestException(message: 'nope', code: '42501'));
      await expectLater(
        () => service.fetchDailyMatches(),
        throwsA(isA<AppException>()),
      );
    });
  });
}
