import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'features/gpa_lab/presentation/screens/gpa_lab_screen.dart';

void main() {
  runApp(const GpaLabPreviewApp());
}

class GpaLabPreviewApp extends StatelessWidget {
  const GpaLabPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UEHero GPA Physics Lab',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const GpaLabScreen(),
    );
  }
}
