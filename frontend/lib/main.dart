import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'models/auth_session.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/company/company_shell.dart';
import 'screens/student/student_shell.dart';
import 'screens/student/vacancy_detail_screen.dart';
import 'state/session_controller.dart';

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
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const AuthScreen(),
        '/main': (_) => const RoleRouterShell(),
        '/vacancy-detail': (_) => const VacancyDetailScreen(),
      },
    );
  }
}

class RoleRouterShell extends StatelessWidget {
  const RoleRouterShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionController.instance,
      builder: (context, _) {
        final session = SessionController.instance.session;
        if (session == null) {
          return const AuthScreen();
        }
        if (session.role == UserRole.company) {
          return const CompanyShell();
        }
        return const StudentShell();
      },
    );
  }
}