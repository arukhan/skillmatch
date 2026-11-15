import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/skill_item.dart';
import '../models/student_profile.dart';
import '../state/session_controller.dart';

class StudentService {
  static Future<StudentProfile> fetchProfile(int studentId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/students/$studentId'),
    );

    if (response.statusCode == 200) {
      return StudentProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body)),
      );
    }

    throw Exception('Failed to load profile (${response.statusCode})');
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

  static Future<List<SkillItem>> fetchSkills(int studentId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/students/$studentId/skills'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        final previousSkills = SessionController.instance.studentSkills;
        final items = data.map((e) {
          final parsed = SkillItem.fromJson(e);
          if (parsed.level == null || parsed.level!.isEmpty) {
            final existing = previousSkills.where(
              (old) => old.name.toLowerCase() == parsed.name.toLowerCase(),
            );
            if (existing.isNotEmpty && existing.first.level != null) {
              return SkillItem(
                name: parsed.name,
                level: existing.first.level,
              );
            }
          }
          return parsed;
        }).toList();

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
          .timeout(const Duration(seconds: 2));
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

  static Future<void> saveLanguage(int studentId, LanguageItem item) async {
    SessionController.instance.upsertLanguage(item);
    try {
      await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/students/$studentId/languages'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(item.toJson()),
          )
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  static Future<void> deleteLanguage(int studentId, String languageName) async {
    SessionController.instance.removeLanguage(languageName);
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/students/$studentId/languages')
          .replace(queryParameters: {'language': languageName});
      await http.delete(uri).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}