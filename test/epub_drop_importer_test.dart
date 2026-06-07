import 'package:flow_read/providers/reading/bookshelf_notifier.dart';
import 'package:flow_read/widgets/epub_drop_importer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('imports dropped EPUB paths through the reading provider', (
    tester,
  ) async {
    final provider = _FakeBookshelfNotifier();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          bookshelfNotifierProvider.overrideWith(() => provider),
        ],
        child: const MaterialApp(
          home: EpubDropImporter(child: Scaffold(body: SizedBox.expand())),
        ),
      ),
    );

    await _sendDropMethod(tester, const MethodCall('dragEntered'));
    await tester.pump();
    expect(find.text('释放以导入 EPUB'), findsOneWidget);

    await _sendDropMethod(
      tester,
      const MethodCall('filesDropped', ['/tmp/notes.txt', '/tmp/book.epub']),
    );
    await tester.pump();

    expect(provider.importedPaths, ['/tmp/book.epub']);
    expect(find.text('EPUB 已导入'), findsOneWidget);
  });

  testWidgets('shows cancelled message for a cancelled dropped import', (
    tester,
  ) async {
    final provider = _FakeBookshelfNotifier(
      importResult: BookImportResult.cancelled,
    );

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          bookshelfNotifierProvider.overrideWith(() => provider),
        ],
        child: const MaterialApp(
          home: EpubDropImporter(child: Scaffold(body: SizedBox.expand())),
        ),
      ),
    );

    await _sendDropMethod(
      tester,
      const MethodCall('filesDropped', ['/tmp/book.epub']),
    );
    await tester.pump();

    expect(provider.importedPaths, ['/tmp/book.epub']);
    expect(find.text('已取消导入'), findsOneWidget);
    expect(find.text('EPUB 已导入'), findsNothing);
  });
}

Future<void> _sendDropMethod(WidgetTester tester, MethodCall call) {
  return tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flow_read/file_drop',
    const StandardMethodCodec().encodeMethodCall(call),
    (_) {},
  );
}

class _FakeBookshelfNotifier extends BookshelfNotifier {
  _FakeBookshelfNotifier({this.importResult = BookImportResult.imported});

  final BookImportResult importResult;
  final List<String> importedPaths = [];

  @override
  BookshelfState build() => const BookshelfState(
    isLoading: false,
    errorMessage: null,
    books: [],
  );

  @override
  Future<BookImportResult> importBook(String filePath) async {
    importedPaths.add(filePath);
    state = state.copyWith(lastImportResult: importResult);
    return importResult;
  }
}
