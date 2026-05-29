import 'dart:typed_data';

import 'package:connect_mobile/features/profile/data/avatar_upload_service.dart';
import 'package:connect_mobile/features/profile/presentation/avatar_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../../../helpers/pump.dart';

class _FakeSource implements AvatarSource {
  _FakeSource(this._bytes);
  final Uint8List? _bytes;
  @override
  Future<Uint8List?> pickAndCropSquareAvatar({
    ImageSource source = ImageSource.gallery,
  }) async =>
      _bytes;
}

class _FakeStorage implements AvatarStorageGateway {
  String? uploadedPath;
  String? patchedUrl;
  String? clearedUserId;
  @override
  Future<void> uploadAvatar({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required bool upsert,
  }) async {
    uploadedPath = path;
  }

  @override
  String getPublicUrl(String path) => 'https://cdn/$path';
  @override
  Future<void> patchPhotoUrl({
    required String userId,
    required String url,
  }) async {
    patchedUrl = url;
  }

  @override
  Future<void> clearPhotoUrl({required String userId}) async {
    clearedUserId = userId;
  }
}

void main() {
  testWidgets(
    'tapping the avatar picker invokes the upload pipeline and yields the new URL',
    (WidgetTester tester) async {
      final _FakeStorage storage = _FakeStorage();
      final AvatarUploadService svc = AvatarUploadService(
        source: _FakeSource(Uint8List.fromList(List<int>.filled(1024, 1))),
        storage: storage,
        userId: 'u-1',
      );
      String? receivedUrl;
      await tester.pumpWidget(
        await wrapWithTheme(
          overrides: <Override>[
            avatarUploadServiceProvider
                .overrideWith((Ref<AvatarUploadService> _) => svc),
          ],
          child: Scaffold(
            body: AvatarPickerField(
              name: 'Sara K',
              currentUrl: null,
              onUploaded: (String url) => receivedUrl = url,
              onRemoved: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('avatarPickerField.tap')));
      await tester.pumpAndSettle();
      expect(receivedUrl, isNotNull);
      expect(receivedUrl, startsWith('https://cdn/u-1/avatar.jpg?v='));
      expect(storage.uploadedPath, 'u-1/avatar.jpg');
    },
  );

  testWidgets('shows a friendly error when the file is too large', (
    WidgetTester tester,
  ) async {
    final _FakeStorage storage = _FakeStorage();
    final Uint8List tooBig = Uint8List(kMaxAvatarBytes + 1);
    final AvatarUploadService svc = AvatarUploadService(
      source: _FakeSource(tooBig),
      storage: storage,
      userId: 'u-1',
    );
    await tester.pumpWidget(
      await wrapWithTheme(
        overrides: <Override>[
          avatarUploadServiceProvider
              .overrideWith((Ref<AvatarUploadService> _) => svc),
        ],
        child: Scaffold(
          body: AvatarPickerField(
            name: 'Sara K',
            currentUrl: null,
            onUploaded: (_) {},
            onRemoved: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('avatarPickerField.tap')));
    await tester.pumpAndSettle();
    expect(find.textContaining('smaller than'), findsOneWidget);
  });
}
