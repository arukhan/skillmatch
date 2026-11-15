import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/vacancy.dart';
import '../state/session_controller.dart';

class VacancyService {
  static Future<List<Vacancy>> fetchVacancies() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/vacancies'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load vacancies (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    if (data is! List) {
      throw Exception('Invalid vacancies format');
    }

    final remote = data
        .map((v) => Vacancy.fromJson(Map<String, dynamic>.from(v)))
        .toList();

    return [
      ...SessionController.instance.localCompanyVacancies,
      ...remote,
    ];
  }

  static Future<double?> fetchMatchScore(int studentId, int vacancyId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/students/$studentId/vacancies/$vacancyId/match',
        ),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      dynamic rawScore;

      if (data is num) {
        rawScore = data;
      } else if (data is Map<String, dynamic>) {
        rawScore = data['match_score'] ??
            data['matchScore'] ??
            data['score'] ??
            data['match_percentage'] ??
            data['percentage'];
      }

      if (rawScore is num) return rawScore.toDouble();
      if (rawScore is String) {
        return double.tryParse(rawScore.replaceAll('%', '').trim());
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Vacancy>> fetchVacanciesWithMatch(int studentId) async {
    final vacancies = await fetchVacancies();

    final enriched = await Future.wait(
      vacancies.map((vacancy) async {
        final score = await fetchMatchScore(studentId, vacancy.id);
        return vacancy.copyWith(matchScore: score);
      }),
    );

    return enriched;
  }

  static Future<Vacancy> createVacancy({
    required int companyId,
    required String companyName,
    required String title,
    required String description,
    required double experienceRequired,
    required String employmentType,
    required String location,
    required List<String> skills,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/vacancies'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'company_id': companyId,
              'title': title,
              'description': description,
              'experience_required': experienceRequired,
              'employment_type': employmentType,
              'location': location,
              'skills': skills,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Vacancy.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)),
        );
      }
    } catch (_) {}

    final created = Vacancy(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      companyId: companyId,
      companyName: companyName,
      title: title,
      description: description,
      experienceRequired: experienceRequired,
      employmentType: employmentType,
      location: location,
      skills: skills,
    );
    SessionController.instance.addLocalCompanyVacancy(created);
    return created;
  }
}