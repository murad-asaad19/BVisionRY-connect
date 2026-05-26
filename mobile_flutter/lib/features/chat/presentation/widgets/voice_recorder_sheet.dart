import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../media/constants.dart';
import '../../../media/data/media_service.dart';
import '../../../media/data/voice_recorder.dart';
import 'voice_waveform.dart';

/// Tri-state enum tracking the sheet's UI mode.
///
/// `idle`: not recording yet — single big mic button starts.
/// `recording`: pulse ring + timer + waveform, mic button stops.
/// `ready`: recording finished, Cancel / Send pair shown.
enum _RecState { idle, recording, ready }

/// Bottom-sheet voice recorder (gallery F2).
///
/// Tap-to-toggle interaction (per Phase 7 plan):
/// - First tap on the mic → starts recording.
/// - Second tap → stops, advances to "ready" preview state.
/// - Auto-stops at `MediaConstants.maxVoiceMs` (120s).
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
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final recorder = ref.read(voiceRecorderProvider);
    final ok = await recorder.hasPermission();
    if (!ok) {
      if (mounted) {
        ref.read(toastServiceProvider.notifier).showToast(
              title: context.t('media.permissionMicTitle'),
              body: context.t('media.permissionMicBody'),
              intent: AppIntent.danger,
            );
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
    if (_path == null) return;
    setState(() => _sending = true);
    final media = ref.read(mediaServiceProvider);
    final toast = ref.read(toastServiceProvider.notifier);
    final failedTitle = context.t('chat.send.failed');
    final navigator = Navigator.of(context);
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final recording = _state == _RecState.recording;
    final ready = _state == _RecState.ready;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.t('chat.recording.title'),
            style: typo.displayMd.copyWith(color: colors.navy),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _sending
                ? null
                : recording
                    ? _stop
                    : (ready ? null : _start),
            child: ScaleTransition(
              scale: recording
                  ? Tween<double>(begin: 0.92, end: 1.08).animate(_pulse)
                  : const AlwaysStoppedAnimation<double>(1.0),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: recording
                      ? colors.dangerBg
                      : (ready ? colors.successBg : colors.goldPale),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: recording
                        ? colors.dangerBorder
                        : (ready ? colors.successBorder : colors.goldLight),
                  ),
                ),
                child: Icon(
                  ready ? LucideIcons.check : LucideIcons.mic,
                  size: 32,
                  color: recording
                      ? colors.danger
                      : (ready ? colors.success : colors.navy),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _fmt(_durationMs),
            style: typo.displayXl.copyWith(color: colors.body),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 22,
            width: 220,
            child: VoiceWaveform(
              progress: _durationMs / MediaConstants.maxVoiceMs,
              activeColor: recording ? colors.danger : colors.navy,
              inactiveColor: colors.slate300,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.t('media.recorderHint'),
            textAlign: TextAlign.center,
            style: typo.bodyMd.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 24),
          if (!ready)
            AppButton(
              label: context.t('chat.recording.cancel'),
              variant: AppButtonVariant.outline,
              onPressed: _cancel,
            )
          else
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
                    onPressed: _sending ? null : _send,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
