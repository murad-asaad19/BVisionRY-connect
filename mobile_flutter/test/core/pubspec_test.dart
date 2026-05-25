import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pubspec declares all foundation dependencies', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final dep in const [
      'flutter_riverpod:',
      'riverpod_annotation:',
      'go_router:',
      'supabase_flutter:',
      'flutter_secure_storage:',
      'shared_preferences:',
      'google_fonts:',
      'lucide_icons_flutter:',
      'freezed_annotation:',
      'json_annotation:',
      'formz:',
      'intl:',
      'cached_network_image:',
      'app_links:',
    ]) {
      expect(pubspec, contains(dep), reason: 'missing $dep');
    }
    for (final dep in const [
      'build_runner:',
      'riverpod_generator:',
      'freezed:',
      'json_serializable:',
      'mocktail:',
      'golden_toolkit:',
    ]) {
      expect(pubspec, contains(dep), reason: 'missing dev dep $dep');
    }
  });

  test('pubspec declares chat-phase dependencies', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final dep in const ['uuid:']) {
      expect(pubspec, contains(dep), reason: 'missing $dep');
    }
  });
}
