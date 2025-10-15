import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Dịch vụ tầng thấp làm việc trực tiếp với PocketBase.
/// - Nhớ token bằng AsyncAuthStore + SharedPreferences
/// - Hỗ trợ login/signup/refresh/logout
class AuthService {
  AuthService._();
  static final AuthService I = AuthService._();

  PocketBase? _pb;

  Future<PocketBase> _ensurePb() async {
    if (_pb != null) return _pb!;

    final prefs = await SharedPreferences.getInstance();
    final store = AsyncAuthStore(
      save: (val) async => prefs.setString('pb_auth', val ?? ''),
      initial: prefs.getString('pb_auth'),
      clear: () async => prefs.remove('pb_auth'),
    );

    final baseUrl =
        (dotenv.env['POCKETBASE_URL'] ?? 'http://10.0.2.2:8090').trim();
    _pb = PocketBase(baseUrl, authStore: store);

    // Nếu có token cũ thì refresh
    try {
      if (_pb!.authStore.isValid) {
        await _pb!.collection('users').authRefresh();
      }
    } catch (_) {/* ignore */}
    return _pb!;
  }

  Future<PocketBase> client() => _ensurePb();

  Future<bool> isLoggedIn() async {
    final pb = await _ensurePb();
    return pb.authStore.isValid && pb.authStore.record != null;
  }

  String? currentUserIdSync() => _pb?.authStore.record?.id;
  String? currentEmailSync() => _pb?.authStore.record?.data['email'];

  // ==== Auth APIs ============================================================
  Future<void> loginWithEmail(String email, String password) async {
    final pb = await _ensurePb();
    await pb.collection('users').authWithPassword(email.trim(), password);
  }

  Future<void> signUpWithEmail(String email, String password,
      {String? name}) async {
    final pb = await _ensurePb();
    await pb.collection('users').create(body: {
      'email': email.trim(),
      'password': password,
      'passwordConfirm': password,
      if (name != null && name.isNotEmpty) 'name': name,
    });
    // Đăng nhập ngay sau khi đăng ký
    await loginWithEmail(email, password);
  }

  Future<void> requestPasswordReset(String email) async {
    final pb = await _ensurePb();
    await pb.collection('users').requestPasswordReset(email.trim());
  }

  Future<void> refresh() async {
    final pb = await _ensurePb();
    await pb.collection('users').authRefresh();
  }

  Future<void> logout() async {
    final pb = await _ensurePb();
    pb.authStore.clear();
  }
}
