import 'package:study_application/models/explanation.dart';
import 'package:study_application/models/flashcard.dart';

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
}
