import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import '../providers/reading/current_book_notifier.dart';
import '../widgets/flow/flow_components.dart';
import '../widgets/practice_card.dart';

class PracticeScreen extends riverpod.ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    ref.watch(currentBookNotifierProvider);
    final result = ref.read(currentBookNotifierProvider.notifier).result;
    if (result == null) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);

    return Scaffold(
      appBar: FlowToolbar(
        title: const Text('练习', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: false,
      ),
      body: result.practice.isEmpty
          ? Center(
              child: Text(
                '暂无练习',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text(
                    '${result.practice.length} 项练习',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: result.practice.length,
                    itemBuilder: (context, index) {
                      return PracticeCard(
                        practice: result.practice[index],
                        index: index,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
