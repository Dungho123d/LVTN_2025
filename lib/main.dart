import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:study_application/manager/auth_manager.dart';

import 'package:study_application/utils/theme.dart';

// Pages
import 'package:study_application/pages/dashboard.dart';
import 'package:study_application/pages/home_page.dart';
import 'package:study_application/pages/explore/study_sets_tab.dart';
import 'package:study_application/pages/library/library_page.dart';
import 'package:study_application/pages/profile/profile_page.dart';
import 'package:study_application/pages/auth/login_page.dart';
import 'package:study_application/pages/auth/register_page.dart';

// Auth

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(
    ChangeNotifierProvider(
      create: (_) =>
          AuthManager()..init(), // vẫn khởi tạo để có trạng thái đăng nhập
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Application',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // LUỒN MỚI: luôn vào Dashboard trước
      home: const DashboardScreen(),

      // Các route còn lại
      routes: {
        ProfilePage.routeName: (_) => const ProfilePage(),
        ExplorePage.routeName: (_) => const ExplorePage(),
        LibraryPage.routeName: (_) => const LibraryPage(),
        HomePage.routeName: (_) => const HomePage(),

        // Trang auth gọi khi cần (từ Dashboard/feature yêu cầu đăng nhập)
        '/auth/login': (_) => const LoginPage(),
        '/auth/register': (_) => const RegisterPage(),
      },
    );
  }
}
