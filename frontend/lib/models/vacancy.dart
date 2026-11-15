class Vacancy {
  final int id;
  final int? companyId;
  final String companyName;
  final String title;
  final String description;
  final double experienceRequired;
  final String employmentType;
  final String location;
  final List<String> skills;
  final double? matchScore;

  const Vacancy({
    required this.id,
    this.companyId,
    required this.companyName,
    required this.title,
    required this.description,
    required this.experienceRequired,
    required this.employmentType,
    required this.location,
    required this.skills,
    this.matchScore,
  });

  factory Vacancy.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skills'] as List? ?? [];
    final rawExp = json['experience_required'];
    double parsedExp = 0.0;
    if (rawExp is num) {
      parsedExp = rawExp.toDouble();
    } else if (rawExp is String) {
      parsedExp = double.tryParse(rawExp) ?? 0.0;
    }

    return Vacancy(
      id: (json['id'] as num?)?.toInt() ?? 0,
      companyId: (json['company_id'] as num?)?.toInt(),
      companyName: json['company_name']?.toString() ?? 'Company',
      title: json['title']?.toString() ?? 'Untitled Vacancy',
      description: json['description']?.toString() ?? '',
      experienceRequired: parsedExp,
      employmentType: json['employment_type']?.toString() ?? 'Internship',
      location: json['location']?.toString() ?? 'Almaty',
      skills: rawSkills.map((e) => e.toString()).toList(),
      matchScore: (json['match_score'] as num?)?.toDouble(),
    );
  }

  Vacancy copyWith({double? matchScore}) {
    return Vacancy(
      id: id,
      companyId: companyId,
      companyName: companyName,
      title: title,
      description: description,
      experienceRequired: experienceRequired,
      employmentType: employmentType,
      location: location,
      skills: skills,
      matchScore: matchScore ?? this.matchScore,
    );
  }
}