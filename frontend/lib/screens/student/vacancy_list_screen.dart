import 'package:flutter/material.dart';
import '../../models/skill_item.dart';
import '../../models/vacancy.dart';
import '../../services/student_service.dart';
import '../../services/vacancy_service.dart';
import '../../state/session_controller.dart';
import '../../widgets/match_score_badge.dart';
import '../../widgets/skill_chip.dart';

class VacancyListScreen extends StatefulWidget {
  const VacancyListScreen({super.key});

  @override
  State<VacancyListScreen> createState() => _VacancyListScreenState();
}

class _VacancyListScreenState extends State<VacancyListScreen> {
  late Future<List<Vacancy>> _futureVacancies;
  String _searchQuery = '';
  bool _onlyHighMatch = false;

  int get _studentId => SessionController.instance.activeStudentProfileId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    StudentService.fetchSkills(_studentId).catchError((_) => <SkillItem>[]);
    _futureVacancies = VacancyService.fetchVacanciesWithMatch(_studentId);
  }

  Future<void> _reload() async {
    setState(() {
      _loadData();
    });
    await _futureVacancies;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internships matched to your profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh Match Scores',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by role, company or skill...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('70%+'),
                  selected: _onlyHighMatch,
                  onSelected: (val) => setState(() => _onlyHighMatch = val),
                ),
              ],
            ),
          ),
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
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Could not load vacancies',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _reload,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allVacancies = snapshot.data ?? [];
                final filtered = allVacancies.where((v) {
                  if (_onlyHighMatch && (v.matchScore ?? 0) < 70) {
                    return false;
                  }
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return v.title.toLowerCase().contains(q) ||
                      v.companyName.toLowerCase().contains(q) ||
                      v.skills.any((s) => s.toLowerCase().contains(q));
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No matching internships found.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildVacancyCard(filtered[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVacancyCard(Vacancy vacancy) {
    final subtitle = vacancy.location.isEmpty
        ? vacancy.companyName
        : '${vacancy.companyName} • ${vacancy.location}';

    return Card(
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.pushNamed(
            context,
            '/vacancy-detail',
            arguments: vacancy,
          );
          _reload();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vacancy.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  MatchScoreBadge(score: vacancy.matchScore),
                ],
              ),
              if (vacancy.skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: vacancy.skills
                      .map((skill) => SkillChip(name: skill))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
