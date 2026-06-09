/// Safe JSON extraction helpers that avoid unsafe `as` casts.
extension SafeJsonExtract on Map<String, dynamic> {
  String str(String key, {String def = ''}) {
    final v = this[key];
    if (v is String) return v;
    if (v != null) return v.toString();
    return def;
  }

  String? strOrNull(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  int integer(String key, {int def = 0}) {
    final v = this[key];
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  double floating(String key, {double def = 0.0}) {
    final v = this[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  bool boolean(String key, {bool def = false}) {
    final v = this[key];
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return v == 'true';
    return def;
  }

  List<dynamic> list(String key, {List<dynamic> def = const []}) {
    final v = this[key];
    if (v is List) return v;
    return def;
  }

  Map<String, dynamic> nested(String key, {Map<String, dynamic>? def}) {
    final v = this[key];
    if (v is Map) return v.cast<String, dynamic>();
    return def ?? <String, dynamic>{};
  }

  Map<String, dynamic>? nestedOrNull(String key) {
    final v = this[key];
    if (v is Map) return v.cast<String, dynamic>();
    return null;
  }

  List<Map<String, dynamic>> nestedList(String key) {
    return list(
      key,
    ).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
