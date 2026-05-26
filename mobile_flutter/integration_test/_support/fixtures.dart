// Phase 15 — integration_test fixtures.
//
// Shared seed data for the integration_test/ suite. The actual seeding
// happens via `seed.dart` against a local Supabase stack started with
// `supabase start`.

class TestUser {
  const TestUser({
    required this.id,
    required this.email,
    required this.password,
    required this.handle,
    required this.displayName,
    this.onboarded = true,
  });

  final String id;
  final String email;
  final String password;
  final String handle;
  final String displayName;
  final bool onboarded;
}

abstract final class TestUsers {
  static const ana = TestUser(
    id: '11111111-1111-1111-1111-111111111111',
    email: 'ana@test.local',
    password: 'TestPass!123',
    handle: 'ana',
    displayName: 'Ana Tester',
  );

  static const bruno = TestUser(
    id: '22222222-2222-2222-2222-222222222222',
    email: 'bruno@test.local',
    password: 'TestPass!123',
    handle: 'bruno',
    displayName: 'Bruno Tester',
  );

  static const carla = TestUser(
    id: '33333333-3333-3333-3333-333333333333',
    email: 'carla@test.local',
    password: 'TestPass!123',
    handle: 'carla',
    displayName: 'Carla (not onboarded)',
    onboarded: false,
  );
}
