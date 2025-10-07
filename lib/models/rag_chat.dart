import 'package:flutter/foundation.dart';

@immutable
class RagContextSnippet {
  final String content;
  final String source;
  final String? sectionTitle;
  final String? qualityTier;
  final Map<String, dynamic> metadata;

  const RagContextSnippet({
    required this.content,
    required this.source,
    this.sectionTitle,
    this.qualityTier,
    this.metadata = const {},
  });

  factory RagContextSnippet.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    final metadata = rawMetadata is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawMetadata)
        : <String, dynamic>{};

    return RagContextSnippet(
      content: json['content'] as String? ?? '',
      source: metadata['source'] as String? ?? 'Không rõ nguồn',
      sectionTitle: metadata['section_title'] as String?,
      qualityTier: metadata['quality_tier'] as String?,
      metadata: metadata,
    );
  }

  String get displayTitle {
    if (sectionTitle != null && sectionTitle!.trim().isNotEmpty) {
      return sectionTitle!;
    }
    return 'Đoạn trích từ $source';
  }
}

enum RagMessageRole { user, assistant, error }

@immutable
class RagMessage {
  final RagMessageRole role;
  final String text;
  final DateTime timestamp;
  final List<RagContextSnippet> contexts;
  final String? interactionId;

  const RagMessage._({
    required this.role,
    required this.text,
    required this.timestamp,
    this.contexts = const [],
    this.interactionId,
  });

  factory RagMessage.user(String text) {
    return RagMessage._(
      role: RagMessageRole.user,
      text: text,
      timestamp: DateTime.now(),
    );
  }

  factory RagMessage.assistant(
    String text, {
    List<RagContextSnippet> contexts = const [],
    String? interactionId,
  }) {
    return RagMessage._(
      role: RagMessageRole.assistant,
      text: text,
      contexts: contexts,
      interactionId: interactionId,
      timestamp: DateTime.now(),
    );
  }

  factory RagMessage.error(String text) {
    return RagMessage._(
      role: RagMessageRole.error,
      text: text,
      timestamp: DateTime.now(),
    );
  }

  bool get isUser => role == RagMessageRole.user;

  bool get isAssistant => role == RagMessageRole.assistant;

  bool get isError => role == RagMessageRole.error;
}

@immutable
class RagChatResponse {
  final String answer;
  final List<RagContextSnippet> contexts;
  final String? interactionId;

  const RagChatResponse({
    required this.answer,
    this.contexts = const [],
    this.interactionId,
  });

  factory RagChatResponse.fromJson(Map<String, dynamic> json) {
    final contexts = <RagContextSnippet>[];
    final rawContexts = json['contexts'];
    if (rawContexts is List) {
      for (final item in rawContexts) {
        if (item is Map<String, dynamic>) {
          contexts.add(RagContextSnippet.fromJson(item));
        }
      }
    }

    return RagChatResponse(
      answer: json['answer'] as String? ?? '',
      contexts: contexts,
      interactionId: json['interaction_id'] as String?,
    );
  }
}
