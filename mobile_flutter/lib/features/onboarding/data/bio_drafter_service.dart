import 'dart:convert';

import 'package:http/http.dart' as http;

/// One AI-suggested (headline, bio) pair.
class BioDraftVariant {
  const BioDraftVariant({required this.headline, required this.bio});

  final String headline;
  final String bio;
}

/// Thin interface so tests can swap the HTTP transport without spinning up a
/// real server. Returns the raw decoded body — parsing the variants out of
/// the model's response lives in [BioDrafterService] so the same logic is
/// exercised under test.
abstract class AnthropicTransport {
  Future<http.Response> postMessages({
    required String apiKey,
    required Map<String, dynamic> body,
  });
}

class _DefaultAnthropicTransport implements AnthropicTransport {
  const _DefaultAnthropicTransport();

  @override
  Future<http.Response> postMessages({
    required String apiKey,
    required Map<String, dynamic> body,
  }) {
    return http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: <String, String>{
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }
}

/// Calls Anthropic's `claude-haiku-4-5` to produce 2-3 headline/bio variants
/// based on the user's primary role + goal text. Failures surface as
/// exceptions; the caller is responsible for falling back to a deterministic
/// template.
class BioDrafterService {
  BioDrafterService({
    required String apiKey,
    AnthropicTransport? transport,
  })  : _apiKey = apiKey,
        _transport = transport ?? const _DefaultAnthropicTransport();

  /// Returns a service instance when [apiKey] is non-empty, else `null` so
  /// callers can skip the API call entirely (and surface the local template
  /// fallback). Mirrors the optional-client pattern used by other Anthropic
  /// SDK wrappers.
  static BioDrafterService? clientFor(
    String apiKey, {
    AnthropicTransport? transport,
  }) {
    if (apiKey.trim().isEmpty) return null;
    return BioDrafterService(apiKey: apiKey, transport: transport);
  }

  final String _apiKey;
  final AnthropicTransport _transport;

  /// Maximum number of variants the model is asked to return; cards beyond
  /// this are clipped client-side.
  static const int maxVariants = 3;

  static const String _model = 'claude-haiku-4-5';

  /// Asks the model for [maxVariants] distinct (headline, bio) variants.
  ///
  /// Throws [BioDraftException] on transport errors, non-2xx responses, or
  /// JSON parse failures. Always returns at least one variant on success
  /// (clipped to [maxVariants]).
  Future<List<BioDraftVariant>> draft({
    required String roleLabel,
    required String goalText,
    String? goalLabel,
  }) async {
    final String prompt = _buildPrompt(
      roleLabel: roleLabel,
      goalText: goalText,
      goalLabel: goalLabel,
    );

    final http.Response response;
    try {
      response = await _transport.postMessages(
        apiKey: _apiKey,
        body: <String, dynamic>{
          'model': _model,
          'max_tokens': 800,
          'messages': <Map<String, dynamic>>[
            <String, dynamic>{'role': 'user', 'content': prompt},
          ],
        },
      );
    } on Object catch (e) {
      throw BioDraftException('transport: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BioDraftException('status=${response.statusCode}');
    }

    final List<BioDraftVariant> parsed = parseResponseBody(response.body);
    if (parsed.isEmpty) {
      throw BioDraftException('no variants in response');
    }
    return parsed.take(maxVariants).toList(growable: false);
  }

  /// Parses Anthropic's `messages` response shape down to the variant list.
  ///
  /// Tolerates the model wrapping the JSON in markdown code fences. Exposed
  /// for unit testing so the same parser runs on canned payloads.
  static List<BioDraftVariant> parseResponseBody(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const <BioDraftVariant>[];
    }
    if (decoded is! Map<String, dynamic>) return const <BioDraftVariant>[];

    final Object? content = decoded['content'];
    if (content is! List) return const <BioDraftVariant>[];

    // Concatenate every text block so a model that splits across blocks
    // still parses.
    final StringBuffer textBuf = StringBuffer();
    for (final Object? block in content) {
      if (block is Map<String, dynamic> &&
          block['type'] == 'text' &&
          block['text'] is String) {
        textBuf.writeln(block['text'] as String);
      }
    }
    final String text = textBuf.toString().trim();
    if (text.isEmpty) return const <BioDraftVariant>[];

    return _parseVariantArray(_stripCodeFences(text));
  }

  /// Extracts the first JSON array literal from [text]. Falls back to the
  /// raw string so a model that returned bare JSON (no fences, no prose) is
  /// handled by the same code path.
  static String _stripCodeFences(String text) {
    final RegExp fenced =
        RegExp(r'```(?:json)?\s*([\s\S]*?)```', caseSensitive: false);
    final RegExpMatch? match = fenced.firstMatch(text);
    if (match != null) return match.group(1)!.trim();
    return text.trim();
  }

  static List<BioDraftVariant> _parseVariantArray(String text) {
    // The model may include leading/trailing prose. Find the first '[' and
    // matching ']' and try that slice.
    final int start = text.indexOf('[');
    final int end = text.lastIndexOf(']');
    final String slice = (start >= 0 && end > start)
        ? text.substring(start, end + 1)
        : text;

    final Object? decoded;
    try {
      decoded = jsonDecode(slice);
    } on FormatException {
      return const <BioDraftVariant>[];
    }
    if (decoded is! List) return const <BioDraftVariant>[];

    final List<BioDraftVariant> out = <BioDraftVariant>[];
    for (final Object? item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final Object? headline = item['headline'];
      final Object? bio = item['bio'];
      if (headline is! String || bio is! String) continue;
      final String h = headline.trim();
      final String b = bio.trim();
      if (h.isEmpty || b.isEmpty) continue;
      out.add(BioDraftVariant(headline: h, bio: b));
    }
    return out;
  }

  static String _buildPrompt({
    required String roleLabel,
    required String goalText,
    String? goalLabel,
  }) {
    final StringBuffer ctx = StringBuffer();
    if (roleLabel.isNotEmpty) ctx.writeln('Role: $roleLabel');
    if (goalLabel != null && goalLabel.isNotEmpty) {
      ctx.writeln('Goal type: $goalLabel');
    }
    if (goalText.isNotEmpty) ctx.writeln('Goal description: $goalText');
    final String contextBlock = ctx.toString().trim();

    return '''
You are helping a user write their professional profile on a networking app.

Context about the user:
${contextBlock.isEmpty ? '(no details provided)' : contextBlock}

Write exactly 3 distinct profile variants. Vary the tone:
1. Concise and direct (one-line headline, factual bio).
2. Warm and personable (friendly tone).
3. Specific and outcome-focused (highlights what the user is looking for).

Constraints:
- "headline" must be 5-80 characters.
- "bio" must be 10-240 characters.
- Write in first person where natural.
- Do not invent details that contradict the context.

Respond with ONLY a JSON array, no prose, no code fences:
[
  {"headline": "...", "bio": "..."},
  {"headline": "...", "bio": "..."},
  {"headline": "...", "bio": "..."}
]
''';
  }
}

class BioDraftException implements Exception {
  BioDraftException(this.message);
  final String message;
  @override
  String toString() => 'BioDraftException($message)';
}
