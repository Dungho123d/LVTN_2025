import 'package:flutter/material.dart';
import 'package:study_application/pages/dashboard.dart';
import 'package:study_application/utils/theme.dart'; // import theme

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Application',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // áp dụng theme từ theme.dart
      home: const DashboardScreen(),
    );
  }
}
