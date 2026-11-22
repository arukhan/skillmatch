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

class UserNotFoundException extends AuthException {
  UserNotFoundException(super.message);
}

class AuthService {
  static AuthSession _parseBackendSession(
    Map<String, dynamic> data,
    String fallbackEmail,
    UserRole fallbackRole,
  ) {
    final rawRole =
        (data['role'] ?? fallbackRole.apiValue).toString().toUpperCase();
    final role = rawRole == 'COMPANY' ? UserRole.company : UserRole.student;
    final userId = (data['user_id'] as num?)?.toInt() ?? 1;
    final profileId = (data['profile_id'] as num?)?.toInt() ?? 1;
    final displayName =
        (data['name'] ?? data['full_name'] ?? fallbackEmail).toString();

    return AuthSession(
      token: data['token']?.toString() ?? 'session-$userId',
      userId: userId,
      email: (data['email'] ?? fallbackEmail).toString(),
      role: role,
      studentProfileId: role == UserRole.student ? profileId : null,
      companyId: role == UserRole.company ? profileId : null,
      displayName: displayName,
      isDemoFallback: false,
    );
  }

  static Future<AuthSession> login({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();

    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      throw AuthException('Please enter a valid email address.');
    }
    if (password.trim().length < 4) {
      throw AuthException('Password must be at least 4 characters.');
    }

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
          .timeout(const Duration(seconds: 6));

      final body = response.body.isNotEmpty
          ? Map<String, dynamic>.from(jsonDecode(response.body))
          : <String, dynamic>{};

      if (response.statusCode == 200) {
        final session =
            _parseBackendSession(body, trimmedEmail, expectedRole);
        if (session.role != expectedRole) {
          throw AuthException(
            'This account is registered as ${session.role.label}. Please switch the role tab above.',
          );
        }
        return session;
      }

      if (response.statusCode == 404 || body['code'] == 'USER_NOT_FOUND') {
        throw UserNotFoundException(
          body['error']?.toString() ??
              'Account not found. Please register first (Sign up).',
        );
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException(
          body['error']?.toString() ?? 'Incorrect password. Please try again.',
        );
      }

      throw AuthException(
        body['error']?.toString() ?? 'Server error (${response.statusCode})',
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(
        'Cannot connect to server. Check that Go backend is running.',
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
              'name': fullName.trim(),
              'university': university.trim(),
              'major': major.trim(),
              'education': education.trim(),
              'experience_years': experienceYears,
            }),
          )
          .timeout(const Duration(seconds: 6));

      final body = response.body.isNotEmpty
          ? Map<String, dynamic>.from(jsonDecode(response.body))
          : <String, dynamic>{};

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseBackendSession(body, trimmedEmail, UserRole.student);
      }
      if (response.statusCode == 409) {
        throw AuthException(
          'An account with this email already exists. Please sign in.',
        );
      }
      throw AuthException(
        body['error']?.toString() ?? 'Registration failed (${response.statusCode})',
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(
        'Cannot connect to server. Check that Go backend is running.',
      );
    }
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
          .timeout(const Duration(seconds: 6));

      final body = response.body.isNotEmpty
          ? Map<String, dynamic>.from(jsonDecode(response.body))
          : <String, dynamic>{};

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _parseBackendSession(body, trimmedEmail, UserRole.company);
      }
      if (response.statusCode == 409) {
        throw AuthException(
          'A company account with this email already exists. Please sign in.',
        );
      }
      throw AuthException(
        body['error']?.toString() ?? 'Registration failed (${response.statusCode})',
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(
        'Cannot connect to server. Check that Go backend is running.',
      );
    }
  }
}