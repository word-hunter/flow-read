// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rss_dao.dart';

// ignore_for_file: type=lint
mixin _$RssDaoMixin on DatabaseAccessor<AppDatabase> {
  $RssSubscriptionsTable get rssSubscriptions =>
      attachedDatabase.rssSubscriptions;
  $RssArticlesTable get rssArticles => attachedDatabase.rssArticles;
  RssDaoManager get managers => RssDaoManager(this);
}

class RssDaoManager {
  final _$RssDaoMixin _db;
  RssDaoManager(this._db);
  $$RssSubscriptionsTableTableManager get rssSubscriptions =>
      $$RssSubscriptionsTableTableManager(
        _db.attachedDatabase,
        _db.rssSubscriptions,
      );
  $$RssArticlesTableTableManager get rssArticles =>
      $$RssArticlesTableTableManager(_db.attachedDatabase, _db.rssArticles);
}
