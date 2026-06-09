import 'package:flutter/material.dart';

import 'reader_left_workspace_panel.dart';
import 'reader_workspace_controller.dart';

class DesktopReaderWorkspaceShell extends StatelessWidget {
  final ReaderWorkspaceController workspaceController;
  final Widget toolbar;
  final Widget centerContent;
  final Widget rightPanel;
  final Widget? readingProgressLine;
  final Widget? readingReminder;
  final ValueChanged<int>? onGoToChapter;

  const DesktopReaderWorkspaceShell({
    super.key,
    required this.workspaceController,
    required this.toolbar,
    required this.centerContent,
    this.rightPanel = const SizedBox.shrink(),
    this.readingProgressLine,
    this.readingReminder,
    this.onGoToChapter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        toolbar,
        ?readingProgressLine,
        ?readingReminder,
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (workspaceController.isLeftPanelOpen)
                SizedBox(
                  width: workspaceController.leftPanelWidth,
                  child: ReaderLeftWorkspacePanel(
                    workspaceController: workspaceController,
                    currentTab: workspaceController.leftTab,
                    onGoToChapter: onGoToChapter,
                  ),
                ),
              Expanded(child: centerContent),
              if (workspaceController.isRightPanelOpen)
                SizedBox(
                  width: workspaceController.rightPanelWidth,
                  child: rightPanel,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
