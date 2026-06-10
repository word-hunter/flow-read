import 'package:flutter/material.dart';

import '../../services/app_update_service.dart';
import '../flow/flow_components.dart';

enum UpdateCheckResultAction { updateNow, viewReleaseNotes }

class UpdateCheckResultDialog extends StatelessWidget {
  const UpdateCheckResultDialog({super.key, required this.update});

  final AppUpdateInfo? update;

  @override
  Widget build(BuildContext context) {
    final update = this.update;
    if (update == null) {
      return FlowDialog(
        title: const Text('已是最新版本'),
        content: const Text('当前版本已经是最新版本。'),
        actions: [
          FlowButton.text(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      );
    }

    final theme = Theme.of(context);
    return FlowDialog(
      title: const Text('发现新版本'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Flow Read ${update.version}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(update.isPrerelease ? '预发布版本' : '正式版本'),
          if (update.assetName != null) ...[
            const SizedBox(height: 8),
            Text(update.assetName!),
          ],
        ],
      ),
      actions: [
        FlowButton.text(
          onPressed: () =>
              Navigator.pop(context, UpdateCheckResultAction.viewReleaseNotes),
          child: const Text('查看更新说明'),
        ),
        FlowButton.primary(
          onPressed: () =>
              Navigator.pop(context, UpdateCheckResultAction.updateNow),
          child: const Text('立即更新'),
        ),
      ],
    );
  }
}
