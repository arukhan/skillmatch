class SkillLevels {
  static const List<String> all = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];
}

class SkillItem {
  final String name;
  final String? level;

  const SkillItem({
    required this.name,
    this.level,
  });

  factory SkillItem.fromJson(dynamic raw) {
    if (raw is String) {
      return SkillItem(name: raw);
    }
    if (raw is Map<String, dynamic>) {
      return SkillItem(
        name: raw['name']?.toString() ?? 'Skill',
        level: raw['level']?.toString(),
      );
    }
    return const SkillItem(name: 'Skill');
  }

  Map<String, dynamic> toJson() => {
        'name': name,
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
    'A1 (Beginner)',
    'A2 (Elementary)',
    'B1 (Intermediate)',
    'B2 (Upper-Intermediate)',
    'C1 (Advanced)',
    'C2 (Proficient)',
    'Native',
  ];
}

enum CertificateVerificationStatus {
  unverified,
  pending,
  verified,
  rejected;

  String get label {
    switch (this) {
      case CertificateVerificationStatus.unverified:
        return 'No certificate';
      case CertificateVerificationStatus.pending:
        return 'Pending review';
      case CertificateVerificationStatus.verified:
        return 'Verified';
      case CertificateVerificationStatus.rejected:
        return 'Rejected';
    }
  }

  static CertificateVerificationStatus fromApi(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'PENDING':
        return CertificateVerificationStatus.pending;
      case 'VERIFIED':
        return CertificateVerificationStatus.verified;
      case 'REJECTED':
        return CertificateVerificationStatus.rejected;
      default:
        return CertificateVerificationStatus.unverified;
    }
  }
}

class LanguageItem {
  final int? id;
  final String languageName;
  final String proficiencyLevel;
  final String? certificateUrl;
  final CertificateVerificationStatus verificationStatus;

  const LanguageItem({
    this.id,
    required this.languageName,
    required this.proficiencyLevel,
    this.certificateUrl,
    this.verificationStatus = CertificateVerificationStatus.unverified,
  });

  factory LanguageItem.fromJson(Map<String, dynamic> json) {
    return LanguageItem(
      id: (json['id'] as num?)?.toInt(),
      languageName: json['language_name']?.toString() ?? 'English',
      proficiencyLevel:
          json['proficiency_level']?.toString() ?? 'B2 (Upper-Intermediate)',
      certificateUrl: json['certificate_url']?.toString(),
      verificationStatus: CertificateVerificationStatus.fromApi(
        json['verification_status']?.toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'language_name': languageName,
        'proficiency_level': proficiencyLevel,
        if (certificateUrl != null) 'certificate_url': certificateUrl,
        'verification_status': verificationStatus.name.toUpperCase(),
      };
}