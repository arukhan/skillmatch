import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics =
      FirebaseAnalytics.instance;

  static Future<void> loginSuccess({
    required String role,
  }) async {
    await _analytics.logEvent(
      name: 'login_success',
      parameters: {
        'role': role,
      },
    );
  }

  static Future<void> vacancyOpened({
    required int vacancyId,
    required int matchScore,
  }) async {
    await _analytics.logEvent(
      name: 'vacancy_opened',
      parameters: {
        'vacancy_id': vacancyId,
        'match_score': matchScore,
      },
    );
  }

  static Future<void> applicationSubmitted({
    required int vacancyId,
    required int matchScore,
  }) async {
    await _analytics.logEvent(
      name: 'application_submitted',
      parameters: {
        'vacancy_id': vacancyId,
        'match_score': matchScore,
      },
    );
  }

  static Future<void> applicationWithdrawn({
    required int applicationId,
    required int vacancyId,
  }) async {
    await _analytics.logEvent(
      name: 'application_withdrawn',
      parameters: {
        'application_id': applicationId,
        'vacancy_id': vacancyId,
      },
    );
  }

  static Future<void> eventRegistered({
    required int eventId,
    required String eventType,
  }) async {
    await _analytics.logEvent(
      name: 'event_registered',
      parameters: {
        'event_id': eventId,
        'event_type': eventType,
      },
    );
  }

  static Future<void> profileUpdated() async {
    await _analytics.logEvent(
      name: 'profile_updated',
    );
  }
}