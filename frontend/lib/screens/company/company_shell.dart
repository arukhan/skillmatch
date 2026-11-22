import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/skill_item.dart';
import '../../models/vacancy.dart';
import '../../services/student_service.dart';
import '../../services/vacancy_service.dart';
import '../../state/session_controller.dart';
import '../../widgets/skill_chip.dart';

class CompanyShell extends StatefulWidget {
  const CompanyShell({super.key});

  @override
  State<CompanyShell> createState() => _CompanyShellState();
}

class _CompanyShellState extends State<CompanyShell> {
  int _selectedTab = 0;
  late Future<List<Vacancy>> _futureVacancies;
  late Future<List<CompanyApplicant>> _futureApplicants;

  int? _filterVacancyId;
  String _filterStatus = 'All';

  final _titleController = TextEditingController();
  final _locationController = TextEditingController(text: 'Almaty');
  final _expController = TextEditingController(text: '1');
  final _salaryController =
      TextEditingController(text: '250,000 - 400,000 KZT');
  final _descController = TextEditingController();

  String _employmentType = 'Internship';
  String _workFormat = 'Hybrid';
  final List<String> _requiredSkills = ['Go', 'PostgreSQL', 'Git'];
  bool _isPosting = false;

  int get _companyId => SessionController.instance.activeCompanyId;

  @override
  void initState() {
    super.initState();
    _selectedTab = SessionController.instance.companyTabIndex.clamp(0, 2);
    _reloadData();
  }

  void _reloadData() {
    _futureVacancies = VacancyService.fetchVacancies(companyId: _companyId);
    _futureApplicants = VacancyService.fetchCompanyApplicants(
      companyId: _companyId,
      vacancyId: _filterVacancyId,
      status: _filterStatus,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _expController.dispose();
    _salaryController.dispose();
    _descController.dispose();
    super.dispose();
  }

  double _parseExperience(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  Color _statusBgColor(String status) {
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

  Color _statusTextColor(String status) {
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

  Future<void> _showDecisionDialog(
    CompanyApplicant applicant,
    String targetStatus,
  ) async {
    final feedbackCtrl =
        TextEditingController(text: applicant.companyFeedback);

    String dialogTitle;
    String hintText;
    Color btnColor;

    switch (targetStatus) {
      case 'Approved':
        dialogTitle = 'Approve Candidate';
        hintText =
            'Welcome message, next steps, or offer details (optional)...';
        btnColor = Colors.green.shade700;
        break;
      case 'Interview':
        dialogTitle = 'Invite to Interview';
        hintText =
            'Date, time, Google Meet link, or Telegram contact...';
        btnColor = Colors.orange.shade800;
        break;
      default:
        dialogTitle = 'Reject Application';
        hintText =
            'Polite feedback or missing skills note for the student...';
        btnColor = Colors.red.shade700;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$dialogTitle: ${applicant.studentName}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vacancy: ${applicant.vacancyTitle} • Match: ${applicant.matchScore}%',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackCtrl,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Message / Feedback to Student',
                  hintText: hintText,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirm $targetStatus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await VacancyService.updateApplicationStatus(
      applicationId: applicant.applicationId,
      status: targetStatus,
      companyFeedback: feedbackCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      setState(() => _reloadData());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${applicant.studentName} marked as $targetStatus',
          ),
          backgroundColor: btnColor,
        ),
      );
    }
  }

  void _showCandidateDossier(CompanyApplicant applicant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.brandPurple,
              child: Text(
                applicant.studentName.isNotEmpty
                    ? applicant.studentName[0].toUpperCase()
                    : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    applicant.studentName,
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    '${applicant.university} • ${applicant.major}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(
                '${applicant.matchScore}% Match',
                style: const TextStyle(
                  color: AppTheme.brandPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppTheme.brandPurpleLight,
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (applicant.targetRole.isNotEmpty)
                  Text(
                    'Target Role: ${applicant.targetRole} (${applicant.experienceYears} yrs exp)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                if (applicant.studentEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Email: ${applicant.studentEmail}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
                if (applicant.githubUrl.isNotEmpty ||
                    applicant.linkedinUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (applicant.githubUrl.isNotEmpty)
                        Chip(
                          avatar: const Icon(Icons.code, size: 16),
                          label: Text(applicant.githubUrl),
                        ),
                      if (applicant.linkedinUrl.isNotEmpty)
                        Chip(
                          avatar: const Icon(Icons.link, size: 16),
                          label: Text(applicant.linkedinUrl),
                        ),
                    ],
                  ),
                ],
                if (applicant.bio.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'About Candidate',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(applicant.bio),
                ],
                if (applicant.coverLetter.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.brandPurpleLight.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cover Note',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandPurple,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(applicant.coverLetter),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Vacancy Skill Match',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...applicant.matchedSkills.map(
                      (s) => Chip(
                        avatar: const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.green.shade50,
                      ),
                    ),
                    ...applicant.missingSkills.map(
                      (s) => Chip(
                        avatar: const Icon(
                          Icons.cancel_outlined,
                          size: 16,
                          color: Colors.red,
                        ),
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.red.shade50,
                      ),
                    ),
                  ],
                ),
                if (applicant.studentSkills.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'All Candidate Skills',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: applicant.studentSkills
                        .map((s) => SkillChip(name: s.name, level: s.level))
                        .toList(),
                  ),
                ],
                if (applicant.studentLanguages.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Languages',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: applicant.studentLanguages
                        .map(
                          (l) => Chip(
                            label: Text(
                              '${l.languageName} (${l.proficiencyLevel})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showDecisionDialog(applicant, 'Rejected');
            },
            child: const Text('Reject'),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange.shade800,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showDecisionDialog(applicant, 'Interview');
            },
            child: const Text('Interview'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showDecisionDialog(applicant, 'Approved');
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSkillPickerDialog() async {
    final catalog = await StudentService.fetchSkillsCatalog();
    if (!mounted) return;

    final searchCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (sbContext, setDialogState) {
          final query = searchCtrl.text.trim().toLowerCase();
          final existingLower =
              _requiredSkills.map((s) => s.toLowerCase()).toSet();

          final filtered = catalog.where((item) {
            if (query.isEmpty) return true;
            return item.name.toLowerCase().contains(query) ||
                (item.category?.toLowerCase().contains(query) ?? false);
          }).toList();

          final exactExists = catalog.any(
            (item) => item.name.toLowerCase() == query,
          );

          return AlertDialog(
            title: const Text('Add Required Skills'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Search skill from catalog',
                      hintText: 'Python, Docker, Flutter, SQL...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                searchCtrl.clear();
                                setDialogState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ...filtered.map((SkillItem item) {
                            final isAdded = existingLower
                                .contains(item.name.toLowerCase());
                            return ListTile(
                              dense: true,
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
                              trailing: isAdded
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    )
                                  : const Icon(
                                      Icons.add_circle_outline,
                                      color: AppTheme.brandPurple,
                                      size: 20,
                                    ),
                              onTap: () {
                                setState(() {
                                  if (isAdded) {
                                    _requiredSkills.removeWhere(
                                      (s) =>
                                          s.toLowerCase() ==
                                          item.name.toLowerCase(),
                                    );
                                  } else {
                                    _requiredSkills.add(item.name);
                                  }
                                });
                                setDialogState(() {});
                              },
                            );
                          }),
                          if (query.isNotEmpty && !exactExists)
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.add_circle,
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
                                final custom = searchCtrl.text.trim();
                                if (custom.isNotEmpty &&
                                    !existingLower
                                        .contains(custom.toLowerCase())) {
                                  setState(() => _requiredSkills.add(custom));
                                  searchCtrl.clear();
                                  setDialogState(() {});
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _publishVacancy() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a job or internship title.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);
    final session = SessionController.instance.session;

    try {
      await VacancyService.createVacancy(
        companyId: _companyId,
        companyName: session?.displayName ?? 'Partner Company',
        title: title,
        description: _descController.text.trim(),
        experienceRequired: _parseExperience(_expController.text),
        employmentType: _employmentType,
        workFormat: _workFormat,
        location: _locationController.text.trim().isEmpty
            ? 'Almaty'
            : _locationController.text.trim(),
        salaryRange: _salaryController.text.trim(),
        skills: List<String>.from(_requiredSkills),
      );

      if (!mounted) return;
      _titleController.clear();
      _descController.clear();

      SessionController.instance.setCompanyTab(0);
      setState(() {
        _selectedTab = 0;
        _reloadData();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vacancy published!'),
          backgroundColor: AppTheme.brandPurple,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish vacancy: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionController.instance.session;

    return Scaffold(
      appBar: AppBar(
        title: Text(session?.displayName ?? 'Company Workspace'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() => _reloadData()),
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
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildMyVacanciesTab(),
          _buildApplicantsTab(),
          _buildCreateVacancyTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        selectedItemColor: AppTheme.brandPurple,
        onTap: (i) {
          setState(() {
            _selectedTab = i;
            if (i == 0 || i == 1) _reloadData();
          });
          SessionController.instance.setCompanyTab(i);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.business_center_outlined),
            activeIcon: Icon(Icons.business_center),
            label: 'Vacancies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Applicants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'Post Vacancy',
          ),
        ],
      ),
    );
  }

  Widget _buildMyVacanciesTab() {
    final session = SessionController.instance.session;

    return FutureBuilder<List<Vacancy>>(
      future: _futureVacancies,
      builder: (context, snapshot) {
        final vacancies = snapshot.data ?? [];
        final totalApplicants =
            vacancies.fold<int>(0, (sum, v) => sum + v.applicantsCount);
        final totalNew =
            vacancies.fold<int>(0, (sum, v) => sum + v.newApplicantsCount);

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _reloadData());
            await _futureVacancies;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 26,
                                backgroundColor: AppTheme.brandPurple,
                                child:
                                    Icon(Icons.business, color: Colors.white),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session?.displayName ?? 'Company Account',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${vacancies.length} vacancies • $totalApplicants total applicants${totalNew > 0 ? ' ($totalNew new)' : ''}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() => _selectedTab = 2);
                                  SessionController.instance.setCompanyTab(2);
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('New Vacancy'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.brandPurple,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (vacancies.isEmpty)
                        const Card(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No vacancies published yet. Tap "New Vacancy" to post your first position.',
                            ),
                          ),
                        )
                      else
                        ...vacancies.map(
                          (v) => Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          v.title,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          v.isActive ? 'Active' : 'Paused',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: v.isActive
                                                ? Colors.green.shade800
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                        backgroundColor: v.isActive
                                            ? Colors.green.shade50
                                            : Colors.grey.shade200,
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (action) async {
                                          if (action == 'toggle') {
                                            await VacancyService
                                                .setVacancyActive(
                                              v.id,
                                              !v.isActive,
                                            );
                                            if (mounted) {
                                              setState(() => _reloadData());
                                            }
                                          } else if (action == 'delete') {
                                            await VacancyService.deleteVacancy(
                                              v.id,
                                            );
                                            if (mounted) {
                                              setState(() => _reloadData());
                                            }
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          PopupMenuItem(
                                            value: 'toggle',
                                            child: Text(
                                              v.isActive
                                                  ? 'Pause Vacancy'
                                                  : 'Reopen Vacancy',
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text(
                                              'Delete Vacancy',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${v.location} • ${v.workFormat} • ${v.employmentType}${v.salaryRange.isNotEmpty ? ' • ${v.salaryRange}' : ''}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  if (v.skills.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: v.skills
                                          .map((s) => SkillChip(name: s))
                                          .toList(),
                                    ),
                                  ],
                                  const Divider(height: 22),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.people_alt_outlined,
                                            size: 18,
                                            color: AppTheme.brandPurple,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${v.applicantsCount} applicants',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (v.newApplicantsCount > 0) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade600,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '+${v.newApplicantsCount} new',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _filterVacancyId = v.id;
                                            _filterStatus = 'All';
                                            _selectedTab = 1;
                                            _reloadData();
                                          });
                                          SessionController.instance
                                              .setCompanyTab(1);
                                        },
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                          size: 16,
                                        ),
                                        label: const Text('Review Applicants'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.brandPurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildApplicantsTab() {
    const statuses = ['All', 'Applied', 'Interview', 'Approved', 'Rejected'];

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _reloadData());
        await _futureApplicants;
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ФИЛЬТР ПО ВАКАНСИИ И СТАТУСУ
                  FutureBuilder<List<Vacancy>>(
                    future: _futureVacancies,
                    builder: (context, vacSnap) {
                      final vacs = vacSnap.data ?? [];
                      return Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<int?>(
                                initialValue: vacs.any(
                                        (v) => v.id == _filterVacancyId)
                                    ? _filterVacancyId
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: 'Filter by Vacancy',
                                  prefixIcon:
                                      Icon(Icons.business_center_outlined),
                                ),
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('All Company Vacancies'),
                                  ),
                                  ...vacs.map(
                                    (v) => DropdownMenuItem<int?>(
                                      value: v.id,
                                      child: Text(
                                        '${v.title} (${v.applicantsCount})',
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _filterVacancyId = val;
                                    _reloadData();
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: statuses.map((st) {
                                    final selected = _filterStatus == st;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(st),
                                        selected: selected,
                                        selectedColor:
                                            AppTheme.brandPurpleLight,
                                        onSelected: (_) {
                                          setState(() {
                                            _filterStatus = st;
                                            _reloadData();
                                          });
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // СПИСОК КАНДИДАТОВ
                  FutureBuilder<List<CompanyApplicant>>(
                    future: _futureApplicants,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Could not load applicants: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }

                      final applicants = snapshot.data ?? [];
                      if (applicants.isEmpty) {
                        return Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No applications match the selected filter yet.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: applicants.map((app) {
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            AppTheme.brandPurpleLight,
                                        child: Text(
                                          app.studentName.isNotEmpty
                                              ? app.studentName[0].toUpperCase()
                                              : 'S',
                                          style: const TextStyle(
                                            color: AppTheme.brandPurple,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              app.studentName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '${app.university} • ${app.major} • ${app.experienceYears} yrs exp',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.brandPurpleLight,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${app.matchScore}% Match',
                                          style: const TextStyle(
                                            color: AppTheme.brandPurple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          app.status,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _statusTextColor(app.status),
                                          ),
                                        ),
                                        backgroundColor:
                                            _statusBgColor(app.status),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Applied for: ${app.vacancyTitle} • ${app.appliedAt}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.brandPurple,
                                    ),
                                  ),
                                  if (app.coverLetter.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '“${app.coverLetter}”',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (app.matchedSkills.isNotEmpty ||
                                      app.missingSkills.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        ...app.matchedSkills.map(
                                          (s) => Chip(
                                            label: Text(
                                              '✓ $s',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.green.shade900,
                                              ),
                                            ),
                                            backgroundColor:
                                                Colors.green.shade50,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ),
                                        ...app.missingSkills.map(
                                          (s) => Chip(
                                            label: Text(
                                              '✕ $s',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.red.shade900,
                                              ),
                                            ),
                                            backgroundColor: Colors.red.shade50,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (app.companyFeedback.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Your note: ${app.companyFeedback}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                  const Divider(height: 20),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () =>
                                            _showCandidateDossier(app),
                                        icon: const Icon(
                                          Icons.person_search_outlined,
                                          size: 18,
                                        ),
                                        label: const Text('Full Profile'),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  Colors.red.shade700,
                                            ),
                                            onPressed: () =>
                                                _showDecisionDialog(
                                              app,
                                              'Rejected',
                                            ),
                                            child: const Text('Reject'),
                                          ),
                                          const SizedBox(width: 6),
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  Colors.orange.shade800,
                                            ),
                                            onPressed: () =>
                                                _showDecisionDialog(
                                              app,
                                              'Interview',
                                            ),
                                            child: const Text('Interview'),
                                          ),
                                          const SizedBox(width: 6),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.green.shade700,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () =>
                                                _showDecisionDialog(
                                              app,
                                              'Approved',
                                            ),
                                            child: const Text('Approve'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
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
        ],
      ),
    );
  }

  Widget _buildCreateVacancyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create New Vacancy',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Job / Internship Title',
                      hintText: 'e.g. ML Developer / Junior Backend',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          decoration:
                              const InputDecoration(labelText: 'City / Location'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _workFormat,
                          decoration:
                              const InputDecoration(labelText: 'Work Format'),
                          items: const [
                            DropdownMenuItem(
                              value: 'Hybrid',
                              child: Text('Hybrid'),
                            ),
                            DropdownMenuItem(
                              value: 'Remote',
                              child: Text('Remote'),
                            ),
                            DropdownMenuItem(
                              value: 'Office',
                              child: Text('Office'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _workFormat = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _employmentType,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: const [
                            DropdownMenuItem(
                              value: 'Internship',
                              child: Text('Internship'),
                            ),
                            DropdownMenuItem(
                              value: 'Full-time',
                              child: Text('Full-time'),
                            ),
                            DropdownMenuItem(
                              value: 'Part-time',
                              child: Text('Part-time'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _employmentType = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _expController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Experience (years)',
                            hintText: 'e.g. 0, 1, 3',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _salaryController,
                    decoration: const InputDecoration(
                      labelText: 'Salary Range',
                      hintText: 'e.g. 250,000 - 400,000 KZT',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Responsibilities and tech stack...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Required Skills',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _showSkillPickerDialog,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Select from List'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _requiredSkills
                        .map(
                          (skill) => SkillChip(
                            name: skill,
                            onDelete: () =>
                                setState(() => _requiredSkills.remove(skill)),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isPosting ? null : _publishVacancy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: _isPosting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Publish Vacancy',
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
      ),
    );
  }
}