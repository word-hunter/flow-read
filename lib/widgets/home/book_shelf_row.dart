import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'book_shelf_item.dart';

class BookShelfRow extends StatelessWidget {
  final List<BookShelfData> books;
  final VoidCallback? onAddBook;
  final String emptyText;

  const BookShelfRow({
    super.key,
    required this.books,
    this.onAddBook,
    this.emptyText = '暂无书籍',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: books.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              if (index == books.length) {
                return _buildAddCard(theme);
              }
              final book = books[index];
              return BookShelfItem(
                title: book.title,
                coverBytes: book.coverBytes,
                progressPercent: book.progressPercent,
                onTap: book.onTap,
              );
            },
          ),
        ),
        // Wooden shelf
        Container(
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF4A3520),
                      const Color(0xFF5C4430),
                      const Color(0xFF4A3520),
                    ]
                  : [
                      const Color(0xFF8B6914),
                      const Color(0xFFA0784C),
                      const Color(0xFF8B6914),
                    ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                offset: const Offset(0, 4),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddCard(ThemeData theme) {
    return GestureDetector(
      onTap: onAddBook,
      child: SizedBox(
        width: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    size: 32,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '添加书籍',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookShelfData {
  final String title;
  final Uint8List? coverBytes;
  final int progressPercent;
  final VoidCallback? onTap;

  const BookShelfData({
    required this.title,
    this.coverBytes,
    required this.progressPercent,
    this.onTap,
  });
}
