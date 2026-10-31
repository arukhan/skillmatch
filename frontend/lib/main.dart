import 'package:flutter/material.dart';
import 'screens.dart';

void main() {
  runApp(const SkillMatchApp());
}

class SkillMatchApp extends StatelessWidget {
  const SkillMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillMatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/main': (context) => const MainScreen(), //экран с нижним меню
        '/vacancy-detail': (context) => const VacancyDetailScreen(),
      },
    );
  }
}