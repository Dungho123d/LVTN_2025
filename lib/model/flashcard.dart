import 'package:pocketbase/pocketbase.dart';

/// Flashcard model
class Flashcard {
  final String id;
  String term;
  String definition;
  String? termImage;
  String? defImage;
  String? studySetId;

  Flashcard({
    required this.id,
    required this.term,
    required this.definition,
    this.termImage,
    this.defImage,
    this.studySetId,
  });

  Flashcard copyWith({
    String? id,
    String? term,
    String? definition,
    String? termImage,
    String? defImage,
    String? studySetId,
  }) {
    return Flashcard(
      id: id ?? this.id,
      term: term ?? this.term,
      definition: definition ?? this.definition,
      termImage: termImage ?? this.termImage,
      defImage: defImage ?? this.defImage,
      studySetId: studySetId ?? this.studySetId,
    );
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: (json['id'] ?? json['@id'] ?? '').toString(),
      term: (json['term'] ?? json['front'] ?? '').toString(),
      definition: (json['definition'] ?? json['back'] ?? '').toString(),
      termImage: json['termImage']?.toString(),
      defImage: json['defImage']?.toString(),
      studySetId: json['studySet']?.toString() ?? json['studySetId']?.toString(),
    );
  }

  factory Flashcard.fromRecord(RecordModel record) {
    return Flashcard.fromJson(record.toJson());
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'term': term,
      'definition': definition,
      'termImage': termImage,
      'defImage': defImage,
      'studySet': studySetId,
      'studySetId': studySetId,
    };
    map.removeWhere((_, value) => value == null);
    return map;
  }

  @override
  String toString() =>
      "Flashcard(id: $id, term: $term, definition: $definition)";
}
