import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/opportunities/data/opportunities_service.dart';
import 'package:connect_mobile/features/opportunities/domain/opportunity_kind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeGateway extends Mock implements OpportunitiesGateway {}

Map<String, dynamic> _opportunityRow({
  String kind = 'hiring',
  String status = 'open',
  String? closedAt,
}) {
  return <String, dynamic>{
    'id': 'a' * 36,
    'author_id': 'b' * 36,
    'kind': kind,
    'title': 'Senior PM',
    'body': 'Tell us if you ship.',
    'tags': const <String>['pm'],
    'location_city': null,
    'location_country': null,
    'remote_ok': true,
    'status': status,
    'expires_at': '2026-07-25T00:00:00Z',
    'created_at': '2026-05-25T00:00:00Z',
    'updated_at': '2026-05-25T00:00:00Z',
    'closed_at': closedAt,
  };
}

Map<String, dynamic> _withAuthor(Map<String, dynamic> row) => <String, dynamic>{
      ...row,
      'author_handle': 'jane',
      'author_name': 'Jane',
      'author_photo_url': null,
      'author_primary_role': null,
      'author_verified_github_username': null,
    };

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  late _FakeGateway gateway;
  late OpportunitiesService service;

  setUp(() {
    gateway = _FakeGateway();
    service = OpportunitiesService(gateway);
  });

  group('listOpportunities', () {
    test('calls list_opportunities RPC with normalized params', () async {
      when(
        () => gateway.rpc('list_opportunities', params: any(named: 'params')),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);

      await service.listOpportunities(
        kinds: const <OpportunityKind>[
          OpportunityKind.hiring,
          OpportunityKind.cofounder,
        ],
        remoteOnly: true,
        search: 'pm',
        limit: 20,
        offset: 0,
      );

      final Map<String, dynamic> captured = verify(
        () => gateway.rpc(
          'list_opportunities',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_kinds'], <String>['hiring', 'cofounder']);
      expect(captured['p_remote_only'], isTrue);
      expect(captured['p_search'], 'pm');
      expect(captured['p_limit'], 20);
      expect(captured['p_offset'], 0);
    });

    test('passes null kinds when the list is empty', () async {
      when(
        () => gateway.rpc('list_opportunities', params: any(named: 'params')),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);

      await service.listOpportunities(
        kinds: const <OpportunityKind>[],
        remoteOnly: false,
        search: null,
        limit: 20,
        offset: 0,
      );

      final Map<String, dynamic> captured = verify(
        () => gateway.rpc(
          'list_opportunities',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_kinds'], isNull);
      expect(captured['p_remote_only'], isFalse);
      expect(captured['p_search'], isNull);
    });

    test('parses rows into OpportunityWithAuthor', () async {
      when(
        () => gateway.rpc('list_opportunities', params: any(named: 'params')),
      ).thenAnswer(
        (_) async => <Map<String, dynamic>>[_withAuthor(_opportunityRow())],
      );

      final result = await service.listOpportunities(
        kinds: const <OpportunityKind>[],
        remoteOnly: false,
        search: null,
        limit: 20,
        offset: 0,
      );
      expect(result, hasLength(1));
      expect(result.first.authorHandle, 'jane');
      expect(result.first.opportunity.kind, OpportunityKind.hiring);
    });

    test('maps PostgrestException through mapPostgrestError', () async {
      when(
        () => gateway.rpc('list_opportunities', params: any(named: 'params')),
      ).thenThrow(const PostgrestException(message: 'boom', code: 'XX999'));
      expect(
        () => service.listOpportunities(
          kinds: const <OpportunityKind>[],
          remoteOnly: false,
          search: null,
          limit: 20,
          offset: 0,
        ),
        throwsA(isA<GenericAppException>()),
      );
    });
  });

  group('getOpportunity', () {
    test('returns OpportunityWithCounts', () async {
      when(
        () => gateway.rpc('get_opportunity', params: any(named: 'params')),
      ).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{
            ..._withAuthor(_opportunityRow()),
            'interested_count': 3,
            'viewer_has_expressed_interest': false,
          },
        ],
      );
      final r = await service.getOpportunity('oid');
      expect(r.interestedCount, 3);
      expect(r.viewerHasExpressedInterest, isFalse);
      expect(r.withAuthor.opportunity.kind, OpportunityKind.hiring);
    });

    test('throws GenericAppException when row not found', () async {
      when(
        () => gateway.rpc('get_opportunity', params: any(named: 'params')),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);
      expect(
        () => service.getOpportunity('oid'),
        throwsA(isA<GenericAppException>()),
      );
    });

    test('forwards 42501 as ForbiddenException', () async {
      when(
        () => gateway.rpc('get_opportunity', params: any(named: 'params')),
      ).thenThrow(const PostgrestException(message: 'no', code: '42501'));
      expect(
        () => service.getOpportunity('oid'),
        throwsA(isA<ForbiddenException>()),
      );
    });
  });

  group('createOpportunity', () {
    test('sends all params and returns new id', () async {
      when(
        () => gateway.rpc('create_opportunity', params: any(named: 'params')),
      ).thenAnswer((_) async => 'new-id');
      final DateTime expires = DateTime.utc(2026, 6, 25);
      final String id = await service.createOpportunity(
        kind: OpportunityKind.hiring,
        title: 'Senior PM',
        body: 'Looking for someone great.',
        tags: const <String>['pm', 'fintech'],
        locationCity: 'Lisbon',
        locationCountry: 'PT',
        remoteOk: true,
        expiresAt: expires,
      );
      expect(id, 'new-id');
      final Map<String, dynamic> captured = verify(
        () => gateway.rpc(
          'create_opportunity',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_kind'], 'hiring');
      expect(captured['p_title'], 'Senior PM');
      expect(captured['p_body'], 'Looking for someone great.');
      expect(captured['p_tags'], <String>['pm', 'fintech']);
      expect(captured['p_location_city'], 'Lisbon');
      expect(captured['p_location_country'], 'PT');
      expect(captured['p_remote_ok'], isTrue);
      expect(captured['p_expires_at'], expires.toIso8601String());
    });

    test('maps 22023 validation -> ValidationException', () async {
      when(
        () => gateway.rpc('create_opportunity', params: any(named: 'params')),
      ).thenThrow(const PostgrestException(message: 'duration', code: '22023'));
      expect(
        () => service.createOpportunity(
          kind: OpportunityKind.hiring,
          title: 'x',
          body: 'y',
          tags: const <String>[],
          locationCity: null,
          locationCountry: null,
          remoteOk: false,
          expiresAt: DateTime.utc(2026, 6, 25),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('updateOpportunity', () {
    test('sends all params and completes on a void/null response', () async {
      // RPC `RETURNS void` — the gateway yields null and the call must not
      // throw (the P1 false-failure bug this guards against).
      when(
        () => gateway.rpc('update_opportunity', params: any(named: 'params')),
      ).thenAnswer(
        (_) async => null,
      );
      await expectLater(
        service.updateOpportunity(
          id: 'oid',
          kind: OpportunityKind.hiring,
          title: 'Senior PM',
          body: 'Tell us if you ship.',
          tags: const <String>['pm'],
          locationCity: null,
          locationCountry: null,
          remoteOk: true,
          expiresAt: DateTime.utc(2026, 7, 25),
        ),
        completes,
      );
      final Map<String, dynamic> captured = verify(
        () => gateway.rpc(
          'update_opportunity',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_id'], 'oid');
      expect(captured['p_kind'], OpportunityKind.hiring.dbValue);
      expect(captured['p_title'], 'Senior PM');
      expect(captured['p_body'], 'Tell us if you ship.');
      expect(captured['p_tags'], const <String>['pm']);
      expect(captured['p_remote_ok'], true);
      expect(captured['p_expires_at'], DateTime.utc(2026, 7, 25).toIso8601String());
    });
  });

  group('closeOpportunity', () {
    test('sends p_id and completes on a void/null response', () async {
      when(
        () => gateway.rpc('close_opportunity', params: any(named: 'params')),
      ).thenAnswer(
        (_) async => null,
      );
      await expectLater(service.closeOpportunity('oid'), completes);
      final Map<String, dynamic> captured = verify(
        () => gateway.rpc(
          'close_opportunity',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_id'], 'oid');
    });
  });

  group('expressInterest', () {
    test('passes p_note when provided', () async {
      when(
        () => gateway.rpc('express_interest', params: any(named: 'params')),
      ).thenAnswer((_) async => null);
      await service.expressInterest(
        opportunityId: 'oid',
        note: 'I am keen to chat.',
      );
      final Map<String, dynamic> captured = verify(
        () => gateway.rpc(
          'express_interest',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_opportunity_id'], 'oid');
      expect(captured['p_note'], 'I am keen to chat.');
    });

    test('passes null note', () async {
      when(
        () => gateway.rpc('express_interest', params: any(named: 'params')),
      ).thenAnswer((_) async => null);
      await service.expressInterest(opportunityId: 'oid', note: null);
      final Map<String, dynamic> captured = verify(
        () => gateway.rpc(
          'express_interest',
          params: captureAny(named: 'params'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['p_note'], isNull);
    });

    test('maps 23505 to DuplicateException', () async {
      when(
        () => gateway.rpc('express_interest', params: any(named: 'params')),
      ).thenThrow(const PostgrestException(message: 'dup', code: '23505'));
      expect(
        () => service.expressInterest(opportunityId: 'oid', note: null),
        throwsA(isA<DuplicateException>()),
      );
    });
  });

  group('listMyOpportunities', () {
    test('returns rows', () async {
      when(() => gateway.rpc('list_my_opportunities'))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);
      expect(await service.listMyOpportunities(), isEmpty);
    });

    test('parses interested_count', () async {
      when(() => gateway.rpc('list_my_opportunities')).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{
            ..._withAuthor(_opportunityRow()),
            'interested_count': 5,
          },
        ],
      );
      final r = await service.listMyOpportunities();
      expect(r.first.interestedCount, 5);
    });
  });

  group('listInterested', () {
    test('returns parsed interested users', () async {
      when(
        () => gateway.rpc('list_interested', params: any(named: 'params')),
      ).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{
            'user_id': 'u' * 36,
            'handle': 'sam',
            'name': 'Sam Patel',
            'photo_url': null,
            'primary_role': 'engineer',
            'note': null,
            'created_at': '2026-05-25T10:00:00Z',
          },
        ],
      );
      final r = await service.listInterested('oid');
      expect(r, hasLength(1));
      expect(r.first.handle, 'sam');
    });

    test('maps 42501 to ForbiddenException', () async {
      when(
        () => gateway.rpc('list_interested', params: any(named: 'params')),
      ).thenThrow(
        const PostgrestException(message: 'forbidden', code: '42501'),
      );
      expect(
        () => service.listInterested('oid'),
        throwsA(isA<ForbiddenException>()),
      );
    });
  });
}
