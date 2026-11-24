enum UserRole {
  student,
  company;

  String get apiValue => this == UserRole.student ? 'STUDENT' : 'COMPANY';

  String get label => this == UserRole.student ? 'Student' : 'Company';

  static UserRole fromApi(String? raw) {
    if (raw != null && raw.toUpperCase() == 'COMPANY') {
      return UserRole.company;
    }
    return UserRole.student;
  }
}

class AuthSession {
  final String token;
  final int userId;
  final String email;
  final UserRole role;
  final int? studentProfileId;
  final int? companyId;
  final String displayName;
  final String? companyWebsite;
  final String? companyDescription;
  final bool isAdmin;
  final bool isDemoFallback;

  const AuthSession({
    required this.token,
    required this.userId,
    required this.email,
    required this.role,
    this.studentProfileId,
    this.companyId,
    required this.displayName,
    this.companyWebsite,
    this.companyDescription,
    this.isAdmin = false,
    this.isDemoFallback = false,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final role = UserRole.fromApi(json['role']?.toString());
    return AuthSession(
      token: json['token']?.toString() ?? 'local-session-token',
      userId: (json['user_id'] as num?)?.toInt() ?? 1,
      email: json['email']?.toString() ?? '',
      role: role,
      studentProfileId: (json['student_profile_id'] as num?)?.toInt() ??
          (role == UserRole.student ? 1 : null),
      companyId: (json['company_id'] as num?)?.toInt() ??
          (role == UserRole.company ? 1 : null),
      displayName: json['full_name']?.toString() ??
          json['company_name']?.toString() ??
          json['name']?.toString() ??
          'SkillMatch User',
      companyWebsite: json['website']?.toString(),
      companyDescription: json['description']?.toString(),
      isAdmin: json['is_admin'] == true,
      isDemoFallback: json['is_demo_fallback'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user_id': userId,
      'email': email,
      'role': role.apiValue,
      'student_profile_id': studentProfileId,
      'company_id': companyId,
      'full_name': displayName,
      'website': companyWebsite,
      'description': companyDescription,
      'is_admin': isAdmin,
      'is_demo_fallback': isDemoFallback,
    };
  }
}