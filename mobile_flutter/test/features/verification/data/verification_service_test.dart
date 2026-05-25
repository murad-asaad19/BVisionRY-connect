// VerificationService — wraps the set/clear GitHub-verification RPCs
// (spec §3.1, §17.3). These are the ONLY path to mutate `profiles.verified_*`
// columns; direct column-UPDATEs are revoked at the SQL layer.
import 'package:connect_mobile/features/verification/data/verification_service.dart';
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
  });
}
