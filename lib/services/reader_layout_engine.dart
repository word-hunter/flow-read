import 'dart:math';

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/content_block.dart';
import '../models/reading_position.dart';

class ReaderLayoutEngine {
  const ReaderLayoutEngine();

  ReadingPositionAnchor anchorFor(
    List<ContentBlock> blocks,
    double scrollOffset,
    double scrollExtent, {
    int chapterIndex = 0,
  }) {
    if (blocks.isEmpty) {
      return ReadingPositionAnchor(chapterIndex: chapterIndex, blockIndex: 0);
    }
    if (scrollOffset <= 0 || scrollExtent <= 0) {
      return ReadingPositionAnchor(
        chapterIndex: chapterIndex,
        blockIndex: 0,
      );
    }
    final ratio = (scrollOffset / scrollExtent).clamp(0.0, 1.0);
    final totalBlocks = blocks.length;
    final blockIndex = min(
      (ratio * totalBlocks).floor(),
      totalBlocks - 1,
    );
    final blockRatioInSegment = (ratio * totalBlocks) - blockIndex;

    return ReadingPositionAnchor(
      chapterIndex: chapterIndex,
      blockIndex: blockIndex,
      textOffset: (blockRatioInSegment * _blockTextLength(blocks[blockIndex]))
          .round(),
    );
  }

  double estimatedScrollOffset(
    List<ContentBlock> blocks,
    double scrollExtent,
    ReadingPositionAnchor anchor,
  ) {
    if (blocks.isEmpty || scrollExtent <= 0) return 0;
    final safeBlockIndex = anchor.blockIndex.clamp(0, blocks.length - 1);
    final totalBlocks = blocks.length;
    final blockRatio = safeBlockIndex / totalBlocks;
    final withinBlockRatio =
        _computeWithinBlockRatio(blocks, safeBlockIndex, anchor.textOffset);
    return (blockRatio + withinBlockRatio) * scrollExtent;
  }

  double _computeWithinBlockRatio(
    List<ContentBlock> blocks,
    int blockIndex,
    int textOffset,
  ) {
    final totalBlocks = blocks.length;
    final blockLength = _blockTextLength(blocks[blockIndex]);
    if (blockLength == 0) return 0;
    return (textOffset / blockLength) / totalBlocks;
  }

  int _blockTextLength(ContentBlock block) {
    return switch (block) {
      TextBlock tb => tb.plainText.length,
      ImageBlock() => 1,
    };
  }

  ReadingPositionAnchor? blockAnchorForContentKey(
    Map<int, GlobalKey> contentKeys,
    BuildContext context, {
    int chapterIndex = 0,
  }) {
    for (final entry in contentKeys.entries) {
      final renderBox =
          entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final offset = renderBox.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
        if (offset.dy >= -renderBox.size.height && offset.dy <= 800) {
          return ReadingPositionAnchor(
            chapterIndex: chapterIndex,
            blockIndex: entry.key,
          );
        }
      }
    }
    return null;
  }

  ReadingPositionAnchor captureAnchor(
    Book book, {
    int chapterIndex = 0,
    double? scrollOffset,
    double? scrollExtent,
  }) {
    final chapters = book.chapters;
    final safeChapter = chapterIndex.clamp(0, chapters.length - 1);
    final blocks = chapters[safeChapter].blocks;
    if (scrollOffset != null && scrollExtent != null && scrollExtent > 0) {
      return anchorFor(blocks, scrollOffset, scrollExtent,
          chapterIndex: safeChapter);
    }
    return ReadingPositionAnchor(chapterIndex: safeChapter, blockIndex: 0);
  }

  double restoreScrollOffset(
    Book book,
    ReadingPositionAnchor anchor,
    double scrollExtent, {
    int? currentChapter,
  }) {
    final chapters = book.chapters;
    final chapterIndex = currentChapter ?? anchor.chapterIndex;
    final safeChapter = chapterIndex.clamp(0, chapters.length - 1);
    final blocks = chapters[safeChapter].blocks;
    return estimatedScrollOffset(blocks, scrollExtent, anchor);
  }
}
