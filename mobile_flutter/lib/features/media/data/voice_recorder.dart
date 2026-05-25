import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' as r;

import '../../../core/errors/app_exception.dart';

/// Thin backend abstraction so unit tests can inject a [FakeVoiceRecorderBackend]
/// instead of hitting platform channels.
abstract class VoiceRecorderBackend {
  Future<bool> hasPermission();
  Future<void> start(String path, r.RecordConfig config);
  Future<String?> stop();
  Future<void> cancel();
  void dispose();
}

class _RealVoiceRecorderBackend implements VoiceRecorderBackend {
  final r.AudioRecorder _recorder = r.AudioRecorder();
  @override
  Future<bool> hasPermission() => _recorder.hasPermission();
  @override
  Future<void> start(String path, r.RecordConfig config) =>
      _recorder.start(config, path: path);
  @override
  Future<String?> stop() => _recorder.stop();
  @override
  Future<void> cancel() => _recorder.cancel();
  @override
  void dispose() => _recorder.dispose();
}

/// In-memory backend used by tests — no platform channels touched.
class FakeVoiceRecorderBackend implements VoiceRecorderBackend {
  FakeVoiceRecorderBackend({this.permission = true});

  bool permission;
  String? _path;
  bool stopped = false;
  bool cancelled = false;

  @override
  Future<bool> hasPermission() async => permission;
  @override
  Future<void> start(String path, r.RecordConfig config) async {
    _path = path;
  }

  @override
  Future<String?> stop() async {
    stopped = true;
    return _path;
  }

  @override
  Future<void> cancel() async {
    cancelled = true;
    _path = null;
  }

  @override
  void dispose() {}
}

/// Captured recording metadata returned by [VoiceRecorder.stop].
@immutable
class VoiceRecording {
  const VoiceRecording({
    required this.path,
    required this.durationMs,
    required this.mime,
  });
  final String path;
  final int durationMs;
  final String mime;
}

/// Wrapper around the `record` package that exposes:
/// - [start] — request permission, begin recording to a temp file, and
///   emit elapsed-ms updates on [durationStream] every 100 ms.
/// - [stop] — finalise the recording and return a [VoiceRecording] with
///   path/duration/mime metadata.
/// - [cancel] — stop and delete the temp file (used when the user
///   swipes the recorder sheet to abort).
///
/// Max-duration enforcement is the SHEET's responsibility: it listens to
/// [durationStream] and auto-stops at `MediaConstants.maxVoiceMs`.
class VoiceRecorder {
  VoiceRecorder._(this._backend, this._tempDirProvider, this._clock);

  /// Live recorder bound to the platform `AudioRecorder` and the OS
  /// temp directory.
  factory VoiceRecorder() => VoiceRecorder._(
    _RealVoiceRecorderBackend(),
    getTemporaryDirectory,
    () => DateTime.now(),
  );

  /// Test recorder with an injected backend + temp dir + clock. The
  /// fakes never touch the file system or the audio HAL.
  @visibleForTesting
  factory VoiceRecorder.test({
    VoiceRecorderBackend? backend,
    Future<Directory> Function()? tempDirProvider,
    DateTime Function()? clock,
  }) {
    return VoiceRecorder._(
      backend ?? FakeVoiceRecorderBackend(),
      tempDirProvider ?? () async => Directory.systemTemp,
      clock ?? () => DateTime.now(),
    );
  }

  final VoiceRecorderBackend _backend;
  final Future<Directory> Function() _tempDirProvider;
  final DateTime Function() _clock;

  Timer? _ticker;
  DateTime? _startedAt;
  String? _currentPath;
  final StreamController<int> _durationCtrl =
      StreamController<int>.broadcast();

  /// Elapsed-ms ticks emitted every 100 ms while a recording is active.
  Stream<int> get durationStream => _durationCtrl.stream;

  Future<bool> hasPermission() => _backend.hasPermission();

  /// Begin recording. Throws [ValidationException]
  /// (`media.permissionMicBody`) when permission is denied so the caller
  /// can surface the standard permission sheet.
  Future<void> start() async {
    if (!await _backend.hasPermission()) {
      throw ValidationException('media.permissionMicBody');
    }
    final dir = await _tempDirProvider();
    final fileName = 'voice_${_clock().millisecondsSinceEpoch}.m4a';
    _currentPath = '${dir.path}/$fileName';
    const cfg = r.RecordConfig(
      encoder: r.AudioEncoder.aacLc,
      bitRate: 64000,
      sampleRate: 44100,
      numChannels: 1,
    );
    await _backend.start(_currentPath!, cfg);
    _startedAt = _clock();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final ms = _clock().difference(_startedAt!).inMilliseconds;
      _durationCtrl.add(ms);
    });
  }

  /// Stop and return the resulting file path + duration + mime. Safe to
  /// call multiple times (subsequent calls return zero duration).
  Future<VoiceRecording> stop() async {
    _ticker?.cancel();
    _ticker = null;
    final path = await _backend.stop();
    final durationMs = _startedAt == null
        ? 0
        : _clock().difference(_startedAt!).inMilliseconds;
    _startedAt = null;
    return VoiceRecording(
      path: path ?? _currentPath ?? '',
      durationMs: durationMs,
      mime: 'audio/m4a',
    );
  }

  /// Abort the recording and delete the temp file.
  Future<void> cancel() async {
    _ticker?.cancel();
    _ticker = null;
    await _backend.cancel();
    final path = _currentPath;
    if (path != null) {
      try {
        final f = File(path);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {
        // Best-effort cleanup; ignore IO failures.
      }
    }
    _startedAt = null;
    _currentPath = null;
  }

  void dispose() {
    _ticker?.cancel();
    _backend.dispose();
    _durationCtrl.close();
  }
}

/// Provider that owns one [VoiceRecorder] per app lifetime. Disposed when
/// the provider scope tears down (sign-out, etc.).
final Provider<VoiceRecorder> voiceRecorderProvider = Provider<VoiceRecorder>((
  ref,
) {
  final rec = VoiceRecorder();
  ref.onDispose(rec.dispose);
  return rec;
});
