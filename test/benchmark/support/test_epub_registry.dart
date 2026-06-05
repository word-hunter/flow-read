import 'dart:io';

class TestEpubFile {
  final String id;
  final String path;
  final String label;
  final List<String> tags;
  final double weight;

  const TestEpubFile({
    required this.id,
    required this.path,
    required this.label,
    this.tags = const [],
    this.weight = 1.0,
  });

  bool fileExists() => File(path).existsSync();
}

class TestEpubRegistry {
  final List<TestEpubFile> files;

  const TestEpubRegistry(this.files);

  factory TestEpubRegistry.load() {
    const dir = '.benchmark-test-files';
    final testDir = Directory(dir);
    if (!testDir.existsSync()) {
      return const TestEpubRegistry([]);
    }

    final epubFiles = testDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.epub'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    if (epubFiles.isEmpty) {
      return const TestEpubRegistry([]);
    }

    return TestEpubRegistry(
      epubFiles.map((f) {
        final name = f.uri.pathSegments.last.replaceAll('.epub', '');
        final id = _sanitizeId(name);
        final sizeMb = f.lengthSync() / (1024 * 1024);
        final tags = <String>[];
        double weight = 1.0;

        if (sizeMb > 10) {
          tags.addAll(['large', 'multi-book']);
          weight = 2.0;
        } else if (sizeMb > 2) {
          tags.add('medium');
          weight = 1.0;
        } else {
          tags.add('small');
          weight = 0.5;
        }

        return TestEpubFile(
          id: id,
          path: f.path,
          label: name,
          tags: tags,
          weight: weight,
        );
      }).toList(),
    );
  }

  static String _sanitizeId(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  List<TestEpubFile> get presentFiles {
    return files.where((f) => f.fileExists()).toList();
  }

  List<TestEpubFile> filterByTags(List<String> tags) {
    if (tags.isEmpty) return files;
    return files
        .where((f) => tags.every((t) => f.tags.contains(t)))
        .toList();
  }
}
