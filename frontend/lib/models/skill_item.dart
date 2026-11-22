class SkillLevels {
  static const List<String> all = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];
}

class SkillItem {
  final int? id;
  final String name;
  final String? category;
  final String? level;

  const SkillItem({
    this.id,
    required this.name,
    this.category,
    this.level,
  });

  factory SkillItem.fromJson(dynamic raw) {
    if (raw is String) {
      return SkillItem(name: raw);
    }
    if (raw is Map<String, dynamic>) {
      return SkillItem(
        id: (raw['id'] as num?)?.toInt(),
        name: raw['name']?.toString() ?? 'Skill',
        category: raw['category']?.toString(),
        level: raw['level']?.toString(),
      );
    }
    return const SkillItem(name: 'Skill');
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        if (category != null) 'category': category,
        if (level != null && level!.isNotEmpty) 'level': level,
      };
}

class LanguageLevels {
  static const List<String> supportedLanguages = [
    'English',
    'Russian',
    'Kazakh',
    'Chinese',
    'German',
    'Turkish',
    'Korean',
  ];

  static const List<String> cefrLevels = [
    'A1',
    'A2',
    'B1',
    'B2',
    'C1',
    'C2',
  ];
}

class LanguageItem {
  final int? id;
  final String languageName;
  final String proficiencyLevel;

  const LanguageItem({
    this.id,
    required this.languageName,
    required this.proficiencyLevel,
  });

  factory LanguageItem.fromJson(Map<String, dynamic> json) {
    return LanguageItem(
      id: (json['id'] as num?)?.toInt(),
      languageName: json['language_name']?.toString() ?? 'English',
      proficiencyLevel:
          (json['cefr_level'] ?? json['proficiency_level'] ?? 'B2').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'language_name': languageName,
        'cefr_level': proficiencyLevel.split(' ').first,
        'proficiency_level': proficiencyLevel,
      };
}