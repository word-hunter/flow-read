class ReaderWorkspaceSettings {
  final bool desktopLeftPanelOpen;
  final String desktopLeftPanelTab;
  final double desktopLeftPanelWidth;
  final bool desktopRightPanelPinned;
  final String desktopRightPanelTab;
  final double desktopRightPanelWidth;
  final bool desktopImmersivePreferred;
  final bool reduceReaderMotion;

  const ReaderWorkspaceSettings({
    required this.desktopLeftPanelOpen,
    required this.desktopLeftPanelTab,
    required this.desktopLeftPanelWidth,
    required this.desktopRightPanelPinned,
    required this.desktopRightPanelTab,
    required this.desktopRightPanelWidth,
    required this.desktopImmersivePreferred,
    required this.reduceReaderMotion,
  });

  factory ReaderWorkspaceSettings.defaults() => const ReaderWorkspaceSettings(
        desktopLeftPanelOpen: true,
        desktopLeftPanelTab: 'toc',
        desktopLeftPanelWidth: 288,
        desktopRightPanelPinned: false,
        desktopRightPanelTab: 'dictionary',
        desktopRightPanelWidth: 360,
        desktopImmersivePreferred: false,
        reduceReaderMotion: false,
      );
}
