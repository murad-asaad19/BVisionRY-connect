import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Visual emphasis tone for [Avatar].
///
/// `featured` adds the gallery's double white+gold halo (used on profile
/// heroes / verified). `default` and `muted` render the plain gradient disc.
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
    this.semanticLabel,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final AvatarTone tone;

  /// Screen-reader label for the avatar as an image. When null the avatar is
  /// excluded from semantics (treated as decorative) — appropriate when an
  /// adjacent name/handle already conveys the identity.
  final String? semanticLabel;

  @override
  State<Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final showImage =
        widget.photoUrl != null && widget.photoUrl!.isNotEmpty && !_failed;
    // Mockup: large/featured avatars use a 135° gold gradient (navy
    // initials); small list/chat avatars use a 135° navy gradient (white
    // initials). Featured adds the double white+gold halo.
    final bool useGold =
        widget.tone == AvatarTone.featured || widget.size >= 60;
    final Gradient gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: useGold
          ? <Color>[colors.goldLight, colors.gold]
          : <Color>[colors.navyLight, colors.navy],
    );
    final Color initialsColor = useGold ? colors.navy : colors.white;
    final List<BoxShadow>? halo = widget.tone == AvatarTone.featured
        ? <BoxShadow>[
            BoxShadow(color: colors.gold, spreadRadius: 4),
            BoxShadow(color: colors.white, spreadRadius: 2),
          ]
        : null;
    final initials = _initials(widget.name);
    final textSize = _textSizeFor(widget.size);
    // Cap the decoded bitmap to the displayed pixel size so list avatars
    // don't pin multi-megabyte full-resolution images in the image cache.
    final int memCache =
        (widget.size * MediaQuery.devicePixelRatioOf(context)).round();

    final Widget frame = Container(
      key: const ValueKey('avatar-frame'),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: showImage ? null : gradient,
        color: showImage ? colors.goldPale : null,
        boxShadow: halo,
      ),
      clipBehavior: Clip.antiAlias,
      child: showImage
          ? CachedNetworkImage(
              imageUrl: widget.photoUrl!,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
              memCacheWidth: memCache,
              memCacheHeight: memCache,
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
                  color: initialsColor,
                  fontWeight: FontWeight.w700,
                  fontSize: textSize,
                  height: 1.1,
                ),
              ),
            ),
    );
    return widget.semanticLabel == null
        ? ExcludeSemantics(child: frame)
        : Semantics(image: true, label: widget.semanticLabel, child: frame);
  }
}

/// Two-letter initials (first letter of first + last token), upper-cased.
/// Empty / whitespace-only names collapse to a single `?`.
String _initials(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  final first = parts.first.isNotEmpty ? parts.first[0] : '';
  final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
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
    this.semanticLabel,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final AvatarTone tone;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Avatar(
        name: name,
        photoUrl: photoUrl,
        size: size,
        tone: tone,
        semanticLabel: semanticLabel,
      );
}
