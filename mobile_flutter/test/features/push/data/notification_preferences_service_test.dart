import 'package:connect_mobile/features/push/data/notification_preferences_service.dart';
import 'package:connect_mobile/features/push/domain/notification_channel.dart';
import 'package:connect_mobile/features/push/domain/notification_kind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeGateway implements NotificationPreferencesGateway {
  List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
  Map<String, dynamic>? lastUpsert;

  @override
  Future<List<Map<String, dynamic>>> listMyPreferences() async => rows;

  @override
  Future<void> upsertPreference(Map<String, dynamic> row) async {
    lastUpsert = row;
  }
}

class _FakeGoTrueClient extends Fake implements GoTrueClient {
  _FakeGoTrueClient(this.uid);
  final String? uid;
  @override
  User? get currentUser {
    final String? u = uid;
    if (u == null) return null;
    return User(
      id: u,
      appMetadata: const <String, dynamic>{},
      userMetadata: const <String, dynamic>{},
      aud: '',
      createdAt: '',
    );
  }
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient({String? uid}) : _auth = _FakeGoTrueClient(uid);
  final GoTrueClient _auth;
  @override
  GoTrueClient get auth => _auth;
}

void main() {
  test('listMyPreferences maps gateway rows -> domain objects', () async {
    final _FakeGateway gateway = _FakeGateway()
      ..rows = <Map<String, dynamic>>[
        <String, dynamic>{
          'user_id': 'u1',
          'kind': 'message_received',
          'channel': 'push',
          'enabled': false,
        },
        <String, dynamic>{
          'user_id': 'u1',
          'kind': 'intro_received',
          'channel': 'email',
          'enabled': true,
        },
      ];
    final NotificationPreferencesService service =
        NotificationPreferencesService(
      gateway,
      supabase: _FakeSupabaseClient(uid: 'u1'),
    );
    final List<dynamic> prefs = await service.listMyPreferences();
    expect(prefs, hasLength(2));
    expect(prefs.first.kind, NotificationKind.messageReceived);
    expect(prefs.first.enabled, isFalse);
  });

  test('setPreference UPSERTs the row with correct columns', () async {
    final _FakeGateway gateway = _FakeGateway();
    final NotificationPreferencesService service =
        NotificationPreferencesService(
      gateway,
      supabase: _FakeSupabaseClient(uid: 'u1'),
    );
    await service.setPreference(
      kind: NotificationKind.messageReceived,
      channel: NotificationChannel.push,
      enabled: false,
    );
    expect(
      gateway.lastUpsert,
      equals(<String, dynamic>{
        'user_id': 'u1',
        'kind': 'message_received',
        'channel': 'push',
        'enabled': false,
      }),
    );
  });

  test('setPreference throws when no authenticated session', () async {
    final NotificationPreferencesService service =
        NotificationPreferencesService(
      _FakeGateway(),
      supabase: _FakeSupabaseClient(),
    );
    await expectLater(
      service.setPreference(
        kind: NotificationKind.messageReceived,
        channel: NotificationChannel.push,
        enabled: false,
      ),
      throwsStateError,
    );
  });
}
