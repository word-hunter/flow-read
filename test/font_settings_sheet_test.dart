import 'package:flow_read/models/reader_font.dart';
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/widgets/font_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('font settings sheet exposes and selects Literata', (
    tester,
  ) async {
    final provider = _FakeReadingProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<ReadingProvider>.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: FontSettingsSheet())),
      ),
    );

    expect(find.text('Literata'), findsOneWidget);

    await tester.ensureVisible(find.text('Literata'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Literata'));
    await tester.pumpAndSettle();

    expect(provider.fontFamily, ReaderFonts.literata);
    expect(
      tester
          .widget<ChoiceChip>(
            find.ancestor(
              of: find.text('Literata'),
              matching: find.byType(ChoiceChip),
            ),
          )
          .selected,
      isTrue,
    );
  });
}

class _FakeReadingProvider extends ReadingProvider {
  double _fontSize = 16;
  double _lineHeight = 2;
  String _fontFamily = ReaderFonts.defaultFamily;
  String _readingTheme = 'light';

  @override
  double get fontSize => _fontSize;

  @override
  double get lineHeight => _lineHeight;

  @override
  String get fontFamily => _fontFamily;

  @override
  String get readingTheme => _readingTheme;

  @override
  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  @override
  void setFontFamily(String family) {
    _fontFamily = family;
    notifyListeners();
  }

  @override
  void setLineHeight(double height) {
    _lineHeight = height;
    notifyListeners();
  }

  @override
  void setReadingTheme(String theme) {
    _readingTheme = theme;
    notifyListeners();
  }
}
