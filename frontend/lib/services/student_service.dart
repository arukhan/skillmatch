import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/skill_item.dart';
import '../models/student_profile.dart';
import '../state/session_controller.dart';

class StudentApplication {
  final int id;
  final int vacancyId;
  final String title;
  final String company;
  final int matchScore;
  final String status;
  final String coverLetter;
  final String companyFeedback;
  final String appliedAt;
  final String updatedAt;

  const StudentApplication({
    required this.id,
    required this.vacancyId,
    required this.title,
    required this.company,
    required this.matchScore,
    required this.status,
    this.coverLetter = '',
    this.companyFeedback = '',
    required this.appliedAt,
    this.updatedAt = '',
  });

  factory StudentApplication.fromJson(Map<String, dynamic> json) {
    return StudentApplication(
      id: (json['id'] as num?)?.toInt() ?? 0,
      vacancyId: (json['vacancy_id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Vacancy',
      company: json['company']?.toString() ?? 'Company',
      matchScore: (json['match_score'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'Applied',
      coverLetter: json['cover_letter']?.toString() ?? '',
      companyFeedback: json['company_feedback']?.toString() ?? '',
      appliedAt: json['applied_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

class StudentService {
  static Future<StudentProfile> fetchProfile(int studentId) async {
    Object? lastError;

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http
            .get(Uri.parse('${ApiConfig.baseUrl}/students/$studentId'))
            .timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          return StudentProfile.fromJson(
            Map<String, dynamic>.from(jsonDecode(response.body)),
          );
        }
        lastError = 'HTTP ${response.statusCode}: ${response.body}';
      } catch (e) {
        lastError = e;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    throw Exception('Failed to load profile ($lastError)');
  }

  static Future<bool> updateProfile(StudentProfile profile) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/students/${profile.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profile.toJson()),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<SkillItem>> fetchSkillsCatalog({String query = ''}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/skills').replace(
        queryParameters: query.trim().isNotEmpty ? {'q': query.trim()} : null,
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((e) => SkillItem.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<SkillItem>> fetchSkills(int studentId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/students/$studentId/skills'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        final items = data.map((e) => SkillItem.fromJson(e)).toList();
        SessionController.instance.setStudentSkills(items);
        return items;
      }
    }

    throw Exception('Failed to load skills (${response.statusCode})');
  }

  static Future<bool> addSkill(
    int studentId,
    String skillName, {
    String? level,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/students/$studentId/skills'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': skillName,
          if (level != null && level.isNotEmpty) 'level': level,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteSkill(int studentId, String skillName) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/students/$studentId/skills')
          .replace(queryParameters: {'name': skillName});
      final response = await http.delete(uri);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  static Future<List<LanguageItem>> fetchLanguages(int studentId) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/students/$studentId/languages'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final items = data
              .map((e) => LanguageItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          SessionController.instance.setStudentLanguages(items);
          return items;
        }
      }
    } catch (_) {}
    return SessionController.instance.studentLanguages;
  }

  static Future<bool> saveLanguage(int studentId, LanguageItem item) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/students/$studentId/languages'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(item.toJson()),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchLanguages(studentId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> deleteLanguage(int studentId, String languageName) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/students/$studentId/languages')
          .replace(queryParameters: {'language': languageName});
      final response = await http.delete(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchLanguages(studentId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<List<StudentApplication>> fetchApplications(
      int studentId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/students/$studentId/applications'),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .map((e) =>
                  StudentApplication.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }
}