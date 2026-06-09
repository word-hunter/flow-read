import 'dart:math' as math;

import 'prompt_builder.dart';

class PassageAnalysisRequest {
  final String selectedText;
  final String currentPassage;
  final SourceLanguage sourceLanguage;
  final SpoilerBoundary spoilerBoundary;

  const PassageAnalysisRequest({
    required this.selectedText,
    required this.currentPassage,
    required this.sourceLanguage,
    required this.spoilerBoundary,
  });
}

class PassageRequestBuilder {
  static const defaultContextRadius = 320;

  final int contextRadius;

  const PassageRequestBuilder({this.contextRadius = defaultContextRadius});

  PassageAnalysisRequest buildSelectedTextAnalysis({
    required String selectedText,
    required String sourceText,
    SpoilerBoundary? spoilerBoundary,
  }) {
    final normalizedSelection = selectedText.trim();
    final currentPassage = _currentPassageForSelection(
      sourceText,
      normalizedSelection,
    );
    final languageSource = currentPassage.isNotEmpty
        ? currentPassage
        : normalizedSelection;

    return PassageAnalysisRequest(
      selectedText: normalizedSelection,
      currentPassage: currentPassage.isNotEmpty
          ? currentPassage
          : normalizedSelection,
      sourceLanguage: SourceLanguage.inferFromText(languageSource),
      spoilerBoundary: spoilerBoundary ?? SpoilerBoundary.currentPassage(),
    );
  }

  String _currentPassageForSelection(String sourceText, String selectedText) {
    final source = sourceText.trim();
    if (selectedText.isEmpty || source.isEmpty) return selectedText;

    final match = _findSelection(source, selectedText);
    if (match == null) return selectedText;

    final block = _blockContaining(source, match.start, match.end);
    final start = math.max(block.start, match.start - contextRadius);
    final end = math.min(block.end, match.end + contextRadius);
    return source.substring(start, end).trim();
  }

  _TextRange? _findSelection(String source, String selectedText) {
    final directIndex = source.indexOf(selectedText);
    if (directIndex >= 0) {
      return _TextRange(directIndex, directIndex + selectedText.length);
    }

    final normalizedSource = _normalizeForSearch(source);
    final normalizedSelection = _normalizeForSearch(selectedText);
    if (normalizedSelection.text.isEmpty) return null;

    final normalizedIndex = normalizedSource.text.indexOf(
      normalizedSelection.text,
    );
    if (normalizedIndex < 0) return null;

    final start = normalizedSource.offsets[normalizedIndex];
    final endIndex = normalizedIndex + normalizedSelection.text.length - 1;
    final end = normalizedSource.offsets[endIndex] + 1;
    return _TextRange(start, end);
  }

  _TextRange _blockContaining(
    String source,
    int selectionStart,
    int selectionEnd,
  ) {
    final separator = RegExp(r'\n\s*\n');
    var blockStart = 0;
    int? passageStart;
    int? passageEnd;

    for (final match in separator.allMatches(source)) {
      final blockEnd = match.start;
      if (_overlaps(blockStart, blockEnd, selectionStart, selectionEnd)) {
        passageStart ??= blockStart;
        passageEnd = blockEnd;
      }
      blockStart = match.end;
    }

    if (_overlaps(blockStart, source.length, selectionStart, selectionEnd)) {
      passageStart ??= blockStart;
      passageEnd = source.length;
    }

    if (passageStart == null || passageEnd == null) {
      return _trimRange(source, 0, source.length);
    }
    return _trimRange(source, passageStart, passageEnd);
  }

  bool _overlaps(int start, int end, int selectionStart, int selectionEnd) {
    return selectionStart < end && selectionEnd > start;
  }

  _TextRange _trimRange(String source, int start, int end) {
    var trimmedStart = start;
    var trimmedEnd = end;
    while (trimmedStart < trimmedEnd && _isWhitespace(source[trimmedStart])) {
      trimmedStart += 1;
    }
    while (trimmedEnd > trimmedStart && _isWhitespace(source[trimmedEnd - 1])) {
      trimmedEnd -= 1;
    }
    return _TextRange(trimmedStart, trimmedEnd);
  }

  _NormalizedText _normalizeForSearch(String value) {
    final buffer = StringBuffer();
    final offsets = <int>[];
    var pendingSpace = false;

    for (var i = 0; i < value.length; i += 1) {
      final char = value[i];
      if (_isWhitespace(char)) {
        pendingSpace = buffer.isNotEmpty;
        continue;
      }
      if (pendingSpace) {
        buffer.write(' ');
        offsets.add(i);
        pendingSpace = false;
      }
      buffer.write(char);
      offsets.add(i);
    }

    return _NormalizedText(buffer.toString(), offsets);
  }

  bool _isWhitespace(String char) => char.trim().isEmpty;
}

class _TextRange {
  final int start;
  final int end;

  const _TextRange(this.start, this.end);
}

class _NormalizedText {
  final String text;
  final List<int> offsets;

  const _NormalizedText(this.text, this.offsets);
}
