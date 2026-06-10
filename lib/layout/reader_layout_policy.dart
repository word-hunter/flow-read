import 'app_platform_class.dart';
import 'reader_layout_spec.dart';
import 'width_class_policy.dart';

enum ReaderActionPanelHost { workspaceRightPanel, wideSidebar, bottomSheet }

class ReaderActionPanelPolicy {
  const ReaderActionPanelPolicy._();

  static ReaderActionPanelHost resolve({
    required ReaderLayoutSpec layoutSpec,
    required bool isWideScreen,
  }) {
    if (layoutSpec.isWorkspace) {
      return ReaderActionPanelHost.workspaceRightPanel;
    }
    if (isWideScreen) {
      return ReaderActionPanelHost.wideSidebar;
    }
    return ReaderActionPanelHost.bottomSheet;
  }
}

class ReaderLayoutPolicy {
  const ReaderLayoutPolicy._();

  static ReaderLayoutSpec resolveLayout({
    required AppPlatformClass platform,
    required double width,
    required bool workspaceFeatureEnabled,
    required bool userRequestedImmersive,
    bool restoreLeftPanelOpen = true,
  }) {
    final widthClass = WidthClass.resolve(width);

    if (platform != AppPlatformClass.desktop) {
      return ReaderLayoutSpec.immersive(
        tocHost: TocPanelHost.sheet,
        assistantHost: AssistantPanelHost.bottomSheet,
      );
    }

    if (userRequestedImmersive || !workspaceFeatureEnabled) {
      return ReaderLayoutSpec.immersive(
        tocHost: TocPanelHost.sheet,
        assistantHost: AssistantPanelHost.bottomSheet,
      );
    }

    if (widthClass == WidthClass.compact) {
      return ReaderLayoutSpec.immersive(
        tocHost: TocPanelHost.sheet,
        assistantHost: AssistantPanelHost.bottomSheet,
      );
    }

    if (widthClass == WidthClass.medium) {
      return ReaderLayoutSpec.immersive(
        tocHost: TocPanelHost.drawer,
        assistantHost: AssistantPanelHost.floatingPanel,
      );
    }

    return ReaderLayoutSpec.desktopWorkspace(
      leftPanelOpen: restoreLeftPanelOpen,
    );
  }
}
