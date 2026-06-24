import 'dart:convert';

class StructuredAIResponseParser {
  const StructuredAIResponseParser();

  Future<T> parseStructuredResponse<T>({
    required String rawResponse,
    required T Function(Map<String, dynamic>) parser,
    required Future<String> Function(String brokenJson) repairFn,
    required T fallback,
  }) async {
    for (final candidate in _localCandidates(rawResponse)) {
      final parsed = _tryParse(candidate, parser);
      if (parsed != null) return parsed;
    }

    try {
      final repaired = await repairFn(rawResponse);
      for (final candidate in _localCandidates(repaired)) {
        final parsed = _tryParse(candidate, parser);
        if (parsed != null) return parsed;
      }
    } catch (_) {
      // Keep the caller's fallback as the final safety net.
    }

    return fallback;
  }

  T? _tryParse<T>(
    String text,
    T Function(Map<String, dynamic>) parser,
  ) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return parser(decoded);
      }
      if (decoded is Map) {
        return parser(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  List<String> _localCandidates(String rawResponse) {
    final stripped = _stripMarkdownFence(rawResponse);
    final extracted = _extractJsonObject(stripped);
    final repaired = _basicJsonRepair(extracted ?? stripped);
    return [
      rawResponse.trim(),
      stripped,
      ?extracted,
      repaired,
    ].where((candidate) => candidate.trim().isNotEmpty).toSet().toList();
  }

  String _stripMarkdownFence(String text) {
    var content = text.trim();
    if (content.startsWith('```')) {
      final firstLineEnd = content.indexOf('\n');
      if (firstLineEnd >= 0) {
        content = content.substring(firstLineEnd + 1);
      } else {
        content = '';
      }
    }
    if (content.endsWith('```')) {
      content = content.substring(0, content.length - 3);
    }
    return content.trim();
  }

  String? _extractJsonObject(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    return text.substring(start, end + 1).trim();
  }

  String _basicJsonRepair(String text) {
    var repaired = text.trim();
    repaired = _removeTrailingCommas(repaired);
    repaired = repaired.replaceAll(RegExp(r',\s*$'), '');

    final openBraces = '{'.allMatches(repaired).length;
    final closeBraces = '}'.allMatches(repaired).length;
    final openBrackets = '['.allMatches(repaired).length;
    final closeBrackets = ']'.allMatches(repaired).length;

    if (openBrackets > closeBrackets) {
      repaired =
          '$repaired${List.filled(openBrackets - closeBrackets, ']').join()}';
    }
    if (openBraces > closeBraces) {
      repaired =
          '$repaired${List.filled(openBraces - closeBraces, '}').join()}';
    }
    repaired = _removeTrailingCommas(repaired);
    return repaired;
  }

  String _removeTrailingCommas(String text) {
    return text.replaceAllMapped(
      RegExp(r',\s*([}\]])'),
      (match) => match.group(1)!,
    );
  }
}
