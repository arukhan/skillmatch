import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/skill_item.dart';
import '../models/vacancy.dart';
import '../state/session_controller.dart';

class CompanyApplicant {
  final int applicationId;
  final int vacancyId;
  final String vacancyTitle;
  final int studentProfileId;
  final String studentName;
  final String studentEmail;
  final String university;
  final String major;
  final double experienceYears;
  final String targetRole;
  final String bio;
  final String githubUrl;
  final String linkedinUrl;
  final int matchScore;
  final String status;
  final String coverLetter;
  final String companyFeedback;
  final String appliedAt;
  final String updatedAt;
  final List<SkillItem> studentSkills;
  final List<LanguageItem> studentLanguages;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> registeredEvents;

  const CompanyApplicant({
    required this.applicationId,
    required this.vacancyId,
    required this.vacancyTitle,
    required this.studentProfileId,
    required this.studentName,
    required this.studentEmail,
    required this.university,
    required this.major,
    required this.experienceYears,
    required this.targetRole,
    required this.bio,
    required this.githubUrl,
    required this.linkedinUrl,
    required this.matchScore,
    required this.status,
    required this.coverLetter,
    required this.companyFeedback,
    required this.appliedAt,
    required this.updatedAt,
    required this.studentSkills,
    required this.studentLanguages,
    required this.matchedSkills,
    required this.missingSkills,
    this.registeredEvents = const [],
  });

  factory CompanyApplicant.fromJson(Map<String, dynamic> json) {
    final rawExp = json['experience_years'];
    double parsedExp = 0.0;
    if (rawExp is num) {
      parsedExp = rawExp.toDouble();
    } else if (rawExp is String) {
      parsedExp = double.tryParse(rawExp) ?? 0.0;
    }

    final rawSkills = json['student_skills'];
    final skills = rawSkills is List
        ? rawSkills.map((e) => SkillItem.fromJson(e)).toList()
        : <SkillItem>[];

    final rawLangs = json['student_languages'];
    final langs = rawLangs is List
        ? rawLangs
            .map((e) => LanguageItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <LanguageItem>[];

    List<String> strList(dynamic raw) =>
        raw is List ? raw.map((e) => e.toString()).toList() : <String>[];

    return CompanyApplicant(
      applicationId: (json['application_id'] as num?)?.toInt() ?? 0,
      vacancyId: (json['vacancy_id'] as num?)?.toInt() ?? 0,
      vacancyTitle: json['vacancy_title']?.toString() ?? 'Vacancy',
      studentProfileId: (json['student_profile_id'] as num?)?.toInt() ?? 0,
      studentName: json['student_name']?.toString() ?? 'Student',
      studentEmail: json['student_email']?.toString() ?? '',
      university: json['university']?.toString() ?? 'KBTU',
      major: json['major']?.toString() ?? 'Information Systems',
      experienceYears: parsedExp,
      targetRole: json['target_role']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      githubUrl: json['github_url']?.toString() ?? '',
      linkedinUrl: json['linkedin_url']?.toString() ?? '',
      matchScore: (json['match_score'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'Applied',
      coverLetter: json['cover_letter']?.toString() ?? '',
      companyFeedback: json['company_feedback']?.toString() ?? '',
      appliedAt: json['applied_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      studentSkills: skills,
      studentLanguages: langs,
      matchedSkills: strList(json['matched_skills']),
      missingSkills: strList(json['missing_skills']),
      registeredEvents: strList(json['registered_events']),
    );
  }
}

class VacancyService {
  static Future<List<Vacancy>> fetchVacancies({
    int? studentId,
    int? companyId,
    bool includeInactive = false,
  }) async {
    final activeStudentId =
        studentId ?? SessionController.instance.activeStudentProfileId;

    final queryParams = <String, String>{};
    if (companyId != null) {
      queryParams['company_id'] = companyId.toString();
      queryParams['include_inactive'] = 'true';
    } else {
      queryParams['student_id'] = activeStudentId.toString();
      if (includeInactive) {
        queryParams['include_inactive'] = 'true';
      }
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/vacancies')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri).timeout(const Duration(seconds: 6));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((e) => Vacancy.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    throw Exception('Failed to load vacancies (${response.statusCode})');
  }

  static Future<void> createVacancy({
    required int companyId,
    required String companyName,
    required String title,
    required String description,
    required double experienceRequired,
    required String employmentType,
    String workFormat = 'Hybrid',
    required String location,
    String salaryRange = '',
    required List<String> skills,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/vacancies'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'company_id': companyId,
            'company_name': companyName,
            'title': title,
            'description': description,
            'experience_required': experienceRequired.round(),
            'employment_type': employmentType,
            'work_format': workFormat,
            'location': location,
            'salary_range': salaryRange,
            'skills': skills,
          }),
        )
        .timeout(const Duration(seconds: 6));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Server returned ${response.statusCode}');
    }
  }

  static Future<bool> setVacancyActive(int vacancyId, bool isActive) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/vacancies/$vacancyId/status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'is_active': isActive}),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteVacancy(int vacancyId) async {
    try {
      final response = await http
          .delete(Uri.parse('${ApiConfig.baseUrl}/vacancies/$vacancyId'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> applyToVacancy({
    required int vacancyId,
    required int studentProfileId,
    required int matchScore,
    String coverLetter = '',
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/vacancies/$vacancyId/apply'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'student_profile_id': studentProfileId,
            'match_score': matchScore,
            'cover_letter': coverLetter,
          }),
        )
        .timeout(const Duration(seconds: 6));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    throw Exception(body['error']?.toString() ?? 'Failed to apply');
  }

  static Future<bool> withdrawApplication(int applicationId) async {
    try {
      final response = await http
          .patch(
            Uri.parse(
                '${ApiConfig.baseUrl}/applications/$applicationId/withdraw'),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<CompanyApplicant>> fetchCompanyApplicants({
    required int companyId,
    int? vacancyId,
    String status = 'All',
  }) async {
    final params = <String, String>{};
    if (vacancyId != null && vacancyId > 0) {
      params['vacancy_id'] = vacancyId.toString();
    }
    if (status.isNotEmpty && status != 'All') {
      params['status'] = status;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/companies/$companyId/applicants')
        .replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await http.get(uri).timeout(const Duration(seconds: 6));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((e) =>
                CompanyApplicant.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    throw Exception('Failed to load applicants (${response.statusCode})');
  }

  static Future<bool> updateApplicationStatus({
    required int applicationId,
    required String status,
    String companyFeedback = '',
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse(
                '${ApiConfig.baseUrl}/applications/$applicationId/status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'status': status,
              'company_feedback': companyFeedback,
            }),
          )
          .timeout(const Duration(seconds: 6));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}