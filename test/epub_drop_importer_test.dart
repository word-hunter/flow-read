import 'package:flow_read/providers/reading/reading_provider_riverpod.dart'
    as riverpod_reading;
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/widgets/epub_drop_importer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('imports dropped EPUB paths through the reading provider', (
    tester,
  ) async {
    final provider = _FakeReadingProvider();

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          riverpod_reading.readingProvider.overrideWith((ref) => provider),
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
    final provider = _FakeReadingProvider(
      importResult: BookImportResult.cancelled,
    );

    await tester.pumpWidget(
      riverpod.ProviderScope(
        overrides: [
          riverpod_reading.readingProvider.overrideWith((ref) => provider),
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

class _FakeReadingProvider extends ReadingProvider {
  _FakeReadingProvider({this.importResult = BookImportResult.imported});

  final BookImportResult importResult;
  final List<String> importedPaths = [];

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<BookImportResult> importBook(String filePath) async {
    importedPaths.add(filePath);
    return importResult;
  }
}
