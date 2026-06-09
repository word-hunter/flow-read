enum ReaderShellKind { desktopWorkspace, immersive }

enum AssistantPanelHost { rightSidebar, bottomSheet, floatingPanel }

enum TocPanelHost { leftWorkspace, drawer, popover, sheet }

class ReaderLayoutSpec {
  final ReaderShellKind shellKind;
  final TocPanelHost tocHost;
  final AssistantPanelHost assistantHost;
  final bool leftPanelOpenByDefault;

  const ReaderLayoutSpec({
    required this.shellKind,
    required this.tocHost,
    required this.assistantHost,
    this.leftPanelOpenByDefault = false,
  });

  bool get isWorkspace => shellKind == ReaderShellKind.desktopWorkspace;

  static ReaderLayoutSpec desktopWorkspace({
    bool leftPanelOpen = true,
  }) {
    return ReaderLayoutSpec(
      shellKind: ReaderShellKind.desktopWorkspace,
      tocHost: TocPanelHost.leftWorkspace,
      assistantHost: AssistantPanelHost.rightSidebar,
      leftPanelOpenByDefault: leftPanelOpen,
    );
  }

  static ReaderLayoutSpec immersive({
    TocPanelHost tocHost = TocPanelHost.sheet,
    AssistantPanelHost assistantHost = AssistantPanelHost.bottomSheet,
  }) {
    return ReaderLayoutSpec(
      shellKind: ReaderShellKind.immersive,
      tocHost: tocHost,
      assistantHost: assistantHost,
    );
  }
}
