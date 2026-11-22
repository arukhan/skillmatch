import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class EventItem {
  final int id;
  final String title;
  final String organizer;
  final String eventType;
  final String eventDate;
  final String location;
  final String workFormat;
  final String description;
  final List<String> tags;
  final int registeredCount;
  final bool isRegistered;

  const EventItem({
    required this.id,
    required this.title,
    required this.organizer,
    required this.eventType,
    required this.eventDate,
    required this.location,
    required this.workFormat,
    required this.description,
    required this.tags,
    required this.registeredCount,
    required this.isRegistered,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags']?.toString() ?? '';
    final parsedTags = rawTags
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return EventItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Tech Event',
      organizer: json['organizer']?.toString() ?? 'Community',
      eventType: json['event_type']?.toString() ?? 'Meetup',
      eventDate: json['event_date']?.toString() ?? '',
      location: json['location']?.toString() ?? 'Almaty',
      workFormat: json['work_format']?.toString() ?? 'Offline',
      description: json['description']?.toString() ?? '',
      tags: parsedTags,
      registeredCount: (json['registered_count'] as num?)?.toInt() ?? 0,
      isRegistered: json['is_registered'] == true,
    );
  }
}

class CourseItem {
  final int id;
  final String title;
  final String provider;
  final String skillName;
  final String level;
  final String duration;
  final bool isFree;
  final String description;
  final String enrollmentStatus;
  final bool isRecommended;
  final String recommendationReason;

  const CourseItem({
    required this.id,
    required this.title,
    required this.provider,
    required this.skillName,
    required this.level,
    required this.duration,
    required this.isFree,
    required this.description,
    required this.enrollmentStatus,
    required this.isRecommended,
    required this.recommendationReason,
  });

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    return CourseItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Course',
      provider: json['provider']?.toString() ?? 'Platform',
      skillName: json['skill_name']?.toString() ?? '',
      level: json['level']?.toString() ?? 'Intermediate',
      duration: json['duration']?.toString() ?? '',
      isFree: json['is_free'] != false,
      description: json['description']?.toString() ?? '',
      enrollmentStatus: json['enrollment_status']?.toString() ?? '',
      isRecommended: json['is_recommended'] == true,
      recommendationReason: json['recommendation_reason']?.toString() ?? '',
    );
  }
}

class LearningService {
  static Future<List<EventItem>> fetchEvents(int studentId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/events')
        .replace(queryParameters: {'student_id': studentId.toString()});
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
    throw Exception('Failed to update registration');
  }

  static Future<List<CourseItem>> fetchCourses(int studentId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/courses')
        .replace(queryParameters: {'student_id': studentId.toString()});
    final response = await http.get(uri).timeout(const Duration(seconds: 6));

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

  static Future<String> updateCourseStatus({
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
      return data['added_skill']?.toString() ?? '';
    }
    throw Exception('Failed to update course status');
  }
}