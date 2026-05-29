import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../media/data/voice_player.dart';

/// Coordinator: ONLY ONE voice message plays at a time. When a different
/// id is requested, the previous source stops, the new URL is loaded,
/// and playback starts. Toggling the SAME id pauses/resumes.
///
/// `position`/`duration` are mirrored onto the state from the player's
/// own [VoicePlayerBackend.positionStream] so bubbles can show progress.
class VoicePlayerNotifier extends StateNotifier<VoicePlayerState> {
  VoicePlayerNotifier(this._backend) : super(const VoicePlayerState()) {
    _posSub = _backend.positionStream.listen((p) {
      state = state.copyWith(
        positionMs: p.inMilliseconds,
        totalMs: _backend.duration?.inMilliseconds ?? state.totalMs,
      );
    });
  }

  final VoicePlayerBackend _backend;
  late final StreamSubscription<Duration> _posSub;

  /// Toggle playback for [messageId] sourced at [url].
  /// - Same id + currently playing → pause.
  /// - Same id + paused → resume.
  /// - Different id → stop the previous, load new url, start playback.
  Future<void> toggle({
    required String messageId,
    required String url,
  }) async {
    if (state.activeId == messageId) {
      if (state.isPlaying) {
        await _backend.pause();
        state = state.copyWith(isPlaying: false);
      } else {
        await _backend.play();
        state = state.copyWith(isPlaying: true);
      }
      return;
    }
    await _backend.stop();
    await _backend.setUrl(url);
    final total = _backend.duration?.inMilliseconds ?? 0;
    state = VoicePlayerState(
      activeId: messageId,
      isPlaying: true,
      positionMs: 0,
      totalMs: total,
    );
    await _backend.play();
  }

  Future<void> stop() async {
    await _backend.stop();
    state = const VoicePlayerState();
  }

  /// Seeks the currently-loaded source to [position] and mirrors it onto
  /// state so the waveform jumps immediately (the position stream confirms
  /// shortly after).
  Future<void> seek(Duration position) async {
    await _backend.seek(position);
    state = state.copyWith(positionMs: position.inMilliseconds);
  }

  /// Scrubs the message [messageId] to [fraction] (0..1) of its duration.
  /// Loads + starts the source first if it isn't the active one, so the
  /// user can scrub a not-yet-played note directly. [url]/[totalMs] are the
  /// resolved signed URL and known clip length.
  Future<void> seekToFraction({
    required String messageId,
    required String url,
    required int totalMs,
    required double fraction,
  }) async {
    final clamped = fraction.clamp(0.0, 1.0);
    if (state.activeId != messageId) {
      await _backend.stop();
      await _backend.setUrl(url);
      final total = _backend.duration?.inMilliseconds ?? totalMs;
      state = VoicePlayerState(
        activeId: messageId,
        isPlaying: true,
        positionMs: 0,
        totalMs: total,
      );
      await _backend.play();
    }
    final effectiveTotal = state.totalMs > 0 ? state.totalMs : totalMs;
    await seek(Duration(milliseconds: (effectiveTotal * clamped).round()));
  }

  @override
  void dispose() {
    _posSub.cancel();
    _backend.dispose();
    super.dispose();
  }
}

/// The single-instance voice player provider.
///
/// Test code overrides this with a builder that wraps a
/// [FakeVoicePlayerBackend] so widget tests can drive playback without
/// touching the audio HAL.
final StateNotifierProvider<VoicePlayerNotifier, VoicePlayerState>
    voicePlayerProvider =
    StateNotifierProvider<VoicePlayerNotifier, VoicePlayerState>((ref) {
  return VoicePlayerNotifier(RealVoicePlayerBackend());
});
