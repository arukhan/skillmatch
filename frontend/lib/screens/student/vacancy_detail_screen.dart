import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/vacancy.dart';
import '../../state/session_controller.dart';
import '../../widgets/match_score_badge.dart';
import '../../widgets/skill_chip.dart';

class VacancyDetailScreen extends StatelessWidget {
  const VacancyDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final Vacancy vacancy;
    if (args is Vacancy) {
      vacancy = args;
    } else if (args is Map<String, dynamic>) {
      vacancy = Vacancy.fromJson(args);
    } else {
      vacancy = const Vacancy(
        id: 0,
        companyName: 'Company',
        title: 'Vacancy',
        description: '',
        experienceRequired: 0,
        employmentType: '',
        location: '',
        skills: [],
      );
    }

    final studentSkillsLower = SessionController.instance.studentSkills
        .map((s) => s.name.toLowerCase())
        .toSet();
    final scoreColor = MatchScoreBadge.colorForScore(vacancy.matchScore);

    return Scaffold(
      appBar: AppBar(title: const Text('Vacancy Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vacancy.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  vacancy.location.isEmpty
                      ? vacancy.companyName
                      : '${vacancy.companyName} • ${vacancy.location}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scoreColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scoreColor.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Match Score',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Calculated in real-time from your skills',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      MatchScoreBadge(score: vacancy.matchScore, large: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (vacancy.employmentType.isNotEmpty)
                      _MetaPill(
                        icon: Icons.schedule_rounded,
                        label: vacancy.employmentType,
                      ),
                    _MetaPill(
                      icon: Icons.work_history_outlined,
                      label: 'Exp: ${vacancy.experienceRequired} yrs',
                    ),
                  ],
                ),

                if (vacancy.description.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vacancy.description,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],

                if (vacancy.skills.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Required Skills Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Green = in your profile, Orange = missing skill',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: vacancy.skills.map((skill) {
                      final hasSkill = studentSkillsLower.contains(
                        skill.toLowerCase(),
                      );
                      return SkillChip(
                        name: skill,
                        isMatched: studentSkillsLower.isEmpty ? null : hasSkill,
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Application submitted!'),
                          backgroundColor: AppTheme.brandPurple,
                        ),
                      );
                    },
                    child: const Text(
                      'Apply Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.brandPurple),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}