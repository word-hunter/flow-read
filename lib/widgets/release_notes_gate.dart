import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../providers/settings_provider.dart';
import '../services/app_version.dart';
import '../services/changelog_service.dart';
import 'release_notes_dialog.dart';

class ReleaseNotesGate extends riverpod.ConsumerStatefulWidget {
  const ReleaseNotesGate({super.key, required this.child});

  final Widget child;

  @override
  riverpod.ConsumerState<ReleaseNotesGate> createState() =>
      _ReleaseNotesGateState();
}

class _ReleaseNotesGateState extends riverpod.ConsumerState<ReleaseNotesGate> {
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showIfNeeded());
  }

  Future<void> _showIfNeeded() async {
    if (!mounted) return;

    final settings = ref.read(settingsProvider);
    if (!settings.shouldShowReleaseNotes(FlowReadVersion.releaseName)) {
      return;
    }

    final notes = await ChangelogService.loadCurrentReleaseNotes();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => ReleaseNotesDialog(notes: notes),
    );

    if (!mounted) return;
    await settings.markReleaseNotesSeen(FlowReadVersion.releaseName);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
