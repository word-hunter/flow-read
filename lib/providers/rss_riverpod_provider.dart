import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rss_provider.dart';

export 'rss_provider.dart' show RssNotifier, RssState, rssFeedServiceProvider;

final rssNotifierProvider = NotifierProvider<RssNotifier, RssState>(
  RssNotifier.new,
);
