import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/routing/routes.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_button.dart';
import '../../chat/providers/conversation_overview_provider.dart';
import 'send_intro_sheet.dart';

/// CTA that introduces the caller to [recipient] — OR, when a conversation
/// already exists with them, collapses to an "Open chat" button instead.
///
/// Sending an intro to someone you already chat with is nonsensical, so every
/// discovery / profile / opportunity surface that offers "Send intro" routes
/// through this widget. The existing-conversation lookup is the derived
/// [conversationIdForPeerProvider], which rides the Realtime-backed chats
/// cache — so the moment an intro is accepted (a conversation is created) the
/// CTA flips to "Open chat" with no manual refresh.
///
/// Surfaces with bespoke states that this widget can't express — e.g. the
/// public profile's sign-in / cooldown branches — apply the same
/// `conversationIdForPeerProvider` check inline rather than wrapping it here.
class IntroOrChatButton extends ConsumerWidget {
  const IntroOrChatButton({
    super.key,
    required this.recipient,
    required this.introLabel,
    this.introVariant = AppButtonVariant.primary,
    this.openChatVariant,
    this.introIcon,
    this.size = AppButtonSize.defaultSize,
    this.fullWidth = true,
    this.buttonKey,
  });

  /// Recipient passed straight through to [showSendIntroSheet] in the intro
  /// state; its `id` also drives the existing-conversation lookup.
  final SendIntroRecipient recipient;

  /// Label shown in the intro state (e.g. "Request intro" / "Send intro").
  final String introLabel;

  /// Button variant in the intro state.
  final AppButtonVariant introVariant;

  /// Button variant in the "Open chat" state. Defaults to [introVariant] so
  /// the CTA keeps the same visual weight when it flips.
  final AppButtonVariant? openChatVariant;

  /// Optional leading icon for the intro state.
  final IconData? introIcon;

  final AppButtonSize size;
  final bool fullWidth;

  /// Stable key applied to the rendered [AppButton] in BOTH states — the
  /// button occupies the same slot regardless of which CTA it shows.
  final Key? buttonKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? conversationId =
        ref.watch(conversationIdForPeerProvider(recipient.id));

    if (conversationId != null) {
      return AppButton(
        key: buttonKey,
        label: context.t('chat.openChat'),
        variant: openChatVariant ?? introVariant,
        size: size,
        fullWidth: fullWidth,
        icon: LucideIcons.messageSquare,
        onPressed: () {
          Haptics.light();
          context.push(Routes.chat(conversationId));
        },
      );
    }

    return AppButton(
      key: buttonKey,
      label: introLabel,
      variant: introVariant,
      size: size,
      fullWidth: fullWidth,
      icon: introIcon,
      onPressed: () {
        Haptics.light();
        Analytics.log(
          AppEvent.introComposeOpened,
          const <String, Object>{'via_warm': false},
        );
        showSendIntroSheet(context, recipient: recipient);
      },
    );
  }
}
