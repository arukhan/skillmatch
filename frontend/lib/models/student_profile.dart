class StudentProfile {
  final int id;
  final int? userId;
  final String fullName;
  final String university;
  final String major;
  final double experienceYears;
  final String bio;
  final String targetRole;
  final String githubUrl;
  final String linkedinUrl;

  const StudentProfile({
    required this.id,
    this.userId,
    required this.fullName,
    required this.university,
    required this.major,
    required this.experienceYears,
    this.bio = '',
    this.targetRole = 'Software Engineering Intern',
    this.githubUrl = '',
    this.linkedinUrl = '',
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
      userId: (json['user_id'] as num?)?.toInt(),
      fullName: json['full_name']?.toString() ?? 'Student',
      university: json['university']?.toString() ?? 'KBTU',
      major: json['major']?.toString() ?? 'Information Systems',
      experienceYears: parsedExp,
      bio: json['bio']?.toString() ?? '',
      targetRole:
          json['target_role']?.toString() ?? 'Software Engineering Intern',
      githubUrl: json['github_url']?.toString() ?? '',
      linkedinUrl: json['linkedin_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (userId != null) 'user_id': userId,
        'full_name': fullName,
        'university': university,
        'major': major,
        'experience_years': experienceYears,
        'bio': bio,
        'target_role': targetRole,
        'github_url': githubUrl,
        'linkedin_url': linkedinUrl,
      };

  StudentProfile copyWith({
    String? fullName,
    String? university,
    String? major,
    double? experienceYears,
    String? bio,
    String? targetRole,
    String? githubUrl,
    String? linkedinUrl,
  }) {
    return StudentProfile(
      id: id,
      userId: userId,
      fullName: fullName ?? this.fullName,
      university: university ?? this.university,
      major: major ?? this.major,
      experienceYears: experienceYears ?? this.experienceYears,
      bio: bio ?? this.bio,
      targetRole: targetRole ?? this.targetRole,
      githubUrl: githubUrl ?? this.githubUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
    );
  }
}