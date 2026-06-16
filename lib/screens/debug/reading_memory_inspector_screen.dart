import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/reading_memory.dart';
import '../../providers/reading/services_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/reading_memory/reading_memory_inspector_service.dart';

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
  var _refreshSeed = 0;
  KnowledgeEntityType? _entityType;
  KnowledgeMasteryState? _masteryState;

  @override
  void dispose() {
    _entitySearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
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
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: '概览'),
              Tab(icon: Icon(Icons.format_list_bulleted), text: '实体'),
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
                  return _EntityTile(entity: entities[index]);
                },
              );
            },
          ),
        ),
      ],
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              key: const ValueKey('reading-memory-entity-search'),
              controller: searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: '搜索实体',
                border: OutlineInputBorder(),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          _EntityTypeDropdown(value: type, onChanged: onTypeChanged),
          _MasteryDropdown(value: masteryState, onChanged: onMasteryChanged),
        ],
      ),
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

class _EntityTile extends StatelessWidget {
  const _EntityTile({required this.entity});

  final MemoryKnowledgeEntity entity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surfaceContainerLowest,
      ),
      child: ListTile(
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
