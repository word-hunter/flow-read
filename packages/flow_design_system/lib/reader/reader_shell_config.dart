import '../shells/shell.dart';
import 'reader_layout.dart';

class ReaderShellConfig {
  final ReaderLayoutConfig layout;
  final bool prefersGlassSurface;
  final bool showScrollbar;
  final double fontSizeStep;
  final double lineHeightStep;

  const ReaderShellConfig({
    required this.layout,
    required this.prefersGlassSurface,
    required this.showScrollbar,
    required this.fontSizeStep,
    required this.lineHeightStep,
  });

  static ReaderShellConfig forShell(ShellId shellId, {required double screenWidth}) {
    final layout = ReaderLayoutConfig.resolve(
      shellId: shellId,
      screenWidth: screenWidth,
    );

    return switch (shellId) {
      ShellId.macosLiquidGlass => ReaderShellConfig(
        layout: layout,
        prefersGlassSurface: true,
        showScrollbar: false,
        fontSizeStep: 1.0,
        lineHeightStep: 0.1,
      ),
      ShellId.macosStandard => ReaderShellConfig(
        layout: layout,
        prefersGlassSurface: false,
        showScrollbar: false,
        fontSizeStep: 1.0,
        lineHeightStep: 0.1,
      ),
      ShellId.windows => ReaderShellConfig(
        layout: layout,
        prefersGlassSurface: false,
        showScrollbar: true,
        fontSizeStep: 2.0,
        lineHeightStep: 0.15,
      ),
      ShellId.ios => ReaderShellConfig(
        layout: layout,
        prefersGlassSurface: false,
        showScrollbar: false,
        fontSizeStep: 1.0,
        lineHeightStep: 0.1,
      ),
      ShellId.android => ReaderShellConfig(
        layout: layout,
        prefersGlassSurface: false,
        showScrollbar: true,
        fontSizeStep: 2.0,
        lineHeightStep: 0.2,
      ),
    };
  }
}
