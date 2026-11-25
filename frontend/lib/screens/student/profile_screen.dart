import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/skill_item.dart';
import '../../models/student_profile.dart';
import '../../services/student_service.dart';
import '../../services/vacancy_service.dart';
import '../../state/session_controller.dart';
import '../../widgets/skill_chip.dart';
<<<<<<< HEAD
import '../admin/admin_analytics_screen.dart';
=======
import '../../services/analytics_service.dart';
>>>>>>> edd3f89 (Add Firebase Analytics and update frontend)

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<StudentProfile> _futureStudent;
  List<SkillItem> _skills = [];
  List<StudentApplication> _applications = [];
  bool _isLoadingSkills = true;
  String? _skillsError;

  int get _studentId => SessionController.instance.activeStudentProfileId;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    _futureStudent = StudentService.fetchProfile(_studentId);
    await Future.wait([
      _loadSkills(),
      StudentService.fetchLanguages(_studentId),
      _loadApplications(),
    ]);
    if (mounted) setState(() {});
  }

  Future<void> _loadSkills() async {
    try {
      final skills = await StudentService.fetchSkills(_studentId);
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

  Future<void> _loadApplications() async {
    final apps = await StudentService.fetchApplications(_studentId);
    if (!mounted) return;
    setState(() => _applications = apps);
  }

  int _calculateCompleteness(StudentProfile student, int langCount) {
    int score = 30;
    if (student.targetRole.trim().isNotEmpty) score += 10;
    if (student.bio.trim().isNotEmpty) score += 15;
    if (student.githubUrl.trim().isNotEmpty ||
        student.linkedinUrl.trim().isNotEmpty) {
      score += 15;
    }
    if (_skills.length >= 3) {
      score += 20;
    } else if (_skills.isNotEmpty) {
      score += 10;
    }
    if (langCount > 0) score += 10;
    return score.clamp(0, 100);
  }

  void _openAdminPanel() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()),
    );
  }

  void _showEditProfileDialog(StudentProfile current) {
    final nameCtrl = TextEditingController(text: current.fullName);
    final roleCtrl = TextEditingController(text: current.targetRole);
    final uniCtrl = TextEditingController(text: current.university);
    final majorCtrl = TextEditingController(text: current.major);
    final expCtrl =
        TextEditingController(text: current.experienceYears.toString());
    final bioCtrl = TextEditingController(text: current.bio);
    final githubCtrl = TextEditingController(text: current.githubUrl);
    final linkedinCtrl = TextEditingController(text: current.linkedinUrl);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Student Profile'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: roleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Target Role',
                    hintText: 'e.g. Backend Go / Flutter Developer',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: uniCtrl,
                  decoration: const InputDecoration(labelText: 'University'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: majorCtrl,
                        decoration: const InputDecoration(labelText: 'Major'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: expCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Experience (yrs)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'About Me / Bio',
                    hintText: 'Projects, hackathon wins, interests...',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: githubCtrl,
                  decoration: const InputDecoration(
                    labelText: 'GitHub URL',
                    hintText: 'https://github.com/username',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: linkedinCtrl,
                  decoration: const InputDecoration(
                    labelText: 'LinkedIn / Portfolio URL',
                    hintText: 'https://linkedin.com/in/username',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final updated = current.copyWith(
                fullName: nameCtrl.text.trim(),
                targetRole: roleCtrl.text.trim(),
                university: uniCtrl.text.trim(),
                major: majorCtrl.text.trim(),
                experienceYears: double.tryParse(expCtrl.text.trim()) ??
                    current.experienceYears,
                bio: bioCtrl.text.trim(),
                githubUrl: githubCtrl.text.trim(),
                linkedinUrl: linkedinCtrl.text.trim(),
              );
              Navigator.pop(dialogCtx);

              final ok = await StudentService.updateProfile(updated);

              if (!mounted) return;

              if (ok) {
                await AnalyticsService.profileUpdated();

                if (!mounted) return;

                setState(() {
                  _futureStudent = StudentService.fetchProfile(_studentId);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile saved to database'),
                    backgroundColor: AppTheme.brandPurple,
                  ),
                );
              }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                }

  Future<void> _showAddSkillDialog() async {
    final catalog = await StudentService.fetchSkillsCatalog();
    if (!mounted) return;

    final searchCtrl = TextEditingController();
    String selectedSkill = '';
    String selectedCategory = 'All';
    String selectedLevel = SkillLevels.all[1];

    final categories = <String>{
      'All',
      ...catalog.map((e) => e.category ?? 'Technical'),
    }.toList();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (sbContext, setDialogState) {
          final query = searchCtrl.text.trim().toLowerCase();
          final existingNames =
              _skills.map((s) => s.name.toLowerCase()).toSet();

          final filteredCatalog = catalog.where((item) {
            final matchesCat = selectedCategory == 'All' ||
                (item.category ?? 'Technical') == selectedCategory;
            if (!matchesCat) return false;
            if (query.isEmpty) return true;
            return item.name.toLowerCase().contains(query) ||
                (item.category?.toLowerCase().contains(query) ?? false);
          }).toList();

          final exactMatchInCatalog = catalog.any(
            (item) => item.name.toLowerCase() == query,
          );

          return AlertDialog(
            title: Text('Skills Catalog (${catalog.length})'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    onChanged: (val) {
                      setDialogState(() {
                        selectedSkill = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search skill',
                      hintText: 'Go, Python, Docker, Figma, SQL...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                searchCtrl.clear();
                                setDialogState(() => selectedSkill = '');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (_, idx) {
                        final cat = categories[idx];
                        final isSel = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat, style: const TextStyle(fontSize: 11)),
                          selected: isSel,
                          selectedColor: AppTheme.brandPurpleLight,
                          onSelected: (_) =>
                              setDialogState(() => selectedCategory = cat),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ...filteredCatalog.map((item) {
                            final alreadyAdded =
                                existingNames.contains(item.name.toLowerCase());
                            final isSelected = selectedSkill.toLowerCase() ==
                                item.name.toLowerCase();

                            return ListTile(
                              dense: true,
                              selected: isSelected,
                              selectedTileColor: AppTheme.brandPurpleLight,
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: item.category != null
                                  ? Text(
                                      item.category!,
                                      style: const TextStyle(fontSize: 11),
                                    )
                                  : null,
                              trailing: alreadyAdded
                                  ? const Chip(
                                      label: Text(
                                        'Added',
                                        style: TextStyle(fontSize: 10),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    )
                                  : isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: AppTheme.brandPurple,
                                          size: 20,
                                        )
                                      : null,
                              onTap: () {
                                setDialogState(() {
                                  selectedSkill = item.name;
                                  searchCtrl.text = item.name;
                                  searchCtrl.selection =
                                      TextSelection.fromPosition(
                                    TextPosition(
                                      offset: searchCtrl.text.length,
                                    ),
                                  );
                                });
                              },
                            );
                          }),
                          if (query.isNotEmpty && !exactMatchInCatalog)
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.add_circle_outline,
                                color: AppTheme.brandPurple,
                              ),
                              title: Text(
                                'Add custom skill "${searchCtrl.text.trim()}"',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.brandPurple,
                                ),
                              ),
                              onTap: () {
                                setDialogState(() {
                                  selectedSkill = searchCtrl.text.trim();
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedLevel,
                    decoration: const InputDecoration(
                      labelText: 'Proficiency Level',
                    ),
                    items: SkillLevels.all
                        .map(
                          (lvl) => DropdownMenuItem(
                            value: lvl,
                            child: Text(lvl),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedLevel = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: selectedSkill.trim().isEmpty
                    ? null
                    : () async {
                        final skillName = selectedSkill.trim();
                        Navigator.pop(dialogContext);

                        final success = await StudentService.addSkill(
                          _studentId,
                          skillName,
                          level: selectedLevel,
                        );
                        if (!mounted) return;

                        if (success) {
                          await _loadSkills();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('$skillName ($selectedLevel) saved'),
                            ),
                          );
                        }
                      },
                child: const Text('Save Skill'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddLanguageDialog() {
    String selectedLanguage = LanguageLevels.supportedLanguages.first;
    String selectedLevel = LanguageLevels.cefrLevels[3];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (sbContext, setDialogState) => AlertDialog(
          title: const Text('Add Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedLanguage,
                decoration: const InputDecoration(labelText: 'Language'),
                items: LanguageLevels.supportedLanguages
                    .map(
                      (lang) => DropdownMenuItem(
                        value: lang,
                        child: Text(lang),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedLanguage = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedLevel,
                decoration: const InputDecoration(labelText: 'CEFR Level'),
                items: LanguageLevels.cefrLevels
                    .map(
                      (lvl) => DropdownMenuItem(
                        value: lvl,
                        child: Text(lvl),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedLevel = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await StudentService.saveLanguage(
                  _studentId,
                  LanguageItem(
                    languageName: selectedLanguage,
                    proficiencyLevel: selectedLevel,
                  ),
                );
                if (mounted) setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showApplicationDetailsDialog(StudentApplication app) {
    Color badgeBg = AppTheme.brandPurpleLight;
    Color badgeFg = AppTheme.brandPurple;
    if (app.status == 'Approved') {
      badgeBg = Colors.green.shade50;
      badgeFg = Colors.green.shade800;
    } else if (app.status == 'Rejected') {
      badgeBg = Colors.red.shade50;
      badgeFg = Colors.red.shade800;
    } else if (app.status == 'Interview') {
      badgeBg = Colors.orange.shade50;
      badgeFg = Colors.orange.shade900;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.title, style: const TextStyle(fontSize: 18)),
                  Text(
                    app.company,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.brandPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(
                app.status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: badgeFg,
                ),
              ),
              backgroundColor: badgeBg,
            ),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI Match Score at submission: ${app.matchScore}%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Submitted: ${app.appliedAt}${app.updatedAt.isNotEmpty ? ' • Updated: ${app.updatedAt}' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Your Cover Note',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    app.coverLetter.isNotEmpty
                        ? app.coverLetter
                        : 'No cover note was attached to this application.',
                    style: TextStyle(
                      fontSize: 13,
                      color: app.coverLetter.isNotEmpty
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                ),
                if (app.companyFeedback.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Company Response',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      app.companyFeedback,
                      style: TextStyle(
                        fontSize: 13,
                        color: badgeFg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (app.status == 'Applied')
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await VacancyService.withdrawApplication(app.id);

                if (ok) {
                  await AnalyticsService.applicationWithdrawn(
                    applicationId: app.id,
                    vacancyId: app.vacancyId,
                  );
                }

                if (ok && mounted) {
                  await _loadApplications();
                }
              },
              child: const Text(
                'Withdraw',
                style: TextStyle(color: Colors.red),
              ),
            ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              SessionController.instance.openVacancyDetail(app.vacancyId);
              Navigator.pushNamed(
                context,
                '/vacancy-detail',
                arguments: app.vacancyId,
              );
            },
            child: const Text('Open Vacancy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        actions: [
          ListenableBuilder(
            listenable: SessionController.instance,
            builder: (context, _) {
              if (!SessionController.instance.isAdmin) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'Admin Analytics',
                icon: const Icon(Icons.admin_panel_settings_rounded),
                onPressed: _openAdminPanel,
              );
            },
          ),
          IconButton(
            tooltip: 'Refresh Profile',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshAll,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              SessionController.instance.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 740),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListenableBuilder(
                    listenable: SessionController.instance,
                    builder: (context, _) {
                      if (!SessionController.instance.isAdmin) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          color: AppTheme.brandPurpleLight,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.brandPurple,
                              child: Icon(
                                Icons.analytics_outlined,
                                color: Colors.white,
                              ),
                            ),
                            title: const Text(
                              'Admin Analytics Panel',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Platform KPIs, universities, companies & skill demand',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppTheme.brandPurple,
                            ),
                            onTap: _openAdminPanel,
                          ),
                        ),
                      );
                    },
                  ),
                  FutureBuilder<StudentProfile>(
                    future: _futureStudent,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Could not load profile:\n${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }

                      final student = snapshot.data!;
                      final langCount =
                          SessionController.instance.studentLanguages.length;
                      final completeness =
                          _calculateCompleteness(student, langCount);

                      return Column(
                        children: [
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 32,
                                        backgroundColor: AppTheme.brandPurple,
                                        child: Text(
                                          student.fullName.isNotEmpty
                                              ? student.fullName[0]
                                                  .toUpperCase()
                                              : 'S',
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student.fullName,
                                              style: const TextStyle(
                                                fontSize: 21,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (student
                                                .targetRole.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                student.targetRole,
                                                style: const TextStyle(
                                                  color: AppTheme.brandPurple,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 2),
                                            Text(
                                              '${student.university} • ${student.major}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            _showEditProfileDialog(student),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 16,
                                        ),
                                        label: const Text('Edit'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.brandPurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      _StatChip(
                                        icon: Icons.work_history_outlined,
                                        label:
                                            '${student.experienceYears} yrs exp',
                                      ),
                                      const SizedBox(width: 10),
                                      _StatChip(
                                        icon: Icons.code_rounded,
                                        label: '${_skills.length} skills',
                                      ),
                                      const SizedBox(width: 10),
                                      _StatChip(
                                        icon: Icons.send_outlined,
                                        label:
                                            '${_applications.length} applied',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Profile Readiness',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '$completeness%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.brandPurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: completeness / 100,
                                      minHeight: 8,
                                      backgroundColor:
                                          AppTheme.brandPurpleLight,
                                      color: AppTheme.brandPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'About & Links',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            _showEditProfileDialog(student),
                                        child: const Text('Update'),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    student.bio.isNotEmpty
                                        ? student.bio
                                        : 'Add a short summary about your projects, coursework and career goals.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: student.bio.isNotEmpty
                                          ? Colors.black87
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  if (student.githubUrl.isNotEmpty ||
                                      student.linkedinUrl.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        if (student.githubUrl.isNotEmpty)
                                          Chip(
                                            avatar: const Icon(
                                              Icons.code,
                                              size: 16,
                                              color: AppTheme.brandPurple,
                                            ),
                                            label: Text(student.githubUrl),
                                            backgroundColor:
                                                AppTheme.brandPurpleLight,
                                          ),
                                        if (student.linkedinUrl.isNotEmpty)
                                          Chip(
                                            avatar: const Icon(
                                              Icons.link,
                                              size: 16,
                                              color: AppTheme.brandPurple,
                                            ),
                                            label: Text(student.linkedinUrl),
                                            backgroundColor:
                                                AppTheme.brandPurpleLight,
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Technical Skills',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Browse & Add'),
                        onPressed: _showAddSkillDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingSkills)
                    const Center(child: CircularProgressIndicator())
                  else if (_skillsError != null)
                    Text(
                      'Could not load skills: $_skillsError',
                      style: const TextStyle(color: Colors.red),
                    )
                  else if (_skills.isEmpty)
                    const Text(
                      'No skills added yet. Tap "Browse & Add" to search the skills catalog.',
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _skills.map((skill) {
                        return SkillChip(
                          name: skill.name,
                          level: skill.level,
                          onDelete: () async {
                            final ok = await StudentService.deleteSkill(
                              _studentId,
                              skill.name,
                            );
                            if (ok && mounted) await _loadSkills();
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Languages',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppTheme.brandPurple,
                        ),
                        onPressed: _showAddLanguageDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListenableBuilder(
                    listenable: SessionController.instance,
                    builder: (context, _) {
                      final languages =
                          SessionController.instance.studentLanguages;
                      if (languages.isEmpty) {
                        return const Text('No languages specified yet.');
                      }
                      return Column(
                        children: languages.map((lang) {
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppTheme.brandPurpleLight,
                                child: Icon(
                                  Icons.translate_rounded,
                                  color: AppTheme.brandPurple,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                lang.languageName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle:
                                  Text('CEFR Level: ${lang.proficiencyLevel}'),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete_outline, size: 20),
                                onPressed: () async {
                                  await StudentService.deleteLanguage(
                                    _studentId,
                                    lang.languageName,
                                  );
                                  if (mounted) setState(() {});
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'My Applications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_applications.isEmpty)
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'You have not applied to any vacancies yet.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _applications.map((app) {
                        Color badgeBg = AppTheme.brandPurpleLight;
                        Color badgeFg = AppTheme.brandPurple;
                        if (app.status == 'Approved') {
                          badgeBg = Colors.green.shade50;
                          badgeFg = Colors.green.shade800;
                        } else if (app.status == 'Rejected') {
                          badgeBg = Colors.red.shade50;
                          badgeFg = Colors.red.shade800;
                        } else if (app.status == 'Interview') {
                          badgeBg = Colors.orange.shade50;
                          badgeFg = Colors.orange.shade900;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showApplicationDetailsDialog(app),
                            child: Card(
                              color: Colors.white,
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const CircleAvatar(
                                          backgroundColor:
                                              AppTheme.brandPurpleLight,
                                          child: Icon(
                                            Icons.work_outline,
                                            color: AppTheme.brandPurple,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                app.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                '${app.company} • Match: ${app.matchScore}%',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Chip(
                                          label: Text(
                                            app.status,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: badgeFg,
                                            ),
                                          ),
                                          backgroundColor: badgeBg,
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                    if (app.companyFeedback.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: badgeBg,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Company response: ${app.companyFeedback}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: badgeFg,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (app.status == 'Applied') ...[
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () async {
                                            final ok = await VacancyService
                                                .withdrawApplication(app.id);

                                            if (ok) {
                                              await AnalyticsService
                                                  .applicationWithdrawn(
                                                applicationId: app.id,
                                                vacancyId: app.vacancyId,
                                              );
                                            }

                                            if (ok && mounted) {
                                              await _loadApplications();
                                            }
                                          },
                                          child: const Text(
                                            'Withdraw Application',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.brandPurple),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}