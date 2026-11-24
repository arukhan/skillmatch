import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../services/learning_service.dart';
import '../../services/student_service.dart';
import '../../state/session_controller.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late Future<List<CourseItem>> _futureCourses;
  final _searchCtrl = TextEditingController();

  String _tabFilter = 'All';
  bool _freeOnly = false;
  String _selectedLang = 'All';
  String _selectedLevel = 'All';
  String _selectedProvider = 'All';

  int get _studentId => SessionController.instance.activeStudentProfileId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _futureCourses = LearningService.fetchCourses(
      _studentId,
      freeOnly: _freeOnly,
      language: _selectedLang,
      level: _selectedLevel,
      provider: _selectedProvider,
      query: _searchCtrl.text.trim(),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCourseUrl(String url) async {
    if (url.trim().isEmpty) return;
    final uri = Uri.parse(url.trim());
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  Future<void> _changeStatus(CourseItem course, String status) async {
    if (status == 'Completed') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Complete Course & Claim Skill?'),
          content: Text(
            'Completing "${course.title}" will add ${course.skillName} (${course.level}) to your Profile and automatically recalculate your Match Score across matching vacancies.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not Yet'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm & Claim'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      final result = await LearningService.updateCourseStatus(
        courseId: course.id,
        studentProfileId: _studentId,
        status: status,
      );
      if (status == 'Completed') {
        final skills = await StudentService.fetchSkills(_studentId);
        SessionController.instance.setStudentSkills(skills);
      }
      if (!mounted) return;
      setState(_reload);

      String msg;
      if (status == 'Completed') {
        if (result.addedSkill.isNotEmpty) {
          final boostNote = result.boostedVacancies > 0
              ? ' Match Score boosted for ${result.boostedVacancies} open vacancies!'
              : ' Added to your Profile skills.';
          msg =
              'Claimed ${result.addedSkill} (${result.addedLevel})!$boostNote';
        } else {
          msg = 'Course marked as Completed!';
        }
      } else {
        msg = 'Enrolled in "${course.title}"!';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: status == 'Completed'
              ? Colors.green.shade700
              : AppTheme.brandPurple,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['All', 'Recommended', 'My Courses'];
    const langs = ['All', 'RU', 'EN'];
    const levels = ['All', 'Beginner', 'Intermediate', 'Advanced'];
    const providers = ['All', 'Company', 'Stepik', 'Coursera'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill-Up Courses'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(_reload),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await _futureCourses;
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => setState(_reload),
                    onChanged: (_) => setState(_reload),
                    decoration: InputDecoration(
                      hintText:
                          'Search by skill, course title or platform (Go, Docker, Kafka, Stepik)...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(_reload);
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ...tabs.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: _tabFilter == f,
                            selectedColor: AppTheme.brandPurpleLight,
                            onSelected: (_) => setState(() => _tabFilter = f),
                          ),
                        ),
                      ),
                      FilterChip(
                        label: const Text('Free Only'),
                        selected: _freeOnly,
                        selectedColor: Colors.green.shade100,
                        checkmarkColor: Colors.green.shade800,
                        onSelected: (val) => setState(() {
                          _freeOnly = val;
                          _reload();
                        }),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedLang,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'Language',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          items: langs
                              .map(
                                (l) => DropdownMenuItem(
                                  value: l,
                                  child: Text(
                                    l,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _selectedLang = v;
                                _reload();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedLevel,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'Level',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          items: levels
                              .map(
                                (lvl) => DropdownMenuItem(
                                  value: lvl,
                                  child: Text(
                                    lvl,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _selectedLevel = v;
                                _reload();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedProvider,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'Source',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          items: providers
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    p == 'Company' ? 'Partner Co.' : p,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _selectedProvider = v;
                                _reload();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<CourseItem>>(
                    future: _futureCourses,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Could not load courses:\n${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final all = snapshot.data ?? [];
                      final courses = all.where((c) {
                        if (_tabFilter == 'Recommended') {
                          return c.isRecommended &&
                              c.enrollmentStatus != 'Completed';
                        } else if (_tabFilter == 'My Courses') {
                          return c.enrollmentStatus.isNotEmpty;
                        }
                        return true;
                      }).toList();

                      if (courses.isEmpty) {
                        return const Center(
                          child: Text('No courses match selected filters.'),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: courses.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final c = courses[index];
                          final isCompleted = c.enrollmentStatus == 'Completed';
                          final isEnrolled = c.enrollmentStatus == 'Enrolled';

                          return Card(
                            color: Colors.white,
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (c.isRecommended && !isCompleted) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.brandPurpleLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome,
                                            size: 14,
                                            color: AppTheme.brandPurple,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              c.recommendationReason,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.brandPurple,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
                                              c.title,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${c.provider} • ${c.duration} • ${c.level} • ${c.language}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          c.isFree ? 'Free' : 'Pro',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: c.isFree
                                                ? Colors.green.shade800
                                                : Colors.orange.shade900,
                                          ),
                                        ),
                                        backgroundColor: c.isFree
                                            ? Colors.green.shade50
                                            : Colors.orange.shade50,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  if (c.description.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      c.description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[800],
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Chip(
                                        avatar: const Icon(
                                          Icons.code,
                                          size: 15,
                                          color: AppTheme.brandPurple,
                                        ),
                                        label: Text(
                                          '+ ${c.skillName} (${c.level})',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        backgroundColor:
                                            AppTheme.backgroundLight,
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (c.externalUrl.isNotEmpty) ...[
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _openCourseUrl(c.externalUrl),
                                              icon: const Icon(
                                                Icons.open_in_new,
                                                size: 16,
                                              ),
                                              label: const Text('Open Site'),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          if (isCompleted)
                                            Chip(
                                              avatar: const Icon(
                                                Icons.verified,
                                                color: Colors.green,
                                                size: 18,
                                              ),
                                              label: const Text(
                                                'Skill Claimed',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              backgroundColor:
                                                  Colors.green.shade50,
                                            )
                                          else if (isEnrolled)
                                            ElevatedButton.icon(
                                              onPressed: () =>
                                                  _changeStatus(c, 'Completed'),
                                              icon: const Icon(
                                                Icons.check_circle_outline,
                                                size: 18,
                                              ),
                                              label: const Text('Claim Skill'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.green.shade700,
                                                foregroundColor: Colors.white,
                                              ),
                                            )
                                          else
                                            ElevatedButton(
                                              onPressed: () =>
                                                  _changeStatus(c, 'Enrolled'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppTheme.brandPurple,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Enroll'),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
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