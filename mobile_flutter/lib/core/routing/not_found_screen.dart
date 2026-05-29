import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../i18n/i18n.dart';
import '../widgets/empty_state.dart';
import '../widgets/top_bar.dart';
import 'routes.dart';

/// Fallback destination for unmatched locations.
///
/// Wired into [GoRouter.errorBuilder] so a bad deep link or a malformed
/// `router.go(...)` payload (e.g. from an FCM notification handler) lands
/// here instead of GoRouter's default red error page. Also registered as
/// an explicit [Routes.notFound] route so it can be navigated to directly.
///
/// Built from the shared [TopBar] + [EmptyState] primitives using the
/// existing `notFound` i18n block, with a single "Go home" CTA that
/// `context.go`s back to [Routes.home] (the route guard then re-resolves
/// the user's correct landing for their auth/onboarding state).
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: TopBar(title: context.t('notFound.title'), back: true),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: LucideIcons.compass,
            title: context.t('notFound.title'),
            body: context.t('notFound.body'),
            action: EmptyStateAction(
              label: context.t('notFound.goHome'),
              onPressed: () => context.go(Routes.home),
            ),
          ),
        ),
      ),
    );
  }
}
