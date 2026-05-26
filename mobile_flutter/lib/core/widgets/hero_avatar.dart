import 'package:flutter/material.dart';

import 'avatar.dart';

/// Phase 15 — `Hero`-wrapped Avatar.
///
/// Used at the discovery card -> public profile transition: tagging both
/// the source and destination avatars with `avatar-<userId>` produces a
/// smooth flight on `Navigator.push`. The tag is deterministic, so as
/// long as two routes render a `HeroAvatar` with the same `userId`, the
/// flight is automatic.
class HeroAvatar extends StatelessWidget {
  const HeroAvatar({
    super.key,
    required this.userId,
    required this.name,
    this.photoUrl,
    this.size = 48,
    this.tone = AvatarTone.defaultTone,
  });

  final String userId;
  final String name;
  final String? photoUrl;
  final double size;
  final AvatarTone tone;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'avatar-$userId',
      // Material wrapper avoids "no Material widget found" mid-flight
      // when the destination is on a non-Material route.
      flightShuttleBuilder: (flightCtx, animation, direction, fromCtx, toCtx) =>
          Material(
        color: Colors.transparent,
        child: Avatar(
          name: name,
          photoUrl: photoUrl,
          size: size,
          tone: tone,
        ),
      ),
      child: Avatar(
        name: name,
        photoUrl: photoUrl,
        size: size,
        tone: tone,
      ),
    );
  }
}
