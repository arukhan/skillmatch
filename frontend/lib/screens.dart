import 'package:flutter/material.dart';
import 'api_service.dart';

// 1. Login Screen
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.work_rounded, size: 80, color: Color(0xFF7C3AED)),
              const SizedBox(height: 24),
              const Text('SkillMatch', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
                  child: const Text('Enter as Student', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. Main Screen
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
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
        selectedItemColor: const Color(0xFF7C3AED),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), activeIcon: Icon(Icons.work), label: 'Internships'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note), activeIcon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// 3. Vacancy List Screen
class VacancyListScreen extends StatelessWidget {
  const VacancyListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internships matched to your profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildVacancyCard(
            context,
            title: 'Data Analytics Intern',
            company: 'Northwind Labs • Remote',
            matchScore: '66%',
            scoreColor: Colors.purple,
            skills: const ['Python', 'SQL', 'Pandas'],
          ),
          const SizedBox(height: 16),
          _buildVacancyCard(
            context,
            title: 'Go Backend Intern',
            company: 'Kaspi.kz • Almaty / Hybrid',
            matchScore: '90%',
            scoreColor: Colors.green,
            skills: const ['Go', 'PostgreSQL', 'Docker'],
          ),
        ],
      ),
    );
  }

  Widget _buildVacancyCard(BuildContext context, {required String title, required String company, required String matchScore, required Color scoreColor, required List<String> skills}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/vacancy-detail'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(company, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: scoreColor.withAlpha(25), borderRadius: BorderRadius.circular(20)),
                    child: Text(matchScore, style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6.0,
                children: skills.map((s) => Chip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.purple.shade50,
                  labelStyle: const TextStyle(color: Color(0xFF7C3AED)),
                  padding: EdgeInsets.zero,
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 4. Vacancy Detail Screen
class VacancyDetailScreen extends StatelessWidget {
  const VacancyDetailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vacancy Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Go Backend Intern', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Kaspi.kz • Almaty', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('AI Match Score:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('90%', style: TextStyle(color: Colors.green, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply Now', style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// 5 & 6. Заглушки
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Career Events')), body: const Center(child: Text('Events Coming Soon')));
}

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Recommended Courses')), body: const Center(child: Text('Courses Coming Soon')));
}

// 7. Profile Screen
// 7. Profile Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future _futureStudent;
  List<dynamic> _skills = [];
  bool _isLoadingSkills = true;

  @override
  void initState() {
    super.initState();
    _futureStudent = ApiService.fetchStudent(1);
    _loadSkills();
  }

  // Загружаем навыки (из бэкенда или с дефолтными значениями)
  Future<void> _loadSkills() async {
    try {
      final skills = await ApiService.fetchStudentSkills(1);
      setState(() {
        _skills = skills;
        _isLoadingSkills = false;
      });
    } catch (_) {
      setState(() {
        _skills = [
          {"name": "Dart"},
          {"name": "Flutter"},
          {"name": "Go"},
          {"name": "PostgreSQL"},
          {"name": "REST API"}
        ];
        _isLoadingSkills = false;
      });
    }
  }

  // Диалоговое окно для ввода нового навыка
  void _showAddSkillDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Skill'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. Docker, Redis, Python'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white),
            onPressed: () async {
              final newSkillText = controller.text.trim();
              if (newSkillText.isNotEmpty) {
                Navigator.pop(context);

                // 1. Отправляем запрос на бэкенд в базу данных
                await ApiService.addStudentSkill(1, newSkillText);

                // 2. Мгновенно добавляем в локальный список интерфейса, чтобы он сразу появился на экране
                setState(() {
                  final exists = _skills.any((s) => s['name'].toString().toLowerCase() == newSkillText.toLowerCase());
                  if (!exists) {
                    _skills.add({"name": newSkillText});
                  }
                });
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
      appBar: AppBar(title: const Text('Student Profile'), backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
              future: _futureStudent,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                }

                final student = snapshot.data!;
                final fullName = student['full_name'] ?? 'No Name';
                final uni = student['university'] ?? 'University';
                final major = student['major'] ?? 'N/A';
                final exp = student['experience_years'] ?? 0;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(radius: 30, backgroundColor: Color(0xFF7C3AED), child: Icon(Icons.person, size: 36, color: Colors.white)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text(uni, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text('Major: $major', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Experience: $exp years', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Заголовок и кнопка добавления навыка (+)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Technical Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF7C3AED)),
                  onPressed: () => _showAddSkillDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _isLoadingSkills
                ? const Center(child: CircularProgressIndicator())
                : _skills.isEmpty
                    ? const Text('No skills added yet.')
                    : Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _skills.map((skill) {
                          final skillName = skill['name'] ?? 'Skill';
                          return Chip(
                      label: Text(skillName),
                      backgroundColor: Colors.purple.shade50,
                      labelStyle: const TextStyle(color: Color(0xFF7C3AED)),
                      // Добавляем крестик и логику удаления
                      deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF7C3AED)),
                      onDeleted: () async {
                        // 1. Отправляем запрос на удаление в бэкенд
                        await ApiService.deleteStudentSkill(1, skillName);

                        // 2. Мгновенно убираем навык с экрана
                        setState(() {
                          _skills.removeWhere((s) => s['name'] == skillName);
                        });
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