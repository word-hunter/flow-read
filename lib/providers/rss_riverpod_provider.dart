import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import 'rss_provider.dart';

final rssProvider = ChangeNotifierProvider<RssProvider>((ref) {
  final provider = RssProvider();
  unawaited(provider.init());
  return provider;
});
