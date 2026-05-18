enum DictionarySourceType {
  wordNet('wordnet', 'WordNet', true),
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
    return [for (final fallback in defaults) byType[fallback.type] ?? fallback]
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }
}
