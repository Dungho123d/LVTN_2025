import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

PocketBase? _pocketbase;

/// Hàm khởi tạo và trả về instance PocketBase
Future<PocketBase> getPocketbaseInstance() async {
  // Nếu đã khởi tạo thì trả về luôn
  if (_pocketbase != null) {
    return _pocketbase!;
  }

  // Lấy SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Tạo AsyncAuthStore để lưu auth token vào SharedPreferences
  final store = AsyncAuthStore(
    save: (String data) async => prefs.setString('pb_auth', data),
    initial: prefs.getString('pb_auth'),
  );

  // Đọc URL từ .env hoặc fallback về localhost
  final baseUrl = dotenv.env['POCKETBASE_URL'] ?? 'http://10.0.2.2:8090';

  // Khởi tạo PocketBase với authStore
  _pocketbase = PocketBase(baseUrl, authStore: store);

  return _pocketbase!;
}
