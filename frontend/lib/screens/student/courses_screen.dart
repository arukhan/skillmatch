import 'package:flutter/material.dart';
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
  String _selectedFilter = 'All';

  int get _studentId => SessionController.instance.activeStudentProfileId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _futureCourses = LearningService.fetchCourses(_studentId);
  }

  Future<void> _changeStatus(CourseItem course, String status) async {
    try {
      final addedSkill = await LearningService.updateCourseStatus(
        courseId: course.id,
        studentProfileId: _studentId,
        status: status,
      );
      if (status == 'Completed') {
        await StudentService.fetchSkills(_studentId);
      }
      if (!mounted) return;
      setState(_reload);

      final msg = status == 'Completed'
          ? (addedSkill.isNotEmpty
              ? 'Course completed! "$addedSkill" added to your Profile skills.'
              : 'Course marked as Completed!')
          : 'Enrolled in "${course.title}"!';

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
    const filters = ['All', 'Recommended', 'My Courses'];

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
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    children: filters.map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: _selectedFilter == f,
                          selectedColor: AppTheme.brandPurpleLight,
                          onSelected: (_) =>
                              setState(() => _selectedFilter = f),
                        ),
                      );
                    }).toList(),
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
                        if (_selectedFilter == 'Recommended') {
                          return c.isRecommended &&
                              c.enrollmentStatus != 'Completed';
                        }
                        if (_selectedFilter == 'My Courses') {
                          return c.enrollmentStatus.isNotEmpty;
                        }
                        return true;
                      }).toList();

                      // Рекомендованные поднимаем вверх
                      courses.sort((a, b) {
                        final aRec = a.isRecommended ? 1 : 0;
                        final bRec = b.isRecommended ? 1 : 0;
                        return bRec.compareTo(aRec);
                      });

                      if (courses.isEmpty) {
                        return const Center(
                          child: Text('No courses match this filter.'),
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
                                              '${c.provider} • ${c.duration} • ${c.level}',
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Chip(
                                        avatar: const Icon(
                                          Icons.code,
                                          size: 15,
                                          color: AppTheme.brandPurple,
                                        ),
                                        label: Text(
                                          'Skill: ${c.skillName}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        backgroundColor:
                                            AppTheme.backgroundLight,
                                      ),
                                      if (isCompleted)
                                        Chip(
                                          avatar: const Icon(
                                            Icons.verified,
                                            color: Colors.green,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Completed',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          backgroundColor: Colors.green.shade50,
                                        )
                                      else if (isEnrolled)
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              _changeStatus(c, 'Completed'),
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Complete & Claim Skill',
                                          ),
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
                                          child: const Text('Start Course'),
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