import 'package:connect_mobile/features/media/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MediaConstants matches spec §13.4', () {
    expect(MediaConstants.maxAvatarBytes, 5 * 1024 * 1024);
    expect(MediaConstants.maxImageBytes, 5 * 1024 * 1024);
    expect(MediaConstants.maxVoiceBytes, 25 * 1024 * 1024);
    expect(MediaConstants.maxVoiceMs, 120000);
    expect(MediaConstants.imageMaxDimension, 1600);
    expect(
      MediaConstants.allowedImageMimes,
      containsAll(<String>['image/jpeg', 'image/png', 'image/webp']),
    );
    expect(
      MediaConstants.allowedVoiceMimes,
      containsAll(<String>[
        'audio/m4a',
        'audio/mp4',
        'audio/aac',
        'audio/webm',
      ]),
    );
    expect(MediaConstants.signedUrlTtlSeconds, 60);
  });
}
