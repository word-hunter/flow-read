import 'package:flow_read/theme/app_surface_tokens.dart';
import 'package:flow_read/theme/city_theme_tokens.dart';
import 'package:flow_read/widgets/reader_shell/reader_right_assistant_panel.dart';
import 'package:flow_read/widgets/reader_shell/reader_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('syncs child theme colors with the assistant surface', (
    tester,
  ) async {
    const probeKey = Key('assistant-theme-probe');
    final controller = ReaderWorkspaceController(
      rightPanelOpen: true,
      rightTab: ReaderRightPanelTab.dictionary,
    );
    addTearDown(controller.dispose);
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0277FE),
      brightness: Brightness.dark,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: darkScheme,
          extensions: [
            AppSurfaceTokens.cityLight(),
            CityThemeTokens.sunny,
          ],
        ),
        home: Scaffold(
          body: ReaderRightAssistantPanel(
            workspaceController: controller,
            dictionaryContent: Builder(
              builder: (context) {
                final scheme = Theme.of(context).colorScheme;
                return Container(
                  key: probeKey,
                  color: scheme.surface,
                  child: Column(
                    children: [
                      Text(
                        'probe',
                        style: TextStyle(color: scheme.onSurface),
                      ),
                      Text(
                        'outline probe',
                        style: TextStyle(color: scheme.outline),
                      ),
                      Container(
                        key: const Key('assistant-low-surface-probe'),
                        color: scheme.surfaceContainerLow,
                        width: 1,
                        height: 1,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    final probe = tester.widget<Container>(find.byKey(probeKey));
    expect(probe.color, const Color(0xFFFCFEFF));

    final label = tester.widget<Text>(find.text('probe'));
    expect(label.style?.color, CityThemeTokens.sunny.textPrimary);

    final outlineLabel = tester.widget<Text>(find.text('outline probe'));
    expect(outlineLabel.style?.color, CityThemeTokens.sunny.textSecondary);

    final lowSurface = tester.widget<Container>(
      find.byKey(const Key('assistant-low-surface-probe')),
    );
    expect(lowSurface.color, const Color(0xFFF7FAFD));
  });
}
