import 'package:flutter/material.dart';

// 1. Login Screen
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SkillMatch')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
          child: const Text('Enter as Student'),
        ),
      ),
    );
  }
}

// 2. Main Screen (Нижнее меню на 4 вкладки)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 4 вкладки, показывающие полное видение проекта
  final List<Widget> _screens = [
    const VacancyListScreen(),
    const EventsScreen(),
    const CoursesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Обязательно для 4+ вкладок, чтобы текст не пропадал
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
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

// 3. Vacancy List Screen
class VacancyListScreen extends StatelessWidget {
  const VacancyListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Internships')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.business, color: Colors.blue),
            title: const Text('Go Backend Intern'),
            subtitle: const Text('Halyk Bank • Match: 85%'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, '/vacancy-detail'),
          ),
          ListTile(
            leading: const Icon(Icons.business, color: Colors.blue),
            title: const Text('Data Analyst Intern'),
            subtitle: const Text('KBTU Lab • Match: 60%'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, '/vacancy-detail'),
          ),
        ],
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
            const SizedBox(height: 10),
            const Text('Match Score: 85%', style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('Skill Gap Analysis:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('• Missing: 1 year experience', style: TextStyle(color: Colors.red)),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply Now'),
            )
          ],
        ),
      ),
    );
  }
}

// 5.Events (Митапы и Воркшопы)
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Career Events')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.calendar_month, color: Colors.orange),
            title: Text('KBTU IT Meetup 2026'),
            subtitle: Text('Oct 10, 14:00 • Networking'),
          ),
          ListTile(
            leading: Icon(Icons.computer, color: Colors.orange),
            title: Text('PostgreSQL Optimization Workshop'),
            subtitle: Text('Oct 12, 16:00 • Online'),
          ),
          ListTile(
            leading: Icon(Icons.people, color: Colors.orange),
            title: Text('How to pass a Tech Interview'),
            subtitle: Text('Oct 15, 18:00 • Guest Speaker'),
          ),
        ],
      ),
    );
  }
}

// 6.Courses
class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommended Courses')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.play_circle_filled, color: Colors.green),
            title: Text('Advanced Go Concurrency'),
            subtitle: Text('To fix your Skill Gap • 4 hours'),
          ),
          ListTile(
            leading: Icon(Icons.play_circle_filled, color: Colors.green),
            title: Text('Flutter State Management'),
            subtitle: Text('Highly requested by employers'),
          ),
        ],
      ),
    );
  }
}

// 7. Profile Screen
// 7. Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {}, // Заглушка для редактирования
          )
        ],
      ),
      body: SingleChildScrollView( // Чтобы экран скроллился, если не влезет
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Шапка профиля
            Center(
              child: Column(
                children: const [
                  CircleAvatar(radius: 50, child: Icon(Icons.person, size: 60)),
                  SizedBox(height: 16),
                  Text('Zhumabek Askerbekuly', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('KBTU Student • 4 course Info Systems', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Индикатор заполненности (отсылка к Acceptance Criteria)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Profile is 80% complete. Add your "Work Experience" to get accurate Match Scores.',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Технические навыки
            const Text('Technical Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [ // <--- Убрали слово const отсюда
                Chip(label: const Text('Flutter'), backgroundColor: Colors.blue.shade50),
                Chip(label: const Text('Dart'), backgroundColor: Colors.blue.shade50),
                Chip(label: const Text('Go'), backgroundColor: Colors.blue.shade50),
                Chip(label: const Text('PostgreSQL'), backgroundColor: Colors.blue.shade50),
                Chip(label: const Text('REST API'), backgroundColor: Colors.blue.shade50),
              ],
            ),

            // 4. Опыт и Образование
            const Text('Experience & Education', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.work_outline, color: Colors.grey),
              title: Text('Work Experience'),
              subtitle: Text('None (Looking for first internship)'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.school_outlined, color: Colors.grey),
              title: Text('Education'),
              subtitle: Text('Kazakh-British Technical University\n3rd year, Information Systems'),
            ),
          ],
        ),
      ),
    );
  }
}