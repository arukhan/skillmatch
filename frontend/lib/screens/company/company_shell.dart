import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/vacancy.dart';
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

  final _titleController = TextEditingController();
  final _locationController = TextEditingController(text: 'Almaty / Hybrid');
  final _expController = TextEditingController(text: '1.0');
  final _descController = TextEditingController();
  final _skillInputController = TextEditingController();
  String _employmentType = 'Internship';
  final List<String> _requiredSkills = ['Go', 'PostgreSQL', 'Git'];
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = SessionController.instance.companyTabIndex.clamp(0, 1);
    _futureVacancies = VacancyService.fetchVacancies();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _expController.dispose();
    _descController.dispose();
    _skillInputController.dispose();
    super.dispose();
  }

  Future<void> _publishVacancy() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);
    final session = SessionController.instance.session;

    await VacancyService.createVacancy(
      companyId: SessionController.instance.activeCompanyId,
      companyName: session?.displayName ?? 'SkillMatch Partner Tech',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      experienceRequired: double.tryParse(_expController.text.trim()) ?? 0.0,
      employmentType: _employmentType,
      location: _locationController.text.trim(),
      skills: List<String>.from(_requiredSkills),
    );

    if (!mounted) return;
    _titleController.clear();
    _descController.clear();

    SessionController.instance.setCompanyTab(0);
    setState(() {
      _isPosting = false;
      _selectedTab = 0;
      _futureVacancies = VacancyService.fetchVacancies();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vacancy published and visible to students!'),
        backgroundColor: AppTheme.brandPurple,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionController.instance.session;

    return Scaffold(
      appBar: AppBar(
        title: Text(session?.displayName ?? 'Company Workspace'),
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
      body: _selectedTab == 0 ? _buildMyVacanciesTab() : _buildCreateVacancyTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        selectedItemColor: AppTheme.brandPurple,
        onTap: (i) {
          setState(() => _selectedTab = i);
          SessionController.instance.setCompanyTab(i);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.business_center_outlined),
            activeIcon: Icon(Icons.business_center),
            label: 'Vacancies',
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

        return ListView(
          padding: const EdgeInsets.all(16),
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
                      child: Icon(Icons.business, color: Colors.white),
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
                            session?.email ?? '',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const Chip(
                      label: Text('COMPANY'),
                      backgroundColor: AppTheme.brandPurpleLight,
                      labelStyle: TextStyle(
                        color: AppTheme.brandPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Vacancies',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _selectedTab = 1);
                    SessionController.instance.setCompanyTab(1);
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
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (vacancies.isEmpty)
              const Text('No vacancies posted yet.')
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
                        Text(
                          v.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${v.companyName} • ${v.location} • ${v.employmentType}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (v.skills.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            children: v.skills
                                .map((s) => SkillChip(name: s))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
                      hintText: 'e.g. Junior Backend Developer',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          decoration:
                              const InputDecoration(labelText: 'Location'),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _expController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Required Experience (years)',
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
                  const Text(
                    'Required Skills',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _skillInputController,
                          decoration: const InputDecoration(
                            hintText: 'Add skill (e.g. Docker)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final val = _skillInputController.text.trim();
                          if (val.isNotEmpty &&
                              !_requiredSkills.contains(val)) {
                            setState(() {
                              _requiredSkills.add(val);
                              _skillInputController.clear();
                            });
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
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
                      child: const Text(
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