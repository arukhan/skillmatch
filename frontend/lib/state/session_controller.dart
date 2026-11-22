import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_session.dart';
import '../models/skill_item.dart';
import '../models/vacancy.dart';

class SessionController extends ChangeNotifier {
  SessionController._();
  static final SessionController instance = SessionController._();

  static const _kSessionKey = 'sm_auth_session';
  static const _kStudentTabKey = 'sm_student_tab';
  static const _kCompanyTabKey = 'sm_company_tab';
  static const _kLastRouteKey = 'sm_last_route';
  static const _kActiveVacancyIdKey = 'sm_active_vacancy_id';

  SharedPreferences? _prefs;

  AuthSession? _session;
  int _studentTabIndex = 0;
  int _companyTabIndex = 0;
  String _lastRoute = '/main';
  int? _activeVacancyId;

  List<SkillItem> _studentSkills = [];
  List<LanguageItem> _studentLanguages = [];
  final List<Vacancy> _localCompanyVacancies = [];

  AuthSession? get session => _session;
  bool get isAuthenticated => _session != null;
  UserRole? get role => _session?.role;
  int get activeStudentProfileId => _session?.studentProfileId ?? 1;
  int get activeCompanyId => _session?.companyId ?? 1;

  int get studentTabIndex => _studentTabIndex;
  int get companyTabIndex => _companyTabIndex;
  String get lastRoute => _lastRoute;
  int? get activeVacancyId => _activeVacancyId;

  List<SkillItem> get studentSkills => List.unmodifiable(_studentSkills);
  List<LanguageItem> get studentLanguages =>
      List.unmodifiable(_studentLanguages);
  List<Vacancy> get localCompanyVacancies =>
      List.unmodifiable(_localCompanyVacancies);

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      final rawSession = _prefs?.getString(_kSessionKey);
      if (rawSession != null && rawSession.isNotEmpty) {
        _session = AuthSession.fromJson(
          Map<String, dynamic>.from(jsonDecode(rawSession)),
        );
      }

      _studentTabIndex = _prefs?.getInt(_kStudentTabKey) ?? 0;
      _companyTabIndex = _prefs?.getInt(_kCompanyTabKey) ?? 0;
      _lastRoute = _prefs?.getString(_kLastRouteKey) ?? '/main';
      _activeVacancyId = _prefs?.getInt(_kActiveVacancyIdKey);
    } catch (_) {}
  }

  void setSession(AuthSession newSession) {
    _session = newSession;
    _studentSkills = [];
    _studentLanguages = [];
    _studentTabIndex = 0;
    _companyTabIndex = 0;
    _lastRoute = '/main';
    _activeVacancyId = null;

    _prefs?.setString(_kSessionKey, jsonEncode(newSession.toJson()));
    _prefs?.setInt(_kStudentTabKey, 0);
    _prefs?.setInt(_kCompanyTabKey, 0);
    _prefs?.setString(_kLastRouteKey, '/main');
    _prefs?.remove(_kActiveVacancyIdKey);

    notifyListeners();
  }

  void logout() {
    _session = null;
    _studentSkills = [];
    _studentLanguages = [];
    _studentTabIndex = 0;
    _companyTabIndex = 0;
    _lastRoute = '/login';
    _activeVacancyId = null;

    _prefs?.remove(_kSessionKey);
    _prefs?.remove(_kStudentTabKey);
    _prefs?.remove(_kCompanyTabKey);
    _prefs?.remove(_kLastRouteKey);
    _prefs?.remove(_kActiveVacancyIdKey);

    notifyListeners();
  }

  void setStudentTab(int index) {
    _studentTabIndex = index;
    _lastRoute = '/main';
    _activeVacancyId = null;
    _prefs?.setInt(_kStudentTabKey, index);
    _prefs?.setString(_kLastRouteKey, '/main');
    _prefs?.remove(_kActiveVacancyIdKey);
    notifyListeners();
  }

  void setCompanyTab(int index) {
    _companyTabIndex = index;
    _lastRoute = '/main';
    _prefs?.setInt(_kCompanyTabKey, index);
    _prefs?.setString(_kLastRouteKey, '/main');
    notifyListeners();
  }

  void openVacancyDetail(int vacancyId) {
    _activeVacancyId = vacancyId;
    _lastRoute = '/vacancy-detail';
    _prefs?.setInt(_kActiveVacancyIdKey, vacancyId);
    _prefs?.setString(_kLastRouteKey, '/vacancy-detail');
  }

  void closeVacancyDetail() {
    _activeVacancyId = null;
    _lastRoute = '/main';
    _prefs?.remove(_kActiveVacancyIdKey);
    _prefs?.setString(_kLastRouteKey, '/main');
  }

  void setStudentSkills(List<SkillItem> skills) {
    _studentSkills = skills;
    notifyListeners();
  }

  void setStudentLanguages(List<LanguageItem> languages) {
    _studentLanguages = languages;
    notifyListeners();
  }

  void upsertLanguage(LanguageItem item) {
    final index = _studentLanguages.indexWhere(
      (l) => l.languageName.toLowerCase() == item.languageName.toLowerCase(),
    );
    if (index >= 0) {
      _studentLanguages[index] = item;
    } else {
      _studentLanguages.add(item);
    }
    notifyListeners();
  }

  void removeLanguage(String languageName) {
    _studentLanguages.removeWhere(
      (l) => l.languageName.toLowerCase() == languageName.toLowerCase(),
    );
    notifyListeners();
  }

  void addLocalCompanyVacancy(Vacancy vacancy) {
    _localCompanyVacancies.insert(0, vacancy);
    notifyListeners();
  }
}