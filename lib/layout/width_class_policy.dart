enum WidthClass {
  compact,
  medium,
  wide,
  workspace;

  static const double _compactMax = 759;
  static const double _wideMin = 1200;
  static const double _workspaceMin = 1440;

  static WidthClass resolve(double width) {
    if (width >= _workspaceMin) return WidthClass.workspace;
    if (width >= _wideMin) return WidthClass.wide;
    if (width >= _compactMax + 1) return WidthClass.medium;
    return WidthClass.compact;
  }
}
