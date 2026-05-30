enum DictionarySourceType {
  wordNet('wordnet', 'WordNet', false),
  dictionaryApi('dictionaryapi', 'Dictionary API', true),
  collins('collins', 'Collins', true),
  longman('longman', 'Longman', true);

  const DictionarySourceType(this.id, this.label, this.online);

  final String id;
  final String label;
  final bool online;

  static DictionarySourceType fromId(String id) {
    return DictionarySourceType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => DictionarySourceType.wordNet,
    );
  }
}

class DictionarySourceConfig {
  final DictionarySourceType type;
  final bool enabled;
  final int priority;

  const DictionarySourceConfig({
    required this.type,
    required this.enabled,
    required this.priority,
  });

  static const defaults = <DictionarySourceConfig>[
    DictionarySourceConfig(
      type: DictionarySourceType.collins,
      enabled: true,
      priority: 0,
    ),
    DictionarySourceConfig(
      type: DictionarySourceType.wordNet,
      enabled: true,
      priority: 1,
    ),
    DictionarySourceConfig(
      type: DictionarySourceType.dictionaryApi,
      enabled: true,
      priority: 2,
    ),
    DictionarySourceConfig(
      type: DictionarySourceType.longman,
      enabled: true,
      priority: 3,
    ),
  ];

  static const legacyWordNetFirstDefaults = <DictionarySourceConfig>[
    DictionarySourceConfig(
      type: DictionarySourceType.wordNet,
      enabled: true,
      priority: 0,
    ),
    DictionarySourceConfig(
      type: DictionarySourceType.dictionaryApi,
      enabled: true,
      priority: 1,
    ),
    DictionarySourceConfig(
      type: DictionarySourceType.collins,
      enabled: true,
      priority: 2,
    ),
    DictionarySourceConfig(
      type: DictionarySourceType.longman,
      enabled: true,
      priority: 3,
    ),
  ];

  DictionarySourceConfig copyWith({
    DictionarySourceType? type,
    bool? enabled,
    int? priority,
  }) {
    return DictionarySourceConfig(
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.id,
    'enabled': enabled,
    'priority': priority,
  };

  factory DictionarySourceConfig.fromJson(Map<String, dynamic> json) {
    return DictionarySourceConfig(
      type: DictionarySourceType.fromId(json['type']?.toString() ?? ''),
      enabled: json['enabled'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
    );
  }

  static List<DictionarySourceConfig> normalize(
    Iterable<DictionarySourceConfig> configs,
  ) {
    final byType = {for (final config in configs) config.type: config};
    final defaultPriority = {
      for (final config in defaults) config.type: config.priority,
    };
    final normalized =
        [
          for (final fallback in defaults)
            _normalizeFallback(byType[fallback.type] ?? fallback),
        ]..sort((a, b) {
          final priority = a.priority.compareTo(b.priority);
          if (priority != 0) return priority;
          return defaultPriority[a.type]!.compareTo(defaultPriority[b.type]!);
        });
    return [
      for (var i = 0; i < normalized.length; i++)
        normalized[i].copyWith(priority: i),
    ];
  }

  static List<DictionarySourceConfig> migrateLegacyOrder(
    Iterable<DictionarySourceConfig> configs,
  ) {
    final normalized = normalize(configs);
    if (!_matchesOrder(normalized, legacyWordNetFirstDefaults)) {
      return normalized;
    }

    final byType = {for (final config in normalized) config.type: config};
    return [
      for (final fallback in defaults)
        (byType[fallback.type] ?? fallback).copyWith(
          priority: fallback.priority,
        ),
    ]..sort((a, b) => a.priority.compareTo(b.priority));
  }

  static bool _matchesOrder(
    List<DictionarySourceConfig> configs,
    List<DictionarySourceConfig> expected,
  ) {
    final byType = {for (final config in configs) config.type: config};
    for (final item in expected) {
      if (byType[item.type]?.priority != item.priority) return false;
    }
    return true;
  }

  static DictionarySourceConfig _normalizeFallback(
    DictionarySourceConfig config,
  ) {
    if (config.type == DictionarySourceType.wordNet) {
      return config.copyWith(enabled: true);
    }
    return config;
  }
}
