import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/widgets/top_bar.dart';

/// Kind discriminator for [LegalScreen] — selects the title + body i18n
/// keys for the privacy vs terms surface.
enum LegalKind { privacy, terms }

/// `/legal/{privacy,terms}` — single widget surfacing the long-form legal
/// text using `flutter_markdown`. The text lives in the locale JSON under
/// `legal.privacy.body` and `legal.terms.body`.
///
/// We re-use a single widget for both routes to keep formatting / scroll
/// behaviour consistent; the [kind] parameter selects which body to render.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.kind});

  /// Selects the title + body i18n keys.
  final LegalKind kind;

  String get _titleKey =>
      kind == LegalKind.privacy ? 'legal.privacy.title' : 'legal.terms.title';

  String get _bodyKey =>
      kind == LegalKind.privacy ? 'legal.privacy.body' : 'legal.terms.body';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t(_titleKey), back: true),
      ),
      body: Markdown(
        data: context.t(_bodyKey),
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}
