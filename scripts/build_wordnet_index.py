#!/usr/bin/env python3
"""
Build compact per-letter word→definitions JSON index files from English WordNet 2025 data.

Input:  english-wordnet-2025-json/ (entries-*.json + POS files)
Output: assets/wordnet/wordnet_a.json ... wordnet_z.json

Each output file maps lowercase words to their definitions:
{
  "abandon": [
    {"pos": "n", "def": "the trait of lacking restraint...", "example": "she danced with abandon"},
    {"pos": "v", "def": "forsake, leave behind", "example": "we abandoned the old car"}
  ]
}
"""

import json
import os
import sys
from collections import defaultdict


def load_synsets(wn_path):
    """Load all synset definition files into a single dict."""
    synsets = {}
    pos_files = [f for f in os.listdir(wn_path)
                 if f.endswith('.json')
                 and not f.startswith('entries')
                 and f != 'frames.json']

    for fname in pos_files:
        with open(os.path.join(wn_path, fname), 'r', encoding='utf-8') as f:
            data = json.load(f)
        for synset_id, entry in data.items():
            synsets[synset_id] = {
                'def': entry.get('definition', []),
                'example': entry.get('example', []),
                'pos': entry.get('partOfSpeech', ''),
            }

    print(f"  Loaded {len(synsets)} synsets from {len(pos_files)} POS files")
    return synsets


def build_index(wn_path, output_dir):
    """Build per-letter word→definitions index files."""
    synsets = load_synsets(wn_path)
    os.makedirs(output_dir, exist_ok=True)

    entries_files = sorted(
        f for f in os.listdir(wn_path)
        if f.startswith('entries-') and f.endswith('.json')
    )

    # Group words by first letter
    letter_words = defaultdict(dict)

    total_words = 0
    total_senses = 0
    missing_synsets = 0

    for efname in entries_files:
        print(f"  Processing {efname}...")
        with open(os.path.join(wn_path, efname), 'r', encoding='utf-8') as f:
            entries = json.load(f)

        for word, word_entry in entries.items():
            lower = word.lower()
            first_letter = lower[0] if lower else '_'
            if not first_letter.isalpha():
                first_letter = '0'

            meanings = []

            for pos_key, pos_data in word_entry.items():
                # Normalize POS: n-1, n-2 → n; a → a; v → v; r → r; s → a
                base_pos = pos_key[0] if pos_key else pos_key
                if base_pos not in ('n', 'v', 'a', 'r'):
                    continue

                pos_label = {'n': 'noun', 'v': 'verb', 'a': 'adj', 'r': 'adv'}[base_pos]

                senses = pos_data.get('sense', [])
                for sense in senses:
                    synset_id = sense.get('synset')
                    if not synset_id:
                        continue

                    synset = synsets.get(synset_id)
                    if not synset:
                        missing_synsets += 1
                        continue

                    def_text = synset['def']
                    example_text = synset['example']

                    if not def_text:
                        continue

                    meaning = {
                        'pos': pos_label,
                        'def': def_text[0] if def_text else '',
                        'example': example_text[0] if example_text else '',
                    }
                    meanings.append(meaning)
                    total_senses += 1

            if meanings:
                letter_words[first_letter][lower] = meanings
                total_words += 1

    print(f"  Total words with definitions: {total_words}")
    print(f"  Total senses: {total_senses}")
    if missing_synsets:
        print(f"  Missing synset references: {missing_synsets}")

    # Write per-letter files
    for letter in sorted(letter_words.keys()):
        out_path = os.path.join(output_dir, f'wordnet_{letter}.json')
        with open(out_path, 'w', encoding='utf-8') as f:
            json.dump(letter_words[letter], f, ensure_ascii=False, separators=(',', ':'))
        size_kb = os.path.getsize(out_path) / 1024
        print(f"  Wrote {out_path} ({len(letter_words[letter])} words, {size_kb:.0f} KB)")


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    wn_path = os.path.join(project_root, 'english-wordnet-2025-json')
    output_dir = os.path.join(project_root, 'assets', 'wordnet')

    if not os.path.isdir(wn_path):
        print(f"Error: WordNet data not found at {wn_path}", file=sys.stderr)
        sys.exit(1)

    print(f"Building WordNet index from {wn_path}")
    print(f"Output directory: {output_dir}")
    build_index(wn_path, output_dir)
    print("Done.")


if __name__ == '__main__':
    main()
