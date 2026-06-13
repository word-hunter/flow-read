import 'dart:io';

class ProxyHttpOverrides extends HttpOverrides {
  final String host;
  final int port;

  ProxyHttpOverrides({required this.host, required this.port});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (_) => 'PROXY $host:$port';
    return client;
  }

  static void apply({
    required bool enabled,
    required String host,
    required int port,
  }) {
    if (enabled && host.isNotEmpty && port > 0) {
      HttpOverrides.global = ProxyHttpOverrides(host: host, port: port);
    } else {
      HttpOverrides.global = null;
    }
  }
}
