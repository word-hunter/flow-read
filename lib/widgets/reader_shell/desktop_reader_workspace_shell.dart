import 'package:flutter/material.dart';

import '../../theme/app_motion_tokens.dart';
import '../surfaces/app_surface.dart';
import 'reader_left_workspace_panel.dart';
import 'reader_panel_resizer.dart';
import 'reader_workspace_controller.dart';

class DesktopReaderWorkspaceShell extends StatelessWidget {
  final ReaderWorkspaceController workspaceController;
  final Widget toolbar;
  final Widget centerContent;
  final Widget rightPanel;
  final Widget? readingProgressLine;
  final Widget? readingReminder;
  final ValueChanged<int>? onGoToChapter;
  final bool reduceMotion;

  const DesktopReaderWorkspaceShell({
    super.key,
    required this.workspaceController,
    required this.toolbar,
    required this.centerContent,
    this.rightPanel = const SizedBox.shrink(),
    this.readingProgressLine,
    this.readingReminder,
    this.onGoToChapter,
    this.reduceMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    final openDuration = reduceMotion
        ? ReaderMotionTokens.reducedMotionDuration
        : ReaderMotionTokens.panelOpenDuration;
    final closeDuration = reduceMotion
        ? ReaderMotionTokens.reducedMotionDuration
        : ReaderMotionTokens.panelCloseDuration;

    return Column(
      children: [
        toolbar,
        ?readingProgressLine,
        ?readingReminder,
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: workspaceController.isLeftPanelOpen
                    ? openDuration
                    : closeDuration,
                curve: workspaceController.isLeftPanelOpen
                    ? ReaderMotionTokens.openCurve
                    : ReaderMotionTokens.closeCurve,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: workspaceController.isLeftPanelOpen
                      ? workspaceController.leftPanelWidth
                      : 0,
                  child: AppSurface(
                    role: AppSurfaceRole.leftWorkspace,
                    child: ReaderLeftWorkspacePanel(
                      workspaceController: workspaceController,
                      currentTab: workspaceController.leftTab,
                      onGoToChapter: onGoToChapter,
                    ),
                  ),
                ),
              ),
              if (workspaceController.isLeftPanelOpen)
                ReaderPanelResizer(
                  onResize: (globalX) {
                    final renderBox =
                        context.findRenderObject() as RenderBox?;
                    if (renderBox == null) return;
                    final localX = renderBox.globalToLocal(Offset(globalX, 0)).dx;
                    workspaceController.setLeftPanelWidth(localX);
                  },
                  minWidth: ReaderPanelWidths.leftPanelMin,
                  maxWidth: ReaderPanelWidths.leftPanelMax,
                ),
              Expanded(child: centerContent),
              if (workspaceController.isRightPanelOpen)
                ReaderPanelResizer(
                  onResize: (globalX) {
                    final renderBox =
                        context.findRenderObject() as RenderBox?;
                    if (renderBox == null) return;
                    final localX = renderBox.globalToLocal(Offset(globalX, 0)).dx;
                    final rightWidth =
                        renderBox.size.width - localX;
                    workspaceController.setRightPanelWidth(rightWidth);
                  },
                  minWidth: ReaderPanelWidths.rightPanelMin,
                  maxWidth: ReaderPanelWidths.rightPanelMax,
                ),
              AnimatedSize(
                duration: workspaceController.isRightPanelOpen
                    ? openDuration
                    : closeDuration,
                curve: workspaceController.isRightPanelOpen
                    ? ReaderMotionTokens.openCurve
                    : ReaderMotionTokens.closeCurve,
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: workspaceController.isRightPanelOpen
                      ? workspaceController.rightPanelWidth
                      : 0,
                  child: AppSurface(
                    role: AppSurfaceRole.rightAssistant,
                    child: rightPanel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
