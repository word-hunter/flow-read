import '../shells/shell.dart';

enum ReaderLayoutMode {
  /// Desktop workspace: sidebar (collapsible) + content + toolbar
  workspace,

  /// Full-screen immersive reading, minimal chrome
  immersive,

  /// Mobile/compact: full-width content, minimal chrome
  compact,
}

class ReaderLayoutConfig {
  final ReaderLayoutMode mode;
  final double sidebarWidth;
  final double sidebarCollapsedWidth;
  final double contentMaxWidth;
  final double toolbarHeight;
  final bool sidebarVisibleByDefault;
  final bool toolbarVisible;
  final bool showChapterNav;

  const ReaderLayoutConfig({
    required this.mode,
    required this.sidebarWidth,
    required this.sidebarCollapsedWidth,
    required this.contentMaxWidth,
    required this.toolbarHeight,
    required this.sidebarVisibleByDefault,
    required this.toolbarVisible,
    required this.showChapterNav,
  });

  /// Returns the recommended reader layout for the given shell and screen
  /// width. Desktop shells with wide screens get workspace layout, narrow
  /// screens or mobile shells get compact layout.
  static ReaderLayoutConfig resolve({
    required ShellId shellId,
    required double screenWidth,
  }) {
    final isDesktop = _isDesktopShell(shellId);
    final isWide = screenWidth >= 900;

    if (isDesktop && isWide) {
      return _workspaceConfig(shellId);
    }
    if (isDesktop) {
      return _compactConfig(shellId);
    }
    return _compactConfig(shellId);
  }

  static ReaderLayoutConfig immersive() {
    return const ReaderLayoutConfig(
      mode: ReaderLayoutMode.immersive,
      sidebarWidth: 0,
      sidebarCollapsedWidth: 0,
      contentMaxWidth: 860,
      toolbarHeight: 0,
      sidebarVisibleByDefault: false,
      toolbarVisible: false,
      showChapterNav: false,
    );
  }

  static bool _isDesktopShell(ShellId id) {
    return switch (id) {
      ShellId.macosStandard || ShellId.macosLiquidGlass || ShellId.windows =>
        true,
      _ => false,
    };
  }

  static ReaderLayoutConfig _workspaceConfig(ShellId id) {
    return switch (id) {
      ShellId.macosStandard || ShellId.macosLiquidGlass => ReaderLayoutConfig(
        mode: ReaderLayoutMode.workspace,
        sidebarWidth: 240,
        sidebarCollapsedWidth: 68,
        contentMaxWidth: 820,
        toolbarHeight: 38,
        sidebarVisibleByDefault: true,
        toolbarVisible: true,
        showChapterNav: true,
      ),
      ShellId.windows => const ReaderLayoutConfig(
        mode: ReaderLayoutMode.workspace,
        sidebarWidth: 256,
        sidebarCollapsedWidth: 48,
        contentMaxWidth: 860,
        toolbarHeight: 40,
        sidebarVisibleByDefault: true,
        toolbarVisible: true,
        showChapterNav: true,
      ),
      _ => const ReaderLayoutConfig(
        mode: ReaderLayoutMode.workspace,
        sidebarWidth: 260,
        sidebarCollapsedWidth: 72,
        contentMaxWidth: 920,
        toolbarHeight: 56,
        sidebarVisibleByDefault: true,
        toolbarVisible: true,
        showChapterNav: true,
      ),
    };
  }

  static ReaderLayoutConfig _compactConfig(ShellId id) {
    return switch (id) {
      ShellId.ios => const ReaderLayoutConfig(
        mode: ReaderLayoutMode.compact,
        sidebarWidth: 0,
        sidebarCollapsedWidth: 0,
        contentMaxWidth: 720,
        toolbarHeight: 44,
        sidebarVisibleByDefault: false,
        toolbarVisible: true,
        showChapterNav: false,
      ),
      _ => const ReaderLayoutConfig(
        mode: ReaderLayoutMode.compact,
        sidebarWidth: 0,
        sidebarCollapsedWidth: 0,
        contentMaxWidth: 800,
        toolbarHeight: 56,
        sidebarVisibleByDefault: false,
        toolbarVisible: true,
        showChapterNav: false,
      ),
    };
  }
}
