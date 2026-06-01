import 'package:hive/hive.dart';

@HiveType(typeId: 10)
class RssFeedSubscription extends HiveObject {
  @HiveField(0)
  final String url;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String? imageUrl;

  @HiveField(4)
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

class RssFeedSubscriptionAdapter extends TypeAdapter<RssFeedSubscription> {
  @override
  final int typeId = 10;

  @override
  RssFeedSubscription read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RssFeedSubscription(
      url: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      imageUrl: fields[3] as String?,
      lastFetchedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, RssFeedSubscription obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.lastFetchedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RssFeedSubscriptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
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
      id: id ?? this.id,
    );
  }
}

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
