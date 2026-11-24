import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class EventItem {
  final int id;
  final int companyId;
  final String title;
  final String organizer;
  final String eventType;
  final String eventDate;
  final String location;
  final String workFormat;
  final int capacity;
  final String externalUrl;
  final String description;
  final List<String> tags;
  final int registeredCount;
  final bool isRegistered;
  final bool isRecommended;
  final List<String> matchedTags;

  const EventItem({
    required this.id,
    this.companyId = 0,
    required this.title,
    required this.organizer,
    required this.eventType,
    required this.eventDate,
    required this.location,
    required this.workFormat,
    this.capacity = 100,
    this.externalUrl = '',
    required this.description,
    required this.tags,
    required this.registeredCount,
    required this.isRegistered,
    this.isRecommended = false,
    this.matchedTags = const [],
  });

  bool get isFull =>
      capacity > 0 && registeredCount >= capacity && !isRegistered;

  factory EventItem.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags']?.toString() ?? '';
    final parsedTags = rawTags
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final rawMatched = json['matched_tags'];
    final parsedMatched = rawMatched is List
        ? rawMatched.map((e) => e.toString()).toList()
        : <String>[];

    return EventItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      companyId: (json['company_id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Tech Event',
      organizer: json['organizer']?.toString() ?? 'Community',
      eventType: json['event_type']?.toString() ?? 'Meetup',
      eventDate: json['event_date']?.toString() ?? '',
      location: json['location']?.toString() ?? 'Almaty',
      workFormat: json['work_format']?.toString() ?? 'Offline',
      capacity: (json['capacity'] as num?)?.toInt() ?? 100,
      externalUrl: json['external_url']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      tags: parsedTags,
      registeredCount: (json['registered_count'] as num?)?.toInt() ?? 0,
      isRegistered: json['is_registered'] == true,
      isRecommended: json['is_recommended'] == true,
      matchedTags: parsedMatched,
    );
  }
}

class CourseItem {
  final int id;
  final int companyId;
  final String title;
  final String provider;
  final String skillName;
  final String level;
  final String language;
  final String duration;
  final bool isFree;
  final String externalUrl;
  final String description;
  final String enrollmentStatus;
  final bool isRecommended;
  final String recommendationReason;
  final int boostedVacanciesCount;

  const CourseItem({
    required this.id,
    this.companyId = 0,
    required this.title,
    required this.provider,
    required this.skillName,
    required this.level,
    this.language = 'RU',
    required this.duration,
    required this.isFree,
    this.externalUrl = '',
    required this.description,
    required this.enrollmentStatus,
    required this.isRecommended,
    required this.recommendationReason,
    this.boostedVacanciesCount = 0,
  });

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    return CourseItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      companyId: (json['company_id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Course',
      provider: json['provider']?.toString() ?? 'Platform',
      skillName: json['skill_name']?.toString() ?? '',
      level: json['level']?.toString() ?? 'Intermediate',
      language: json['language']?.toString() ?? 'RU',
      duration: json['duration']?.toString() ?? '',
      isFree: json['is_free'] != false,
      externalUrl: json['external_url']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      enrollmentStatus: json['enrollment_status']?.toString() ?? '',
      isRecommended: json['is_recommended'] == true,
      recommendationReason: json['recommendation_reason']?.toString() ?? '',
      boostedVacanciesCount:
          (json['boosted_vacancies_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CourseCompletionResult {
  final String status;
  final String addedSkill;
  final String addedLevel;
  final int boostedVacancies;

  const CourseCompletionResult({
    required this.status,
    required this.addedSkill,
    required this.addedLevel,
    required this.boostedVacancies,
  });
}

class LearningService {
  static Future<List<EventItem>> fetchEvents({
    int? studentId,
    int? companyId,
  }) async {
    final params = <String, String>{};
    if (studentId != null && studentId > 0) {
      params['student_id'] = studentId.toString();
    }
    if (companyId != null && companyId > 0) {
      params['company_id'] = companyId.toString();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/events')
        .replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri).timeout(const Duration(seconds: 6));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((e) => EventItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    throw Exception('Failed to load events (${response.statusCode})');
  }

  static Future<void> createEvent({
    required int companyId,
    required String title,
    required String organizer,
    required String eventType,
    required String eventDate,
    required String location,
    required String workFormat,
    required int capacity,
    required String externalUrl,
    required String description,
    required String tags,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/events'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'company_id': companyId,
            'title': title,
            'organizer': organizer,
            'event_type': eventType,
            'event_date': eventDate,
            'location': location,
            'work_format': workFormat,
            'capacity': capacity,
            'external_url': externalUrl,
            'description': description,
            'tags': tags,
          }),
        )
        .timeout(const Duration(seconds: 6));

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create event (${response.statusCode})');
    }
  }

  static Future<void> deleteEvent(int eventId) async {
    await http
        .delete(Uri.parse('${ApiConfig.baseUrl}/events/$eventId'))
        .timeout(const Duration(seconds: 6));
  }

  static Future<bool> toggleEventRegistration(
    int eventId,
    int studentProfileId,
  ) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/events/$eventId/toggle'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'student_profile_id': studentProfileId}),
        )
        .timeout(const Duration(seconds: 6));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['registered'] == true;
    }
    final err = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    throw Exception(
      err['error']?.toString() ?? 'Failed to update registration',
    );
  }

  static Future<List<CourseItem>> fetchCourses(
    int studentId, {
    int? companyId,
    String? skill,
    bool freeOnly = false,
    String? language,
    String? level,
    String? provider,
    String? query,
  }) async {
    final params = <String, String>{};
    if (studentId > 0) params['student_id'] = studentId.toString();
    if (companyId != null && companyId > 0) {
      params['company_id'] = companyId.toString();
    }
    if (skill != null && skill.trim().isNotEmpty) {
      params['skill'] = skill.trim();
    }
    if (freeOnly) params['free_only'] = 'true';
    if (language != null && language != 'All') params['lang'] = language;
    if (level != null && level != 'All') params['level'] = level;
    if (provider != null && provider != 'All') params['provider'] = provider;
    if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();

    final uri = Uri.parse('${ApiConfig.baseUrl}/courses')
        .replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((e) => CourseItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    throw Exception('Failed to load courses (${response.statusCode})');
  }

  static Future<void> createCourse({
    required int companyId,
    required String title,
    required String provider,
    required String skillName,
    required String level,
    required String language,
    required String duration,
    required bool isFree,
    required String externalUrl,
    required String description,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/courses'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'company_id': companyId,
            'title': title,
            'provider': provider,
            'skill_name': skillName,
            'level': level,
            'language': language,
            'duration': duration,
            'is_free': isFree,
            'external_url': externalUrl,
            'description': description,
          }),
        )
        .timeout(const Duration(seconds: 6));

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create course (${response.statusCode})');
    }
  }

  static Future<void> deleteCourse(int courseId) async {
    await http
        .delete(Uri.parse('${ApiConfig.baseUrl}/courses/$courseId'))
        .timeout(const Duration(seconds: 6));
  }

  static Future<CourseCompletionResult> updateCourseStatus({
    required int courseId,
    required int studentProfileId,
    required String status,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/courses/$courseId/status'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'student_profile_id': studentProfileId,
            'status': status,
          }),
        )
        .timeout(const Duration(seconds: 6));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CourseCompletionResult(
        status: data['status']?.toString() ?? status,
        addedSkill: data['added_skill']?.toString() ?? '',
        addedLevel: data['added_level']?.toString() ?? '',
        boostedVacancies: (data['boosted_vacancies'] as num?)?.toInt() ?? 0,
      );
    }
    throw Exception('Failed to update course status');
  }

  static Future<Map<String, dynamic>> fetchAdminAnalytics() async {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/admin/analytics'))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to load analytics (${response.statusCode})');
  }
}