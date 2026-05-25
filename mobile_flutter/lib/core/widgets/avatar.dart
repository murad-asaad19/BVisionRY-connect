import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Visual emphasis tone for [Avatar].
///
/// `default` draws a neutral 2px border; `featured` swaps it for a 3px gold
/// halo; `muted` removes the border entirely (used inside dense list rows).
enum AvatarTone { defaultTone, featured, muted }

/// Circular avatar primitive — renders a photo when [photoUrl] is provided
/// and falls back to two-letter initials over the brand gold-pale background.
///
/// Sizes follow the design spec (32 / 38 / 48 / 64 / 76 / 96). The
/// implementation accepts any double so phase-specific call sites can opt
/// into custom sizes; `Avatar(size: 60)` works fine.
class Avatar extends StatefulWidget {
  const Avatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 48,
    this.tone = AvatarTone.defaultTone,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final AvatarTone tone;

  @override
  State<Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final showImage = widget.photoUrl != null &&
        widget.photoUrl!.isNotEmpty &&
        !_failed;
    final border = switch (widget.tone) {
      AvatarTone.featured => Border.all(color: colors.gold, width: 3),
      AvatarTone.defaultTone => Border.all(color: colors.border, width: 2),
      AvatarTone.muted => null,
    };
    final initials = _initials(widget.name);
    final textSize = _textSizeFor(widget.size);

    return Container(
      key: const ValueKey('avatar-frame'),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.goldPale,
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: showImage
          ? CachedNetworkImage(
              imageUrl: widget.photoUrl!,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) {
                // Defer the fallback to initials by flagging the failure on
                // next frame — this avoids a setState during build.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _failed = true);
                });
                return Container(color: colors.goldPale);
              },
            )
          : Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: colors.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: textSize,
                  height: 1.1,
                ),
              ),
            ),
    );
  }
}

/// Two-letter initials (first letter of first + last token), upper-cased.
/// Empty / whitespace-only names collapse to a single `?`.
String _initials(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  final first = parts.first.isNotEmpty ? parts.first[0] : '';
  final last =
      parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
  final result = (first + last).toUpperCase();
  return result.isEmpty ? '?' : result;
}

double _textSizeFor(double size) {
  // Same ratios as the RN source: ~40% of the avatar diameter, rounded.
  if (size <= 32) return 13;
  if (size <= 38) return 15;
  if (size <= 48) return 19;
  if (size <= 64) return 25;
  if (size <= 76) return 30;
  return 38;
}

/// Back-compat alias — the RN codebase migrated `AvatarCircle` -> `Avatar`,
/// keeping both export names to avoid touching every call site at once. We
/// mirror that here so Phase-3 onward can use either symbol freely.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 48,
    this.tone = AvatarTone.defaultTone,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final AvatarTone tone;

  @override
  Widget build(BuildContext context) => Avatar(
        name: name,
        photoUrl: photoUrl,
        size: size,
        tone: tone,
      );
}
