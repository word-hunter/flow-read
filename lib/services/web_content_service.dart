import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

class WebPageContent {
  final Uri url;
  final String title;
  final List<String> paragraphs;

  const WebPageContent({
    required this.url,
    required this.title,
    required this.paragraphs,
  });

  String get plainText => paragraphs.join('\n\n');
}

class WebContentService {
  static const _headers = {
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'User-Agent': 'FlowRead/1.0 Web Reader',
  };

  final http.Client _client;

  WebContentService({http.Client? client}) : _client = client ?? http.Client();

  void close() {
    _client.close();
  }

  Future<WebPageContent> fetch(String inputUrl) async {
    final uri = normalizeUri(inputUrl);
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('网页响应异常: HTTP ${response.statusCode}');
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.toLowerCase().contains('text/html') &&
        !contentType.toLowerCase().contains('application/xhtml+xml') &&
        !contentType.toLowerCase().contains('application/xml')) {
      throw StateError('暂不支持该内容类型: $contentType');
    }

    final source = utf8.decode(response.bodyBytes, allowMalformed: true);
    return parse(source, uri);
  }

  static Uri normalizeUri(String inputUrl) {
    var normalized = inputUrl.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('请输入网页地址');
    }
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        uri.host.trim().isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError('请输入有效的网页地址');
    }
    return uri;
  }

  static WebPageContent parse(String source, Uri url) {
    final document = html.parse(source);
    _removeNoise(document);

    final title = _clean(
      document
              .querySelector('meta[property="og:title"]')
              ?.attributes['content'] ??
          document.querySelector('title')?.text ??
          document.querySelector('h1')?.text ??
          url.host,
    );

    final root =
        document.querySelector('article') ??
        document.querySelector('main') ??
        document.body ??
        document.documentElement!;

    final paragraphs = _extractParagraphs(root);
    if (paragraphs.isEmpty) {
      final fallback = _clean(root.text);
      if (fallback.isNotEmpty) {
        paragraphs.addAll(_splitFallbackText(fallback));
      }
    }

    return WebPageContent(
      url: url,
      title: title.isEmpty ? url.host : title,
      paragraphs: paragraphs,
    );
  }

  static void _removeNoise(dom.Document document) {
    const selectors = [
      'script',
      'style',
      'noscript',
      'svg',
      'canvas',
      'iframe',
      'nav',
      'footer',
      'header',
      'form',
      'aside',
      '[role="navigation"]',
      '[aria-hidden="true"]',
    ];
    for (final selector in selectors) {
      document.querySelectorAll(selector).forEach((node) => node.remove());
    }
  }

  static List<String> _extractParagraphs(dom.Element root) {
    final nodes = root.querySelectorAll('h1,h2,h3,p,li,blockquote,pre');
    final result = <String>[];
    final seen = <String>{};

    for (final node in nodes) {
      final text = _clean(node.text);
      if (text.isEmpty) continue;
      if (text.length < 20 &&
          node.localName != 'h1' &&
          node.localName != 'h2') {
        continue;
      }
      if (!seen.add(text)) continue;
      result.add(text);
    }
    return result;
  }

  static List<String> _splitFallbackText(String text) {
    final chunks = <String>[];
    final sentences = text.split(RegExp(r'(?<=[.!?。！？])\s+'));
    var buffer = '';
    for (final sentence in sentences) {
      if (buffer.length + sentence.length > 900 && buffer.isNotEmpty) {
        chunks.add(buffer.trim());
        buffer = sentence;
      } else {
        buffer += buffer.isEmpty ? sentence : ' $sentence';
      }
    }
    if (buffer.trim().isNotEmpty) chunks.add(buffer.trim());
    return chunks;
  }

  static String _clean(String value) {
    return value
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
