enum AIAutomationMode {
  saving,
  assisted,
  automatic,
}

class AIAutomationSettings {
  const AIAutomationSettings({
    this.mode = AIAutomationMode.saving,
    this.allowedActionModes = const {AIAutomationMode.saving},
  });

  final AIAutomationMode mode;
  final Set<AIAutomationMode> allowedActionModes;

  bool get canAutoSpendTokens => mode == AIAutomationMode.automatic;

  bool allows(AIAutomationMode candidate) {
    return allowedActionModes.contains(candidate);
  }
}
