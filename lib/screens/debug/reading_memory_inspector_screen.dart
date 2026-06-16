import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/reading_memory.dart';
import '../../providers/reading/services_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/reading_memory/reading_memory_inspector_service.dart';
import '../../widgets/flow/flow_sheet.dart';

class ReadingMemoryInspectorScreen extends ConsumerWidget {
  const ReadingMemoryInspectorScreen({super.key});

  static const routeName = '/debug/reading-memory';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) {
      return const _InspectorUnavailableScaffold();
    }

    final database = ref.watch(appDatabaseProvider);
    final languageCode = ref.watch(settingsProvider).activeSourceLanguage;

    return database.when(
      data: (db) => ReadingMemoryInspectorView(
        service: ReadingMemoryInspectorService(
          dao: db.readingMemoryDao,
          languageCode: languageCode,
        ),
        languageCode: languageCode,
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Reading Memory Inspector')),
        body: Center(child: Text('无法读取数据库：$error')),
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Reading Memory Inspector')),
        body: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class ReadingMemoryInspectorView extends StatefulWidget {
  const ReadingMemoryInspectorView({
    super.key,
    required this.service,
    required this.languageCode,
  });

  final ReadingMemoryInspectorService service;
  final String languageCode;

  @override
  State<ReadingMemoryInspectorView> createState() =>
      _ReadingMemoryInspectorViewState();
}

class _ReadingMemoryInspectorViewState
    extends State<ReadingMemoryInspectorView> {
  final _entitySearchController = TextEditingController();
  final _sourceSearchController = TextEditingController();
  final _evidenceSearchController = TextEditingController();
  final _eventSearchController = TextEditingController();
  var _refreshSeed = 0;
  KnowledgeEntityType? _entityType;
  KnowledgeMasteryState? _masteryState;
  SourceKind? _sourceKind;
  SourceAvailability? _sourceAvailability;
  SourceKind? _evidenceSourceKind;
  SourceAvailability? _evidenceSourceAvailability;
  MemoryEventType? _eventType;

  @override
  void dispose() {
    _entitySearchController.dispose();
    _sourceSearchController.dispose();
    _evidenceSearchController.dispose();
    _eventSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reading Memory Inspector'),
          actions: [
            Tooltip(
              message: '刷新',
              child: IconButton(
                key: const ValueKey('reading-memory-inspector-refresh'),
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: '概览'),
              Tab(icon: Icon(Icons.format_list_bulleted), text: '实体'),
              Tab(icon: Icon(Icons.source_outlined), text: '来源'),
              Tab(icon: Icon(Icons.article_outlined), text: '证据'),
              Tab(icon: Icon(Icons.timeline_outlined), text: '事件'),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InspectorHeader(languageCode: widget.languageCode),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewPane(
                    key: ValueKey('overview-$_refreshSeed'),
                    service: widget.service,
                    languageCode: widget.languageCode,
                  ),
                  _EntitiesPane(
                    key: ValueKey('entities-$_refreshSeed'),
                    service: widget.service,
                    languageCode: widget.languageCode,
                    searchController: _entitySearchController,
                    type: _entityType,
                    masteryState: _masteryState,
                    onTypeChanged: (value) {
                      setState(() => _entityType = value);
                    },
                    onMasteryChanged: (value) {
                      setState(() => _masteryState = value);
                    },
                    onSearchChanged: (_) => setState(() {}),
                  ),
                  _SourcesPane(
                    key: ValueKey('sources-$_refreshSeed'),
                    service: widget.service,
                    languageCode: widget.languageCode,
                    searchController: _sourceSearchController,
                    sourceKind: _sourceKind,
                    availability: _sourceAvailability,
                    onSourceKindChanged: (value) {
                      setState(() => _sourceKind = value);
                    },
                    onAvailabilityChanged: (value) {
                      setState(() => _sourceAvailability = value);
                    },
                    onSearchChanged: (_) => setState(() {}),
                  ),
                  _EvidencesPane(
                    key: ValueKey('evidences-$_refreshSeed'),
                    service: widget.service,
                    languageCode: widget.languageCode,
                    searchController: _evidenceSearchController,
                    sourceKind: _evidenceSourceKind,
                    sourceAvailability: _evidenceSourceAvailability,
                    onSourceKindChanged: (value) {
                      setState(() => _evidenceSourceKind = value);
                    },
                    onSourceAvailabilityChanged: (value) {
                      setState(() => _evidenceSourceAvailability = value);
                    },
                    onSearchChanged: (_) => setState(() {}),
                  ),
                  _EventsPane(
                    key: ValueKey('events-$_refreshSeed'),
                    service: widget.service,
                    languageCode: widget.languageCode,
                    searchController: _eventSearchController,
                    eventType: _eventType,
                    onEventTypeChanged: (value) {
                      setState(() => _eventType = value);
                    },
                    onSearchChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refresh() {
    setState(() => _refreshSeed += 1);
  }
}

class _InspectorHeader extends StatelessWidget {
  const _InspectorHeader({required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Icon(
            Icons.storage_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '当前语言：$languageCode',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPane extends StatelessWidget {
  const _OverviewPane({
    super.key,
    required this.service,
    required this.languageCode,
  });

  final ReadingMemoryInspectorService service;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReadingMemoryInspectorOverview>(
      future: service.overview(languageCode: languageCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(message: snapshot.error.toString());
        }
        final overview = snapshot.requireData;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _CountGrid(overview: overview),
            const SizedBox(height: 16),
            _DistributionSection(
              title: '实体类型',
              values: overview.entityCountsByType.map(
                (key, value) => MapEntry(key.storageValue, value),
              ),
            ),
            const SizedBox(height: 16),
            _DistributionSection(
              title: '掌握状态',
              values: overview.entityCountsByMastery.map(
                (key, value) => MapEntry(key.storageValue, value),
              ),
            ),
            const SizedBox(height: 16),
            _DistributionSection(
              title: '事件类型',
              values: overview.eventCountsByType.map(
                (key, value) => MapEntry(key.storageValue, value),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CountGrid extends StatelessWidget {
  const _CountGrid({required this.overview});

  final ReadingMemoryInspectorOverview overview;

  @override
  Widget build(BuildContext context) {
    final items = [
      _CountItem('Sources', overview.sourceCount),
      _CountItem('Entities', overview.entityCount),
      _CountItem('Explanations', overview.explanationCount),
      _CountItem('Evidences', overview.evidenceCount),
      _CountItem('Events', overview.eventCount),
      _CountItem('Review candidates', overview.reviewCandidateCount),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 860
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 86,
          ),
          itemBuilder: (context, index) => _CountTile(item: items[index]),
        );
      },
    );
  }
}

class _CountItem {
  const _CountItem(this.label, this.value);

  final String label;
  final int value;
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.item});

  final _CountItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surfaceContainerLowest,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.value.toString(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionSection extends StatelessWidget {
  const _DistributionSection({required this.title, required this.values});

  final String title;
  final Map<String, int> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (values.isEmpty)
              Text(
                '暂无数据',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in values.entries)
                    Chip(label: Text('${entry.key}: ${entry.value}')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EntitiesPane extends StatelessWidget {
  const _EntitiesPane({
    super.key,
    required this.service,
    required this.languageCode,
    required this.searchController,
    required this.type,
    required this.masteryState,
    required this.onTypeChanged,
    required this.onMasteryChanged,
    required this.onSearchChanged,
  });

  final ReadingMemoryInspectorService service;
  final String languageCode;
  final TextEditingController searchController;
  final KnowledgeEntityType? type;
  final KnowledgeMasteryState? masteryState;
  final ValueChanged<KnowledgeEntityType?> onTypeChanged;
  final ValueChanged<KnowledgeMasteryState?> onMasteryChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EntityFilterBar(
          searchController: searchController,
          type: type,
          masteryState: masteryState,
          onTypeChanged: onTypeChanged,
          onMasteryChanged: onMasteryChanged,
          onSearchChanged: onSearchChanged,
        ),
        Expanded(
          child: FutureBuilder<List<MemoryKnowledgeEntity>>(
            future: service.entities(
              languageCode: languageCode,
              query: searchController.text,
              type: type,
              masteryState: masteryState,
              limit: 100,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ErrorState(message: snapshot.error.toString());
              }
              final entities = snapshot.requireData;
              if (entities.isEmpty) {
                return const _EmptyState(message: '暂无实体');
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: entities.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entity = entities[index];
                  return _EntityTile(
                    entity: entity,
                    onTap: () => _showEntityDetail(context, entity.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEntityDetail(BuildContext context, String entityId) {
    showFlowSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FlowSheet(
          maxWidth: 760,
          title: const Text('实体详情'),
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.78,
            child: FutureBuilder<ReadingMemoryEntityDetail?>(
              future: service.entityDetail(entityId),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(message: snapshot.error.toString());
                }
                final detail = snapshot.data;
                if (detail == null) {
                  return const _EmptyState(message: '实体不存在');
                }
                return _EntityDetailView(detail: detail);
              },
            ),
          ),
        );
      },
    );
  }
}

class _EntityFilterBar extends StatelessWidget {
  const _EntityFilterBar({
    required this.searchController,
    required this.type,
    required this.masteryState,
    required this.onTypeChanged,
    required this.onMasteryChanged,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final KnowledgeEntityType? type;
  final KnowledgeMasteryState? masteryState;
  final ValueChanged<KnowledgeEntityType?> onTypeChanged;
  final ValueChanged<KnowledgeMasteryState?> onMasteryChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return _InspectorFilterBar(
      searchKey: const ValueKey('reading-memory-entity-search'),
      searchLabel: '搜索实体',
      searchController: searchController,
      onSearchChanged: onSearchChanged,
      children: [
        _EntityTypeDropdown(value: type, onChanged: onTypeChanged),
        _MasteryDropdown(value: masteryState, onChanged: onMasteryChanged),
      ],
    );
  }
}

class _InspectorFilterBar extends StatelessWidget {
  const _InspectorFilterBar({
    required this.searchKey,
    required this.searchLabel,
    required this.searchController,
    required this.onSearchChanged,
    required this.children,
  });

  final Key searchKey;
  final String searchLabel;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final searchWidth = constraints.maxWidth < 360
            ? constraints.maxWidth
            : 320.0;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: searchWidth,
                child: TextField(
                  key: searchKey,
                  controller: searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    labelText: searchLabel,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              ...children,
            ],
          ),
        );
      },
    );
  }
}

class _EntityTypeDropdown extends StatelessWidget {
  const _EntityTypeDropdown({required this.value, required this.onChanged});

  final KnowledgeEntityType? value;
  final ValueChanged<KnowledgeEntityType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<KnowledgeEntityType?>(
      value: value,
      hint: const Text('实体类型'),
      items: [
        const DropdownMenuItem<KnowledgeEntityType?>(
          value: null,
          child: Text('全部类型'),
        ),
        for (final type in KnowledgeEntityType.values)
          DropdownMenuItem<KnowledgeEntityType?>(
            value: type,
            child: Text(type.storageValue),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _MasteryDropdown extends StatelessWidget {
  const _MasteryDropdown({required this.value, required this.onChanged});

  final KnowledgeMasteryState? value;
  final ValueChanged<KnowledgeMasteryState?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<KnowledgeMasteryState?>(
      value: value,
      hint: const Text('掌握状态'),
      items: [
        const DropdownMenuItem<KnowledgeMasteryState?>(
          value: null,
          child: Text('全部状态'),
        ),
        for (final state in KnowledgeMasteryState.values)
          DropdownMenuItem<KnowledgeMasteryState?>(
            value: state,
            child: Text(state.storageValue),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _TileSurface extends StatelessWidget {
  const _TileSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _EntityTile extends StatelessWidget {
  const _EntityTile({required this.entity, required this.onTap});

  final MemoryKnowledgeEntity entity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _TileSurface(
      child: ListTile(
        onTap: onTap,
        title: Text(
          entity.displayText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${entity.type.storageValue} · ${entity.canonicalKey}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Chip(label: Text(entity.masteryState.storageValue)),
      ),
    );
  }
}

class _SourcesPane extends StatelessWidget {
  const _SourcesPane({
    super.key,
    required this.service,
    required this.languageCode,
    required this.searchController,
    required this.sourceKind,
    required this.availability,
    required this.onSourceKindChanged,
    required this.onAvailabilityChanged,
    required this.onSearchChanged,
  });

  final ReadingMemoryInspectorService service;
  final String languageCode;
  final TextEditingController searchController;
  final SourceKind? sourceKind;
  final SourceAvailability? availability;
  final ValueChanged<SourceKind?> onSourceKindChanged;
  final ValueChanged<SourceAvailability?> onAvailabilityChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SourceFilterBar(
          searchController: searchController,
          sourceKind: sourceKind,
          availability: availability,
          onSourceKindChanged: onSourceKindChanged,
          onAvailabilityChanged: onAvailabilityChanged,
          onSearchChanged: onSearchChanged,
        ),
        Expanded(
          child: FutureBuilder<List<MemorySourceRecord>>(
            future: service.sources(
              languageCode: languageCode,
              query: searchController.text,
              sourceKind: sourceKind,
              availability: availability,
              limit: 100,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ErrorState(message: snapshot.error.toString());
              }
              final sources = snapshot.requireData;
              if (sources.isEmpty) {
                return const _EmptyState(message: '暂无来源');
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: sources.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _SourceTile(source: sources[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SourceFilterBar extends StatelessWidget {
  const _SourceFilterBar({
    required this.searchController,
    required this.sourceKind,
    required this.availability,
    required this.onSourceKindChanged,
    required this.onAvailabilityChanged,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final SourceKind? sourceKind;
  final SourceAvailability? availability;
  final ValueChanged<SourceKind?> onSourceKindChanged;
  final ValueChanged<SourceAvailability?> onAvailabilityChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return _InspectorFilterBar(
      searchKey: const ValueKey('reading-memory-source-search'),
      searchLabel: '搜索来源',
      searchController: searchController,
      onSearchChanged: onSearchChanged,
      children: [
        _SourceKindDropdown(value: sourceKind, onChanged: onSourceKindChanged),
        _SourceAvailabilityDropdown(
          value: availability,
          onChanged: onAvailabilityChanged,
        ),
      ],
    );
  }
}

class _EvidencesPane extends StatelessWidget {
  const _EvidencesPane({
    super.key,
    required this.service,
    required this.languageCode,
    required this.searchController,
    required this.sourceKind,
    required this.sourceAvailability,
    required this.onSourceKindChanged,
    required this.onSourceAvailabilityChanged,
    required this.onSearchChanged,
  });

  final ReadingMemoryInspectorService service;
  final String languageCode;
  final TextEditingController searchController;
  final SourceKind? sourceKind;
  final SourceAvailability? sourceAvailability;
  final ValueChanged<SourceKind?> onSourceKindChanged;
  final ValueChanged<SourceAvailability?> onSourceAvailabilityChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EvidenceFilterBar(
          searchController: searchController,
          sourceKind: sourceKind,
          sourceAvailability: sourceAvailability,
          onSourceKindChanged: onSourceKindChanged,
          onSourceAvailabilityChanged: onSourceAvailabilityChanged,
          onSearchChanged: onSearchChanged,
        ),
        Expanded(
          child: FutureBuilder<List<MemoryKnowledgeEvidence>>(
            future: service.evidences(
              languageCode: languageCode,
              query: searchController.text,
              sourceKind: sourceKind,
              sourceAvailability: sourceAvailability,
              limit: 100,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ErrorState(message: snapshot.error.toString());
              }
              final evidences = snapshot.requireData;
              if (evidences.isEmpty) {
                return const _EmptyState(message: '暂无证据');
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: evidences.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _EvidenceTile(evidence: evidences[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EvidenceFilterBar extends StatelessWidget {
  const _EvidenceFilterBar({
    required this.searchController,
    required this.sourceKind,
    required this.sourceAvailability,
    required this.onSourceKindChanged,
    required this.onSourceAvailabilityChanged,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final SourceKind? sourceKind;
  final SourceAvailability? sourceAvailability;
  final ValueChanged<SourceKind?> onSourceKindChanged;
  final ValueChanged<SourceAvailability?> onSourceAvailabilityChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return _InspectorFilterBar(
      searchKey: const ValueKey('reading-memory-evidence-search'),
      searchLabel: '搜索证据',
      searchController: searchController,
      onSearchChanged: onSearchChanged,
      children: [
        _SourceKindDropdown(value: sourceKind, onChanged: onSourceKindChanged),
        _SourceAvailabilityDropdown(
          value: sourceAvailability,
          onChanged: onSourceAvailabilityChanged,
        ),
      ],
    );
  }
}

class _EventsPane extends StatelessWidget {
  const _EventsPane({
    super.key,
    required this.service,
    required this.languageCode,
    required this.searchController,
    required this.eventType,
    required this.onEventTypeChanged,
    required this.onSearchChanged,
  });

  final ReadingMemoryInspectorService service;
  final String languageCode;
  final TextEditingController searchController;
  final MemoryEventType? eventType;
  final ValueChanged<MemoryEventType?> onEventTypeChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EventFilterBar(
          searchController: searchController,
          eventType: eventType,
          onEventTypeChanged: onEventTypeChanged,
          onSearchChanged: onSearchChanged,
        ),
        Expanded(
          child: FutureBuilder<List<MemoryEvent>>(
            future: service.events(
              languageCode: languageCode,
              query: searchController.text,
              type: eventType,
              limit: 100,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ErrorState(message: snapshot.error.toString());
              }
              final events = snapshot.requireData;
              if (events.isEmpty) {
                return const _EmptyState(message: '暂无事件');
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: events.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _EventTile(event: events[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EventFilterBar extends StatelessWidget {
  const _EventFilterBar({
    required this.searchController,
    required this.eventType,
    required this.onEventTypeChanged,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final MemoryEventType? eventType;
  final ValueChanged<MemoryEventType?> onEventTypeChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return _InspectorFilterBar(
      searchKey: const ValueKey('reading-memory-event-search'),
      searchLabel: '搜索事件',
      searchController: searchController,
      onSearchChanged: onSearchChanged,
      children: [
        _EventTypeDropdown(value: eventType, onChanged: onEventTypeChanged),
      ],
    );
  }
}

class _SourceKindDropdown extends StatelessWidget {
  const _SourceKindDropdown({required this.value, required this.onChanged});

  final SourceKind? value;
  final ValueChanged<SourceKind?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<SourceKind?>(
      value: value,
      hint: const Text('来源类型'),
      items: [
        const DropdownMenuItem<SourceKind?>(
          value: null,
          child: Text('全部来源'),
        ),
        for (final kind in SourceKind.values)
          DropdownMenuItem<SourceKind?>(
            value: kind,
            child: Text(kind.storageValue),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _SourceAvailabilityDropdown extends StatelessWidget {
  const _SourceAvailabilityDropdown({
    required this.value,
    required this.onChanged,
  });

  final SourceAvailability? value;
  final ValueChanged<SourceAvailability?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<SourceAvailability?>(
      value: value,
      hint: const Text('可用状态'),
      items: [
        const DropdownMenuItem<SourceAvailability?>(
          value: null,
          child: Text('全部状态'),
        ),
        for (final availability in SourceAvailability.values)
          DropdownMenuItem<SourceAvailability?>(
            value: availability,
            child: Text(availability.storageValue),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _EventTypeDropdown extends StatelessWidget {
  const _EventTypeDropdown({required this.value, required this.onChanged});

  final MemoryEventType? value;
  final ValueChanged<MemoryEventType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<MemoryEventType?>(
      value: value,
      hint: const Text('事件类型'),
      items: [
        const DropdownMenuItem<MemoryEventType?>(
          value: null,
          child: Text('全部事件'),
        ),
        for (final type in MemoryEventType.values)
          DropdownMenuItem<MemoryEventType?>(
            value: type,
            child: Text(type.storageValue),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.source});

  final MemorySourceRecord source;

  @override
  Widget build(BuildContext context) {
    return _TileSurface(
      child: ListTile(
        title: Text(
          source.titleSnapshot,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            source.id,
            if (_hasText(source.authorSnapshot)) source.authorSnapshot!,
            'updated ${_formatDateTime(source.updatedAt)}',
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Wrap(
          spacing: 6,
          children: [
            _ValueChip(label: source.sourceKind.storageValue),
            _ValueChip(label: source.availability.storageValue),
          ],
        ),
      ),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({required this.evidence});

  final MemoryKnowledgeEvidence evidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _TileSurface(
      child: ListTile(
        title: Text(
          _nonEmpty(evidence.shortExcerpt, '无摘录'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  evidence.sourceTitleSnapshot,
                  if (_hasText(evidence.locationLocator))
                    evidence.locationLocator!,
                  if (evidence.chapterIndex != null)
                    'chapter ${evidence.chapterIndex}',
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                evidence.entityId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        trailing: Wrap(
          spacing: 6,
          children: [
            _ValueChip(label: evidence.sourceKind.storageValue),
            _ValueChip(label: evidence.sourceAvailability.storageValue),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final MemoryEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _TileSurface(
      child: ListTile(
        title: Text(
          _nonEmpty(event.targetText, event.canonicalKey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  event.canonicalKey,
                  if (_hasText(event.sourceId)) event.sourceId!,
                  _formatDateTime(event.createdAt),
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (_hasText(event.entityId)) ...[
                const SizedBox(height: 4),
                Text(
                  event.entityId!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: _ValueChip(label: event.type.storageValue),
      ),
    );
  }
}

class _EntityDetailView extends StatelessWidget {
  const _EntityDetailView({required this.detail});

  final ReadingMemoryEntityDetail detail;

  @override
  Widget build(BuildContext context) {
    final entity = detail.entity;
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        _DetailSection(
          title: entity.displayText,
          child: _KeyValueList(
            rows: [
              _InfoRow('id', entity.id),
              _InfoRow('type', entity.type.storageValue),
              _InfoRow('canonical', entity.canonicalKey),
              _InfoRow('mastery', entity.masteryState.storageValue),
              _InfoRow('confidence', entity.confidence.toStringAsFixed(2)),
              _InfoRow('updated', _formatDateTime(entity.updatedAt)),
            ],
          ),
        ),
        _DetailSection(
          title: '保存的解释',
          emptyMessage: '暂无解释',
          isEmpty: detail.explanations.isEmpty,
          child: _DetailList(
            itemCount: detail.explanations.length,
            itemBuilder: (context, index) {
              final explanation = detail.explanations[index];
              return _ExplanationDetailTile(explanation: explanation);
            },
          ),
        ),
        _DetailSection(
          title: '证据',
          emptyMessage: '暂无证据',
          isEmpty: detail.evidences.isEmpty,
          child: _DetailList(
            itemCount: detail.evidences.length,
            itemBuilder: (context, index) {
              final evidence = detail.evidences[index];
              return _EvidenceDetailTile(evidence: evidence);
            },
          ),
        ),
        _DetailSection(
          title: '最近事件',
          emptyMessage: '暂无事件',
          isEmpty: detail.recentEvents.isEmpty,
          child: _DetailList(
            itemCount: detail.recentEvents.length,
            itemBuilder: (context, index) {
              final event = detail.recentEvents[index];
              return _EventDetailTile(event: event);
            },
          ),
        ),
        _DetailSection(
          title: '复习候选',
          emptyMessage: '暂无候选',
          isEmpty: detail.reviewCandidates.isEmpty,
          child: _DetailList(
            itemCount: detail.reviewCandidates.length,
            itemBuilder: (context, index) {
              final candidate = detail.reviewCandidates[index];
              return _ReviewCandidateDetailTile(candidate: candidate);
            },
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.child,
    this.emptyMessage,
    this.isEmpty = false,
  });

  final String title;
  final Widget child;
  final String? emptyMessage;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (isEmpty)
            Text(
              emptyMessage ?? '暂无数据',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            child,
        ],
      ),
    );
  }
}

class _DetailList extends StatelessWidget {
  const _DetailList({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < itemCount; index++) ...[
          itemBuilder(context, index),
          if (index != itemCount - 1) const Divider(height: 20),
        ],
      ],
    );
  }
}

class _ExplanationDetailTile extends StatelessWidget {
  const _ExplanationDetailTile({required this.explanation});

  final MemoryKnowledgeExplanation explanation;

  @override
  Widget build(BuildContext context) {
    return _DetailTile(
      title: explanation.explanation,
      rows: [
        _InfoRow('source', explanation.source.storageValue),
        _InfoRow('target', explanation.targetLanguage),
        if (_hasText(explanation.promptVersion))
          _InfoRow('prompt', explanation.promptVersion!),
        _InfoRow('updated', _formatDateTime(explanation.updatedAt)),
      ],
    );
  }
}

class _EvidenceDetailTile extends StatelessWidget {
  const _EvidenceDetailTile({required this.evidence});

  final MemoryKnowledgeEvidence evidence;

  @override
  Widget build(BuildContext context) {
    return _DetailTile(
      title: _nonEmpty(evidence.shortExcerpt, '无摘录'),
      rows: [
        _InfoRow('source', evidence.sourceTitleSnapshot),
        _InfoRow('kind', evidence.sourceKind.storageValue),
        _InfoRow('availability', evidence.sourceAvailability.storageValue),
        _InfoRow('retention', evidence.retentionPolicy.storageValue),
        if (_hasText(evidence.locationLocator))
          _InfoRow('locator', evidence.locationLocator!),
      ],
    );
  }
}

class _EventDetailTile extends StatelessWidget {
  const _EventDetailTile({required this.event});

  final MemoryEvent event;

  @override
  Widget build(BuildContext context) {
    return _DetailTile(
      title: _nonEmpty(event.targetText, event.canonicalKey),
      rows: [
        _InfoRow('type', event.type.storageValue),
        _InfoRow('canonical', event.canonicalKey),
        if (_hasText(event.sourceId)) _InfoRow('source', event.sourceId!),
        _InfoRow('created', _formatDateTime(event.createdAt)),
        if (_hasText(event.sourceRefJson))
          _InfoRow('sourceRef', _compactJson(event.sourceRefJson)),
        if (_hasText(event.metadataJson))
          _InfoRow('metadata', _compactJson(event.metadataJson)),
      ],
    );
  }
}

class _ReviewCandidateDetailTile extends StatelessWidget {
  const _ReviewCandidateDetailTile({required this.candidate});

  final ReviewCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return _DetailTile(
      title: candidate.targetText,
      rows: [
        _InfoRow('status', candidate.status.storageValue),
        _InfoRow('type', candidate.entityType.storageValue),
        _InfoRow('priority', candidate.priority.toStringAsFixed(2)),
        if (_hasText(candidate.suggestedQuestionType))
          _InfoRow('question', candidate.suggestedQuestionType!),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 6),
        _KeyValueList(rows: rows),
      ],
    );
  }
}

class _KeyValueList extends StatelessWidget {
  const _KeyValueList({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final row in rows) _ValueChip(label: '${row.label}: ${row.value}'),
      ],
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: theme.colorScheme.outlineVariant),
      backgroundColor: theme.colorScheme.surfaceContainerLow,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

bool _hasText(String? value) {
  return value != null && value.trim().isNotEmpty;
}

String _nonEmpty(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

String _compactJson(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 96) return trimmed;
  return '${trimmed.substring(0, 93)}...';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

class _InspectorUnavailableScaffold extends StatelessWidget {
  const _InspectorUnavailableScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading Memory Inspector')),
      body: const Center(child: Text('当前构建不可用')),
    );
  }
}
