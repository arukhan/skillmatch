import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/skill_item.dart';
import '../../models/student_profile.dart';
import '../../services/student_service.dart';
import '../../state/session_controller.dart';
import '../../widgets/skill_chip.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<StudentProfile> _futureStudent;
  List<SkillItem> _skills = [];
  bool _isLoadingSkills = true;
  String? _skillsError;

  int get _studentId => SessionController.instance.activeStudentProfileId;

  @override
  void initState() {
    super.initState();
    _futureStudent = StudentService.fetchProfile(_studentId);
    _loadSkills();
    StudentService.fetchLanguages(_studentId);
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

  void _showEditProfileDialog(StudentProfile current) {
    final nameCtrl = TextEditingController(text: current.fullName);
    final uniCtrl = TextEditingController(text: current.university);
    final majorCtrl = TextEditingController(text: current.major);
    final expCtrl =
        TextEditingController(text: current.experienceYears.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Student Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: uniCtrl,
                decoration: const InputDecoration(labelText: 'University'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: majorCtrl,
                decoration: const InputDecoration(labelText: 'Major'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: expCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Experience (years)'),
              ),
            ],
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
                university: uniCtrl.text.trim(),
                major: majorCtrl.text.trim(),
                experienceYears: double.tryParse(expCtrl.text.trim()) ??
                    current.experienceYears,
              );
              Navigator.pop(dialogCtx);

              final ok = await StudentService.updateProfile(updated);
              if (!mounted) return;
              if (ok) {
                setState(() {
                  _futureStudent = StudentService.fetchProfile(_studentId);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddSkillDialog() {
    final controller = TextEditingController();
    String selectedLevel = SkillLevels.all[1];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Technical Skill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Skill Name',
                  hintText: 'e.g. Docker, Git, Redis',
                ),
              ),
              const SizedBox(height: 16),
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
                final skillName = controller.text.trim();
                if (skillName.isEmpty) return;
                Navigator.pop(dialogContext);

                final success = await StudentService.addSkill(
                  _studentId,
                  skillName,
                  level: selectedLevel,
                );
                if (!mounted) return;

                if (success) {
                  await _loadSkills();
                  final updatedList = _skills.map((s) {
                    if (s.name.toLowerCase() == skillName.toLowerCase() &&
                        (s.level == null || s.level!.isEmpty)) {
                      return SkillItem(name: s.name, level: selectedLevel);
                    }
                    return s;
                  }).toList();
                  SessionController.instance.setStudentSkills(updatedList);
                  setState(() => _skills = updatedList);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLanguageDialog() {
    String selectedLanguage = LanguageLevels.supportedLanguages.first;
    String selectedLevel = LanguageLevels.cefrLevels[3];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                decoration:
                    const InputDecoration(labelText: 'Proficiency Level'),
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.brandPurpleLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 18,
                      color: AppTheme.brandPurple,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Certificate verification (IELTS, TOEFL, HSK) will be available soon.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        actions: [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    return Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 30,
                                  backgroundColor: AppTheme.brandPurple,
                                  child: Icon(
                                    Icons.person,
                                    size: 34,
                                    color: Colors.white,
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
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        student.university,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Edit Profile',
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: AppTheme.brandPurple,
                                  ),
                                  onPressed: () =>
                                      _showEditProfileDialog(student),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(
                              'Major: ${student.major}',
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Experience: ${student.experienceYears} years',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Technical Skills',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppTheme.brandPurple,
                      ),
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
                  const Text('No skills added yet.')
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

                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Languages',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Row(
                              children: [
                                Text(lang.proficiencyLevel),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    lang.verificationStatus.label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () async {
                                await StudentService.deleteLanguage(
                                  _studentId,
                                  lang.languageName,
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
