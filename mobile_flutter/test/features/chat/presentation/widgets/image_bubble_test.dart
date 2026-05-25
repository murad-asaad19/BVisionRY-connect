import 'package:connect_mobile/features/chat/presentation/widgets/image_bubble.dart';
import 'package:connect_mobile/features/chat/presentation/widgets/text_bubble.dart';
import 'package:connect_mobile/features/media/data/media_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump.dart';

void main() {
  testWidgets('renders the resolved signed URL via CachedNetworkImage', (
    tester,
  ) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const Scaffold(
          body: ImageBubble(
            mediaPath: 'c1/m1/photo.jpg',
            variant: BubbleVariant.them,
          ),
        ),
        overrides: <Override>[
          signedChatMediaUrlProvider('c1/m1/photo.jpg').overrideWith(
            (_) async => 'https://example.com/signed.jpg',
          ),
        ],
      ),
    );
    expect(find.byType(ImageBubble), findsOneWidget);
  });

  testWidgets('shows error fallback when signed URL fetch fails', (
    tester,
  ) async {
    await pumpWithI18n(
      tester,
      await wrapWithTheme(
        child: const Scaffold(
          body: ImageBubble(
            mediaPath: 'c1/m1/photo.jpg',
            variant: BubbleVariant.them,
          ),
        ),
        overrides: <Override>[
          signedChatMediaUrlProvider('c1/m1/photo.jpg').overrideWith(
            (_) async => Future<String>.error(StateError('boom')),
          ),
        ],
      ),
    );
    expect(find.byIcon(Icons.broken_image), findsOneWidget);
  });
}
