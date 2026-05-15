class WordContextExample {
  final String word;
  final String text;
  final String title;
  final String url;
  final String favicon;
  final DateTime? createdAt;

  const WordContextExample({
    required this.word,
    required this.text,
    this.title = '',
    this.url = '',
    this.favicon = '',
    this.createdAt,
  });

  factory WordContextExample.fromJson(Map<String, dynamic> json) {
    return WordContextExample(
      word: json['word'] as String? ?? '',
      text: json['text'] as String? ?? '',
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      favicon: json['favicon'] as String? ?? '',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'text': text,
    'title': title,
    'url': url,
    'favicon': favicon,
    'createdAt': createdAt?.toIso8601String(),
  };
}
