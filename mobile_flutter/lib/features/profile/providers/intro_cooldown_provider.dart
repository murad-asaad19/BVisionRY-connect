import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Viewer-side decline-cooldown state for a recipient profile (gallery
/// section I4).
///
/// Encodes whether the current viewer is currently locked out of sending an
/// intro to the recipient (because the recipient declined a prior intro) and,
/// when available, the wall-clock date when the cooldown lifts. The server
/// is the authoritative gate — `intros.send` raises `IntroCooldownException`
/// regardless — but exposing the same state up-front lets the UI render a
/// disabled "Send intro · available {date}" button and a warning banner per
/// the gallery spec (lines 2379–2388).
class IntroCooldownState {
  const IntroCooldownState({this.active = false, this.availableAt});

  /// `true` when the recipient declined an earlier intro from this viewer
  /// and the 30-day cooldown is still in effect.
  final bool active;

  /// UTC instant when the cooldown lifts. Null when the server hasn't
  /// exposed the exact release date — the UI falls back to "available soon"
  /// copy in that case.
  final DateTime? availableAt;
}

/// Stub provider that returns "no cooldown" by default — see
/// [IntroCooldownState]. Override in a future change that wires the RPC
/// payload through; consumers don't need to be touched. Family-keyed by the
/// recipient's profile id so the same hook works for every public profile
/// view.
final FutureProviderFamily<IntroCooldownState, String> introCooldownProvider =
    FutureProvider.family<IntroCooldownState, String>(
  (Ref<AsyncValue<IntroCooldownState>> ref, String _) async {
    return const IntroCooldownState();
  },
);
