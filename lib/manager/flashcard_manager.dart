import 'package:flutter/foundation.dart';

import '../model/flashcard.dart';
import '../services/pocketbase_service.dart';
import 'studysets_manager.dart';

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
  FlashcardManager._(this._service);

  final PocketBaseService _service;
  final ValueNotifier<List<Flashcard>> _all = ValueNotifier(const []);
  final ValueNotifier<bool> _isLoadingAll = ValueNotifier(false);
  final ValueNotifier<String?> _errorAll = ValueNotifier(null);
  final Map<String, Flashcard> _byId = {};
  final Map<String, List<Flashcard>> _byStudySet = {};
  final Map<String, ValueNotifier<List<Flashcard>>> _notifiersBySet = {};
  final Map<String, ValueNotifier<bool>> _loadingBySet = {};
  final Map<String, ValueNotifier<String?>> _errorBySet = {};
  bool _hasLoadedAll = false;

  static final FlashcardManager instance =
      FlashcardManager._(PocketBaseService.instance);

  static ValueListenable<List<Flashcard>> get listenableAll => instance._all;
  static ValueListenable<bool> get loadingAll => instance._isLoadingAll;
  static ValueListenable<String?> get errorAll => instance._errorAll;

  static ValueListenable<List<Flashcard>> listenableForSet(String studySetId) =>
      instance._listenableForSet(studySetId);

  static ValueListenable<bool> loadingForSet(String studySetId) =>
      instance._loadingNotifier(studySetId);

  static ValueListenable<String?> errorForSet(String studySetId) =>
      instance._errorNotifier(studySetId);

  static Future<void> loadAll({bool force = false}) =>
      instance.loadAll(force: force);

  static Future<void> loadForStudySet(String studySetId, {bool force = false}) =>
      instance.loadForStudySet(studySetId, force: force);

  static Future<Flashcard> create({
    required String term,
    required String definition,
    required String studySetId,
    String? termImage,
    String? defImage,
  }) =>
      instance.create(
        term: term,
        definition: definition,
        studySetId: studySetId,
        termImage: termImage,
        defImage: defImage,
      );

  static Future<List<Flashcard>> createMany(List<FlashcardCreate> inputs) =>
      instance.createMany(inputs);

  static Future<Flashcard?> update(String id, Flashcard updated) =>
      instance.update(id, updated);

  static Future<void> remove(String id) => instance.remove(id);

  static void clearCache([String? studySetId]) =>
      instance.clearLocalCache(studySetId);

  ValueListenable<List<Flashcard>> _listenableForSet(String studySetId) {
    return _notifiersBySet.putIfAbsent(
      studySetId,
      () => ValueNotifier(const []),
    );
  }

  ValueNotifier<bool> _loadingNotifier(String studySetId) {
    return _loadingBySet.putIfAbsent(
      studySetId,
      () => ValueNotifier(false),
    );
  }

  ValueNotifier<String?> _errorNotifier(String studySetId) {
    return _errorBySet.putIfAbsent(
      studySetId,
      () => ValueNotifier(null),
    );
  }

  Future<void> loadAll({bool force = false}) async {
    if (_isLoadingAll.value) return;
    if (_hasLoadedAll && !force) return;

    _isLoadingAll.value = true;
    _errorAll.value = null;

    try {
      final records = await _service.fetchFlashcards();
      _byId.clear();
      _byStudySet.clear();
      for (final record in records) {
        final card = Flashcard.fromRecord(record);
        _byId[card.id] = card;
        final studySetId = card.studySetId;
        if (studySetId != null) {
          final list = _byStudySet.putIfAbsent(studySetId, () => []);
          list.add(card);
        }
      }
      for (final entry in _byStudySet.entries) {
        _notifyStudySet(entry.key);
      }
      _syncAll();
      _hasLoadedAll = true;
    } on PocketBaseServiceException catch (error) {
      _errorAll.value = error.message;
    } catch (error) {
      _errorAll.value = 'Failed to load flashcards: $error';
    } finally {
      _isLoadingAll.value = false;
    }
  }

  Future<void> loadForStudySet(String studySetId, {bool force = false}) async {
    final loading = _loadingNotifier(studySetId);
    if (loading.value) return;
    if (!force && _byStudySet.containsKey(studySetId)) return;

    loading.value = true;
    final error = _errorNotifier(studySetId);
    error.value = null;

    try {
      final records = await _service.fetchFlashcards(
        filter: 'studySet="$studySetId"',
      );
      final list = <Flashcard>[];
      for (final record in records) {
        final card = Flashcard.fromRecord(record);
        _byId[card.id] = card;
        list.add(card);
      }
      _byStudySet[studySetId] = list;
      _notifyStudySet(studySetId);
      _syncAll();
    } on PocketBaseServiceException catch (pbError) {
      error.value = pbError.message;
    } catch (pbError) {
      error.value = 'Failed to load flashcards: $pbError';
    } finally {
      loading.value = false;
    }
  }

  Future<Flashcard> create({
    required String term,
    required String definition,
    required String studySetId,
    String? termImage,
    String? defImage,
  }) async {
    if (studySetId.isEmpty) {
      throw const PocketBaseServiceException(
        'A study set id is required to create a flashcard.',
      );
    }

    try {
      final record = await _service.createFlashcard({
        'term': term,
        'definition': definition,
        'termImage': termImage,
        'defImage': defImage,
        'studySet': studySetId,
      });
      final card = Flashcard.fromRecord(record);
      _byId[card.id] = card;
      final list = _byStudySet.putIfAbsent(studySetId, () => []);
      list.removeWhere((c) => c.id == card.id);
      list.add(card);
      _notifyStudySet(studySetId);
      _syncAll();
      return card;
    } on PocketBaseServiceException catch (error) {
      _errorAll.value = error.message;
      rethrow;
    } catch (error) {
      final message = 'Failed to create flashcard: $error';
      _errorAll.value = message;
      throw PocketBaseServiceException(message, error: error);
    }
  }

  Future<List<Flashcard>> createMany(List<FlashcardCreate> inputs) async {
    final created = <Flashcard>[];
    for (final input in inputs) {
      final studySetId = input.studySetId;
      if (studySetId == null || studySetId.isEmpty) {
        throw const PocketBaseServiceException(
          'Each flashcard must reference a study set.',
        );
      }
      created.add(
        await create(
          term: input.term,
          definition: input.definition,
          studySetId: studySetId,
          termImage: input.termImage,
          defImage: input.defImage,
        ),
      );
    }
    return created;
  }

  Future<Flashcard?> update(String id, Flashcard updated) async {
    final existing = _byId[id];
    final previousStudySet = existing?.studySetId;
    try {
      final record = await _service.updateFlashcard(id, updated.toJson());
      final card = Flashcard.fromRecord(record);
      _byId[id] = card;
      if (previousStudySet != null && previousStudySet != card.studySetId) {
        _removeFromStudySet(previousStudySet, id);
      }
      if (card.studySetId != null) {
        final list = _byStudySet.putIfAbsent(card.studySetId!, () => []);
        list.removeWhere((c) => c.id == card.id);
        list.add(card);
        _notifyStudySet(card.studySetId!);
      }
      _syncAll();
      return card;
    } on PocketBaseServiceException catch (error) {
      _errorAll.value = error.message;
      rethrow;
    } catch (error) {
      final message = 'Failed to update flashcard: $error';
      _errorAll.value = message;
      throw PocketBaseServiceException(message, error: error);
    }
  }

  Future<void> remove(String id) async {
    final existing = _byId[id];
    final studySetId = existing?.studySetId;
    try {
      await _service.deleteFlashcard(id);
      _byId.remove(id);
      _removeFromStudySet(studySetId, id);
      _syncAll();
    } on PocketBaseServiceException catch (error) {
      _errorAll.value = error.message;
      rethrow;
    } catch (error) {
      final message = 'Failed to delete flashcard: $error';
      _errorAll.value = message;
      throw PocketBaseServiceException(message, error: error);
    }
  }

  void clearLocalCache([String? studySetId]) {
    if (studySetId == null) {
      _byId.clear();
      _byStudySet.clear();
      _all.value = const [];
      for (final notifier in _notifiersBySet.values) {
        notifier.value = const [];
      }
      notifyListeners();
    } else {
      _byStudySet.remove(studySetId);
      _notifyStudySet(studySetId);
    }
  }

  void _removeFromStudySet(String? studySetId, String id) {
    if (studySetId == null) return;
    final list = _byStudySet[studySetId];
    if (list == null) return;
    list.removeWhere((card) => card.id == id);
    _notifyStudySet(studySetId);
  }

  void _notifyStudySet(String studySetId) {
    final notifier = _notifiersBySet.putIfAbsent(
      studySetId,
      () => ValueNotifier(const []),
    );
    final list = List<Flashcard>.unmodifiable(_byStudySet[studySetId] ?? const []);
    notifier.value = list;
    StudySetManager.patchFlashcards(studySetId, list);
  }

  void _syncAll() {
    _all.value = List.unmodifiable(_byId.values);
    notifyListeners();
  }
}
