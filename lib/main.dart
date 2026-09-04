import 'package:ai_cv_analyzer/screens/splash_screen.dart';
import 'package:flutter/material.dart';
// import 'screens/home_dashboard.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AiCvAnalyzerApp());
}

class AiCvAnalyzerApp extends StatelessWidget {
  const AiCvAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI CV Analyzer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const SplashScreen(),
    );
  }
}
