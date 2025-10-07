import 'package:flutter/foundation.dart';

import '../model/explanation.dart';
import '../services/pocketbase_service.dart';
import 'studysets_manager.dart';

class ExplanationManager {
  ExplanationManager._(this._service);

  final PocketBaseService _service;
  final ValueNotifier<List<Explanation>> _all = ValueNotifier(const []);
  final ValueNotifier<bool> _isLoadingAll = ValueNotifier(false);
  final ValueNotifier<String?> _errorAll = ValueNotifier(null);
  final Map<String, List<Explanation>> _byStudySet = {};
  final Map<String, ValueNotifier<List<Explanation>>> _notifiersBySet = {};
  final Map<String, ValueNotifier<bool>> _loadingBySet = {};
  final Map<String, ValueNotifier<String?>> _errorBySet = {};
  bool _hasLoadedAll = false;

  static final ExplanationManager instance =
      ExplanationManager._(PocketBaseService.instance);

  static ValueListenable<List<Explanation>> get listenableAll => instance._all;
  static ValueListenable<bool> get loadingAll => instance._isLoadingAll;
  static ValueListenable<String?> get errorAll => instance._errorAll;

  static ValueListenable<List<Explanation>> listenableForSet(String studySetId) =>
      instance._listenableForSet(studySetId);

  static ValueListenable<bool> loadingForSet(String studySetId) =>
      instance._loadingNotifier(studySetId);

  static ValueListenable<String?> errorForSet(String studySetId) =>
      instance._errorNotifier(studySetId);

  static Future<void> loadAll({bool force = false}) =>
      instance.loadAll(force: force);

  static Future<void> loadForStudySet(String studySetId, {bool force = false}) =>
      instance.loadForStudySet(studySetId, force: force);

  static Future<Explanation> create({
    required String title,
    required double sizeMB,
    required String studySetId,
    int? views,
  }) =>
      instance.create(
        title: title,
        sizeMB: sizeMB,
        studySetId: studySetId,
        views: views,
      );

  static Future<Explanation?> update(String id, Explanation updated) =>
      instance.update(id, updated);

  static Future<void> remove(String id) => instance.remove(id);

  static void clearCache([String? studySetId]) =>
      instance.clearLocalCache(studySetId);

  ValueListenable<List<Explanation>> _listenableForSet(String studySetId) {
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
      final records = await _service.fetchExplanations();
      _byStudySet.clear();
      final explanations = <Explanation>[];
      for (final record in records) {
        final explanation = Explanation.fromRecord(record);
        explanations.add(explanation);
        final studySetId = explanation.studySetId;
        final list = _byStudySet.putIfAbsent(studySetId, () => []);
        list.add(explanation);
      }
      for (final entry in _byStudySet.entries) {
        _notifyStudySet(entry.key);
      }
      _all.value = List.unmodifiable(explanations);
      _hasLoadedAll = true;
    } on PocketBaseServiceException catch (error) {
      _errorAll.value = error.message;
    } catch (error) {
      _errorAll.value = 'Failed to load explanations: $error';
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
      final records = await _service.fetchExplanations(
        filter: 'studySet="$studySetId"',
      );
      final list = <Explanation>[];
      for (final record in records) {
        list.add(Explanation.fromRecord(record));
      }
      _byStudySet[studySetId] = list;
      _notifyStudySet(studySetId);
      _refreshAllFromStudySets();
    } on PocketBaseServiceException catch (pbError) {
      error.value = pbError.message;
    } catch (pbError) {
      error.value = 'Failed to load explanations: $pbError';
    } finally {
      loading.value = false;
    }
  }

  Future<Explanation> create({
    required String title,
    required double sizeMB,
    required String studySetId,
    int? views,
  }) async {
    if (studySetId.isEmpty) {
      throw const PocketBaseServiceException(
        'A study set id is required to create an explanation.',
      );
    }

    try {
      final record = await _service.createExplanation({
        'title': title,
        'sizeMB': sizeMB,
        'studySet': studySetId,
        'views': views,
      });
      final explanation = Explanation.fromRecord(record);
      final list = _byStudySet.putIfAbsent(studySetId, () => []);
      list.removeWhere((item) => item.id == explanation.id);
      list.add(explanation);
      _notifyStudySet(studySetId);
      _refreshAllFromStudySets();
      return explanation;
    } on PocketBaseServiceException catch (error) {
      _errorAll.value = error.message;
      rethrow;
    } catch (error) {
      final message = 'Failed to create explanation: $error';
      _errorAll.value = message;
      throw PocketBaseServiceException(message, error: error);
    }
  }

  Future<Explanation?> update(String id, Explanation updated) async {
    final previousStudySet = _findStudySetForExplanation(id);
    try {
      final record = await _service.updateExplanation(id, updated.toJson());
      final explanation = Explanation.fromRecord(record);
      if (previousStudySet != null && previousStudySet != explanation.studySetId) {
        _removeFromStudySet(previousStudySet, id);
      }
      final studySetId = explanation.studySetId;
      final list = _byStudySet.putIfAbsent(studySetId, () => []);
      list.removeWhere((item) => item.id == explanation.id);
      list.add(explanation);
      _notifyStudySet(studySetId);
      _refreshAllFromStudySets();
      return explanation;
    } on PocketBaseServiceException catch (error) {
      _errorAll.value = error.message;
      rethrow;
    } catch (error) {
      final message = 'Failed to update explanation: $error';
      _errorAll.value = message;
      throw PocketBaseServiceException(message, error: error);
    }
  }

  Future<void> remove(String id) async {
    final previousStudySet = _findStudySetForExplanation(id);
    try {
      await _service.deleteExplanation(id);
      _removeFromStudySet(previousStudySet, id);
      _refreshAllFromStudySets();
    } on PocketBaseServiceException catch (error) {
      _errorAll.value = error.message;
      rethrow;
    } catch (error) {
      final message = 'Failed to delete explanation: $error';
      _errorAll.value = message;
      throw PocketBaseServiceException(message, error: error);
    }
  }

  void clearLocalCache([String? studySetId]) {
    if (studySetId == null) {
      _byStudySet.clear();
      _all.value = const [];
      for (final notifier in _notifiersBySet.values) {
        notifier.value = const [];
      }
    } else {
      _byStudySet.remove(studySetId);
      _notifyStudySet(studySetId);
      _refreshAllFromStudySets();
    }
  }

  void _removeFromStudySet(String? studySetId, String id) {
    if (studySetId == null) return;
    final list = _byStudySet[studySetId];
    if (list == null) return;
    list.removeWhere((item) => item.id == id);
    _notifyStudySet(studySetId);
  }

  String? _findStudySetForExplanation(String id) {
    for (final entry in _byStudySet.entries) {
      if (entry.value.any((item) => item.id == id)) {
        return entry.key;
      }
    }
    return null;
  }

  void _notifyStudySet(String studySetId) {
    final notifier = _notifiersBySet.putIfAbsent(
      studySetId,
      () => ValueNotifier(const []),
    );
    final list = List<Explanation>.unmodifiable(_byStudySet[studySetId] ?? const []);
    notifier.value = list;
    StudySetManager.patchExplanations(studySetId, list);
  }

  void _refreshAllFromStudySets() {
    final items = <Explanation>[];
    for (final list in _byStudySet.values) {
      items.addAll(list);
    }
    _all.value = List.unmodifiable(items);
  }
}
