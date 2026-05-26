import 'package:connect_mobile/features/opportunities/domain/tag_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TagInput', () {
    test('initial is empty and pure', () {
      const TagInput t = TagInput.pure();
      expect(t.value, isEmpty);
      expect(t.isValid, isTrue);
      expect(t.isPure, isTrue);
    });

    test('add normalizes to lowercase + trimmed', () {
      TagInput t = const TagInput.pure();
      t = t.add('  PM ');
      expect(t.value, <String>['pm']);
    });

    test('add ignores duplicates', () {
      TagInput t = const TagInput.pure();
      t = t.add('pm').add('PM');
      expect(t.value, <String>['pm']);
    });

    test('add rejects when limit (8) reached', () {
      TagInput t = const TagInput.pure();
      for (int i = 0; i < 8; i++) {
        t = t.add('tag$i');
      }
      expect(t.value, hasLength(8));
      final TagInput next = t.add('tag8');
      expect(next.value, hasLength(8));
      expect(identical(next, t), isTrue);
    });

    test('add rejects empty strings', () {
      TagInput t = const TagInput.pure();
      t = t.add('');
      expect(t.value, isEmpty);
      t = t.add('   ');
      expect(t.value, isEmpty);
    });

    test('add rejects > 30 char tags', () {
      TagInput t = const TagInput.pure();
      final String tooLong = String.fromCharCodes(List<int>.filled(31, 0x61));
      t = t.add(tooLong);
      expect(t.value, isEmpty);
      t = t.add(String.fromCharCodes(List<int>.filled(30, 0x61)));
      expect(t.value, hasLength(1));
    });

    test('add normalizes mixed-case tags', () {
      TagInput t = const TagInput.pure();
      t = t.add('Fintech');
      expect(t.value, <String>['fintech']);
    });

    test('remove drops a tag', () {
      TagInput t = const TagInput.pure().add('a').add('b');
      t = t.remove('a');
      expect(t.value, <String>['b']);
    });

    test('remove is a no-op for unknown tags', () {
      final TagInput t = const TagInput.pure().add('a');
      final TagInput next = t.remove('z');
      expect(identical(next, t), isTrue);
    });

    test('TagInput.dirty marks dirty state', () {
      const TagInput t = TagInput.dirty(<String>['pm', 'fintech']);
      expect(t.isPure, isFalse);
      expect(t.value, <String>['pm', 'fintech']);
      expect(t.isValid, isTrue);
    });

    test('TagInput.dirty with 9 tags is invalid', () {
      final List<String> nine = List<String>.generate(9, (int i) => 'tag$i');
      final TagInput t = TagInput.dirty(nine);
      expect(t.isValid, isFalse);
      expect(t.error, TagInputError.tooMany);
    });

    test('TagInput.dirty with a 31-char tag is invalid', () {
      final TagInput t = TagInput.dirty(<String>[
        String.fromCharCodes(List<int>.filled(31, 0x61)),
      ]);
      expect(t.error, TagInputError.tagTooLong);
    });

    test('TagInput.dirty with an empty tag is invalid', () {
      const TagInput t = TagInput.dirty(<String>['']);
      expect(t.error, TagInputError.tagEmpty);
    });
  });
}
