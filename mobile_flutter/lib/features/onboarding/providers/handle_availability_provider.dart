import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/onboarding_schemas.dart' show HandleInput;

/// Test-seam abstraction over the `check_handle_available(p_handle text)`
/// RPC (spec §3.1). Pure interface so we don't have to mock the sealed
/// `SupabaseClient` in tests.
abstract class HandleAvailabilityRunner {
  /// Returns `true` when the handle is free, `false` when taken.
  Future<bool> check(String handle);
}

class _SupabaseHandleAvailabilityRunner implements HandleAvailabilityRunner {
  _SupabaseHandleAvailabilityRunner(this._client);
  final SupabaseClient _client;

  @override
  Future<bool> check(String handle) async {
    final Object? result = await _client.rpc<Object?>(
      'check_handle_available',
      params: <String, dynamic>{'p_handle': handle},
    );
    return result == true;
  }
}

final Provider<HandleAvailabilityRunner> handleAvailabilityRunnerProvider =
    Provider<HandleAvailabilityRunner>((Ref<HandleAvailabilityRunner> ref) {
  return _SupabaseHandleAvailabilityRunner(ref.watch(supabaseClientProvider));
});

/// Returns `true`/`false` for whether the handle is available, or `null`
/// when the input is empty / format-invalid (in which case the UI shows the
/// format error first and never sends a network request).
///
/// Keyed by handle so the same value taps Riverpod's cache instead of
/// re-issuing the RPC each time the field is focused.
final FutureProviderFamily<bool?, String> handleAvailabilityProvider =
    FutureProvider.family<bool?, String>(
  (Ref<AsyncValue<bool?>> ref, String handle) async {
    if (handle.isEmpty) return null;
    if (HandleInput.dirty(handle).error != null) return null;
    final HandleAvailabilityRunner runner =
        ref.watch(handleAvailabilityRunnerProvider);
    return runner.check(handle);
  },
);
