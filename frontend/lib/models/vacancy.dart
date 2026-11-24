class Vacancy {
  final int id;
  final int companyId;
  final String companyName;
  final String title;
  final String description;
  final double experienceRequired;
  final String employmentType;
  final String workFormat;
  final String location;
  final String salaryRange;
  final bool isActive;
  final int applicantsCount;
  final int newApplicantsCount;
  final int applicationId;
  final String appliedStatus;
  final String coverLetter;
  final String companyFeedback;
  final List<String> skills;
  final int matchScore;
  final List<String> matchedSkills;
  final List<String> missingSkills;

  const Vacancy({
    required this.id,
    this.companyId = 1,
    required this.companyName,
    required this.title,
    required this.description,
    required this.experienceRequired,
    required this.employmentType,
    this.workFormat = 'Hybrid',
    required this.location,
    this.salaryRange = '',
    this.isActive = true,
    this.applicantsCount = 0,
    this.newApplicantsCount = 0,
    this.applicationId = 0,
    this.appliedStatus = '',
    this.coverLetter = '',
    this.companyFeedback = '',
    required this.skills,
    this.matchScore = 0,
    this.matchedSkills = const [],
    this.missingSkills = const [],
  });

  bool get hasApplied =>
      appliedStatus.isNotEmpty && appliedStatus != 'Withdrawn';

  factory Vacancy.fromJson(Map<String, dynamic> json) {
    final rawExp = json['experience_required'];
    double parsedExp = 0.0;
    if (rawExp is num) {
      parsedExp = rawExp.toDouble();
    } else if (rawExp is String) {
      parsedExp = double.tryParse(rawExp) ?? 0.0;
    }

    List<String> parseStringList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return [];
    }

    return Vacancy(
      id: (json['id'] as num?)?.toInt() ?? 0,
      companyId: (json['company_id'] as num?)?.toInt() ?? 1,
      companyName: json['company_name']?.toString() ?? 'Company',
      title: json['title']?.toString() ?? 'Vacancy',
      description: json['description']?.toString() ?? '',
      experienceRequired: parsedExp,
      employmentType: json['employment_type']?.toString() ?? 'Internship',
      workFormat: json['work_format']?.toString() ?? 'Hybrid',
      location: json['location']?.toString() ?? 'Almaty',
      salaryRange: json['salary_range']?.toString() ?? '',
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      applicantsCount: (json['applicants_count'] as num?)?.toInt() ?? 0,
      newApplicantsCount: (json['new_applicants_count'] as num?)?.toInt() ?? 0,
      applicationId: (json['application_id'] as num?)?.toInt() ?? 0,
      appliedStatus: json['applied_status']?.toString() ?? '',
      coverLetter: json['cover_letter']?.toString() ?? '',
      companyFeedback: json['company_feedback']?.toString() ?? '',
      skills: parseStringList(json['skills']),
      matchScore: (json['match_score'] as num?)?.toInt() ?? 0,
      matchedSkills: parseStringList(json['matched_skills']),
      missingSkills: parseStringList(json['missing_skills']),
    );
  }
}