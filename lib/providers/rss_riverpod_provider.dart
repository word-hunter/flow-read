import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rss_provider.dart';

export 'rss_provider.dart' show rssFeedServiceProvider, RssNotifier, RssState;

final rssNotifierProvider = NotifierProvider<RssNotifier, RssState>(
  RssNotifier.new,
);
