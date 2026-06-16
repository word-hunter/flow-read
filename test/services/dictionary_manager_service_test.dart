import 'dart:async';

import 'package:flow_dictionary/flow_dictionary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses local WordNet fallback when an online source times out', () async {
    final service = DictionaryManagerService(
      configs: [
        DictionarySourceConfig(
          type: DictionarySourceType.collins,
          enabled: true,
          priority: 0,
          supportedLanguages: {'en'},
        ),
        DictionarySourceConfig(
          type: DictionarySourceType.wordNet,
          enabled: true,
          priority: 1,
          supportedLanguages: {'en'},
        ),
      ],
      sources: const [
        DictionarySourceAdapter(
          type: DictionarySourceType.collins,
          repository: _HangingRepository(),
        ),
        DictionarySourceAdapter(
          type: DictionarySourceType.wordNet,
          repository: _LocalRepository(),
        ),
      ],
      sourceTimeout: Duration(milliseconds: 1),
    );

    final entry = await service.lookup('flow');

    expect(entry, isNotNull);
    expect(entry!.sourceName, 'WordNet');
    expect(entry.meanings.single.definitions.single, 'local definition');
    expect(entry.errorMessage, contains('在线词典请求失败'));
    expect(entry.errorMessage, contains('Collins: 请求超时'));
  });
}

class _HangingRepository implements WordRepository {
  const _HangingRepository();

  @override
  Future<DictionaryEntry?> lookup(
    String word, {
    String languageCode = 'en',
  }) {
    return Completer<DictionaryEntry?>().future;
  }
}

class _LocalRepository implements WordRepository {
  const _LocalRepository();

  @override
  Future<DictionaryEntry?> lookup(
    String word, {
    String languageCode = 'en',
  }) async {
    return DictionaryEntry(
      word: word,
      meanings: const [
        Meaning(partOfSpeech: 'n.', definitions: ['local definition']),
      ],
    );
  }
}
