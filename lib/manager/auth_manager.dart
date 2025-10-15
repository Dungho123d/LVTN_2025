import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:study_application/service/auth.dart';

/// Quản lý trạng thái đăng nhập ở tầng UI.
/// - Expose: isLoggedIn, userId, email
/// - Tự refresh token định kỳ (mặc định 20 phút)
class AuthManager extends ChangeNotifier {
  final AuthService _auth;
  AuthManager({AuthService? auth}) : _auth = auth ?? AuthService.I;

  bool _initialized = false;
  bool _isLoggedIn = false;
  String? _userId;
  String? _email;
  Timer? _refreshTimer;

  bool get initialized => _initialized;
  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get email => _email;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _isLoggedIn = await _auth.isLoggedIn();
    _userId = _auth.currentUserIdSync();
    _email = _auth.currentEmailSync();
    _setupAutoRefresh();
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _auth.loginWithEmail(email, password);
    _isLoggedIn = true;
    _userId = _auth.currentUserIdSync();
    _email = _auth.currentEmailSync();
    notifyListeners();
  }

  Future<void> signup(String email, String password, {String? name}) async {
    await _auth.signUpWithEmail(email, password, name: name);
    _isLoggedIn = true;
    _userId = _auth.currentUserIdSync();
    _email = _auth.currentEmailSync();
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.logout();
    _isLoggedIn = false;
    _userId = null;
    _email = null;
    notifyListeners();
  }

  void _setupAutoRefresh() {
    _refreshTimer?.cancel();
    // refresh mỗi 20 phút. PB token mặc định ~2h nên vậy là an toàn.
    _refreshTimer = Timer.periodic(const Duration(minutes: 20), (_) async {
      try {
        await _auth.refresh();
        _isLoggedIn = await _auth.isLoggedIn();
        _userId = _auth.currentUserIdSync();
        _email = _auth.currentEmailSync();
        notifyListeners();
      } catch (_) {/* ignore */}
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
