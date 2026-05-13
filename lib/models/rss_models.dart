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
  final String title;
  final String? link;
  final String? description;
  final DateTime? pubDate;
  final String? author;
  bool isRead;
  final String id;

  RssArticle({
    required this.feedUrl,
    required this.title,
    this.link,
    this.description,
    this.pubDate,
    this.author,
    this.isRead = false,
    String? id,
  }) : id =
           id ??
           '${feedUrl.hashCode}_${title.hashCode}_${pubDate?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';

  RssArticle copyWith({
    String? feedUrl,
    String? title,
    String? link,
    String? description,
    DateTime? pubDate,
    String? author,
    bool? isRead,
    String? id,
  }) {
    return RssArticle(
      feedUrl: feedUrl ?? this.feedUrl,
      title: title ?? this.title,
      link: link ?? this.link,
      description: description ?? this.description,
      pubDate: pubDate ?? this.pubDate,
      author: author ?? this.author,
      isRead: isRead ?? this.isRead,
      id: id ?? this.id,
    );
  }
}
