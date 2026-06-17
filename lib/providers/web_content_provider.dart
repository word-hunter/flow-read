import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/web_content_service.dart';

final webContentServiceProvider = Provider<WebContentService>((ref) {
  final service = WebContentService();
  ref.onDispose(service.close);
  return service;
});
