import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart' as r;

import '../../../../core/i18n/i18n.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../media/constants.dart';
import '../../../media/data/media_service.dart';
import '../../../media/data/voice_recorder.dart';
import '../../domain/message.dart';
import '../../providers/messages_provider.dart';

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
/// - Live waveform strip — a fixed-width row of 30 navy bars driven by
///   the `record` package's `onAmplitudeChanged` stream (~10 Hz). The
///   newest sample pushes onto the right; older samples scroll left.
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
  StreamSubscription<r.Amplitude>? _ampSub;
  late final AnimationController _pulse;
  bool _sending = false;

  /// Rolling buffer of the last [_LiveWaveformStrip.barCount] normalized
  /// (0..1) amplitude samples. Owned by the state so we can cancel the
  /// subscription on dispose / cancel / send and so the painter repaints
  /// without rebuilding the whole sheet.
  final ValueNotifier<List<double>> _levels = ValueNotifier<List<double>>(
    List<double>.filled(_LiveWaveformStrip.barCount, 0),
  );

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    // Idle on open — the user explicitly taps "Start recording" so an
    // accidental composer-mic tap does NOT capture audio. Resolves
    // T-CHAT-RECORD-AUTOSTART (audit 21-F02).
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ampSub?.cancel();
    // The mic may be open in TWO states: still recording, OR captured a
    // clip but never sent (ready). Both must close the underlying recorder
    // so we don't leak the mic on swipe-down / Android-back dismissal.
    // voiceRecorderProvider is a non-autoDispose Provider so ref.read in
    // dispose returns the live singleton.
    if (_state == _RecState.recording || _state == _RecState.ready) {
      unawaited(ref.read(voiceRecorderProvider).cancel());
    }
    _levels.dispose();
    _pulse.dispose();
    super.dispose();
  }

  /// Convert a dBFS sample (typically -50..0) to a 0..1 magnitude. Values
  /// below the floor clamp to 0 (silence); 0 dBFS clamps to 1 (clipping).
  static double _dbfsToLevel(double dbfs) {
    const minDb = -50.0;
    if (dbfs.isNaN || dbfs.isInfinite) return 0;
    final clamped = dbfs.clamp(minDb, 0.0);
    return (clamped - minDb) / -minDb;
  }

  void _pushLevel(double level) {
    final next = List<double>.from(_levels.value);
    // Drop the oldest sample on the left, push the newest onto the right
    // so the strip scrolls left-to-right while recording.
    next.removeAt(0);
    next.add(level.clamp(0.0, 1.0));
    _levels.value = next;
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
    // Light tick to confirm the mic is now live (meaningful action: the
    // user committed to recording).
    Haptics.light();
    setState(() {
      _state = _RecState.recording;
      _durationMs = 0;
    });
    _sub = recorder.durationStream.listen((ms) async {
      if (!mounted) return;
      setState(() => _durationMs = ms);
      if (ms >= MediaConstants.maxVoiceMs) await _stop();
    });
    _ampSub = recorder.amplitudeStream.listen((amp) {
      if (!mounted) return;
      _pushLevel(_dbfsToLevel(amp.current));
    });
  }

  /// Stops the recorder and transitions to [_RecState.ready].
  ///
  /// [haptic] fires a light tick to confirm the capture ended — true for a
  /// deliberate stop (auto-stop at the 2-minute cap). The send path passes
  /// false because [_send] already emits its own send haptic, so we avoid a
  /// double buzz.
  Future<void> _stop({bool haptic = true}) async {
    await _sub?.cancel();
    _sub = null;
    await _ampSub?.cancel();
    _ampSub = null;
    final recorder = ref.read(voiceRecorderProvider);
    final result = await recorder.stop();
    if (!mounted) return;
    if (haptic) Haptics.light();
    // Drain the live buffer so the strip falls back to its idle visual
    // (all bars at the minimum height).
    _levels.value = List<double>.filled(_LiveWaveformStrip.barCount, 0);
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
    await _ampSub?.cancel();
    _ampSub = null;
    final recorder = ref.read(voiceRecorderProvider);
    await recorder.cancel();
    if (mounted) unawaited(navigator.maybePop());
  }

  Future<void> _send() async {
    // Capture context-dependent values BEFORE any awaits — Dart lints flag
    // post-await `context` reads in async handlers.
    final media = ref.read(mediaServiceProvider);
    final toast = ref.read(toastServiceProvider.notifier);
    final messages = ref.read(
      messagesProvider(widget.conversationId).notifier,
    );
    final senderId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    final failedTitle = context.t('chat.send.failed');
    final navigator = Navigator.of(context);
    // If still recording, stop first so we have a finalised clip on disk.
    // Suppress the stop haptic — _send() emits its own send tick below.
    if (_state == _RecState.recording) {
      await _stop(haptic: false);
    }
    if (_path == null) return;
    setState(() => _sending = true);
    final Uint8List bytes;
    try {
      bytes = await File(_path!).readAsBytes();
      media.validateVoiceBytes(bytes, mime: _mime, durationMs: _durationMs);
    } catch (_) {
      // Pre-flight failure (too long / too large) before any optimistic
      // bubble exists — surface inside the still-open sheet.
      toast.showToast(title: failedTitle, intent: AppIntent.danger);
      if (mounted) setState(() => _sending = false);
      return;
    }

    Haptics.light();
    final messageId = media.generateMessageId();
    final ext = _mime.endsWith('webm') ? 'webm' : 'm4a';
    final mime = _mime;
    final durationMs = _durationMs;

    Future<void> send() => messages.sendMedia(
          messageId: messageId,
          optimistic: Message.optimisticVoice(
            messageId: messageId,
            conversationId: widget.conversationId,
            senderId: senderId ?? '',
            createdAt: DateTime.now().toUtc(),
            durationMs: durationMs,
          ),
          send: () async {
            final path = await media.uploadChatMedia(
              conversationId: widget.conversationId,
              messageId: messageId,
              fileName: 'voice.$ext',
              bytes: bytes,
              mime: mime,
            );
            return media.sendVoiceMessage(
              conversationId: widget.conversationId,
              mediaPath: path,
              mediaMime: mime,
              mediaSizeBytes: bytes.lengthInBytes,
              durationMs: durationMs,
            );
          },
        );

    // Close the sheet immediately — the optimistic bubble (and any inline
    // FAILED state) now lives in the conversation thread. Errors surface on
    // the bubble, not as a toast here.
    if (mounted) unawaited(navigator.maybePop());
    unawaited(send().catchError((_) {}));
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
          // Prominent "recording" affordance — a 70px danger-bg circle with
          // a 3px danger border, a centred glyph, and an outer glow ring,
          // matching the gallery's `.recorder .pulse`. The glow ring breathes
          // (opacity-animated) while recording to read as "live"; idle/ready
          // drops to a muted, static treatment.
          Center(
            child: _RecordPulse(
              animation: _pulse,
              recording: _state == _RecState.recording,
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
          // Live amplitude-driven waveform — bars scroll left-to-right
          // while recording; falls back to all-minimum bars otherwise.
          Center(
            child: RepaintBoundary(
              child: _LiveWaveformStrip(
                levels: _levels,
                color: colors.navy,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.t('chat.recorderDisclosure'),
            textAlign: TextAlign.center,
            style: typo.bodyXs.copyWith(color: colors.muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (_state == _RecState.idle)
            // Explicit START gate — user must opt in to recording instead of
            // the sheet auto-capturing the moment it opens. Pairs with the
            // dispose() cancel sweep above.
            Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    label: context.t('chat.recording.cancel'),
                    variant: AppButtonVariant.outline,
                    onPressed: _cancel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    key: const ValueKey('voice-recorder-start'),
                    label: context.t('chat.recording.start'),
                    variant: AppButtonVariant.primary,
                    onPressed: _start,
                  ),
                ),
              ],
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

/// The gallery's `.recorder .pulse`: a 70px danger-bg circle with a 3px
/// danger border, a centred ● glyph in the danger tone, and a soft outer
/// glow ring (`box-shadow: 0 0 0 6px rgba(danger,0.15)`).
///
/// While [recording] the glow ring breathes via [animation] to signal a
/// live mic; idle/ready collapses to a static muted disc so the affordance
/// still reads but no longer implies capture is in progress.
class _RecordPulse extends StatelessWidget {
  const _RecordPulse({required this.animation, required this.recording});

  final Animation<double> animation;
  final bool recording;

  static const double _diameter = 70;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final fill = recording ? colors.dangerBg : colors.slate100;
    final accent = recording ? colors.danger : colors.muted;
    final disc = Container(
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 3),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.circle, size: 24, color: accent),
    );
    if (!recording) return disc;
    // Animate the 6px outer glow ring's opacity so the disc itself stays
    // crisp while the surrounding halo breathes.
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = 0.10 + 0.18 * animation.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.danger.withValues(alpha: t),
                spreadRadius: 6,
                blurRadius: 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: disc,
    );
  }
}

/// Live amplitude strip — 30 navy bars driven by [levels]. Each entry is
/// a 0..1 magnitude (silence..clipping). The painter maps that magnitude
/// to a bar height in [_minBarHeight].._maxBarHeight].
///
/// Repaints are triggered by the [ValueNotifier], so the parent sheet
/// only rebuilds for state-machine changes (timer, cancel/send affordance).
class _LiveWaveformStrip extends StatelessWidget {
  const _LiveWaveformStrip({required this.levels, required this.color});

  /// Number of bars in the strip. ~30 gives ~3 s of history at 10 Hz which
  /// matches the gallery proportions while staying readable.
  static const int barCount = 30;
  static const double _barWidth = 2;
  static const double _barGap = 2;
  static const double _minBarHeight = 4;
  static const double _maxBarHeight = 24;
  static const double _stripHeight = 28;
  static double get _stripWidth =>
      barCount * _barWidth + (barCount - 1) * _barGap;

  final ValueListenable<List<double>> levels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _stripWidth,
      height: _stripHeight,
      child: ValueListenableBuilder<List<double>>(
        valueListenable: levels,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _WaveformPainter(
              levels: value,
              color: color,
              barWidth: _barWidth,
              barGap: _barGap,
              minBarHeight: _minBarHeight,
              maxBarHeight: _maxBarHeight,
            ),
            size: Size(_stripWidth, _stripHeight),
          );
        },
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.levels,
    required this.color,
    required this.barWidth,
    required this.barGap,
    required this.minBarHeight,
    required this.maxBarHeight,
  });

  final List<double> levels;
  final Color color;
  final double barWidth;
  final double barGap;
  final double minBarHeight;
  final double maxBarHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final radius = Radius.circular(barWidth);
    final centerY = size.height / 2;
    for (var i = 0; i < levels.length; i++) {
      final level = levels[i].clamp(0.0, 1.0);
      final height = minBarHeight + (maxBarHeight - minBarHeight) * level;
      final x = i * (barWidth + barGap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, centerY - height / 2, barWidth, height),
        radius,
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.color != color ||
      old.barWidth != barWidth ||
      old.barGap != barGap ||
      old.minBarHeight != minBarHeight ||
      old.maxBarHeight != maxBarHeight ||
      !_listEquals(old.levels, levels);

  static bool _listEquals(List<double> a, List<double> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
