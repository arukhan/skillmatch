import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'models/auth_session.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/company/company_shell.dart';
import 'screens/student/student_shell.dart';
import 'screens/student/vacancy_detail_screen.dart';
import 'state/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SkillMatchApp());
}

class SkillMatchApp extends StatelessWidget {
  const SkillMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = FirebaseAnalytics.instance;

    return MaterialApp(
      title: 'SkillMatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',

      navigatorObservers: [
        FirebaseAnalyticsObserver(
          analytics: analytics,
        ),
      ],

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