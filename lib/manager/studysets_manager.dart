import 'package:study_application/model/study_set.dart';

class StudySetManager {
  static final demoSets = <StudySet>[
    StudySet(
      id: '1',
      title: 'Cell Biology',
      flashcards: 45,
      explanations: 12,
      progress: 0.58,
      isCommunity: false,
      byYou: true,
    ),
    StudySet(
      id: '2',
      title: 'Microbiology',
      flashcards: 246,
      explanations: 195,
      progress: 0.52,
      isCommunity: true,
      byYou: false,
    ),
  ];
}
