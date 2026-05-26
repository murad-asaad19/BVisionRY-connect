import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Backend abstraction for a single audio player. Real impl wraps
/// [AudioPlayer]; test impl is in-memory so unit tests don't need the
/// platform audio HAL.
abstract class VoicePlayerBackend {
  Future<void> setUrl(String url);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Stream<Duration> get positionStream;
  Duration? get duration;
  void dispose();
}

class RealVoicePlayerBackend implements VoicePlayerBackend {
  RealVoicePlayerBackend();
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> setUrl(String url) async {
    await _player.setUrl(url);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Duration? get duration => _player.duration;

  @override
  void dispose() => _player.dispose();
}

/// In-memory backend for tests. No audio is played; [positionStream] is
/// driven manually via [advancePosition].
class FakeVoicePlayerBackend implements VoicePlayerBackend {
  FakeVoicePlayerBackend({Duration? totalDuration})
      : _duration = totalDuration ?? const Duration(seconds: 30);

  final Duration _duration;
  final StreamController<Duration> _positions =
      StreamController<Duration>.broadcast();

  String? loadedUrl;
  bool isPlaying = false;
  bool stopped = false;
  Duration position = Duration.zero;

  void advancePosition(Duration d) {
    position = d;
    _positions.add(d);
  }

  @override
  Future<void> setUrl(String url) async {
    loadedUrl = url;
  }

  @override
  Future<void> play() async {
    isPlaying = true;
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
  }

  @override
  Future<void> stop() async {
    isPlaying = false;
    stopped = true;
    position = Duration.zero;
  }

  @override
  Stream<Duration> get positionStream => _positions.stream;

  @override
  Duration? get duration => _duration;

  @override
  void dispose() {
    _positions.close();
  }
}

/// Immutable snapshot of the single-player coordinator.
@immutable
class VoicePlayerState {
  const VoicePlayerState({
    this.activeId,
    this.isPlaying = false,
    this.positionMs = 0,
    this.totalMs = 0,
  });

  /// Id of the message currently loaded into the player (null when idle).
  final String? activeId;
  final bool isPlaying;
  final int positionMs;
  final int totalMs;

  VoicePlayerState copyWith({
    String? activeId,
    bool? isPlaying,
    int? positionMs,
    int? totalMs,
  }) =>
      VoicePlayerState(
        activeId: activeId ?? this.activeId,
        isPlaying: isPlaying ?? this.isPlaying,
        positionMs: positionMs ?? this.positionMs,
        totalMs: totalMs ?? this.totalMs,
      );
}
