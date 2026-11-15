class StudentProfile {
  final int id;
  final int userId;
  final String fullName;
  final String university;
  final String major;
  final String education;
  final double experienceYears;

  const StudentProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.university,
    required this.major,
    required this.education,
    required this.experienceYears,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final rawExp = json['experience_years'];
    double parsedExp = 0.0;
    if (rawExp is num) {
      parsedExp = rawExp.toDouble();
    } else if (rawExp is String) {
      parsedExp = double.tryParse(rawExp) ?? 0.0;
    }

    return StudentProfile(
      id: (json['id'] as num?)?.toInt() ?? 1,
      userId: (json['user_id'] as num?)?.toInt() ?? 1,
      fullName: json['full_name']?.toString() ?? 'Student',
      university: json['university']?.toString() ??
          'Kazakh-British Technical University',
      major: json['major']?.toString() ?? 'Information Systems',
      education: json['education']?.toString() ?? 'Bachelor student',
      experienceYears: parsedExp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'university': university,
      'major': major,
      'education': education,
      'experience_years': experienceYears,
    };
  }

  StudentProfile copyWith({
    String? fullName,
    String? university,
    String? major,
    String? education,
    double? experienceYears,
  }) {
    return StudentProfile(
      id: id,
      userId: userId,
      fullName: fullName ?? this.fullName,
      university: university ?? this.university,
      major: major ?? this.major,
      education: education ?? this.education,
      experienceYears: experienceYears ?? this.experienceYears,
    );
  }
}