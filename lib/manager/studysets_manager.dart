import 'package:study_application/manager/flashcard_manager.dart';
import 'package:study_application/model/study_set.dart';
import 'package:flutter/foundation.dart';

import 'explanation_manager.dart';

class StudySetManager {
  static final ValueNotifier<List<StudySet>> _studySets = ValueNotifier([
    StudySet(
      id: '1',
      title: 'Cell Biology',
      subject: 'Biology',
      description: 'Key concepts from cell membranes to organelles.',
      flashcards: List.of(FlashcardManager.demo().all),
      explanations: List.of(ExplanationManager.demoExplanations),
      progress: 0.58,
      isCommunity: false,
      byYou: true,
    ),
    StudySet(
      id: '2',
      title: 'Microbiology',
      subject: 'Medicine',
      description: 'Explore microbes and their behaviours.',
      flashcards: List.of(FlashcardManager.demo().all),
      explanations: List.of(ExplanationManager.demoExplanations),
      progress: 0.52,
      isCommunity: true,
      byYou: false,
    ),
    StudySet(
      id: '3',
      title: 'Engineering School',
      subject: 'Medicine',
      description: 'Explore microbes and their behaviours.',
      flashcards: List.of(FlashcardManager.demo().all),
      explanations: List.of(ExplanationManager.demoExplanations),
      progress: 0.41,
      isCommunity: true,
      byYou: false,
    ),
    StudySet(
      id: '4',
      title: 'Mathematics',
      subject: 'Medicine',
      description: 'Explore microbes and their behaviours.',
      flashcards: List.of(FlashcardManager.demo().all),
      explanations: List.of(ExplanationManager.demoExplanations),
      progress: 0.67,
      isCommunity: false,
      byYou: false,
    ),
  ]);

  static ValueListenable<List<StudySet>> get listenable => _studySets;

  static List<StudySet> get demoSets => List.unmodifiable(_studySets.value);

  static void addStudySet(StudySet set) {
    _studySets.value = [..._studySets.value, set];
  }

  static StudySet createStudySet({
    required String name,
    String? subject,
    String? description,
    bool isPrivate = true,
  }) {
    final StudySet newSet = StudySet(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: name,
      subject: subject,
      description: description,
      flashcards: [],
      explanations: [],
      progress: 0,
      isCommunity: !isPrivate,
      byYou: true,
    );

    addStudySet(newSet);
    return newSet;
  }
}
