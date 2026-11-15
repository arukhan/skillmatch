import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/auth_session.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  static Future<AuthSession> login({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();

    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      throw AuthException('Please enter a valid email address.');
    }
    if (password.trim().length < 4 || password.trim() == 'wrong') {
      throw AuthException('Invalid email or password.');
    }

    // 1. Пробуем реальный эндпоинт авторизации (задача T9)
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': trimmedEmail,
              'password': password,
              'role': expectedRole.apiValue,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(response.body));
        final session = AuthSession.fromJson(data);
        if (session.role != expectedRole) {
          throw AuthException(
            'This account is registered as ${session.role.label}. Switch the role tab above.',
          );
        }
        return session;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException('Invalid credentials or wrong account role.');
      }
    } on AuthException {
      rethrow;
    } catch (_) {
      // Если бэкенд авторизации ещё не запушен — переходим на фоллбэк
    }

    // 2. Временный фоллбэк для тестирования обеих ролей (US9)
    if (expectedRole == UserRole.student) {
      String resolvedName = 'Zhumabek Askerbekuly';
      try {
        final profileRes = await http
            .get(Uri.parse('${ApiConfig.baseUrl}/students/1'))
            .timeout(const Duration(seconds: 3));
        if (profileRes.statusCode == 200) {
          final profileJson = jsonDecode(profileRes.body);
          if (profileJson['full_name'] != null) {
            resolvedName = profileJson['full_name'].toString();
          }
        }
      } catch (_) {}

      return AuthSession(
        token: 'demo-student-jwt',
        userId: 1,
        email: trimmedEmail,
        role: UserRole.student,
        studentProfileId: 1,
        displayName: resolvedName,
        isDemoFallback: true,
      );
    } else {
      return AuthSession(
        token: 'demo-company-jwt',
        userId: 2,
        email: trimmedEmail,
        role: UserRole.company,
        companyId: 1,
        displayName: 'SkillMatch Partner Tech',
        companyWebsite: 'https://skillmatch.kz',
        companyDescription: 'Hiring talented junior developers and interns.',
        isDemoFallback: true,
      );
    }
  }

  static Future<AuthSession> registerStudent({
    required String fullName,
    required String email,
    required String password,
    required String university,
    required String major,
    required String education,
    required double experienceYears,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': trimmedEmail,
              'password': password,
              'role': 'STUDENT',
              'full_name': fullName.trim(),
              'university': university.trim(),
              'major': major.trim(),
              'education': education.trim(),
              'experience_years': experienceYears,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthSession.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)),
        );
      }
      if (response.statusCode == 409) {
        throw AuthException('User with this email already exists.');
      }
    } on AuthException {
      rethrow;
    } catch (_) {}

    int createdProfileId = 1;
    try {
      final studentRes = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/students'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': DateTime.now().millisecondsSinceEpoch % 100000,
              'full_name': fullName.trim(),
              'university': university.trim(),
              'major': major.trim(),
              'education': education.trim(),
              'experience_years': experienceYears,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (studentRes.statusCode == 200 || studentRes.statusCode == 201) {
        final body = jsonDecode(studentRes.body);
        if (body is Map && body['id'] != null) {
          createdProfileId = (body['id'] as num).toInt();
        }
      }
    } catch (_) {}

    return AuthSession(
      token: 'demo-student-jwt',
      userId: createdProfileId,
      email: trimmedEmail,
      role: UserRole.student,
      studentProfileId: createdProfileId,
      displayName: fullName.trim(),
      isDemoFallback: true,
    );
  }

  static Future<AuthSession> registerCompany({
    required String companyName,
    required String email,
    required String password,
    required String website,
    required String description,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': trimmedEmail,
              'password': password,
              'role': 'COMPANY',
              'name': companyName.trim(),
              'website': website.trim(),
              'description': description.trim(),
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthSession.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)),
        );
      }
    } catch (_) {}

    return AuthSession(
      token: 'demo-company-jwt',
      userId: 2,
      email: trimmedEmail,
      role: UserRole.company,
      companyId: 1,
      displayName: companyName.trim(),
      companyWebsite: website.trim(),
      companyDescription: description.trim(),
      isDemoFallback: true,
    );
  }
}