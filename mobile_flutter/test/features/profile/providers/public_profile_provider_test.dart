// publicProfileProvider — family-keyed FutureProvider over PublicProfileService.
import 'package:connect_mobile/features/profile/data/public_profile_service.dart';
import 'package:connect_mobile/features/profile/providers/public_profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGateway implements PublicProfileGateway {
  _FakeGateway(this.byHandle);
  final Map<String, Object?> byHandle;
  final Map<String, int> calls = <String, int>{};

  @override
  Future<Object?> getPublicProfile(String handle) async {
    calls[handle] = (calls[handle] ?? 0) + 1;
    return byHandle[handle];
  }
}

void main() {
  test('returns the parsed profile for the supplied handle', () async {
    final _FakeGateway gateway = _FakeGateway(<String, Object?>{
      'omar-d': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'u-1',
          'handle': 'omar-d',
          'name': 'Omar',
          'roles': <String>['builder'],
        },
      ],
    });
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        publicProfileServiceProvider
            .overrideWithValue(PublicProfileService(gateway)),
      ],
    );
    addTearDown(container.dispose);

    final PublicProfile? p =
        await container.read(publicProfileProvider('omar-d').future);
    expect(p, isNotNull);
    expect(p!.handle, 'omar-d');
    expect(gateway.calls['omar-d'], 1);
  });

  test('dedupes equivalent reads (family key collision)', () async {
    final _FakeGateway gateway = _FakeGateway(<String, Object?>{
      'omar-d': <Map<String, dynamic>>[
        <String, dynamic>{'id': 'u', 'handle': 'omar-d'},
      ],
    });
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        publicProfileServiceProvider
            .overrideWithValue(PublicProfileService(gateway)),
      ],
    );
    addTearDown(container.dispose);

    final Future<PublicProfile?> a =
        container.read(publicProfileProvider('omar-d').future);
    final Future<PublicProfile?> b =
        container.read(publicProfileProvider('omar-d').future);
    await Future.wait<PublicProfile?>(<Future<PublicProfile?>>[a, b]);
    expect(
      gateway.calls['omar-d'],
      1,
      reason: 'family-keyed provider should dedupe equivalent reads',
    );
  });

  test('returns null when the handle is unknown', () async {
    final _FakeGateway gateway = _FakeGateway(<String, Object?>{});
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        publicProfileServiceProvider
            .overrideWithValue(PublicProfileService(gateway)),
      ],
    );
    addTearDown(container.dispose);

    final PublicProfile? p =
        await container.read(publicProfileProvider('nobody').future);
    expect(p, isNull);
  });
}
