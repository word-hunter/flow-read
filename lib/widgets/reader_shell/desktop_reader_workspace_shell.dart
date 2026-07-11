import 'package:flutter/material.dart';

import '../../theme/app_motion_tokens.dart';
import '../../theme/app_surface_tokens.dart';
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
  final Color? workspaceBackgroundColor;
  final Color? centerBackgroundColor;
  final Color? centerBorderColor;

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
    this.workspaceBackgroundColor,
    this.centerBackgroundColor,
    this.centerBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppSurfaceTokens.of(context);
    final animatePanels =
        workspaceController.animatePanelTransitions && !reduceMotion;
    final openDuration = animatePanels
        ? ReaderMotionTokens.panelOpenDuration
        : Duration.zero;
    final closeDuration = animatePanels
        ? ReaderMotionTokens.panelCloseDuration
        : Duration.zero;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: workspaceBackgroundColor ?? tokens.readerWorkspaceBackground,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                child: ClipRect(
                  child: _WorkspacePaneFrame(
                    child: AppSurface(
                      role: AppSurfaceRole.leftWorkspace,
                      child: ReaderLeftWorkspacePanel(
                        workspaceController: workspaceController,
                        onGoToChapter: onGoToChapter,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (workspaceController.isLeftPanelOpen)
              ReaderPanelResizer(
                onResize: (globalX) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;
                  final localX = renderBox.globalToLocal(Offset(globalX, 0)).dx;
                  workspaceController.setLeftPanelWidth(localX);
                },
                minWidth: ReaderPanelWidths.leftPanelMin,
                maxWidth: ReaderPanelWidths.leftPanelMax,
              ),
            Expanded(
              child: _WorkspaceCenterFrame(
                toolbar: toolbar,
                readingProgressLine: readingProgressLine,
                readingReminder: readingReminder,
                backgroundColor: centerBackgroundColor,
                borderColor: centerBorderColor,
                child: centerContent,
              ),
            ),
            if (workspaceController.isRightPanelOpen)
              ReaderPanelResizer(
                onResize: (globalX) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;
                  final localX = renderBox.globalToLocal(Offset(globalX, 0)).dx;
                  final rightWidth = renderBox.size.width - localX;
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
                child: ClipRect(
                  child: _WorkspacePaneFrame(
                    child: AppSurface(
                      role: AppSurfaceRole.rightAssistant,
                      child: rightPanel,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspacePaneFrame extends StatelessWidget {
  final Widget child;

  const _WorkspacePaneFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = AppSurfaceTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.panelBorderColor),
        boxShadow: [
          BoxShadow(
            color: tokens.panelShadowColor,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

class _WorkspaceCenterFrame extends StatelessWidget {
  final Widget toolbar;
  final Widget? readingProgressLine;
  final Widget? readingReminder;
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;

  const _WorkspaceCenterFrame({
    required this.toolbar,
    required this.readingProgressLine,
    required this.readingReminder,
    required this.child,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppSurfaceTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? tokens.readerOpaqueSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? tokens.readerPageBorderColor),
        boxShadow: [
          BoxShadow(
            color: tokens.panelShadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            toolbar,
            ?readingReminder,
            Expanded(child: child),
            ?readingProgressLine,
          ],
        ),
      ),
    );
  }
}
