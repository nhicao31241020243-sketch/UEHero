import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'features/gpa_tracker/presentation/screens/gpa_dashboard_screen.dart';

void main() {
  runApp(const GpaPreviewApp());
}

class GpaPreviewApp extends StatelessWidget {
  const GpaPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UEHero GPA Preview',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const GpaDashboardScreen(),
    );
  }
}
