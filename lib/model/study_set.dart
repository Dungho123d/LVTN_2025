import 'package:pocketbase/pocketbase.dart';
import 'package:study_application/model/explanation.dart';
import 'package:study_application/model/flashcard.dart';

class StudySet {
  final String id;
  final String title;
  final String? subject;
  final String? description;
  final List<Flashcard> flashcards;
  final List<Explanation> explanations;
  final double progress;
  final bool isCommunity;
  final bool byYou;

  const StudySet({
    required this.id,
    required this.title,
    this.subject,
    this.description,
    required this.flashcards,
    required this.explanations,
    required this.progress,
    required this.isCommunity,
    required this.byYou,
  });

  int get explanationCount => explanations.length;
  int get flashcardCount => flashcards.length;

  StudySet copyWith({
    String? id,
    String? title,
    String? subject,
    String? description,
    List<Flashcard>? flashcards,
    List<Explanation>? explanations,
    double? progress,
    bool? isCommunity,
    bool? byYou,
  }) {
    return StudySet(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      flashcards: flashcards ?? this.flashcards,
      explanations: explanations ?? this.explanations,
      progress: progress ?? this.progress,
      isCommunity: isCommunity ?? this.isCommunity,
      byYou: byYou ?? this.byYou,
    );
  }

  factory StudySet.fromJson(
    Map<String, dynamic> json, {
    List<Flashcard>? flashcards,
    List<Explanation>? explanations,
  }) {
    final rawFlashcards = flashcards ??
        (json['flashcards'] is List
            ? (json['flashcards'] as List)
                .whereType<Map<String, dynamic>>()
                .map(Flashcard.fromJson)
                .toList()
            : <Flashcard>[]);
    final rawExplanations = explanations ??
        (json['explanations'] is List
            ? (json['explanations'] as List)
                .whereType<Map<String, dynamic>>()
                .map(Explanation.fromJson)
                .toList()
            : <Explanation>[]);

    return StudySet(
      id: (json['id'] ?? json['@id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      subject: (json['subject'] ?? json['category'])?.toString(),
      description: json['description']?.toString(),
      flashcards: rawFlashcards,
      explanations: rawExplanations,
      progress: _parseDouble(json['progress']) ?? 0,
      isCommunity: _parseBool(json['isCommunity']) ??
          _parseBool(json['is_public']) ??
          false,
      byYou: _parseBool(json['byYou']) ??
          _parseBool(json['by_you']) ??
          false,
    );
  }

  factory StudySet.fromRecord(
    RecordModel record, {
    List<Flashcard>? flashcards,
    List<Explanation>? explanations,
  }) {
    final data = record.toJson();
    return StudySet.fromJson(
      data,
      flashcards: flashcards ??
          _parseExpandedList<Flashcard>(
            record,
            'flashcards',
            Flashcard.fromRecord,
          ),
      explanations: explanations ??
          _parseExpandedList<Explanation>(
            record,
            'explanations',
            Explanation.fromRecord,
          ),
    );
  }

  Map<String, dynamic> toJson({bool includeRelations = false}) {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'subject': subject,
      'description': description,
      'progress': progress,
      'isCommunity': isCommunity,
      'byYou': byYou,
    };

    if (includeRelations) {
      map['flashcards'] = flashcards.map((e) => e.toJson()).toList();
      map['explanations'] = explanations.map((e) => e.toJson()).toList();
    }

    map.removeWhere((_, value) => value == null);
    return map;
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return null;
  }

  static List<T> _parseExpandedList<T>(
    RecordModel record,
    String field,
    T Function(RecordModel) fromRecord,
  ) {
    final expand = record.expand;
    if (expand == null || !expand.containsKey(field)) {
      return const [];
    }

    final entries = expand[field];
    if (entries is List) {
      return entries
          .whereType<RecordModel>()
          .map(fromRecord)
          .toList(growable: false);
    }
    if (entries is RecordModel) {
      return <T>[fromRecord(entries)];
    }
    return const [];
  }
}
