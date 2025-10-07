import 'package:flutter/foundation.dart';

import '../model/explanation.dart';
import '../model/flashcard.dart';
import '../model/study_set.dart';
import '../services/pocketbase_service.dart';

class StudySetManager {
  StudySetManager._(this._service);

  final PocketBaseService _service;
  final ValueNotifier<List<StudySet>> _studySets = ValueNotifier(const []);
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<String?> _error = ValueNotifier(null);
  final Map<String, StudySet> _cache = {};
  bool _hasLoaded = false;
  Future<void>? _pendingLoad;

  static final StudySetManager _instance =
      StudySetManager._(PocketBaseService.instance);

  static StudySetManager get instance => _instance;

  static ValueListenable<List<StudySet>> get listenable => instance._studySets;
  static ValueListenable<bool> get loadingListenable => instance._isLoading;
  static ValueListenable<String?> get errorListenable => instance._error;

  static List<StudySet> get current => List.unmodifiable(instance._studySets.value);

  static Future<void> loadInitialData({bool force = false}) =>
      instance._loadInitialData(force: force);

  Future<void> _loadInitialData({bool force = false}) {
    if (_pendingLoad != null) {
      if (force) {
        _pendingLoad = _performInitialLoad(force: true);
      }
      return _pendingLoad!;
    }
    if (_hasLoaded && !force) {
      return Future.value();
    }

    _pendingLoad = _performInitialLoad(force: force);
    return _pendingLoad!;
  }

  Future<void> _performInitialLoad({required bool force}) async {
    if (_isLoading.value && !force) {
      return;
    }

    _isLoading.value = true;
    _error.value = null;

    try {
      final records = await _service.fetchStudySets();
      _cache
        ..clear()
        ..addEntries(records.map((record) {
          final set =
              StudySet.fromRecord(record, flashcards: const [], explanations: const []);
          return MapEntry(set.id, set);
        }));
      _sync();
      _hasLoaded = true;
    } on PocketBaseServiceException catch (error) {
      _error.value = error.message;
    } catch (error) {
      _error.value = 'Failed to load study sets: $error';
    } finally {
      _isLoading.value = false;
      _pendingLoad = null;
    }
  }

  void _sync() {
    _studySets.value = List.unmodifiable(_cache.values);
  }

  static StudySet? getById(String id) => instance._cache[id];

  static Future<StudySet> createStudySet({
    required String name,
    String? subject,
    String? description,
    bool isPrivate = true,
  }) =>
      instance._createStudySet(
        name: name,
        subject: subject,
        description: description,
        isPrivate: isPrivate,
      );

  Future<StudySet> _createStudySet({
    required String name,
    String? subject,
    String? description,
    bool isPrivate = true,
  }) async {
    try {
      final record = await _service.createStudySet({
        'title': name,
        'subject': subject,
        'description': description,
        'isCommunity': !isPrivate,
        'byYou': true,
        'progress': 0,
      });
      final studySet =
          StudySet.fromRecord(record, flashcards: const [], explanations: const []);
      _cache[studySet.id] = studySet;
      _sync();
      return studySet;
    } on PocketBaseServiceException catch (error) {
      _error.value = error.message;
      rethrow;
    } catch (error) {
      final message = 'Failed to create study set: $error';
      _error.value = message;
      throw PocketBaseServiceException(message, error: error);
    }
  }

  static Future<StudySet?> updateStudySet(String id, StudySet update) =>
      instance._updateStudySet(id, update);

  Future<StudySet?> _updateStudySet(String id, StudySet update) async {
    try {
      final record = await _service.updateStudySet(id, update.toJson());
      final next = StudySet.fromRecord(
        record,
        flashcards: update.flashcards,
        explanations: update.explanations,
      );
      _cache[id] = next;
      _sync();
      return next;
    } on PocketBaseServiceException catch (error) {
      _error.value = error.message;
      rethrow;
    } catch (error) {
      final message = 'Failed to update study set: $error';
      _error.value = message;
      throw PocketBaseServiceException(message, error: error);
    }
  }

  static Future<void> deleteStudySet(String id) => instance._deleteStudySet(id);

  Future<void> _deleteStudySet(String id) async {
    try {
      await _service.deleteStudySet(id);
      _cache.remove(id);
      _sync();
    } on PocketBaseServiceException catch (error) {
      _error.value = error.message;
      rethrow;
    } catch (error) {
      final message = 'Failed to delete study set: $error';
      _error.value = message;
      throw PocketBaseServiceException(message, error: error);
    }
  }

  static void patchFlashcards(String studySetId, List<Flashcard> flashcards) =>
      instance._patchFlashcards(studySetId, flashcards);

  void _patchFlashcards(String studySetId, List<Flashcard> flashcards) {
    final current = _cache[studySetId];
    if (current == null) return;
    _cache[studySetId] = current.copyWith(flashcards: flashcards);
    _sync();
  }

  static void patchExplanations(String studySetId, List<Explanation> explanations) =>
      instance._patchExplanations(studySetId, explanations);

  void _patchExplanations(String studySetId, List<Explanation> explanations) {
    final current = _cache[studySetId];
    if (current == null) return;
    _cache[studySetId] = current.copyWith(explanations: explanations);
    _sync();
  }

  static Future<void> refreshStudySet(String id) => instance._refreshStudySet(id);

  Future<void> _refreshStudySet(String id) async {
    try {
      final record = await _service.getStudySet(id);
      final current = _cache[id];
      final refreshed = StudySet.fromRecord(
        record,
        flashcards: current?.flashcards ?? const [],
        explanations: current?.explanations ?? const [],
      );
      _cache[id] = refreshed;
      _sync();
    } on PocketBaseServiceException catch (error) {
      _error.value = error.message;
    } catch (error) {
      _error.value = 'Failed to refresh study set: $error';
    }
  }
}
