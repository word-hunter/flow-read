class FlowReadFeatureFlags {
  static bool _v2Enabled = false;

  const FlowReadFeatureFlags._();

  static bool get v2Enabled => _v2Enabled;

  static void setV2Enabled(bool enabled) {
    _v2Enabled = enabled;
  }
}
