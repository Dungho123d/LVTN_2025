import 'package:pocketbase/pocketbase.dart';

import '../environment.dart';

class PocketBaseServiceException implements Exception {
  const PocketBaseServiceException(this.message, {this.error, this.stackTrace, this.details});

  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? details;

  @override
  String toString() =>
      'PocketBaseServiceException(message: $message, error: $error, details: $details)';
}

class PocketBaseService {
  PocketBaseService._({PocketBase? client}) : _client = client ?? PocketBase(Environment.pocketBaseUrl);

  final PocketBase _client;

  static final PocketBaseService instance = PocketBaseService._();

  PocketBase get client => _client;

  static const String studySetsCollection = 'study_sets';
  static const String flashcardsCollection = 'flashcards';
  static const String explanationsCollection = 'explanations';
  static const String usersCollection = 'users';

  Future<void> ensureAuth({bool asAdmin = false}) async {
    if (_client.authStore.isValid) {
      return;
    }

    if (asAdmin) {
      if (!Environment.hasAdminCredentials) {
        throw const PocketBaseServiceException(
          'PocketBase admin credentials are not configured.',
        );
      }
      await _client.admins.authWithPassword(
        Environment.pocketBaseAdminEmail,
        Environment.pocketBaseAdminPassword,
      );
      return;
    }

    if (!Environment.hasUserCredentials) {
      throw const PocketBaseServiceException(
        'PocketBase user credentials are not configured.',
      );
    }

    await _client.collection(usersCollection).authWithPassword(
          Environment.pocketBaseUserEmail,
          Environment.pocketBaseUserPassword,
        );
  }

  Future<RecordAuth> authenticateUser(String identity, String password) {
    return _guard(
      () => _client.collection(usersCollection).authWithPassword(identity, password),
      'Failed to authenticate user.',
    );
  }

  Future<AdminAuth> authenticateAdmin(String email, String password) {
    return _guard(
      () => _client.admins.authWithPassword(email, password),
      'Failed to authenticate admin.',
    );
  }

  Future<void> signOut() async {
    _client.authStore.clear();
  }

  Future<List<RecordModel>> fetchStudySets({
    String? filter,
    List<String>? expand,
    String? sort,
  }) {
    return _guard(
      () => _client.collection(studySetsCollection).getFullList(
            filter: filter,
            expand: _expandString(expand),
            sort: sort,
          ),
      'Failed to load study sets.',
    );
  }

  Future<RecordModel> getStudySet(String id, {List<String>? expand}) {
    return _guard(
      () => _client.collection(studySetsCollection).getOne(
            id,
            expand: _expandString(expand),
          ),
      'Failed to load study set.',
    );
  }

  Future<RecordModel> createStudySet(Map<String, dynamic> data) {
    return _guard(
      () => _client.collection(studySetsCollection).create(body: data),
      'Failed to create study set.',
    );
  }

  Future<RecordModel> updateStudySet(String id, Map<String, dynamic> data) {
    return _guard(
      () => _client.collection(studySetsCollection).update(
            id,
            body: data,
          ),
      'Failed to update study set.',
    );
  }

  Future<void> deleteStudySet(String id) {
    return _guard(
      () async => _client.collection(studySetsCollection).delete(id),
      'Failed to delete study set.',
    );
  }

  Future<List<RecordModel>> fetchFlashcards({
    String? filter,
    List<String>? expand,
    String? sort,
  }) {
    return _guard(
      () => _client.collection(flashcardsCollection).getFullList(
            filter: filter,
            expand: _expandString(expand),
            sort: sort,
          ),
      'Failed to load flashcards.',
    );
  }

  Future<RecordModel> createFlashcard(Map<String, dynamic> data) {
    return _guard(
      () => _client.collection(flashcardsCollection).create(body: data),
      'Failed to create flashcard.',
    );
  }

  Future<RecordModel> updateFlashcard(String id, Map<String, dynamic> data) {
    return _guard(
      () => _client.collection(flashcardsCollection).update(id, body: data),
      'Failed to update flashcard.',
    );
  }

  Future<void> deleteFlashcard(String id) {
    return _guard(
      () async => _client.collection(flashcardsCollection).delete(id),
      'Failed to delete flashcard.',
    );
  }

  Future<List<RecordModel>> fetchExplanations({
    String? filter,
    List<String>? expand,
    String? sort,
  }) {
    return _guard(
      () => _client.collection(explanationsCollection).getFullList(
            filter: filter,
            expand: _expandString(expand),
            sort: sort,
          ),
      'Failed to load explanations.',
    );
  }

  Future<RecordModel> createExplanation(Map<String, dynamic> data) {
    return _guard(
      () => _client.collection(explanationsCollection).create(body: data),
      'Failed to create explanation.',
    );
  }

  Future<RecordModel> updateExplanation(String id, Map<String, dynamic> data) {
    return _guard(
      () => _client.collection(explanationsCollection).update(id, body: data),
      'Failed to update explanation.',
    );
  }

  Future<void> deleteExplanation(String id) {
    return _guard(
      () async => _client.collection(explanationsCollection).delete(id),
      'Failed to delete explanation.',
    );
  }

  Future<List<RecordModel>> fetchUsers({
    String? filter,
    List<String>? expand,
    String? sort,
  }) {
    return _guard(
      () => _client.collection(usersCollection).getFullList(
            filter: filter,
            expand: _expandString(expand),
            sort: sort,
          ),
      'Failed to load users.',
    );
  }

  Future<RecordModel> getUser(String id, {List<String>? expand}) {
    return _guard(
      () => _client.collection(usersCollection).getOne(
            id,
            expand: _expandString(expand),
          ),
      'Failed to load user.',
    );
  }

  Future<RecordModel> updateUser(String id, Map<String, dynamic> data) {
    return _guard(
      () => _client.collection(usersCollection).update(id, body: data),
      'Failed to update user.',
    );
  }

  Future<void> deleteUser(String id) {
    return _guard(
      () async => _client.collection(usersCollection).delete(id),
      'Failed to delete user.',
    );
  }

  Future<T> _guard<T>(Future<T> Function() run, String message) async {
    try {
      return await run();
    } on ClientException catch (error, stackTrace) {
      throw PocketBaseServiceException(
        message,
        error: error,
        stackTrace: stackTrace,
        details: error.response,
      );
    } catch (error, stackTrace) {
      throw PocketBaseServiceException(
        message,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String? _expandString(List<String>? expand) {
    if (expand == null || expand.isEmpty) return null;
    return expand.join(',');
  }
}
