class ReadingToken {
  const ReadingToken({
    required this.surface,
    required this.canonical,
    required this.languageId,
    required this.startOffset,
    required this.endOffset,
    this.reading,
    this.partOfSpeech,
    this.isStudyTarget = false,
    this.isBoundary = false,
  }) : assert(startOffset <= endOffset);

  final String surface;
  final String canonical;
  final String languageId;
  final int startOffset;
  final int endOffset;
  final String? reading;
  final String? partOfSpeech;
  final bool isStudyTarget;
  final bool isBoundary;

  bool containsOffset(int offset) {
    return offset >= startOffset && offset < endOffset;
  }

  bool overlapsRange(int start, int end) {
    return endOffset > start && startOffset < end;
  }
}

class TokenizedText {
  const TokenizedText({
    required this.originalText,
    required this.languageId,
    required this.tokens,
    required this.createdAt,
  });

  final String originalText;
  final String languageId;
  final List<ReadingToken> tokens;
  final DateTime createdAt;

  ReadingToken? tokenAt(int offset) {
    if (offset < 0 || offset >= originalText.length) return null;
    for (final token in tokens) {
      if (token.containsOffset(offset)) return token;
    }
    return null;
  }

  List<ReadingToken> tokensInRange(int start, int end) {
    if (end <= start) return const [];
    return tokens
        .where((token) => token.overlapsRange(start, end))
        .toList(growable: false);
  }
}
