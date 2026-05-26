import 'package:formz/formz.dart';

/// Validation failure modes for [TagInput]. The server raises
/// `_opportunity_validate_input` errors for each of these; the value object
/// mirrors them so the client can short-circuit before round-tripping.
enum TagInputError { tooMany, tagTooLong, tagEmpty }

/// Formz value object for the opportunity tag list.
///
/// Server contract (`_opportunity_validate_input`): at most 8 tags; each tag
/// lowercase, 1–30 chars, non-empty. The client additionally rejects
/// duplicates and trims whitespace on add.
class TagInput extends FormzInput<List<String>, TagInputError> {
  /// Empty, pristine input — the initial state for a composer with no tags.
  const TagInput.pure() : super.pure(const <String>[]);

  /// Constructs a `dirty` input from an existing list. Used by the composer
  /// when pre-populating from a draft / edit fixture.
  const TagInput.dirty([super.value = const <String>[]]) : super.dirty();

  /// Hard cap on the number of tags. Matches the server-side ≤ 8 check.
  static const int maxTags = 8;

  /// Per-tag length cap. Matches the server-side `length(t) BETWEEN 1 AND 30`
  /// check.
  static const int maxTagLength = 30;

  /// Adds [tag] to the list, applying the normalisation rules:
  ///   - `trim()` + `toLowerCase()`,
  ///   - reject empty,
  ///   - reject when > 30 chars,
  ///   - reject duplicates,
  ///   - reject when 8 tags already present.
  ///
  /// Returns `this` unchanged on rejection so the caller can ignore the
  /// difference safely (the TextField just won't append the dud value).
  TagInput add(String tag) {
    final String normalized = tag.trim().toLowerCase();
    if (normalized.isEmpty) return this;
    if (normalized.length > maxTagLength) return this;
    if (value.contains(normalized)) return this;
    if (value.length >= maxTags) return this;
    return TagInput.dirty(<String>[...value, normalized]);
  }

  /// Removes [tag] from the list, returning the unchanged input if [tag]
  /// isn't present (e.g. a stale chip tap after rebuild).
  TagInput remove(String tag) {
    if (!value.contains(tag)) return this;
    return TagInput.dirty(
      value.where((String t) => t != tag).toList(growable: false),
    );
  }

  @override
  TagInputError? validator(List<String> v) {
    if (v.length > maxTags) return TagInputError.tooMany;
    for (final String t in v) {
      if (t.isEmpty) return TagInputError.tagEmpty;
      if (t.length > maxTagLength) return TagInputError.tagTooLong;
    }
    return null;
  }
}
