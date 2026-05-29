import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../media/data/media_service.dart';
import '../../domain/message.dart';
import '../../domain/transcript_status.dart';
import '../../providers/voice_player_provider.dart';
import 'send_status_footer.dart';
import 'text_bubble.dart';
import 'voice_waveform.dart';

/// Voice-message bubble (gallery F1/F3).
///
/// Layout: gold 28px circular play/pause button, 13-bar [VoiceWaveform]
/// driven by the [voicePlayerProvider]'s position/total, and a `mm:ss`
/// duration label. When the message has a ready transcript, a collapsible
/// "Show transcript" affordance below the bubble reveals the text.
///
/// The bubble registers/reads via [voicePlayerProvider] so only one voice
/// note plays at a time across the whole app; tapping the play button
/// resolves the signed URL via [MediaService.getSignedUrl] (TTL-cached)
/// before toggling playback.
class VoiceBubble extends ConsumerStatefulWidget {
  const VoiceBubble({
    super.key,
    required this.messageId,
    required this.mediaPath,
    required this.durationMs,
    required this.variant,
    this.transcript,
    this.transcriptStatus,
    this.onLongPress,
    this.sendStatus,
    this.onRetry,
  });

  final String messageId;
  final String mediaPath;
  final int durationMs;
  final BubbleVariant variant;
  final String? transcript;
  final TranscriptStatus? transcriptStatus;
  final VoidCallback? onLongPress;

  /// Optimistic send state — drives the inline status footer + retry. Null
  /// for confirmed server rows.
  final MessageSendStatus? sendStatus;
  final VoidCallback? onRetry;

  @override
  ConsumerState<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends ConsumerState<VoiceBubble> {
  bool _transcriptOpen = false;

  String _fmt(int ms) {
    if (ms <= 0) return '0:00';
    final s = (ms / 1000).floor();
    final mm = (s ~/ 60).toString();
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _toggle() async {
    final media = ref.read(mediaServiceProvider);
    final url = await media.getSignedUrl(widget.mediaPath);
    await ref
        .read(voicePlayerProvider.notifier)
        .toggle(messageId: widget.messageId, url: url);
  }

  Future<void> _seek(double fraction) async {
    final media = ref.read(mediaServiceProvider);
    final url = await media.getSignedUrl(widget.mediaPath);
    await ref.read(voicePlayerProvider.notifier).seekToFraction(
          messageId: widget.messageId,
          url: url,
          totalMs: widget.durationMs,
          fraction: fraction,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final isMe = widget.variant == BubbleVariant.me;
    // PERF: select ONLY the three derived values this bubble cares about so
    // the per-tick position stream rebuilds this widget at most once per
    // ~1% progress change — not on every emitted millisecond. Inactive
    // bubbles never rebuild from another note's playback.
    final view = ref.watch(
      voicePlayerProvider.select((s) {
        final active = s.activeId == widget.messageId;
        return (
          isActive: active,
          isPlaying: active && s.isPlaying,
          progress: active && s.totalMs > 0 ? s.positionMs / s.totalMs : 0.0,
        );
      }),
    );
    final progress = view.progress;
    final isReady = widget.transcriptStatus == TranscriptStatus.ready;
    final hasTranscript = isReady && (widget.transcript?.isNotEmpty ?? false);
    final isTranscribing =
        widget.transcriptStatus == TranscriptStatus.pending ||
            widget.transcriptStatus == TranscriptStatus.processing;

    final isOptimistic = widget.sendStatus != null;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              label: context.t(
                'chat.voiceMessage',
                vars: <String, Object>{'duration': _fmt(widget.durationMs)},
              ),
              onLongPressHint: widget.onLongPress != null
                  ? context.t('chat.messageActionsHint')
                  : null,
              child: GestureDetector(
                onLongPress: widget.onLongPress,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? colors.navy : colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isMe ? 14 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 14),
                    ),
                    border: isMe ? null : Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _PlayButton(
                        isPlaying: view.isPlaying,
                        isMe: isMe,
                        label: context.t(
                          view.isPlaying
                              ? 'media.pauseVoice'
                              : 'media.playVoice',
                        ),
                        onTap: isOptimistic ? null : _toggle,
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: VoiceWaveform(
                          progress: progress,
                          activeColor: isMe ? colors.gold : colors.navy,
                          inactiveColor:
                              isMe ? colors.navyLight : colors.slate300,
                          onSeek: isOptimistic ? null : _seek,
                          seekSemanticLabel: context.t('media.playVoice'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _fmt(widget.durationMs),
                        style: typo.bodyXs.copyWith(
                          color: isMe ? colors.goldLight : colors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.sendStatus != null)
              SendStatusFooter(
                status: widget.sendStatus,
                onRetry: widget.onRetry,
              ),
            if (hasTranscript || isTranscribing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: hasTranscript
                      ? () => setState(() => _transcriptOpen = !_transcriptOpen)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      isTranscribing
                          ? context.t('media.transcriptPending')
                          : _transcriptOpen
                              ? context.t('media.hideTranscript')
                              : context.t('media.showTranscript'),
                      style: typo.bodyXs.copyWith(
                        color: isTranscribing ? colors.muted : colors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            if (_transcriptOpen && hasTranscript) ...<Widget>[
              Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.white,
                  borderRadius: BorderRadius.circular(radii.card),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      context.t('media.transcriptLabel').toUpperCase(),
                      style: typo.bodyXs.copyWith(
                        color: colors.muted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.transcript ?? '',
                      style: typo.bodyMd.copyWith(color: colors.body),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                child: Text(
                  // Full two-sentence disclosure per the mockup: the
                  // accessibility/safety sentence precedes the search-index
                  // clause.
                  '${context.t('media.transcriptFooter')} '
                  '${context.t('chat.transcriptPrivacyFooter')}',
                  style: typo.bodyXs.copyWith(
                    color: colors.muted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Play/pause control: keeps the gallery's 28px gold chip visual but
/// expands the hit + semantics surface to the 44dp WCAG/HIG minimum and
/// announces a localized Play/Pause label.
class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isMe,
    required this.label,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isMe;
  final String label;
  final VoidCallback? onTap;

  static const double _hit = 44;
  static const double _chip = 28;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: SizedBox(
        width: _hit,
        height: _hit,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkResponse(
            radius: _hit / 2,
            onTap: onTap,
            child: Center(
              child: Container(
                width: _chip,
                height: _chip,
                decoration: BoxDecoration(
                  // Mockup: outgoing ("me") chip is gold with a navy glyph;
                  // incoming ("them") chip inverts to navy with a gold glyph
                  // (.bubble.voice.them .play). Mirrors the navy/gold contrast
                  // of the two bubble fills.
                  color: isMe ? colors.gold : colors.navy,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                // Cross-fade the play/pause glyph so the toggle reads as a
                // smooth state change rather than a hard icon swap.
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeOut,
                  child: Icon(
                    isPlaying ? LucideIcons.pause : LucideIcons.play,
                    key: ValueKey<bool>(isPlaying),
                    size: 14,
                    color: isMe ? colors.navy : colors.gold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
