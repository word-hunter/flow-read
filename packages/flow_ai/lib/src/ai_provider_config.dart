class AIProviderDefinition {
  final String id;
  final String label;
  final String defaultBaseUrl;
  final String defaultModel;
  final bool baseUrlEditable;
  final bool modelEditable;

  const AIProviderDefinition({
    required this.id,
    required this.label,
    required this.defaultBaseUrl,
    required this.defaultModel,
    this.baseUrlEditable = false,
    this.modelEditable = true,
  });
}

class AIProviderConfig {
  final AIProviderDefinition definition;
  final String apiKey;
  final String baseUrl;
  final String model;

  const AIProviderConfig({
    required this.definition,
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  });

  String get normalizedBaseUrl {
    final trimmed = baseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  AIProviderConfig copyWith({String? apiKey, String? baseUrl, String? model}) {
    return AIProviderConfig(
      definition: definition,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
    );
  }
}

class AIProviders {
  static const deepSeek = AIProviderDefinition(
    id: 'deepseek',
    label: 'DeepSeek',
    defaultBaseUrl: 'https://api.deepseek.com/v1',
    defaultModel: 'deepseek-chat',
  );

  static const openAI = AIProviderDefinition(
    id: 'openai',
    label: 'OpenAI',
    defaultBaseUrl: 'https://api.openai.com/v1',
    defaultModel: 'gpt-4o-mini',
  );

  static const openAICompatible = AIProviderDefinition(
    id: 'openai_compatible',
    label: 'OpenAI 兼容',
    defaultBaseUrl: 'https://api.example.com/v1',
    defaultModel: 'model-name',
    baseUrlEditable: true,
  );

  static const all = <AIProviderDefinition>[deepSeek, openAI, openAICompatible];

  static AIProviderDefinition byId(String id) {
    return all.firstWhere(
      (provider) => provider.id == id,
      orElse: () => deepSeek,
    );
  }
}
