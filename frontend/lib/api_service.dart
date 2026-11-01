import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    // Android Emulator:
    // return 'http://10.0.2.2:8080/api/v1';

    // Flutter Web:
    return 'http://localhost:8080/api/v1';
  }

  // =========================================================
  // STUDENT PROFILE
  // =========================================================

  static Future<Map<String, dynamic>> fetchStudent(int studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/students/$studentId'),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      'Failed to load student: ${response.statusCode}',
    );
  }

  // =========================================================
  // STUDENT SKILLS
  // =========================================================

  static Future<List<dynamic>> fetchStudentSkills(int studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/students/$studentId/skills'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }
    }

    throw Exception(
      'Failed to load student skills: ${response.statusCode}',
    );
  }

  static Future<bool> addStudentSkill(
    int studentId,
    String skillName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/students/$studentId/skills'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': skillName,
        }),
      );

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteStudentSkill(
    int studentId,
    String skillName,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/students/$studentId/skills',
      ).replace(
        queryParameters: {
          'name': skillName,
        },
      );

      final response = await http.delete(uri);

      return response.statusCode == 200 ||
          response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // VACANCIES
  // =========================================================

  static Future<List<Map<String, dynamic>>> fetchVacancies() async {
    final response = await http.get(
      Uri.parse('$baseUrl/vacancies'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load vacancies: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw Exception('Invalid vacancies response');
    }

    return data
        .map(
          (vacancy) => Map<String, dynamic>.from(vacancy),
        )
        .toList();
  }

  // =========================================================
  // MATCH SCORE
  // =========================================================

  static Future<double?> fetchMatchScore(
    int studentId,
    int vacancyId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/students/$studentId/vacancies/$vacancyId/match',
        ),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);

      dynamic rawScore;

      if (data is num) {
        rawScore = data;
      } else if (data is Map<String, dynamic>) {
        // Поддерживаем несколько возможных названий,
        // чтобы Flutter не зависел от одного JSON key.
        rawScore = data['match_score'] ??
            data['matchScore'] ??
            data['score'] ??
            data['match_percentage'] ??
            data['matchPercentage'] ??
            data['percentage'];
      }

      if (rawScore is num) {
        return rawScore.toDouble();
      }

      if (rawScore is String) {
        final cleaned = rawScore.replaceAll('%', '').trim();
        return double.tryParse(cleaned);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // VACANCIES + MATCH SCORE
  // =========================================================

  static Future<List<Map<String, dynamic>>> fetchVacanciesWithMatch(
    int studentId,
  ) async {
    final vacancies = await fetchVacancies();

    final result = await Future.wait(
      vacancies.map((vacancy) async {
        final vacancyId =
            (vacancy['id'] as num).toInt();

        final matchScore = await fetchMatchScore(
          studentId,
          vacancyId,
        );

        return {
          ...vacancy,
          'match_score': matchScore,
        };
      }),
    );

    return result;
  }
}