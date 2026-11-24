import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/vacancy.dart';
import '../../services/learning_service.dart';
import '../../services/vacancy_service.dart';

class _AdminBundle {
  final Map<String, dynamic> analytics;
  final List<Vacancy> vacancies;
  final List<EventItem> events;
  final List<CourseItem> courses;

  const _AdminBundle({
    required this.analytics,
    required this.vacancies,
    required this.events,
    required this.courses,
  });
}

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  late Future<_AdminBundle> _futureBundle;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _futureBundle = _loadBundle();
  }

  Future<_AdminBundle> _loadBundle() async {
    final results = await Future.wait<dynamic>([
      LearningService.fetchAdminAnalytics(),
      VacancyService.fetchVacancies(includeInactive: true),
      LearningService.fetchEvents(),
      LearningService.fetchCourses(0),
    ]);

    return _AdminBundle(
      analytics: results[0] as Map<String, dynamic>,
      vacancies: results[1] as List<Vacancy>,
      events: results[2] as List<EventItem>,
      courses: results[3] as List<CourseItem>,
    );
  }

  Future<void> _refresh() async {
    final nextFuture = _loadBundle();
    setState(() {
      _futureBundle = nextFuture;
    });
    await nextFuture;
  }

  Future<void> _runModerationAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      await action();
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update content: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Admin & Analytics'),
        actions: [
          IconButton(
            tooltip: 'Refresh Data',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isMutating ? null : _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: FutureBuilder<_AdminBundle>(
                future: _futureBundle,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Analytics error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  final bundle = snapshot.data!;
                  final data = bundle.analytics;
                  final kpis = Map<String, dynamic>.from(data['kpis'] ?? {});
                  final universities = (data['universities'] as List? ?? [])
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();
                  final companies = (data['companies'] as List? ?? [])
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();
                  final skillsDemand = (data['skills_demand'] as List? ?? [])
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Platform Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _KpiCard(
                            label: 'Students',
                            value: '${kpis['total_students'] ?? 0}',
                            icon: Icons.school_outlined,
                          ),
                          _KpiCard(
                            label: 'Companies',
                            value: '${kpis['total_companies'] ?? 0}',
                            icon: Icons.business_outlined,
                          ),
                          _KpiCard(
                            label: 'Active Vacancies',
                            value:
                                '${kpis['active_vacancies'] ?? 0} / ${kpis['total_vacancies'] ?? 0}',
                            icon: Icons.work_outline,
                          ),
                          _KpiCard(
                            label: 'Applications',
                            value: '${kpis['total_applications'] ?? 0}',
                            icon: Icons.send_outlined,
                          ),
                          _KpiCard(
                            label: 'Interviews',
                            value: '${kpis['interviews_count'] ?? 0}',
                            icon: Icons.calendar_today_outlined,
                          ),
                          _KpiCard(
                            label: 'Approved / Offers',
                            value: '${kpis['approved_count'] ?? 0}',
                            icon: Icons.verified_outlined,
                          ),
                          _KpiCard(
                            label: 'Tech Events',
                            value: '${kpis['total_events'] ?? 0}',
                            icon: Icons.event_outlined,
                          ),
                          _KpiCard(
                            label: 'Courses',
                            value: '${kpis['total_courses'] ?? 0}',
                            icon: Icons.menu_book_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Students & Applications by University',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: universities.isEmpty
                              ? const Text('No student records yet.')
                              : Column(
                                  children: universities.map((u) {
                                    return ListTile(
                                      dense: true,
                                      leading: const CircleAvatar(
                                        backgroundColor:
                                            AppTheme.brandPurpleLight,
                                        child: Icon(
                                          Icons.account_balance,
                                          size: 18,
                                          color: AppTheme.brandPurple,
                                        ),
                                      ),
                                      title: Text(
                                        u['university'].toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Students: ${u['students_count']} • Applications sent: ${u['applications_count']} • Approved: ${u['approved_count']}',
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Companies Activity & Conversion',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...companies.map((comp) {
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      comp['name'].toString(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        'Avg Match: ${comp['avg_match_score']}%',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.brandPurple,
                                        ),
                                      ),
                                      backgroundColor: AppTheme.brandPurpleLight,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Vacancies: ${comp['active_vacancies_count']}/${comp['vacancies_count']} • Applicants: ${comp['applications_count']} • Events: ${comp['events_count']} • Courses: ${comp['courses_count']}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 22),
                      const Text(
                        'Skills Demand vs Student Supply',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: skillsDemand.isEmpty
                              ? const Text('No vacancy skill data yet.')
                              : Column(
                                  children: skillsDemand.map((sk) {
                                    final demand =
                                        (sk['demand_count'] as num).toInt();
                                    final supply =
                                        (sk['supply_count'] as num).toInt();
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 130,
                                            child: Text(
                                              sk['skill_name'].toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'Required in $demand vacancies • Owned by $supply students',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: supply < demand
                                                    ? Colors.red.shade700
                                                    : Colors.green.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Content Moderation (Vacancies, Events, Courses)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.white,
                        child: Column(
                          children: bundle.vacancies
                              .map(
                                (v) => ListTile(
                                  title: Text('[Vacancy] ${v.title}'),
                                  subtitle: Text(v.companyName),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: _isMutating
                                        ? null
                                        : () => _runModerationAction(
                                              action: () =>
                                                  VacancyService.deleteVacancy(
                                                v.id,
                                              ),
                                              successMessage:
                                                  'Vacancy "${v.title}" deleted',
                                            ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        color: Colors.white,
                        child: Column(
                          children: bundle.events
                              .map(
                                (e) => ListTile(
                                  title: Text('[Event] ${e.title}'),
                                  subtitle: Text(e.organizer),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: _isMutating
                                        ? null
                                        : () => _runModerationAction(
                                              action: () =>
                                                  LearningService.deleteEvent(
                                                e.id,
                                              ),
                                              successMessage:
                                                  'Event "${e.title}" deleted',
                                            ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        color: Colors.white,
                        child: Column(
                          children: bundle.courses
                              .map(
                                (c) => ListTile(
                                  title: Text('[Course] ${c.title}'),
                                  subtitle: Text(
                                    '${c.provider} • ${c.skillName}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: _isMutating
                                        ? null
                                        : () => _runModerationAction(
                                              action: () =>
                                                  LearningService.deleteCourse(
                                                c.id,
                                              ),
                                              successMessage:
                                                  'Course "${c.title}" deleted',
                                            ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 195,
      child: Card(
        color: Colors.white,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.brandPurple, size: 20),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}