import 'package:connect_mobile/features/chat/providers/voice_player_provider.dart';
import 'package:connect_mobile/features/media/data/voice_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggle starts playback for a new id', () async {
    final backend = FakeVoicePlayerBackend();
    final container = ProviderContainer(
      overrides: [
        voicePlayerProvider.overrideWith(
          (ref) => VoicePlayerNotifier(backend),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(voicePlayerProvider.notifier);
    await notifier.toggle(messageId: 'm1', url: 'https://x/a.m4a');
    expect(backend.loadedUrl, 'https://x/a.m4a');
    expect(backend.isPlaying, isTrue);
    expect(container.read(voicePlayerProvider).activeId, 'm1');
    expect(container.read(voicePlayerProvider).isPlaying, isTrue);
  });

  test('toggle same id pauses then resumes', () async {
    final backend = FakeVoicePlayerBackend();
    final container = ProviderContainer(
      overrides: [
        voicePlayerProvider.overrideWith(
          (ref) => VoicePlayerNotifier(backend),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(voicePlayerProvider.notifier);
    await notifier.toggle(messageId: 'm1', url: 'https://x/a.m4a');
    expect(container.read(voicePlayerProvider).isPlaying, isTrue);
    await notifier.toggle(messageId: 'm1', url: 'https://x/a.m4a');
    expect(container.read(voicePlayerProvider).isPlaying, isFalse);
    await notifier.toggle(messageId: 'm1', url: 'https://x/a.m4a');
    expect(container.read(voicePlayerProvider).isPlaying, isTrue);
  });

  test('switching ids stops previous and starts new', () async {
    final backend = FakeVoicePlayerBackend();
    final container = ProviderContainer(
      overrides: [
        voicePlayerProvider.overrideWith(
          (ref) => VoicePlayerNotifier(backend),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(voicePlayerProvider.notifier);
    await notifier.toggle(messageId: 'm1', url: 'https://x/a.m4a');
    await notifier.toggle(messageId: 'm2', url: 'https://x/b.m4a');
    expect(container.read(voicePlayerProvider).activeId, 'm2');
    expect(backend.loadedUrl, 'https://x/b.m4a');
    expect(backend.stopped, isTrue);
  });

  test('stop resets state to idle', () async {
    final backend = FakeVoicePlayerBackend();
    final container = ProviderContainer(
      overrides: [
        voicePlayerProvider.overrideWith(
          (ref) => VoicePlayerNotifier(backend),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(voicePlayerProvider.notifier);
    await notifier.toggle(messageId: 'm1', url: 'https://x/a.m4a');
    await notifier.stop();
    expect(container.read(voicePlayerProvider).activeId, isNull);
    expect(container.read(voicePlayerProvider).isPlaying, isFalse);
  });

  test('position stream feeds positionMs onto state', () async {
    final backend = FakeVoicePlayerBackend(
      totalDuration: const Duration(seconds: 30),
    );
    final container = ProviderContainer(
      overrides: [
        voicePlayerProvider.overrideWith(
          (ref) => VoicePlayerNotifier(backend),
        ),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(voicePlayerProvider.notifier);
    await notifier.toggle(messageId: 'm1', url: 'https://x/a.m4a');
    backend.advancePosition(const Duration(seconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(container.read(voicePlayerProvider).positionMs, 5000);
    expect(container.read(voicePlayerProvider).totalMs, 30000);
  });
}
