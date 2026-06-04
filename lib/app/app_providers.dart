import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';

import '../providers/reading/reading_provider_riverpod.dart'
    as riverpod_reading;
import '../providers/reading_provider.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final container = riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    );
    final settings = container.read(settingsProvider);
    final reader = container.read(riverpod_reading.readingProvider);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        ChangeNotifierProvider<ReadingProvider>.value(
          value: reader,
        ),
      ],
      child: child,
    );
  }
}
