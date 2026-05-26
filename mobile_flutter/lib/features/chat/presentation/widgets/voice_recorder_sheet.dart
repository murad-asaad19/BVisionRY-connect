import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../media/constants.dart';
import '../../../media/data/media_service.dart';
import '../../../media/data/voice_recorder.dart';

/// Tri-state enum tracking the sheet's UI mode.
///
/// `idle`: not recording yet — Send is disabled, Cancel dismisses.
/// `recording`: pulse dot + timer + static waveform — Send stops & sends.
/// `ready`: recording captured, Cancel/Send both armed.
enum _RecState { idle, recording, ready }

/// Bottom-sheet voice recorder (gallery F2).
///
/// Visual structure (matches the gallery):
/// - Pulsing red dot at the top with animated opacity.
/// - Timer rendered as `m:ss / 2:00` (current / max).
/// - Static waveform strip — a row of small vertical bars; deliberately
///   not driven by real audio analysis since the gallery uses a fixed
///   visual.
/// - Disclosure line: "Max 2 minutes — voice notes are transcribed for
///   accessibility & safety." (`chat.recorderDisclosure`).
/// - Side-by-side Cancel (outline) + Send (gold solid) buttons that are
///   ALWAYS visible. The sheet auto-starts recording on open and Send
///   either stops-and-sends (during recording) or sends the captured clip
///   (after a manual stop).
///
/// On Send: validates → uploads to `chat-media/{conv}/{messageId}/voice.m4a`
/// → calls `send_voice_message`. The conversation's [messagesProvider]
/// receives the inserted row via Realtime; this sheet just pops.
///
/// Failures route through [ToastService] so the user gets a localised
/// banner instead of a crash.
class VoiceRecorderSheet extends ConsumerStatefulWidget {
  const VoiceRecorderSheet({super.key, required this.conversationId});

  final String conversationId;

  /// Convenience launcher — opens the sheet via [showAppBottomSheet].
  static Future<void> show(
    BuildContext context, {
    required String conversationId,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      child: VoiceRecorderSheet(conversationId: conversationId),
    );
  }

  @override
  ConsumerState<VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends ConsumerState<VoiceRecorderSheet>
    with SingleTickerProviderStateMixin {
  _RecState _state = _RecState.idle;
  int _durationMs = 0;
  String? _path;
  String _mime = 'audio/m4a';
  StreamSubscription<int>? _sub;
  late final AnimationController _pulse;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    // Auto-start so the sheet matches the gallery's "already recording"
    // visual the moment the user taps the mic in the composer.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!mounted || _state != _RecState.idle) return;
    final recorder = ref.read(voiceRecorderProvider);
    final ok = await recorder.hasPermission();
    if (!ok) {
      if (mounted) {
        ref.read(toastServiceProvider.notifier).showToast(
              title: context.t('media.permissionMicTitle'),
              body: context.t('media.permissionMicBody'),
              intent: AppIntent.danger,
            );
        unawaited(Navigator.of(context).maybePop());
      }
      return;
    }
    await recorder.start();
    if (!mounted) return;
    setState(() {
      _state = _RecState.recording;
      _durationMs = 0;
    });
    _sub = recorder.durationStream.listen((ms) async {
      if (!mounted) return;
      setState(() => _durationMs = ms);
      if (ms >= MediaConstants.maxVoiceMs) await _stop();
    });
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    _sub = null;
    final recorder = ref.read(voiceRecorderProvider);
    final result = await recorder.stop();
    if (!mounted) return;
    setState(() {
      _path = result.path;
      _durationMs = result.durationMs;
      _mime = result.mime;
      _state = _RecState.ready;
    });
  }

  Future<void> _cancel() async {
    final navigator = Navigator.of(context);
    await _sub?.cancel();
    _sub = null;
    final recorder = ref.read(voiceRecorderProvider);
    await recorder.cancel();
    if (mounted) unawaited(navigator.maybePop());
  }

  Future<void> _send() async {
    // Capture context-dependent values BEFORE any awaits — Dart lints flag
    // post-await `context` reads in async handlers.
    final media = ref.read(mediaServiceProvider);
    final toast = ref.read(toastServiceProvider.notifier);
    final failedTitle = context.t('chat.send.failed');
    final navigator = Navigator.of(context);
    // If still recording, stop first so we have a finalised clip on disk.
    if (_state == _RecState.recording) {
      await _stop();
    }
    if (_path == null) return;
    setState(() => _sending = true);
    try {
      final file = File(_path!);
      final bytes = await file.readAsBytes();
      media.validateVoiceBytes(
        bytes,
        mime: _mime,
        durationMs: _durationMs,
      );
      final messageId = media.generateMessageId();
      final ext = _mime.endsWith('webm') ? 'webm' : 'm4a';
      final path = await media.uploadChatMedia(
        conversationId: widget.conversationId,
        messageId: messageId,
        fileName: 'voice.$ext',
        bytes: bytes,
        mime: _mime,
      );
      await media.sendVoiceMessage(
        conversationId: widget.conversationId,
        mediaPath: path,
        mediaMime: _mime,
        mediaSizeBytes: bytes.lengthInBytes,
        durationMs: _durationMs,
      );
      if (mounted) unawaited(navigator.maybePop());
    } catch (_) {
      toast.showToast(title: failedTitle, intent: AppIntent.danger);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _fmt(int ms) {
    if (ms <= 0) return '0:00';
    final s = (ms / 1000).floor();
    final mm = (s ~/ 60).toString();
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _fmtMax() {
    const maxSec = MediaConstants.maxVoiceMs ~/ 1000;
    const mm = maxSec ~/ 60;
    final ss = (maxSec % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final canSend = !_sending &&
        (_state == _RecState.recording || _state == _RecState.ready) &&
        (_state == _RecState.ready ? _path != null : true);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Pulsing red dot — opacity-animated; the gallery uses the same
          // "live" cue at the top of the recorder card.
          Center(
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.35, end: 1.0).animate(_pulse),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _state == _RecState.recording
                      ? colors.danger
                      : colors.muted,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Combined "current / max" timer per gallery.
          Center(
            child: Text(
              '${_fmt(_durationMs)} / ${_fmtMax()}',
              style: typo.displayLg.copyWith(color: colors.navy),
            ),
          ),
          const SizedBox(height: 12),
          // Static decorative waveform (no audio analysis — matches the
          // gallery's fixed bar strip).
          const _StaticWaveformStrip(),
          const SizedBox(height: 12),
          Text(
            context.t('chat.recorderDisclosure'),
            textAlign: TextAlign.center,
            style: typo.bodyXs.copyWith(color: colors.muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: context.t('chat.recording.cancel'),
                  variant: AppButtonVariant.outline,
                  onPressed: _sending ? null : _cancel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: context.t('chat.recording.send'),
                  variant: AppButtonVariant.primary,
                  loading: _sending,
                  onPressed: canSend ? _send : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Decorative bar strip — 13 fixed-height bars per the gallery's
/// `.wave-strip`. We deliberately do NOT drive these from live audio
/// because the gallery itself uses a static visual.
class _StaticWaveformStrip extends StatelessWidget {
  const _StaticWaveformStrip();

  static const _heights = <double>[
    8, 14, 22, 18, 26, 12, 20, 16, 24, 10, 18, 22, 14,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          for (final h in _heights) ...<Widget>[
            Container(
              width: 3,
              height: h,
              decoration: BoxDecoration(
                color: colors.navy,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}
