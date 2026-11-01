import 'package:flutter/material.dart';
import 'api_service.dart';

// ============================================================
// 1. LOGIN SCREEN
// ============================================================

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.work_rounded,
                size: 80,
                color: Color(0xFF7C3AED),
              ),
              const SizedBox(height: 24),
              const Text(
                'SkillMatch',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/main',
                    );
                  },
                  child: const Text(
                    'Enter as Student',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 2. MAIN SCREEN
// ============================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() =>
      _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    VacancyListScreen(),
    EventsScreen(),
    CoursesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor:
            const Color(0xFF7C3AED),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Internships',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            activeIcon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 3. VACANCY LIST
// ============================================================

class VacancyListScreen extends StatefulWidget {
  const VacancyListScreen({super.key});

  @override
  State<VacancyListScreen> createState() =>
      _VacancyListScreenState();
}

class _VacancyListScreenState
    extends State<VacancyListScreen> {
  static const int studentId = 1;

  late Future<List<Map<String, dynamic>>>
      _futureVacancies;

  @override
  void initState() {
    super.initState();

    _futureVacancies =
        ApiService.fetchVacanciesWithMatch(
      studentId,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _futureVacancies =
          ApiService.fetchVacanciesWithMatch(
        studentId,
      );
    });

    await _futureVacancies;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Internships matched to your profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<
          List<Map<String, dynamic>>>(
        future: _futureVacancies,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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
                      size: 50,
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

          final vacancies =
              snapshot.data ?? [];

          if (vacancies.isEmpty) {
            return const Center(
              child: Text(
                'No internships available.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vacancies.length,
              separatorBuilder:
                  (context, index) =>
                      const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final vacancy =
                    vacancies[index];

                return _buildVacancyCard(
                  context,
                  vacancy,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildVacancyCard(
    BuildContext context,
    Map<String, dynamic> vacancy,
  ) {
    final title =
        vacancy['title']?.toString() ??
            'Untitled Vacancy';

    final company =
        vacancy['company_name']?.toString() ??
            'Company';

    final location =
        vacancy['location']?.toString() ?? '';

    final skillsRaw =
        vacancy['skills'] as List? ?? [];

    final skills =
        skillsRaw.map((e) => e.toString()).toList();

    final matchScore =
        vacancy['match_score'] as double?;

    final scoreText = matchScore == null
        ? '—'
        : '${matchScore.round()}%';

    Color scoreColor;

    if (matchScore == null) {
      scoreColor = Colors.grey;
    } else if (matchScore >= 80) {
      scoreColor = Colors.green;
    } else if (matchScore >= 50) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    final companyText = location.isEmpty
        ? company
        : '$company • $location';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/vacancy-detail',
            arguments: vacancy,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          companyText,
                          style: TextStyle(
                            color:
                                Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scoreColor.withAlpha(25),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      scoreText,
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              if (skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skills
                      .map(
                        (skill) => Chip(
                          label: Text(
                            skill,
                            style:
                                const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor:
                              Colors.purple.shade50,
                          labelStyle:
                              const TextStyle(
                            color:
                                Color(0xFF7C3AED),
                          ),
                          padding:
                              EdgeInsets.zero,
                        ),
                      )
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

// ============================================================
// 4. VACANCY DETAIL SCREEN
// ============================================================

class VacancyDetailScreen
    extends StatelessWidget {
  const VacancyDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)
            ?.settings
            .arguments;

    final vacancy =
        args is Map<String, dynamic>
            ? args
            : <String, dynamic>{};

    final title =
        vacancy['title']?.toString() ??
            'Vacancy';

    final company =
        vacancy['company_name']?.toString() ??
            'Company';

    final location =
        vacancy['location']?.toString() ?? '';

    final description =
        vacancy['description']?.toString() ??
            '';

    final employmentType =
        vacancy['employment_type']
                ?.toString() ??
            '';

    final experience =
        vacancy['experience_required'];

    final skillsRaw =
        vacancy['skills'] as List? ?? [];

    final skills =
        skillsRaw.map((e) => e.toString()).toList();

    final matchScore =
        vacancy['match_score'] as double?;

    final scoreText = matchScore == null
        ? 'Not available'
        : '${matchScore.round()}%';

    final scoreColor =
        matchScore != null &&
                matchScore >= 80
            ? Colors.green
            : matchScore != null &&
                    matchScore >= 50
                ? Colors.orange
                : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Vacancy Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              location.isEmpty
                  ? company
                  : '$company • $location',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    scoreColor.withAlpha(20),
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color:
                      scoreColor.withAlpha(80),
                ),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  const Text(
                    'AI Match Score:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  Text(
                    scoreText,
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (employmentType.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Type: $employmentType',
                style:
                    const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],

            if (experience != null) ...[
              const SizedBox(height: 8),
              Text(
                'Experience required: $experience years',
                style:
                    const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],

            if (description.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(description),
            ],

            if (skills.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Required Skills',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: skills
                    .map(
                      (skill) => Chip(
                        label: Text(skill),
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                          0xFF7C3AED),
                  foregroundColor:
                      Colors.white,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(
                          context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Application feature coming soon',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Apply Now',
                  style:
                      TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 5. EVENTS
// ============================================================

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Career Events')),
      body: const Center(
        child: Text('Events Coming Soon'),
      ),
    );
  }
}

// ============================================================
// 6. COURSES
// ============================================================

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Recommended Courses'),
      ),
      body: const Center(
        child: Text('Courses Coming Soon'),
      ),
    );
  }
}

// ============================================================
// 7. PROFILE
// ============================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  static const int studentId = 1;

  late Future<Map<String, dynamic>>
      _futureStudent;

  List<dynamic> _skills = [];

  bool _isLoadingSkills = true;

  String? _skillsError;

  @override
  void initState() {
    super.initState();

    _futureStudent =
        ApiService.fetchStudent(studentId);

    _loadSkills();
  }

  Future<void> _loadSkills() async {
    try {
      final skills =
          await ApiService.fetchStudentSkills(
        studentId,
      );

      if (!mounted) return;

      setState(() {
        _skills = skills;
        _isLoadingSkills = false;
        _skillsError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _skills = [];
        _isLoadingSkills = false;
        _skillsError = e.toString();
      });
    }
  }

  void _showAddSkillDialog(
    BuildContext context,
  ) {
    final controller =
        TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
        title:
            const Text('Add New Skill'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(
            hintText:
                'e.g. Docker, Redis, Python',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child:
                const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF7C3AED),
              foregroundColor:
                  Colors.white,
            ),
            onPressed: () async {
              final skillName =
                  controller.text.trim();

              if (skillName.isEmpty) {
                return;
              }

              Navigator.pop(dialogContext);

              final success =
                  await ApiService
                      .addStudentSkill(
                studentId,
                skillName,
              );

              if (!mounted) return;

              if (success) {
                await _loadSkills();

                if (!mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      '$skillName added',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Failed to add skill',
                    ),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Student Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            FutureBuilder<
                Map<String, dynamic>>(
              future: _futureStudent,
              builder:
                  (context, snapshot) {
                if (snapshot
                        .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .all(16),
                      child: Text(
                        'Could not load profile:\n${snapshot.error}',
                        style:
                            const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                }

                final student =
                    snapshot.data!;

                final fullName =
                    student['full_name'] ??
                        'No Name';

                final university =
                    student['university'] ??
                        'University';

                final major =
                    student['major'] ??
                        'N/A';

                final experience =
                    student[
                            'experience_years'] ??
                        0;

                return Card(
                  elevation: 2,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                            16),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor:
                                  Color(
                                      0xFF7C3AED),
                              child: Icon(
                                Icons.person,
                                size: 36,
                                color:
                                    Colors.white,
                              ),
                            ),
                            const SizedBox(
                                width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    fullName
                                        .toString(),
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          20,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                  Text(
                                    university
                                        .toString(),
                                    style:
                                        TextStyle(
                                      color:
                                          Colors.grey[
                                              600],
                                      fontSize:
                                          14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                            height: 24),
                        Text(
                          'Major: $major',
                          style:
                              const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(
                            height: 8),
                        Text(
                          'Experience: $experience years',
                          style:
                              const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                const Text(
                  'Technical Skills',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color:
                        Color(0xFF7C3AED),
                  ),
                  onPressed: () {
                    _showAddSkillDialog(
                        context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_isLoadingSkills)
              const Center(
                child:
                    CircularProgressIndicator(),
              )
            else if (_skillsError != null)
              Text(
                'Could not load skills: $_skillsError',
                style: const TextStyle(
                  color: Colors.red,
                ),
              )
            else if (_skills.isEmpty)
              const Text(
                'No skills added yet.',
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children:
                    _skills.map((skill) {
                  final skillName =
                      skill['name']
                              ?.toString() ??
                          'Skill';

                  return Chip(
                    label:
                        Text(skillName),
                    backgroundColor:
                        Colors
                            .purple.shade50,
                    labelStyle:
                        const TextStyle(
                      color:
                          Color(0xFF7C3AED),
                    ),
                    deleteIcon:
                        const Icon(
                      Icons.close,
                      size: 16,
                      color:
                          Color(0xFF7C3AED),
                    ),
                    onDeleted: () async {
                      final success =
                          await ApiService
                              .deleteStudentSkill(
                        studentId,
                        skillName,
                      );

                      if (!mounted) {
                        return;
                      }

                      if (success) {
                        await _loadSkills();
                      } else {
                        if (!mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(
                                context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Failed to delete skill',
                            ),
                          ),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}