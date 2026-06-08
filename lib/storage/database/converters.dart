import 'dart:convert';

import 'package:drift/drift.dart';

const _emptyJsonList = '[]';
const _emptyJsonMap = '{}';

final class DateTimeConverter extends TypeConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromSql(String fromDb) {
    final parsed = DateTime.tryParse(fromDb);
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  String toSql(DateTime value) => value.toUtc().toIso8601String();
}

final class NullableDateTimeConverter
    extends TypeConverter<DateTime?, String?> {
  const NullableDateTimeConverter();

  @override
  DateTime? fromSql(String? fromDb) {
    if (fromDb == null || fromDb.isEmpty) return null;
    return DateTime.tryParse(fromDb);
  }

  @override
  String? toSql(DateTime? value) =>
      value?.toUtc().toIso8601String();
}

final class JsonStringListConverter
    extends TypeConverter<List<String>, String> {
  const JsonStringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    try {
      final decoded = json.decode(fromDb);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  @override
  String toSql(List<String> value) =>
      value.isEmpty ? _emptyJsonList : json.encode(value);
}

final class JsonStringMapConverter
    extends TypeConverter<Map<String, String>, String> {
  const JsonStringMapConverter();

  @override
  Map<String, String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const {};
    try {
      final decoded = json.decode(fromDb);
      if (decoded is Map) {
        return decoded.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        );
      }
      return const {};
    } catch (_) {
      return const {};
    }
  }

  @override
  String toSql(Map<String, String> value) =>
      value.isEmpty ? _emptyJsonMap : json.encode(value);
}

final class JsonDynamicMapConverter
    extends TypeConverter<Map<String, dynamic>?, String?> {
  const JsonDynamicMapConverter();

  @override
  Map<String, dynamic>? fromSql(String? fromDb) {
    if (fromDb == null || fromDb.isEmpty) return null;
    try {
      final decoded = json.decode(fromDb);
      if (decoded is Map) {
        return decoded.map(
          (k, v) => MapEntry(k.toString(), v),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  String? toSql(Map<String, dynamic>? value) {
    if (value == null || value.isEmpty) return null;
    return json.encode(value);
  }
}

final class BoolIntConverter extends TypeConverter<bool, int> {
  const BoolIntConverter();

  @override
  bool fromSql(int fromDb) => fromDb == 1;

  @override
  int toSql(bool value) => value ? 1 : 0;
}

final class IntStringConverter extends TypeConverter<int, String> {
  const IntStringConverter();

  @override
  int fromSql(String fromDb) => int.tryParse(fromDb) ?? 0;

  @override
  String toSql(int value) => value.toString();
}

final class RssBodyBlocksConverter
    extends TypeConverter<List<Map<String, dynamic>>, String> {
  const RssBodyBlocksConverter();

  @override
  List<Map<String, dynamic>> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    try {
      final decoded = json.decode(fromDb);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  @override
  String toSql(List<Map<String, dynamic>> value) =>
      value.isEmpty ? _emptyJsonList : json.encode(value);
}

final class RssImagesConverter
    extends TypeConverter<List<Map<String, dynamic>>, String> {
  const RssImagesConverter();

  @override
  List<Map<String, dynamic>> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    try {
      final decoded = json.decode(fromDb);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  @override
  String toSql(List<Map<String, dynamic>> value) =>
      value.isEmpty ? _emptyJsonList : json.encode(value);
}
