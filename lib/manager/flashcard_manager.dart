// lib/data/flashcard_manager.dart
import 'package:flutter/foundation.dart';
import 'package:study_application/model/flashcard.dart';

/// DTO gọn để tạo flashcard mới (không cần truyền id)
class FlashcardCreate {
  final String term;
  final String definition;
  final String? termImage;
  final String? defImage;
  final String? studySetId;

  const FlashcardCreate({
    required this.term,
    required this.definition,
    this.termImage,
    this.defImage,
    this.studySetId,
  });
}

class FlashcardManager extends ChangeNotifier {
  final List<Flashcard> _flashcards = [];

  List<Flashcard> get all => List.unmodifiable(_flashcards);

  String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

  // ----------------- CRUD -----------------

  /// Tạo 1 flashcard mới
  Flashcard create({
    required String term,
    required String definition,
    String? termImage,
    String? defImage,
    String? studySetId,
  }) {
    final card = Flashcard(
      id: _genId(),
      term: term,
      definition: definition,
      termImage: termImage,
      defImage: defImage,
      studySetId: studySetId,
    );
    _flashcards.add(card);
    notifyListeners();
    return card;
  }

  List<Flashcard> createMany(List<FlashcardCreate> inputs) {
    final created = <Flashcard>[];
    for (final i in inputs) {
      created.add(create(
        term: i.term,
        definition: i.definition,
        termImage: i.termImage,
        defImage: i.defImage,
        studySetId: i.studySetId,
      ));
    }
    return created;
  }

  void add(Flashcard card) {
    _flashcards.add(card);
    notifyListeners();
  }

  /// Cập nhật 1 thẻ theo id
  void update(String id, Flashcard newCard) {
    final index = _flashcards.indexWhere((c) => c.id == id);
    if (index != -1) {
      _flashcards[index] = newCard;
      notifyListeners();
    }
  }

  /// Xoá theo id
  void remove(String id) {
    _flashcards.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// Gắn một flashcard vào study set
  void attachToStudySet({
    required String cardId,
    required String studySetId,
  }) {
    final index = _flashcards.indexWhere((c) => c.id == cardId);
    if (index == -1) return;
    final card = _flashcards[index];
    if (card.studySetId == studySetId) return;
    _flashcards[index] = card.copyWith(studySetId: studySetId);
    notifyListeners();
  }

  /// Bỏ gắn kết flashcard khỏi study set
  void detachFromStudySet(String cardId) {
    final index = _flashcards.indexWhere((c) => c.id == cardId);
    if (index == -1) return;
    final card = _flashcards[index];
    if (card.studySetId == null) return;
    _flashcards[index] = card.copyWith(studySetId: null);
    notifyListeners();
  }

  /// Xoá tất cả
  void clear() {
    _flashcards.clear();
    notifyListeners();
  }

  // ----------------- DEMO -----------------
  static FlashcardManager demo() {
    final m = FlashcardManager();
    m.create(term: 'Mitochondria', definition: 'The powerhouse of the cell.');
    m.create(
      term: 'Cell Membrane',
      definition: 'Controls what enters and exits the cell.',
      studySetId: '1',
    );
    return m;
  }
}
