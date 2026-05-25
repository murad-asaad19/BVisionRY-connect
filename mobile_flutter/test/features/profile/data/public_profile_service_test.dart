// PublicProfileService — anon-callable handle lookup backing /p/:handle.
//
// The service must work without an authenticated session — `get_public_profile`
// is granted to PUBLIC in the schema. Tests drive it through a fake gateway
// so we don't need a live Supabase client.
import 'package:connect_mobile/features/profile/data/public_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGateway implements PublicProfileGateway {
  String? capturedHandle;
  List<Map<String, dynamic>>? response;
  Object? throwable;

  @override
  Future<Object?> getPublicProfile(String handle) async {
    capturedHandle = handle;
    if (throwable != null) {
      // ignore: only_throw_errors
      throw throwable!;
    }
    return response;
  }
}

void main() {
  group('PublicProfileService', () {
    test('forwards the lowercased handle to the get_public_profile RPC',
        () async {
      final _FakeGateway g = _FakeGateway()
        ..response = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'u-1',
            'handle': 'omar-d',
            'name': 'Omar Daher',
            'photo_url': null,
            'headline': 'Senior backend',
            'bio': null,
            'primary_role': 'builder',
            'roles': <String>['builder'],
            'city': 'London',
            'country': 'UK',
            'verified_github_username': null,
          }
        ];
      final PublicProfileService svc = PublicProfileService(g);
      final PublicProfile? result = await svc.getPublicProfile('Omar-D');
      expect(
        g.capturedHandle,
        'omar-d',
        reason: 'service lowercases + trims before forwarding the handle',
      );
      expect(result, isNotNull);
      expect(result!.handle, 'omar-d');
      expect(result.primaryRole, 'builder');
      expect(result.city, 'London');
    });

    test('returns null when the RPC returns an empty result set', () async {
      final _FakeGateway g = _FakeGateway()
        ..response = <Map<String, dynamic>>[];
      final PublicProfileService svc = PublicProfileService(g);
      expect(await svc.getPublicProfile('nobody'), isNull);
    });

    test('returns null when the RPC returns null', () async {
      final _FakeGateway g = _FakeGateway(); // response stays null
      final PublicProfileService svc = PublicProfileService(g);
      expect(await svc.getPublicProfile('nobody'), isNull);
    });

    test('parses a single-row record (RPC returns a Map, not a List)', () async {
      // The Supabase client may unwrap a single-row JSON object when the
      // function declares `returns ... language sql stable rows 1` — guard
      // both shapes.
      final _FakeGateway g = _FakeGateway()
        ..response = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'u-2',
            'handle': 'sara-k',
            'name': 'Sara K',
            'roles': <String>['founder'],
          }
        ];
      final PublicProfileService svc = PublicProfileService(g);
      final PublicProfile? result = await svc.getPublicProfile('sara-k');
      expect(result?.handle, 'sara-k');
      expect(result?.roles, <String>['founder']);
    });
  });
}
