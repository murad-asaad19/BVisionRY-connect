import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Elevation tokens — themeable [BoxShadow] lists derived from the brand
/// palette so card/button/bubble halos stay tinted with [AppColors] (navy /
/// gold) instead of opaque black drop shadows.
///
/// Build the light-surface set with [AppShadows.from] (the tints reference
/// [AppColors] so they track theming). Use [AppShadows.none] on dark surfaces
/// where navy/gold halos would read as muddy.
@immutable
class AppShadows extends ThemeExtension<AppShadows> {
  const AppShadows({
    required this.card,
    required this.cardFeatured,
    required this.topBar,
    required this.bottomNav,
    required this.buttonPrimary,
    required this.buttonGold,
    required this.authCard,
    required this.bubbleMe,
    required this.bubbleThem,
    required this.chip,
  });

  /// Brand-tinted elevation set for light surfaces.
  factory AppShadows.from(AppColors c) {
    return AppShadows(
      card: <BoxShadow>[
        BoxShadow(
          color: c.navy.withValues(alpha: 0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: c.navy.withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
      cardFeatured: <BoxShadow>[
        BoxShadow(
          color: c.gold.withValues(alpha: 0.12),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: c.navy.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
      topBar: <BoxShadow>[
        BoxShadow(
          color: c.navy.withValues(alpha: 0.05),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
      bottomNav: <BoxShadow>[
        BoxShadow(
          color: c.navy.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
      buttonPrimary: <BoxShadow>[
        BoxShadow(
          color: c.navy.withValues(alpha: 0.22),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
      buttonGold: <BoxShadow>[
        BoxShadow(
          color: c.gold.withValues(alpha: 0.32),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
      authCard: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.20),
          blurRadius: 40,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      bubbleMe: <BoxShadow>[
        BoxShadow(
          color: c.navy.withValues(alpha: 0.22),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      bubbleThem: <BoxShadow>[
        BoxShadow(
          color: c.navy.withValues(alpha: 0.07),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
      chip: <BoxShadow>[
        BoxShadow(
          color: c.navy.withValues(alpha: 0.22),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Flat set — no halos. Used on dark surfaces where brand-tinted glows
  /// read as muddy.
  static const AppShadows none = AppShadows(
    card: <BoxShadow>[],
    cardFeatured: <BoxShadow>[],
    topBar: <BoxShadow>[],
    bottomNav: <BoxShadow>[],
    buttonPrimary: <BoxShadow>[],
    buttonGold: <BoxShadow>[],
    authCard: <BoxShadow>[],
    bubbleMe: <BoxShadow>[],
    bubbleThem: <BoxShadow>[],
    chip: <BoxShadow>[],
  );

  /// Standard card resting elevation.
  final List<BoxShadow> card;

  /// Featured (gold) card elevation.
  final List<BoxShadow> cardFeatured;

  /// Top app bar drop shadow.
  final List<BoxShadow> topBar;

  /// Bottom navigation bar drop shadow (casts upward).
  final List<BoxShadow> bottomNav;

  /// Primary (navy) button elevation.
  final List<BoxShadow> buttonPrimary;

  /// Gold button elevation.
  final List<BoxShadow> buttonGold;

  /// Auth card elevation (deep, on the navy hero).
  final List<BoxShadow> authCard;

  /// Outgoing chat bubble elevation.
  final List<BoxShadow> bubbleMe;

  /// Incoming chat bubble elevation.
  final List<BoxShadow> bubbleThem;

  /// Chip / pill elevation.
  final List<BoxShadow> chip;

  @override
  AppShadows copyWith({
    List<BoxShadow>? card,
    List<BoxShadow>? cardFeatured,
    List<BoxShadow>? topBar,
    List<BoxShadow>? bottomNav,
    List<BoxShadow>? buttonPrimary,
    List<BoxShadow>? buttonGold,
    List<BoxShadow>? authCard,
    List<BoxShadow>? bubbleMe,
    List<BoxShadow>? bubbleThem,
    List<BoxShadow>? chip,
  }) {
    return AppShadows(
      card: card ?? this.card,
      cardFeatured: cardFeatured ?? this.cardFeatured,
      topBar: topBar ?? this.topBar,
      bottomNav: bottomNav ?? this.bottomNav,
      buttonPrimary: buttonPrimary ?? this.buttonPrimary,
      buttonGold: buttonGold ?? this.buttonGold,
      authCard: authCard ?? this.authCard,
      bubbleMe: bubbleMe ?? this.bubbleMe,
      bubbleThem: bubbleThem ?? this.bubbleThem,
      chip: chip ?? this.chip,
    );
  }

  @override
  AppShadows lerp(ThemeExtension<AppShadows>? other, double t) {
    if (other is! AppShadows) return this;
    return AppShadows(
      card: _lerp(card, other.card, t),
      cardFeatured: _lerp(cardFeatured, other.cardFeatured, t),
      topBar: _lerp(topBar, other.topBar, t),
      bottomNav: _lerp(bottomNav, other.bottomNav, t),
      buttonPrimary: _lerp(buttonPrimary, other.buttonPrimary, t),
      buttonGold: _lerp(buttonGold, other.buttonGold, t),
      authCard: _lerp(authCard, other.authCard, t),
      bubbleMe: _lerp(bubbleMe, other.bubbleMe, t),
      bubbleThem: _lerp(bubbleThem, other.bubbleThem, t),
      chip: _lerp(chip, other.chip, t),
    );
  }

  static List<BoxShadow> _lerp(
    List<BoxShadow> a,
    List<BoxShadow> b,
    double t,
  ) {
    // BoxShadow.lerp requires matching list lengths; when the two sets differ
    // (e.g. the flat dark set vs. the tinted light set) fall back to a
    // discrete crossover rather than risk a length mismatch.
    if (a.length != b.length) return t < 0.5 ? a : b;
    return <BoxShadow>[
      for (int i = 0; i < a.length; i++) BoxShadow.lerp(a[i], b[i], t)!,
    ];
  }
}
