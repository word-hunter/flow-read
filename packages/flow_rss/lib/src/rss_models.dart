enum RssLoadStatus { idle, loading, loaded, empty, error }

enum RssErrorType { network, parse, empty, unknown }

class RssError {
  final RssErrorType type;
  final String message;
  final String? detail;

  const RssError({required this.type, required this.message, this.detail});
}

class RssFeedSubscription {
  final String url;

  String title;

  String? description;

  String? imageUrl;

  DateTime? lastFetchedAt;

  RssFeedSubscription({
    required this.url,
    this.title = '',
    this.description,
    this.imageUrl,
    this.lastFetchedAt,
  });

  RssFeedSubscription copyWith({
    String? url,
    String? title,
    String? description,
    String? imageUrl,
    DateTime? lastFetchedAt,
  }) {
    return RssFeedSubscription(
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    );
  }
}

class RssArticle {
  final String feedUrl;
  final String feedTitle;
  final String title;
  final String? link;
  final String? description;
  final String? content;
  final List<RssArticleBodyBlock> bodyBlocks;
  final List<RssArticleImage> images;
  final DateTime? pubDate;
  final String? author;
  bool isRead;
  bool isFavorite;
  bool isReadLater;
  final String id;

  RssArticle({
    required this.feedUrl,
    this.feedTitle = '',
    required this.title,
    this.link,
    this.description,
    this.content,
    this.bodyBlocks = const [],
    this.images = const [],
    this.pubDate,
    this.author,
    this.isRead = false,
    this.isFavorite = false,
    this.isReadLater = false,
    String? id,
  }) : id =
           id ??
           '${feedUrl.hashCode}_${(link ?? title).hashCode}_${pubDate?.millisecondsSinceEpoch ?? 0}';

  RssArticle copyWith({
    String? feedUrl,
    String? feedTitle,
    String? title,
    String? link,
    String? description,
    String? content,
    List<RssArticleBodyBlock>? bodyBlocks,
    List<RssArticleImage>? images,
    DateTime? pubDate,
    String? author,
    bool? isRead,
    bool? isFavorite,
    bool? isReadLater,
    String? id,
  }) {
    return RssArticle(
      feedUrl: feedUrl ?? this.feedUrl,
      feedTitle: feedTitle ?? this.feedTitle,
      title: title ?? this.title,
      link: link ?? this.link,
      description: description ?? this.description,
      content: content ?? this.content,
      bodyBlocks: bodyBlocks ?? this.bodyBlocks,
      images: images ?? this.images,
      pubDate: pubDate ?? this.pubDate,
      author: author ?? this.author,
      isRead: isRead ?? this.isRead,
      isFavorite: isFavorite ?? this.isFavorite,
      isReadLater: isReadLater ?? this.isReadLater,
      id: id ?? this.id,
    );
  }
}

enum RssArticleFilter { all, unread, favorite, readLater }

enum RssArticleTextBlockType { paragraph, heading, listItem, blockquote }

sealed class RssArticleBodyBlock {
  const RssArticleBodyBlock();
}

class RssArticleTextBlock extends RssArticleBodyBlock {
  final RssArticleTextBlockType type;
  final String text;
  final int headingLevel;
  final int indent;

  const RssArticleTextBlock({
    required this.type,
    required this.text,
    this.headingLevel = 0,
    this.indent = 0,
  });
}

class RssArticleImageBlock extends RssArticleBodyBlock {
  final RssArticleImage image;

  const RssArticleImageBlock(this.image);
}

class RssArticleImage {
  final String url;
  final String? alt;
  final int? width;
  final int? height;

  const RssArticleImage({required this.url, this.alt, this.width, this.height});

  double? get aspectRatio {
    final imageWidth = width;
    final imageHeight = height;
    if (imageWidth == null || imageHeight == null || imageHeight <= 0) {
      return null;
    }
    return imageWidth / imageHeight;
  }
}
