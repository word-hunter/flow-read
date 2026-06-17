import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../providers/reading/bookshelf_notifier.dart';
import '../../services/epub_import_source.dart';

Future<void> importEpubFromPicker(
  BuildContext context,
  BookshelfNotifier notifier,
) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['epub'],
    withReadStream: true,
  );
  final file = result?.files.single;
  if (file == null || !context.mounted) return;

  final source = EpubImportSource.tryFromPlatformFile(file);
  if (source == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('无法读取 EPUB 文件')));
    return;
  }

  await notifier.importBookFromSource(source);
}
