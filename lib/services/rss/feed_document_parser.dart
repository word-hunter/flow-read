import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:xml/xml.dart';

import '../../models/rss_models.dart';

class RssFeedDocumentParser {
  const RssFeedDocumentParser({
    List<FeedDocumentAdapter> adapters = const [
      RssFeedDocumentAdapter(),
      AtomFeedDocumentAdapter(),
    ],
  }) : _adapters = adapters;

  final List<FeedDocumentAdapter> _adapters;

  ParsedFeedMetadata parseMetadata(XmlDocument document) {
    return _adapterFor(document).parseMetadata(document);
  }

  List<RssArticle> parseArticles(
    XmlDocument document, {
    required String feedUrl,
    String fallbackFeedTitle = '',
  }) {
    final articles = _adapterFor(document).parseArticles(
      document,
      FeedParseContext(feedUrl: feedUrl, fallbackFeedTitle: fallbackFeedTitle),
    )..sort(compareArticlesByDateDesc);
    return articles;
  }

  void ensureSupported(XmlDocument document) {
    _adapterFor(document);
  }

  FeedDocumentAdapter _adapterFor(XmlDocument document) {
    for (final adapter in _adapters) {
      if (adapter.supports(document)) return adapter;
    }
    throw StateError('未识别到 RSS/Atom 内容');
  }

  static int compareArticlesByDateDesc(RssArticle a, RssArticle b) {
    final aTime = a.pubDate?.millisecondsSinceEpoch ?? 0;
    final bTime = b.pubDate?.millisecondsSinceEpoch ?? 0;
    if (aTime != bTime) return bTime.compareTo(aTime);
    return a.title.compareTo(b.title);
  }
}

abstract class FeedDocumentAdapter {
  const FeedDocumentAdapter();

  bool supports(XmlDocument document);

  ParsedFeedMetadata parseMetadata(XmlDocument document);

  List<RssArticle> parseArticles(
    XmlDocument document,
    FeedParseContext context,
  );
}

class RssFeedDocumentAdapter extends FeedDocumentAdapter {
  const RssFeedDocumentAdapter();

  @override
  bool supports(XmlDocument document) {
    return document.findAllElements('channel').isNotEmpty;
  }

  @override
  ParsedFeedMetadata parseMetadata(XmlDocument document) {
    final channel = document.findAllElements('channel').firstOrNull;
    if (channel == null) return const ParsedFeedMetadata();
    return ParsedFeedMetadata(
      title: _childText(channel, ['title']),
      description: _cleanText(_childText(channel, ['description'])),
      imageUrl: channel
          .findElements('image')
          .firstOrNull
          ?.findElements('url')
          .firstOrNull
          ?.innerText,
    );
  }

  @override
  List<RssArticle> parseArticles(
    XmlDocument document,
    FeedParseContext context,
  ) {
    final channel = document.findAllElements('channel').firstOrNull;
    final feedTitle =
        channel?.findElements('title').firstOrNull?.innerText ??
        context.fallbackFeedTitle;
    return document.findAllElements('item').map((item) {
      final description = _childText(item, ['description']);
      final content = _childText(item, ['content:encoded', 'encoded']);
      final link = _childText(item, ['link']);
      final pubDate = _parseDate(_childText(item, ['pubDate', 'date']));
      final guid = _childText(item, ['guid']);
      final title = _childText(item, ['title']) ?? 'Untitled';
      return RssArticle(
        feedUrl: context.feedUrl,
        feedTitle: feedTitle,
        title: title,
        link: link,
        description: description != null ? _stripHtml(description) : null,
        content: _cleanArticleContent(content ?? description),
        images: _extractArticleImages(
          item,
          feedUrl: context.feedUrl,
          articleLink: link,
          htmlSources: [content, description],
        ),
        pubDate: pubDate,
        author: _childText(item, ['author', 'dc:creator', 'creator']),
        id: guid?.isNotEmpty == true
            ? '${context.feedUrl.hashCode}_${guid.hashCode}'
            : '${context.feedUrl.hashCode}_${(link ?? title).hashCode}_${pubDate?.millisecondsSinceEpoch ?? 0}',
      );
    }).toList();
  }
}

class AtomFeedDocumentAdapter extends FeedDocumentAdapter {
  const AtomFeedDocumentAdapter();

  @override
  bool supports(XmlDocument document) {
    return document.findAllElements('feed').isNotEmpty;
  }

  @override
  ParsedFeedMetadata parseMetadata(XmlDocument document) {
    final feed = document.findAllElements('feed').firstOrNull;
    if (feed == null) return const ParsedFeedMetadata();
    return ParsedFeedMetadata(
      title: _childText(feed, ['title']),
      description: _cleanText(_childText(feed, ['subtitle'])),
      imageUrl: _childText(feed, ['logo', 'icon']),
    );
  }

  @override
  List<RssArticle> parseArticles(
    XmlDocument document,
    FeedParseContext context,
  ) {
    final feed = document.findAllElements('feed').firstOrNull;
    final feedTitle =
        feed?.findElements('title').firstOrNull?.innerText ??
        context.fallbackFeedTitle;
    return document.findAllElements('entry').map((entry) {
      final summary = _childText(entry, ['summary']);
      final content = _childText(entry, ['content']);
      final link = _atomLink(entry);
      final pubDate = _parseDate(
        _childText(entry, ['published', 'updated', 'modified']),
      );
      final id = _childText(entry, ['id']);
      final title = _childText(entry, ['title']) ?? 'Untitled';
      return RssArticle(
        feedUrl: context.feedUrl,
        feedTitle: feedTitle,
        title: title,
        link: link,
        description: summary != null ? _stripHtml(summary) : null,
        content: _cleanArticleContent(content ?? summary),
        images: _extractArticleImages(
          entry,
          feedUrl: context.feedUrl,
          articleLink: link,
          htmlSources: [content, summary],
        ),
        pubDate: pubDate,
        author: entry
            .findElements('author')
            .firstOrNull
            ?.findElements('name')
            .firstOrNull
            ?.innerText,
        id: id?.isNotEmpty == true
            ? '${context.feedUrl.hashCode}_${id.hashCode}'
            : '${context.feedUrl.hashCode}_${(link ?? title).hashCode}_${pubDate?.millisecondsSinceEpoch ?? 0}',
      );
    }).toList();
  }
}

class FeedParseContext {
  const FeedParseContext({required this.feedUrl, this.fallbackFeedTitle = ''});

  final String feedUrl;
  final String fallbackFeedTitle;
}

class ParsedFeedMetadata {
  const ParsedFeedMetadata({this.title, this.description, this.imageUrl});

  final String? title;
  final String? description;
  final String? imageUrl;
}

DateTime? _parseDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;
  try {
    return DateTime.parse(dateStr).toLocal();
  } catch (_) {
    return _parseRfc822Date(dateStr);
  }
}

DateTime? _parseRfc822Date(String value) {
  final cleaned = value
      .replaceFirst(RegExp(r'^[A-Za-z]{3},\s*'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final match = RegExp(
    r'^(\d{1,2})\s+([A-Za-z]{3})\s+(\d{2,4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([A-Za-z]{1,4}|[+-]\d{4})?$',
  ).firstMatch(cleaned);
  if (match == null) return null;

  const months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };
  final month = months[match.group(2)!.toLowerCase()];
  if (month == null) return null;

  var year = int.parse(match.group(3)!);
  if (year < 100) year += year >= 70 ? 1900 : 2000;
  final day = int.parse(match.group(1)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final second = int.tryParse(match.group(6) ?? '0') ?? 0;
  final zone = (match.group(7) ?? 'GMT').toUpperCase();
  final offset = _timezoneOffset(zone);
  final utc = DateTime.utc(
    year,
    month,
    day,
    hour,
    minute,
    second,
  ).subtract(offset);
  return utc.toLocal();
}

Duration _timezoneOffset(String zone) {
  const named = {
    'UT': Duration.zero,
    'UTC': Duration.zero,
    'GMT': Duration.zero,
    'Z': Duration.zero,
    'EST': Duration(hours: -5),
    'EDT': Duration(hours: -4),
    'CST': Duration(hours: -6),
    'CDT': Duration(hours: -5),
    'MST': Duration(hours: -7),
    'MDT': Duration(hours: -6),
    'PST': Duration(hours: -8),
    'PDT': Duration(hours: -7),
  };
  final upper = zone.toUpperCase();
  if (named.containsKey(upper)) return named[upper]!;
  final match = RegExp(r'^([+-])(\d{2})(\d{2})$').firstMatch(upper);
  if (match == null) return Duration.zero;
  final sign = match.group(1) == '-' ? -1 : 1;
  final hours = int.parse(match.group(2)!);
  final minutes = int.parse(match.group(3)!);
  return Duration(minutes: sign * (hours * 60 + minutes));
}

String _stripHtml(String htmlText) {
  try {
    final document = html.parse(htmlText);
    final text = document.body?.text ?? htmlText;
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  } catch (_) {
    return htmlText.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

String? _cleanArticleContent(String? value) {
  final text = _cleanText(value);
  if (text == null || text.isEmpty) return null;
  return text;
}

String? _cleanText(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return _stripHtml(trimmed);
}

List<RssArticleImage> _extractArticleImages(
  XmlElement item, {
  required String feedUrl,
  required String? articleLink,
  required List<String?> htmlSources,
}) {
  final images = <RssArticleImage>[];
  final seen = <String>{};

  void addImage({
    required String? rawUrl,
    String? alt,
    int? width,
    int? height,
  }) {
    final url = _resolveImageUrl(
      rawUrl,
      feedUrl: feedUrl,
      articleLink: articleLink,
    );
    if (url == null || !seen.add(url)) return;
    images.add(
      RssArticleImage(
        url: url,
        alt: _cleanOptional(alt),
        width: width,
        height: height,
      ),
    );
  }

  for (final source in htmlSources) {
    final trimmed = source?.trim();
    if (trimmed == null || trimmed.isEmpty) continue;
    final fragment = html.parseFragment(trimmed);
    for (final image in fragment.querySelectorAll('img')) {
      addImage(
        rawUrl: _htmlImageSource(image),
        alt: image.attributes['alt'],
        width:
            _parseImageDimension(image.attributes['width']) ??
            _parseCssDimension(image.attributes['style'], 'width'),
        height:
            _parseImageDimension(image.attributes['height']) ??
            _parseCssDimension(image.attributes['style'], 'height'),
      );
    }
  }

  for (final child in item.childElements) {
    final local = child.name.local.toLowerCase();
    final qualified = child.name.qualified.toLowerCase();
    final type = child.getAttribute('type')?.toLowerCase() ?? '';
    final medium = child.getAttribute('medium')?.toLowerCase();
    final isMediaImage =
        qualified == 'media:thumbnail' ||
        (local == 'thumbnail' && child.getAttribute('url') != null) ||
        (qualified == 'media:content' &&
            (medium == 'image' || type.startsWith('image/')));
    final isImageEnclosure = local == 'enclosure' && type.startsWith('image/');
    if (!isMediaImage && !isImageEnclosure) continue;

    addImage(
      rawUrl: child.getAttribute('url') ?? child.innerText,
      alt:
          child.getAttribute('alt') ??
          child.getAttribute('title') ??
          child.getAttribute('description'),
      width: _parseImageDimension(child.getAttribute('width')),
      height: _parseImageDimension(child.getAttribute('height')),
    );
  }

  return images;
}

String? _htmlImageSource(dom.Element image) {
  final src =
      image.attributes['src'] ??
      image.attributes['data-src'] ??
      image.attributes['data-original'];
  if (src != null && src.trim().isNotEmpty) return src.trim();

  final srcset = image.attributes['srcset'];
  if (srcset == null || srcset.trim().isEmpty) return null;
  final first = srcset.split(',').first.trim();
  if (first.isEmpty) return null;
  return first.split(RegExp(r'\s+')).first.trim();
}

String? _resolveImageUrl(
  String? rawUrl, {
  required String feedUrl,
  required String? articleLink,
}) {
  final text = rawUrl?.trim();
  if (text == null || text.isEmpty) return null;
  final uri = Uri.tryParse(text);
  if (uri == null || uri.scheme == 'data' || uri.scheme == 'blob') {
    return null;
  }
  final articleBase = articleLink == null || articleLink.trim().isEmpty
      ? null
      : Uri.tryParse(articleLink);
  final base = articleBase ?? Uri.tryParse(feedUrl);
  final resolved = uri.hasScheme ? uri : base?.resolveUri(uri);
  if (resolved == null ||
      (resolved.scheme != 'http' && resolved.scheme != 'https')) {
    return null;
  }
  return resolved.removeFragment().toString();
}

String? _cleanOptional(String? value) {
  final trimmed = value?.replaceAll(RegExp(r'\s+'), ' ').trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

int? _parseCssDimension(String? style, String property) {
  if (style == null || style.trim().isEmpty) return null;
  final match = RegExp(
    '(^|;)\\s*$property\\s*:\\s*([^;]+)',
    caseSensitive: false,
  ).firstMatch(style);
  return _parseImageDimension(match?.group(2));
}

int? _parseImageDimension(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  final match = RegExp(r'^(\d+(?:\.\d+)?)(?:px)?$').firstMatch(text);
  if (match == null) return null;
  final parsed = double.tryParse(match.group(1)!);
  if (parsed == null || parsed <= 0) return null;
  return parsed.round();
}

String? _childText(XmlElement element, List<String> names) {
  for (final child in element.childElements) {
    final qualified = child.name.qualified;
    final local = child.name.local;
    for (final name in names) {
      final expectedLocal = name.contains(':') ? name.split(':').last : name;
      if (qualified == name || local == name || local == expectedLocal) {
        final text = child.innerText.trim();
        if (text.isNotEmpty) return text;
      }
    }
  }
  return null;
}

String? _atomLink(XmlElement entry) {
  final links = entry.findElements('link').toList();
  final alternate = links.where((e) {
    final rel = e.getAttribute('rel');
    return rel == null || rel == 'alternate';
  }).firstOrNull;
  final selected = alternate ?? links.firstOrNull;
  return selected?.getAttribute('href') ?? selected?.innerText;
}
