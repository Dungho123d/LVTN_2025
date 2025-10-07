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

  @override
  String toString() =>
      "Flashcard(id: $id, term: $term, definition: $definition)";
}
