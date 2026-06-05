import 'dart:ui' show PointerDeviceKind;

import 'package:flow_read/models/reader_font.dart';
import 'package:flow_read/providers/reading/reading_provider_riverpod.dart'
    as riverpod_reading;
import 'package:flow_read/providers/reading_provider.dart';
import 'package:flow_read/widgets/font_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('font settings sheet exposes and selects Literata', (
    tester,
  ) async {
    final provider = _FakeReadingProvider();

    await tester.pumpWidget(
      _withReadingProvider(
        provider,
        const MaterialApp(home: Scaffold(body: FontSettingsSheet())),
      ),
    );

    const literataTile = ValueKey('font-family-option-Literata');
    expect(find.text('阅读设置'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reading-settings-preview')),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(literataTile),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(literataTile));
    await tester.pumpAndSettle();

    expect(provider.fontFamily, ReaderFonts.literata);
    expect(
      find.descendant(
        of: find.byKey(literataTile),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });

  testWidgets('desktop dropdown relies on the reader and omits preview card', (
    tester,
  ) async {
    final provider = _FakeReadingProvider();

    await tester.pumpWidget(
      _withReadingProvider(
        provider,
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: FontSettingsDropdownPanel(width: 720, maxHeight: 640),
            ),
          ),
        ),
      ),
    );

    expect(find.text('阅读设置'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reading-settings-preview')),
      findsNothing,
    );
  });

  testWidgets(
    'selected specific font label does not show a dropdown affordance',
    (
      tester,
    ) async {
      final provider = _FakeReadingProvider();

      await tester.pumpWidget(
        _withReadingProvider(
          provider,
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: FontSettingsDropdownPanel(width: 720, maxHeight: 640),
              ),
            ),
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('具体字体'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Serif'), findsWidgets);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    },
  );

  testWidgets('desktop dropdown uses a compact default height', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final provider = _FakeReadingProvider();

    await tester.pumpWidget(
      _withReadingProvider(
        provider,
        const MaterialApp(
          home: Scaffold(
            body: Center(child: FontSettingsDropdownPanel(width: 720)),
          ),
        ),
      ),
    );

    expect(
      tester
          .getSize(find.byKey(const ValueKey('font-settings-dropdown-panel')))
          .height,
      600,
    );
  });

  testWidgets('setting option cards expose hover feedback', (tester) async {
    final provider = _FakeReadingProvider();

    await tester.pumpWidget(
      _withReadingProvider(
        provider,
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: FontSettingsDropdownPanel(width: 720, maxHeight: 640),
            ),
          ),
        ),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);

    for (final key in [
      const ValueKey('font-category-sans'),
      const ValueKey('font-family-option-Literata'),
      const ValueKey('reading-theme-dark'),
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(key),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final beforeHover = _cardDecoration(tester, key);
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump(const Duration(milliseconds: 160));

      final afterHover = _cardDecoration(tester, key);
      expect(afterHover.color, isNot(beforeHover.color));
      expect(afterHover.border, isNot(beforeHover.border));

      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 160));
    }

    await mouse.removePointer();
  });

  testWidgets('theme hover target is limited to the preview card', (
    tester,
  ) async {
    final provider = _FakeReadingProvider();

    await tester.pumpWidget(
      _withReadingProvider(
        provider,
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: FontSettingsDropdownPanel(width: 720, maxHeight: 640),
            ),
          ),
        ),
      ),
    );

    const darkThemeKey = ValueKey('reading-theme-dark');
    await tester.scrollUntilVisible(
      find.byKey(darkThemeKey),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final darkThemeTarget = find.byKey(darkThemeKey);
    expect(tester.getSize(darkThemeTarget).height, 86);
    expect(
      tester.getTopLeft(find.text('深色')).dy,
      greaterThan(tester.getBottomLeft(darkThemeTarget).dy),
    );
  });
}

Widget _withReadingProvider(ReadingProvider provider, Widget child) {
  return riverpod.ProviderScope(
    overrides: [
      riverpod_reading.readingProvider.overrideWith((ref) => provider),
    ],
    child: child,
  );
}

BoxDecoration _cardDecoration(WidgetTester tester, Key key) {
  final container = find
      .descendant(of: find.byKey(key), matching: find.byType(AnimatedContainer))
      .first;
  return tester.widget<AnimatedContainer>(container).decoration!
      as BoxDecoration;
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
