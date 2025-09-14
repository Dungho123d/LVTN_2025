class StudySet {
  final String id;
  final String title;
  final int flashcards;
  final int explanations;
  final double progress;
  final bool isCommunity;
  final bool byYou;

  const StudySet({
    required this.id,
    required this.title,
    required this.flashcards,
    required this.explanations,
    required this.progress,
    required this.isCommunity,
    required this.byYou,
  });
}
