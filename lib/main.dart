import 'package:flutter/material.dart';
import 'package:study_application/pages/dashboard.dart';
import 'package:study_application/pages/explore/study_sets_tab.dart';
import 'package:study_application/pages/home_page.dart';
import 'package:study_application/pages/library/library_page.dart';
import 'package:study_application/pages/profile/profile_page.dart';
import 'package:study_application/utils/theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Application',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
      routes: {
        ProfilePage.routeName: (_) => const ProfilePage(),
        ExplorePage.routeName: (_) => const ExplorePage(),
        LibraryPage.routeName: (_) => const LibraryPage(),
        HomePage.routeName: (_) => const HomePage(),
      },
    );
  }
}
