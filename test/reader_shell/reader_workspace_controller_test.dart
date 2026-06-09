import 'package:flutter_test/flutter_test.dart';
import 'package:flow_read/widgets/reader_shell/reader_workspace_controller.dart';

void main() {
  group('ReaderWorkspaceController', () {
    late ReaderWorkspaceController controller;

    setUp(() {
      controller = ReaderWorkspaceController();
    });

    test('default state', () {
      expect(controller.isLeftPanelOpen, true);
      expect(controller.isRightPanelOpen, false);
      expect(controller.isRightPanelPinned, false);
      expect(controller.leftTab, ReaderLeftPanelTab.toc);
      expect(controller.rightTab, ReaderRightPanelTab.dictionary);
    });

    test('openToc when left is closed opens left and selects toc', () {
      controller.setLeftPanelOpen(false);
      expect(controller.isLeftPanelOpen, false);

      controller.openToc();
      expect(controller.isLeftPanelOpen, true);
      expect(controller.leftTab, ReaderLeftPanelTab.toc);
    });

    test('openToc when left is open just selects toc', () {
      controller.setLeftTab(ReaderLeftPanelTab.bookmarks);
      controller.openToc();
      expect(controller.isLeftPanelOpen, true);
      expect(controller.leftTab, ReaderLeftPanelTab.toc);
    });

    test('toggle left panel', () {
      controller.toggleLeftPanel();
      expect(controller.isLeftPanelOpen, false);

      controller.toggleLeftPanel();
      expect(controller.isLeftPanelOpen, true);
    });

    test('set left tab', () {
      controller.setLeftTab(ReaderLeftPanelTab.bookmarks);
      expect(controller.leftTab, ReaderLeftPanelTab.bookmarks);
    });

    test('set left panel width with clamping', () {
      controller.setLeftPanelWidth(200);
      expect(controller.leftPanelWidth, 240);

      controller.setLeftPanelWidth(300);
      expect(controller.leftPanelWidth, 300);

      controller.setLeftPanelWidth(500);
      expect(controller.leftPanelWidth, 360);
    });

    test('open right panel with tab', () {
      controller.openRightPanel(ReaderRightPanelTab.ai);
      expect(controller.isRightPanelOpen, true);
      expect(controller.rightTab, ReaderRightPanelTab.ai);
    });

    test('close right panel when not pinned', () {
      controller.openRightPanel(ReaderRightPanelTab.dictionary);
      controller.closeRightPanel();
      expect(controller.isRightPanelOpen, false);
    });

    test('close right panel ignored when pinned', () {
      controller.openRightPanel(ReaderRightPanelTab.dictionary);
      controller.setRightPanelPinned(true);
      controller.closeRightPanel();
      expect(controller.isRightPanelOpen, true);
    });

    test('toggle right panel', () {
      controller.toggleRightPanel();
      expect(controller.isRightPanelOpen, true);

      controller.toggleRightPanel();
      expect(controller.isRightPanelOpen, false);
    });

    test('set right panel width with clamping', () {
      controller.setRightPanelWidth(200);
      expect(controller.rightPanelWidth, 320);

      controller.setRightPanelWidth(400);
      expect(controller.rightPanelWidth, 400);

      controller.setRightPanelWidth(600);
      expect(controller.rightPanelWidth, 460);
    });

    test('set right panel pinned', () {
      controller.setRightPanelPinned(true);
      expect(controller.isRightPanelPinned, true);
    });

    test('enter immersive closes all panels', () {
      controller.openRightPanel(ReaderRightPanelTab.dictionary);
      controller.enterImmersive();
      expect(controller.isLeftPanelOpen, false);
      expect(controller.isRightPanelOpen, false);
    });

    test('notifies listeners on state change', () {
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.toggleLeftPanel();
      expect(notifyCount, 1);

      controller.openRightPanel(ReaderRightPanelTab.ai);
      expect(notifyCount, 2);

      controller.enterImmersive();
      expect(notifyCount, 3);
    });
  });
}
