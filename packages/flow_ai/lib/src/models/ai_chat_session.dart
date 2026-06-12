import '../prompt_builder.dart' show AIContextScope;
import 'ai_assistant_action.dart';
import 'ai_context_snapshot.dart';

enum AIChatMessageRole { user, assistant }

class AIAssistantCitation {
  const AIAssistantCitation({
    required this.sourceType,
    required this.label,
    this.bookId,
    this.chapterIndex,
    this.paragraphIndex,
    this.startOffset,
    this.endOffset,
    this.quote,
  });

  final String sourceType;
  final String label;
  final String? bookId;
  final int? chapterIndex;
  final int? paragraphIndex;
  final int? startOffset;
  final int? endOffset;
  final String? quote;
}

class AIChatMessage {
  const AIChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.actionType,
    this.scope,
    this.citations = const [],
  });

  final String id;
  final AIChatMessageRole role;
  final String content;
  final DateTime createdAt;
  final AIAssistantActionType? actionType;
  final AIContextScope? scope;
  final List<AIAssistantCitation> citations;
}

class AIAssistantSession {
  const AIAssistantSession({
    required this.id,
    required this.title,
    required this.scope,
    required this.anchor,
    required this.createdAt,
    required this.updatedAt,
    this.bookId,
    this.chapterIndex,
    this.messages = const [],
  });

  final String id;
  final String? bookId;
  final int? chapterIndex;
  final String title;
  final AIContextScope scope;
  final AIContextSnapshot anchor;
  final List<AIChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  AIAssistantSession copyWith({
    String? title,
    AIContextScope? scope,
    AIContextSnapshot? anchor,
    List<AIChatMessage>? messages,
    DateTime? updatedAt,
  }) {
    return AIAssistantSession(
      id: id,
      bookId: bookId,
      chapterIndex: chapterIndex,
      title: title ?? this.title,
      scope: scope ?? this.scope,
      anchor: anchor ?? this.anchor,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
