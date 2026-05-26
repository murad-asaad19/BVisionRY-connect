import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/i18n/i18n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../media/data/media_service.dart';
import '../../domain/transcript_status.dart';
import '../../providers/voice_player_provider.dart';
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
  });

  final String messageId;
  final String mediaPath;
  final int durationMs;
  final BubbleVariant variant;
  final String? transcript;
  final TranscriptStatus? transcriptStatus;
  final VoidCallback? onLongPress;

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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final isMe = widget.variant == BubbleVariant.me;
    final player = ref.watch(voicePlayerProvider);
    final active = player.activeId == widget.messageId;
    final progress =
        active && player.totalMs > 0 ? player.positionMs / player.totalMs : 0.0;
    final isReady = widget.transcriptStatus == TranscriptStatus.ready;
    final hasTranscript = isReady && (widget.transcript?.isNotEmpty ?? false);
    final isTranscribing =
        widget.transcriptStatus == TranscriptStatus.pending ||
            widget.transcriptStatus == TranscriptStatus.processing;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            GestureDetector(
              onLongPress: widget.onLongPress,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
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
                      isPlaying: active && player.isPlaying,
                      isMe: isMe,
                      onTap: _toggle,
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 140,
                      child: VoiceWaveform(
                        progress: progress,
                        activeColor: isMe ? colors.gold : colors.navy,
                        inactiveColor:
                            isMe ? colors.navyLight : colors.slate300,
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
            if (hasTranscript || isTranscribing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: hasTranscript
                      ? () => setState(() => _transcriptOpen = !_transcriptOpen)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          _transcriptOpen
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 12,
                          color: colors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isTranscribing
                              ? context.t('media.transcriptPending')
                              : _transcriptOpen
                                  ? context.t('media.hideTranscript')
                                  : context.t('media.showTranscript'),
                          style: typo.displayXs.copyWith(
                            color: colors.muted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_transcriptOpen && hasTranscript)
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
          ],
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isMe,
    required this.onTap,
  });

  final bool isPlaying;
  final bool isMe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Material(
      color: isMe ? colors.gold : colors.goldPale,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            isPlaying ? LucideIcons.pause : LucideIcons.play,
            size: 14,
            color: colors.navy,
          ),
        ),
      ),
    );
  }
}
