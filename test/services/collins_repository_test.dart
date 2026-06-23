import 'package:flow_dictionary/flow_dictionary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses only the primary Collins entry from a multi-entry page', () {
    final repository = CollinsRepository(
      DictionaryCacheService(repository: _MemoryDictionaryCacheRepository()),
    );

    final entry = repository.parseHtml('sleepyhead', '''
      <div id="main_content">
        <div class="res_cell_center">
          <div class="cB">
            <div class="hom">
              <span class="pron">BR-pron</span>
              <span class="gramGrp"><span class="pos">noun</span></span>
              <div class="sense">
                <span class="def">a sleepy or lazy person</span>
              </div>
            </div>
          </div>
          <div class="cB">
            <div class="hom">
              <span class="pron">US-pron</span>
              <span class="gramGrp"><span class="pos">noun</span></span>
              <div class="sense">
                <span class="def">a sleepy person [an affectionate or playful use]</span>
              </div>
            </div>
          </div>
          <div class="cB">
            <div class="hom">
              <span class="pron">OTHER-pron</span>
              <span class="gramGrp"><span class="pos">noun</span></span>
              <div class="sense">
                <span class="def">a sleepy person</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    ''');

    expect(entry, isNotNull);
    expect(entry!.phonetic, 'BR-pron');
    expect(entry.meanings, hasLength(1));
    expect(entry.meanings.single.partOfSpeech, 'noun');
    expect(entry.meanings.single.definitions, ['a sleepy or lazy person']);
  });
}

class _MemoryDictionaryCacheRepository implements DictionaryCacheRepository {
  final Map<String, String> _items = {};

  @override
  Future<void> init() async {}

  @override
  String? get(String key) => _items[key];

  @override
  Future<void> put(String key, String content) async {
    _items[key] = content;
  }

  @override
  bool containsKey(String key) => _items.containsKey(key);

  @override
  int get length => _items.length;

  @override
  Iterable<dynamic> get keys => _items.keys;

  @override
  Future<void> delete(dynamic key) async {
    _items.remove(key);
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }

  @override
  Future<void> close() async {}
}
