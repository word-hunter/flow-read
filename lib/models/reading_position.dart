class ReadingPositionAnchor {
  final int chapterIndex;
  final int blockIndex;
  final int textOffset;

  const ReadingPositionAnchor({
    required this.chapterIndex,
    required this.blockIndex,
    this.textOffset = 0,
  });

  static const zero = ReadingPositionAnchor(
    chapterIndex: 0,
    blockIndex: 0,
  );

  ReadingPositionAnchor copyWith({
    int? chapterIndex,
    int? blockIndex,
    int? textOffset,
  }) {
    return ReadingPositionAnchor(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      blockIndex: blockIndex ?? this.blockIndex,
      textOffset: textOffset ?? this.textOffset,
    );
  }

  bool isAtOrBefore(ReadingPositionAnchor other) {
    if (chapterIndex < other.chapterIndex) return true;
    if (chapterIndex > other.chapterIndex) return false;
    if (blockIndex < other.blockIndex) return true;
    if (blockIndex > other.blockIndex) return false;
    return textOffset <= other.textOffset;
  }

  @override
  bool operator ==(Object other) {
    return other is ReadingPositionAnchor &&
        other.chapterIndex == chapterIndex &&
        other.blockIndex == blockIndex &&
        other.textOffset == textOffset;
  }

  @override
  int get hashCode => Object.hash(chapterIndex, blockIndex, textOffset);

  @override
  String toString() =>
      'Anchor(ch=$chapterIndex, b=$blockIndex, t=$textOffset)';
}

class PageBlockRange {
  final int startBlockIndex;
  final int endBlockIndex;
  final int startTextOffset;
  final int endTextOffset;

  const PageBlockRange({
    required this.startBlockIndex,
    required this.endBlockIndex,
    this.startTextOffset = 0,
    this.endTextOffset = 0,
  });

  @override
  String toString() =>
      'PageBlockRange(b=$startBlockIndex-$endBlockIndex, t=$startTextOffset-$endTextOffset)';
}

class PageSlice {
  final int pageIndex;
  final PageBlockRange blockRange;
  final List<int> imageBlockIndices;

  const PageSlice({
    required this.pageIndex,
    required this.blockRange,
    this.imageBlockIndices = const [],
  });

  bool get isEmpty => blockRange.startBlockIndex == blockRange.endBlockIndex &&
      blockRange.startTextOffset == blockRange.endTextOffset &&
      imageBlockIndices.isEmpty;

  @override
  String toString() =>
      'PageSlice(#$pageIndex, $blockRange, img=${imageBlockIndices.length})';
}

enum PageLayoutMode { scroll, paged }

class PageLayoutConfig {
  final double fontSize;
  final String fontFamily;
  final double lineHeight;
  final double viewportWidth;
  final double viewportHeight;
  final double horizontalPadding;
  final PageLayoutMode mode;

  const PageLayoutConfig({
    required this.fontSize,
    required this.fontFamily,
    required this.lineHeight,
    required this.viewportWidth,
    required this.viewportHeight,
    this.horizontalPadding = 18.0,
    this.mode = PageLayoutMode.scroll,
  });

  double get contentWidth =>
      (viewportWidth - horizontalPadding * 2).clamp(0, double.infinity);

  PageLayoutConfig copyWith({
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    double? viewportWidth,
    double? viewportHeight,
    double? horizontalPadding,
    PageLayoutMode? mode,
  }) {
    return PageLayoutConfig(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
      viewportWidth: viewportWidth ?? this.viewportWidth,
      viewportHeight: viewportHeight ?? this.viewportHeight,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      mode: mode ?? this.mode,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PageLayoutConfig &&
        other.fontSize == fontSize &&
        other.fontFamily == fontFamily &&
        other.lineHeight == lineHeight &&
        other.viewportWidth == viewportWidth &&
        other.viewportHeight == viewportHeight &&
        other.horizontalPadding == horizontalPadding &&
        other.mode == mode;
  }

  @override
  int get hashCode => Object.hash(
    fontSize,
    fontFamily,
    lineHeight,
    viewportWidth,
    viewportHeight,
    horizontalPadding,
    mode,
  );

  @override
  String toString() =>
      'PageLayoutConfig(fs=$fontSize, w=$viewportWidth, h=$viewportHeight, mode=$mode)';
}

class PageLayoutCacheKey {
  final String chapterSignature;
  final PageLayoutConfig config;
  final int hash;

  PageLayoutCacheKey({
    required this.chapterSignature,
    required this.config,
  }) : hash = Object.hash(chapterSignature, config);

  @override
  bool operator ==(Object other) {
    return other is PageLayoutCacheKey && other.hash == hash;
  }

  @override
  int get hashCode => hash;

  @override
  String toString() => 'CacheKey(ch=$chapterSignature, cfg=$config)';
}
