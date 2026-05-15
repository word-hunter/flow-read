import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'book_shelf_item.dart';

class BookShelfRow extends StatelessWidget {
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

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final book = books[index];
          return BookShelfItem(
            title: book.title,
            coverBytes: book.coverBytes,
            progressPercent: book.progressPercent,
            onTap: book.onTap,
            onRemove: book.onRemove,
          );
        },
      ),
    );
  }
}

class BookShelfData {
  final String title;
  final Uint8List? coverBytes;
  final int progressPercent;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const BookShelfData({
    required this.title,
    this.coverBytes,
    required this.progressPercent,
    this.onTap,
    this.onRemove,
  });
}
