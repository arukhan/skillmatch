import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/vacancy.dart';
import '../../services/vacancy_service.dart';
import '../../state/session_controller.dart';
import '../../widgets/match_badge.dart';

class VacancyListScreen extends StatefulWidget {
  const VacancyListScreen({super.key});

  @override
  State<VacancyListScreen> createState() => _VacancyListScreenState();
}

class _VacancyListScreenState extends State<VacancyListScreen> {
  late Future<List<Vacancy>> _futureVacancies;
  final _searchCtrl = TextEditingController();
  String _selectedType = 'All';
  String _selectedFormat = 'All';

  int get _studentId => SessionController.instance.activeStudentProfileId;

  @override
  void initState() {
    super.initState();
    _loadVacancies();
  }

  void _loadVacancies() {
    _futureVacancies = VacancyService.fetchVacancies(studentId: _studentId);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green.shade50;
      case 'Rejected':
        return Colors.red.shade50;
      case 'Interview':
        return Colors.orange.shade50;
      default:
        return AppTheme.brandPurpleLight;
    }
  }

  Color _statusFg(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green.shade800;
      case 'Rejected':
        return Colors.red.shade800;
      case 'Interview':
        return Colors.orange.shade900;
      default:
        return AppTheme.brandPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    const types = ['All', 'Internship', 'Full-time', 'Part-time'];
    const formats = ['All', 'Hybrid', 'Remote', 'Office'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vacancies & Internships'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(_loadVacancies),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_loadVacancies);
          await _futureVacancies;
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by role, company, or skill (Go, Python, ML)...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ...types.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(t, style: const TextStyle(fontSize: 12)),
                            selected: _selectedType == t,
                            selectedColor: AppTheme.brandPurpleLight,
                            onSelected: (_) => setState(() => _selectedType = t),
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 14, indent: 8, endIndent: 8),
                      ...formats.where((f) => f != 'All').map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                label: Text(f,
                                    style: const TextStyle(fontSize: 12)),
                                selected: _selectedFormat == f,
                                selectedColor: AppTheme.brandPurpleLight,
                                onSelected: (val) => setState(
                                  () => _selectedFormat = val ? f : 'All',
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: FutureBuilder<List<Vacancy>>(
                    future: _futureVacancies,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Could not load vacancies:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }

                      final query = _searchCtrl.text.trim().toLowerCase();
                      final all = snapshot.data ?? [];
                      final filtered = all.where((v) {
                        if (_selectedType != 'All' &&
                            v.employmentType.toLowerCase() !=
                                _selectedType.toLowerCase()) {
                          return false;
                        }
                        if (_selectedFormat != 'All' &&
                            v.workFormat.toLowerCase() !=
                                _selectedFormat.toLowerCase()) {
                          return false;
                        }
                        if (query.isEmpty) return true;
                        return v.title.toLowerCase().contains(query) ||
                            v.companyName.toLowerCase().contains(query) ||
                            v.location.toLowerCase().contains(query) ||
                            v.skills
                                .any((s) => s.toLowerCase().contains(query));
                      }).toList();

                      filtered.sort(
                        (a, b) => b.matchScore.compareTo(a.matchScore),
                      );

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text('No matching vacancies found.'),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final v = filtered[index];
                          final matchedLower = v.matchedSkills
                              .map((s) => s.toLowerCase())
                              .toSet();

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              SessionController.instance
                                  .openVacancyDetail(v.id);
                              Navigator.pushNamed(
                                context,
                                '/vacancy-detail',
                                arguments: v,
                              ).then((_) {
                                if (mounted) setState(_loadVacancies);
                              });
                            },
                            child: Card(
                              color: Colors.white,
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                v.title,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${v.companyName} • ${v.location} • ${v.workFormat}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        MatchBadge(
                                          score: v.matchScore.toDouble(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Chip(
                                          label: Text(
                                            v.employmentType,
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        if (v.salaryRange.isNotEmpty)
                                          Text(
                                            v.salaryRange,
                                            style: const TextStyle(
                                              color: AppTheme.brandPurple,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        if (v.hasApplied)
                                          Chip(
                                            label: Text(
                                              v.appliedStatus,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    _statusFg(v.appliedStatus),
                                              ),
                                            ),
                                            backgroundColor:
                                                _statusBg(v.appliedStatus),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                      ],
                                    ),
                                    if (v.skills.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: v.skills.map((skill) {
                                          final isMatched = matchedLower
                                              .contains(skill.toLowerCase());
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isMatched
                                                  ? Colors.green.shade50
                                                  : AppTheme.brandPurpleLight,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              isMatched ? '✓ $skill' : skill,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isMatched
                                                    ? Colors.green.shade900
                                                    : AppTheme.brandPurple,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}