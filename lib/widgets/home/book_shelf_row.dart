import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/book_difficulty.dart';
import 'book_shelf_item.dart';

class BookShelfRow extends StatelessWidget {
  static const double _horizontalPadding = 24;
  static const double _itemSpacing = 20;
  static const double _rowSpacing = 24;

  final List<BookShelfData> books;
  final String emptyText;

  const BookShelfRow({super.key, required this.books, this.emptyText = '暂无书籍'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (books.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          height: 180,
          child: Center(
            child: Text(
              emptyText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Wrap(
        spacing: _itemSpacing,
        runSpacing: _rowSpacing,
        children: books.map(_buildItem).toList(growable: false),
      ),
    );
  }

  Widget _buildItem(BookShelfData book) {
    return BookShelfItem(
      title: book.title,
      author: book.author,
      coverBytes: book.coverBytes,
      progressPercent: book.progressPercent,
      difficulty: book.difficulty,
      isDifficultyLoading: book.isDifficultyLoading,
      forceDefaultCover: book.forceDefaultCover,
      onTap: book.onTap,
      onRename: book.onRename,
      onRemove: book.onRemove,
    );
  }
}

class BookShelfData {
  final String title;
  final String author;
  final Uint8List? coverBytes;
  final int progressPercent;
  final BookDifficultyRating? difficulty;
  final bool isDifficultyLoading;
  final bool forceDefaultCover;
  final VoidCallback? onTap;
  final VoidCallback? onRename;
  final VoidCallback? onRemove;

  const BookShelfData({
    required this.title,
    required this.author,
    this.coverBytes,
    required this.progressPercent,
    this.difficulty,
    this.isDifficultyLoading = false,
    this.forceDefaultCover = false,
    this.onTap,
    this.onRename,
    this.onRemove,
  });
}
