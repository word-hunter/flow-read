import 'package:flutter/foundation.dart';

import '../../theme/app_motion_tokens.dart';

enum ReaderLeftPanelTab { toc, bookmarks, search, goals }

enum ReaderRightPanelTab { dictionary, ai, chapter }

class ReaderWorkspaceController extends ChangeNotifier {
  bool _isLeftPanelOpen;
  bool _isRightPanelOpen;
  ReaderLeftPanelTab _leftTab;
  ReaderRightPanelTab _rightTab;
  double _leftPanelWidth;
  double _rightPanelWidth;
  bool _animatePanelTransitions = true;

  ReaderWorkspaceController({
    bool leftPanelOpen = true,
    ReaderLeftPanelTab leftTab = ReaderLeftPanelTab.toc,
    double leftPanelWidth = ReaderPanelWidths.leftPanelDefault,
    bool rightPanelOpen = false,
    ReaderRightPanelTab rightTab = ReaderRightPanelTab.dictionary,
    double rightPanelWidth = ReaderPanelWidths.rightPanelDefault,
  }) : _isLeftPanelOpen = leftPanelOpen,
       _isRightPanelOpen = rightPanelOpen,
       _leftTab = leftTab,
       _rightTab = rightTab,
       _leftPanelWidth = leftPanelWidth,
       _rightPanelWidth = rightPanelWidth;

  bool get isLeftPanelOpen => _isLeftPanelOpen;
  bool get isRightPanelOpen => _isRightPanelOpen;
  ReaderLeftPanelTab get leftTab => _leftTab;
  ReaderRightPanelTab get rightTab => _rightTab;
  double get leftPanelWidth => _leftPanelWidth;
  double get rightPanelWidth => _rightPanelWidth;
  bool get animatePanelTransitions => _animatePanelTransitions;

  bool get isTocOpen => _isLeftPanelOpen && _leftTab == ReaderLeftPanelTab.toc;

  void openToc({bool animate = true}) {
    _animatePanelTransitions = animate;
    if (!_isLeftPanelOpen) {
      _isLeftPanelOpen = true;
    }
    _leftTab = ReaderLeftPanelTab.toc;
    notifyListeners();
  }

  void toggleToc({bool animate = true}) {
    _animatePanelTransitions = animate;
    if (isTocOpen) {
      _isLeftPanelOpen = false;
    } else {
      _isLeftPanelOpen = true;
      _leftTab = ReaderLeftPanelTab.toc;
    }
    notifyListeners();
  }

  void toggleLeftPanel({bool animate = true}) {
    _animatePanelTransitions = animate;
    _isLeftPanelOpen = !_isLeftPanelOpen;
    notifyListeners();
  }

  void setLeftPanelOpen(bool open, {bool animate = true}) {
    if (_isLeftPanelOpen == open) return;
    _animatePanelTransitions = animate;
    _isLeftPanelOpen = open;
    notifyListeners();
  }

  void setLeftTab(ReaderLeftPanelTab tab) {
    if (_leftTab == tab) return;
    _leftTab = tab;
    notifyListeners();
  }

  void setLeftPanelWidth(double width) {
    final clamped = width.clamp(
      ReaderPanelWidths.leftPanelMin,
      ReaderPanelWidths.leftPanelMax,
    );
    if (_leftPanelWidth == clamped) return;
    _leftPanelWidth = clamped;
    notifyListeners();
  }

  void setRightPanelOpen(bool open, {bool animate = true}) {
    if (_isRightPanelOpen == open) return;
    _animatePanelTransitions = animate;
    _isRightPanelOpen = open;
    notifyListeners();
  }

  void openRightPanel(ReaderRightPanelTab tab, {bool animate = true}) {
    _animatePanelTransitions = animate;
    _isRightPanelOpen = true;
    _rightTab = tab;
    notifyListeners();
  }

  void closeRightPanel({bool animate = true}) {
    if (!_isRightPanelOpen) return;
    _animatePanelTransitions = animate;
    _isRightPanelOpen = false;
    notifyListeners();
  }

  void toggleRightPanel({bool animate = true}) {
    _animatePanelTransitions = animate;
    _isRightPanelOpen = !_isRightPanelOpen;
    notifyListeners();
  }

  void setRightTab(ReaderRightPanelTab tab) {
    if (_rightTab == tab) return;
    _rightTab = tab;
    notifyListeners();
  }

  void setRightPanelWidth(double width) {
    final clamped = width.clamp(
      ReaderPanelWidths.rightPanelMin,
      ReaderPanelWidths.rightPanelMax,
    );
    if (_rightPanelWidth == clamped) return;
    _rightPanelWidth = clamped;
    notifyListeners();
  }

  void enterImmersive({bool animate = true}) {
    _animatePanelTransitions = animate;
    _isLeftPanelOpen = false;
    _isRightPanelOpen = false;
    notifyListeners();
  }
}
