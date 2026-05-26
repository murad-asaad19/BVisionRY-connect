import 'package:connect_mobile/core/accessibility/semantics_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('semanticIconLabel returns non-empty for known icons', () {
    expect(semanticIconLabel('Inbox'), 'inbox');
    expect(semanticIconLabel('Send'), 'send');
    expect(semanticIconLabel('BadgeCheck'), 'verified');
    expect(semanticIconLabel('Mic'), 'record voice');
  });

  test('semanticIconLabel falls back to lowercase icon name', () {
    expect(semanticIconLabel('UnknownIcon'), 'unknownicon');
  });
}
