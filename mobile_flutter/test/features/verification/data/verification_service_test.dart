// VerificationService — wraps the set/clear GitHub-verification RPCs
// (spec §3.1, §17.3) plus the generic manual-review proof RPCs
// (`submit_verification`, `list_my_verifications`). These RPCs are the ONLY
// path to mutate the verification state; direct writes are revoked at the SQL
// layer.
import 'package:connect_mobile/features/verification/data/verification_service.dart';
import 'package:connect_mobile/features/verification/domain/verification_request.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGateway implements VerificationGateway {
  String? capturedRpc;
  Map<String, dynamic>? capturedParams;
  Object? response;
  Object? throwable;

  @override
  Future<Object?> rpc(String name, {Map<String, dynamic>? params}) async {
    capturedRpc = name;
    capturedParams = params;
    if (throwable != null) {
      // ignore: only_throw_errors
      throw throwable!;
    }
    return response;
  }
}

void main() {
  group('VerificationService', () {
    test('setGithubVerification lowercases the username and forwards the id',
        () async {
      final _FakeGateway g = _FakeGateway();
      final VerificationService svc = VerificationService(g);

      await svc.setGithubVerification(username: 'OctoCat', githubId: 42);

      expect(g.capturedRpc, 'set_github_verification');
      expect(g.capturedParams, <String, dynamic>{
        'p_github_username': 'octocat',
        'p_github_id': 42,
      });
    });

    test('setGithubVerification trims whitespace before forwarding the handle',
        () async {
      final _FakeGateway g = _FakeGateway();
      final VerificationService svc = VerificationService(g);

      await svc.setGithubVerification(username: '  Octo  ', githubId: 1);

      expect(g.capturedParams!['p_github_username'], 'octo');
    });

    test('clearGithubVerification invokes the no-arg RPC', () async {
      final _FakeGateway g = _FakeGateway();
      final VerificationService svc = VerificationService(g);

      await svc.clearGithubVerification();

      expect(g.capturedRpc, 'clear_github_verification');
      expect(g.capturedParams, anyOf(isNull, isEmpty));
    });

    test('submitVerification forwards the kind wire + payload', () async {
      final _FakeGateway g = _FakeGateway();
      final VerificationService svc = VerificationService(g);

      await svc.submitVerification(
        VerificationKind.investorCrunchbase,
        payload: <String, dynamic>{'url': 'https://crunchbase.com/x'},
      );

      expect(g.capturedRpc, 'submit_verification');
      expect(g.capturedParams, <String, dynamic>{
        'p_kind': 'investor_crunchbase',
        'p_payload': <String, dynamic>{'url': 'https://crunchbase.com/x'},
      });
    });

    test('submitVerification omits p_payload when none supplied', () async {
      final _FakeGateway g = _FakeGateway();
      final VerificationService svc = VerificationService(g);

      await svc.submitVerification(VerificationKind.founderDomainEmail);

      expect(g.capturedParams, <String, dynamic>{
        'p_kind': 'founder_domain_email',
      });
    });

    test('listMyVerifications maps rows into typed requests', () async {
      final _FakeGateway g = _FakeGateway();
      g.response = <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'v-1',
          'kind': 'founder_team_page',
          'status': 'pending',
          'created_at': '2026-06-01T00:00:00Z',
          'reviewed_at': null,
          'note': null,
        },
        <String, dynamic>{
          'id': 'v-2',
          'kind': 'investor_portfolio',
          'status': 'rejected',
          'created_at': '2026-05-01T00:00:00Z',
          'reviewed_at': '2026-05-02T00:00:00Z',
          'note': 'Need 2+ public listings.',
        },
      ];
      final VerificationService svc = VerificationService(g);

      final List<VerificationRequest> rows = await svc.listMyVerifications();

      expect(g.capturedRpc, 'list_my_verifications');
      expect(rows, hasLength(2));
      expect(rows.first.kind, VerificationKind.founderTeamPage);
      expect(rows.first.status, VerificationStatus.pending);
      expect(rows[1].status, VerificationStatus.rejected);
      expect(rows[1].note, 'Need 2+ public listings.');
      expect(rows[1].reviewedAt, isNotNull);
    });

    test('listMyVerifications drops rows with unknown enum values', () async {
      final _FakeGateway g = _FakeGateway();
      g.response = <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'v-9',
          'kind': 'some_future_kind',
          'status': 'pending',
          'created_at': '2026-06-01T00:00:00Z',
          'reviewed_at': null,
          'note': null,
        },
      ];
      final VerificationService svc = VerificationService(g);

      expect(await svc.listMyVerifications(), isEmpty);
    });

    test('listMyVerifications returns empty on a null RPC response', () async {
      final _FakeGateway g = _FakeGateway();
      g.response = null;
      final VerificationService svc = VerificationService(g);

      expect(await svc.listMyVerifications(), isEmpty);
    });
  });
}
