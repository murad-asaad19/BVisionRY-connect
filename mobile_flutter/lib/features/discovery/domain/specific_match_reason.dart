import '../../profile/domain/profile.dart';
import 'discovery_profile.dart';

/// Compose a human-readable, specific match-reason line for the viewer ↔
/// match pair, derived client-side from the public profile fields both
/// users expose.
///
/// The gallery's §9 "tiered specificity ladder" wants matches to surface
/// the highest-specificity heuristic available — e.g.
/// `"open to fractional CTO; you're hiring one"` rather than a generic
/// `"Complementary goals"`. Server-side composition would be ideal long
/// term; until then this resolver produces a useful subset using only
/// data already on [DiscoveryProfile] + the viewer's [Profile].
///
/// Returns `null` when nothing more specific than the server-side category
/// label can be derived — the chip should then fall back to
/// `MatchReason.i18nKey`.
String? composeSpecificMatchReason({
  required Profile viewer,
  required DiscoveryProfile match,
}) {
  final viewerGoal = viewer.goalType;
  final matchGoal = match.goalType;

  // --- Goal-type complementarity ---------------------------------------
  // Highest-specificity: complementary goals between viewer and match.
  final complementary = _complementaryGoal(viewerGoal, matchGoal);
  if (complementary != null) return complementary;

  // --- Shared sector / domain keywords ---------------------------------
  // When both goals or headlines mention the same domain term, surface
  // it. Cheap keyword overlap from a fixed list — not a free-text NLP.
  final keyword =
      _firstSharedKeyword(_corpusFor(viewer), _corpusForMatch(match));
  if (keyword != null) {
    final viewerRole = _capitalize(viewer.primaryRole ?? '');
    if (viewerRole.isNotEmpty) {
      return '$viewerRole in $keyword';
    }
    return 'shared focus: $keyword';
  }

  // --- Same role + same city ------------------------------------------
  if (viewer.primaryRole != null &&
      match.primaryRole != null &&
      viewer.primaryRole == match.primaryRole &&
      (viewer.city ?? '').isNotEmpty &&
      viewer.city == match.city) {
    return '${_capitalize(match.primaryRole!)}s in ${match.city}';
  }

  // --- Same city (any role) -------------------------------------------
  if ((viewer.city ?? '').isNotEmpty && viewer.city == match.city) {
    return 'also in ${match.city}';
  }

  return null;
}

/// Pairs the viewer's `goalType` with a likely-complementary match
/// `goalType`. Returned strings are short, lower-case fragments that read
/// naturally inline (the chip renders them after "Match:").
String? _complementaryGoal(String? viewer, String? match) {
  if (viewer == null || match == null) return null;
  // (viewer, match) -> chip text. Symmetric: hire/beHired both render
  // the "open to work" framing when the viewer is the hirer.
  const Map<(String, String), String> table = <(String, String), String>{
    ('hire', 'beHired'): "open to work; you're hiring",
    ('beHired', 'hire'): "hiring; you're looking for work",
    ('raise', 'invest'): "invests in this space; you're raising",
    ('invest', 'raise'): "raising; you're investing",
    ('coFound', 'coFound'): "also looking for a co-founder",
    ('findAdvisor', 'advise'): "advisor; you're seeking one",
    ('advise', 'findAdvisor'): "seeking advice; you advise",
    ('peerConnect', 'peerConnect'): "both open to peer connections",
  };
  return table[(viewer, match)];
}

/// Text corpora used by the keyword-overlap heuristic. Lower-cased so
/// matches are case-insensitive. We deliberately exclude the bio (too
/// noisy) and stick to fields the user curated explicitly.
String _corpusFor(Profile p) =>
    <String?>[p.goalText, p.headline].whereType<String>().join(' ').toLowerCase();

String _corpusForMatch(DiscoveryProfile p) => <String?>[p.headline, p.bio]
    .whereType<String>()
    .join(' ')
    .toLowerCase();

/// Domain keywords the composer looks for in both corpora. Curated rather
/// than data-derived so the chip text stays predictable.
const List<String> _kKeywordCatalogue = <String>[
  'MENA',
  'fintech',
  'healthtech',
  'edtech',
  'climate',
  'devtools',
  'AI',
  'agritech',
  'B2B',
  'B2C',
  'SaaS',
  'crypto',
  'web3',
  'consumer',
  'gaming',
  'biotech',
  'robotics',
  'infrastructure',
  'payments',
  'logistics',
  'marketplace',
  'security',
  'developer tools',
];

String? _firstSharedKeyword(String a, String b) {
  for (final kw in _kKeywordCatalogue) {
    final lc = kw.toLowerCase();
    if (a.contains(lc) && b.contains(lc)) return kw;
  }
  return null;
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
