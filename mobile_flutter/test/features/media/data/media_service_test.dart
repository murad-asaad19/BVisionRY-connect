import 'dart:typed_data';

import 'package:connect_mobile/core/errors/app_exception.dart';
import 'package:connect_mobile/features/media/constants.dart';
import 'package:connect_mobile/features/media/data/media_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGateway extends Mock implements MediaGateway {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(<String, dynamic>{});
  });

  group('validation', () {
    test('validateImageBytes rejects oversize', () {
      final svc = MediaService(_MockGateway(), idGenerator: () => 'u');
      expect(
        () => svc.validateImageBytes(
          Uint8List(MediaConstants.maxImageBytes + 1),
          mime: 'image/jpeg',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('validateImageBytes rejects unsupported mime', () {
      final svc = MediaService(_MockGateway(), idGenerator: () => 'u');
      expect(
        () => svc.validateImageBytes(Uint8List(100), mime: 'image/heic'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('validateImageBytes accepts allowed mime + size', () {
      final svc = MediaService(_MockGateway(), idGenerator: () => 'u');
      svc.validateImageBytes(Uint8List(100), mime: 'image/jpeg');
    });

    test('validateVoiceBytes rejects oversize', () {
      final svc = MediaService(_MockGateway(), idGenerator: () => 'u');
      expect(
        () => svc.validateVoiceBytes(
          Uint8List(MediaConstants.maxVoiceBytes + 1),
          mime: 'audio/m4a',
          durationMs: 1000,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('validateVoiceBytes rejects bad mime', () {
      final svc = MediaService(_MockGateway(), idGenerator: () => 'u');
      expect(
        () => svc.validateVoiceBytes(
          Uint8List(100),
          mime: 'audio/wav',
          durationMs: 1000,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('validateVoiceBytes rejects too-long duration', () {
      final svc = MediaService(_MockGateway(), idGenerator: () => 'u');
      expect(
        () => svc.validateVoiceBytes(
          Uint8List(100),
          mime: 'audio/m4a',
          durationMs: MediaConstants.maxVoiceMs + 1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  test('chatMediaPath builds {conversationId}/{messageId}/{filename}', () {
    final svc = MediaService(_MockGateway(), idGenerator: () => 'm-1');
    expect(
      svc.chatMediaPath(
        conversationId: 'c1',
        messageId: 'm-1',
        fileName: 'photo.jpg',
      ),
      'c1/m-1/photo.jpg',
    );
  });

  test('generateMessageId returns the injected value', () {
    final svc = MediaService(_MockGateway(), idGenerator: () => 'fixed-id');
    expect(svc.generateMessageId(), 'fixed-id');
  });

  group('uploadChatMedia', () {
    test('forwards bucket/path/mime to gateway and returns path', () async {
      final gw = _MockGateway();
      final svc = MediaService(gw, idGenerator: () => 'm1');
      when(
        () => gw.uploadBinary(
          bucket: 'chat-media',
          path: 'c1/m1/photo.jpg',
          bytes: any(named: 'bytes'),
          contentType: 'image/jpeg',
        ),
      ).thenAnswer((_) async {});
      final bytes = Uint8List.fromList(<int>[1, 2, 3]);
      final path = await svc.uploadChatMedia(
        conversationId: 'c1',
        messageId: 'm1',
        fileName: 'photo.jpg',
        bytes: bytes,
        mime: 'image/jpeg',
      );
      expect(path, 'c1/m1/photo.jpg');
    });
  });

  group('getSignedUrl', () {
    test('caches subsequent calls for the same path', () async {
      final gw = _MockGateway();
      final svc = MediaService(gw, idGenerator: () => 'u');
      var calls = 0;
      when(
        () => gw.createSignedUrl(
          bucket: 'chat-media',
          path: 'c1/m1/photo.jpg',
          ttlSeconds: 60,
        ),
      ).thenAnswer((_) async {
        calls++;
        return 'https://signed/$calls';
      });
      final a = await svc.getSignedUrl('c1/m1/photo.jpg');
      final b = await svc.getSignedUrl('c1/m1/photo.jpg');
      expect(a, b);
      expect(calls, 1);
    });
  });

  group('sendImageMessage', () {
    test('dispatches send_image_message with all params', () async {
      final gw = _MockGateway();
      final svc = MediaService(gw, idGenerator: () => 'm1');
      when(
        () => gw.rpc('send_image_message', params: any(named: 'params')),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'id': 'm1',
          'conversation_id': 'c1',
          'sender_id': 'u1',
          'kind': 'image',
          'media_path': 'c1/m1/photo.jpg',
          'media_size_bytes': 1024,
          'created_at': '2026-05-25T10:00:00Z',
        },
      );
      final msg = await svc.sendImageMessage(
        conversationId: 'c1',
        mediaPath: 'c1/m1/photo.jpg',
        mediaMime: 'image/jpeg',
        mediaSizeBytes: 1024,
      );
      expect(msg.id, 'm1');
      expect(msg.mediaPath, 'c1/m1/photo.jpg');
      verify(
        () => gw.rpc(
          'send_image_message',
          params: <String, dynamic>{
            'p_conversation_id': 'c1',
            'p_media_path': 'c1/m1/photo.jpg',
            'p_media_mime': 'image/jpeg',
            'p_media_size_bytes': 1024,
          },
        ),
      ).called(1);
    });
  });

  group('sendVoiceMessage', () {
    test('dispatches send_voice_message with all params', () async {
      final gw = _MockGateway();
      final svc = MediaService(gw, idGenerator: () => 'm1');
      when(
        () => gw.rpc('send_voice_message', params: any(named: 'params')),
      ).thenAnswer(
        (_) async => <String, dynamic>{
          'id': 'm1',
          'conversation_id': 'c1',
          'sender_id': 'u1',
          'kind': 'voice',
          'media_path': 'c1/m1/voice.m4a',
          'media_duration_ms': 30000,
          'media_size_bytes': 240000,
          'created_at': '2026-05-25T10:00:00Z',
        },
      );
      final msg = await svc.sendVoiceMessage(
        conversationId: 'c1',
        mediaPath: 'c1/m1/voice.m4a',
        mediaMime: 'audio/m4a',
        mediaSizeBytes: 240000,
        durationMs: 30000,
      );
      expect(msg.id, 'm1');
      expect(msg.mediaDurationMs, 30000);
      verify(
        () => gw.rpc(
          'send_voice_message',
          params: <String, dynamic>{
            'p_conversation_id': 'c1',
            'p_media_path': 'c1/m1/voice.m4a',
            'p_media_mime': 'audio/m4a',
            'p_media_size_bytes': 240000,
            'p_duration_ms': 30000,
          },
        ),
      ).called(1);
    });
  });
}
