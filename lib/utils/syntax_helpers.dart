import 'package:flutter/material.dart';

class SyntaxHelpers {
  static IconData typeIcon(String type) {
    switch (type) {
      case 'relative_clause':
        return Icons.account_tree;
      case 'embedded_clause':
        return Icons.layers;
      case 'parenthetical':
        return Icons.format_quote;
      case 'long_sentence':
        return Icons.wrap_text;
      default:
        return Icons.text_fields;
    }
  }

  static String typeLabel(String type) {
    switch (type) {
      case 'relative_clause':
        return '关系从句';
      case 'embedded_clause':
        return '嵌套从句';
      case 'parenthetical':
        return '插入语';
      case 'long_sentence':
        return '长难句';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  static IconData practiceTypeIcon(String type) {
    switch (type) {
      case 'inference':
        return Icons.lightbulb_outline;
      case 'vocabulary_in_context':
        return Icons.translate;
      case 'sentence_structure':
        return Icons.account_tree_outlined;
      case 'paraphrasing':
        return Icons.edit_note;
      default:
        return Icons.quiz_outlined;
    }
  }

  static String practiceTypeLabel(String type) {
    switch (type) {
      case 'inference':
        return 'Inference';
      case 'vocabulary_in_context':
        return 'Vocabulary in Context';
      case 'sentence_structure':
        return 'Sentence Structure';
      case 'paraphrasing':
        return 'Paraphrasing';
      default:
        return type.replaceAll('_', ' ');
    }
  }
}
