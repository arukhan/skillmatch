import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/auth_session.dart';
import '../../services/auth_service.dart';
import '../../state/session_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  UserRole _selectedRole = UserRole.student;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _universityController = TextEditingController(
    text: 'Kazakh-British Technical University',
  );
  final _majorController = TextEditingController(
    text: 'Information Systems',
  );
  final _experienceController = TextEditingController(text: '1.5');
  final _websiteController = TextEditingController(text: 'https://');
  final _companyDescController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    _experienceController.dispose();
    _websiteController.dispose();
    _companyDescController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      AuthSession session;
      if (_isLogin) {
        session = await AuthService.login(
          email: _emailController.text,
          password: _passwordController.text,
          expectedRole: _selectedRole,
        );
      } else if (_selectedRole == UserRole.student) {
        session = await AuthService.registerStudent(
          fullName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          university: _universityController.text,
          major: _majorController.text,
          education: 'Bachelor student',
          experienceYears:
              double.tryParse(_experienceController.text.trim()) ?? 0.0,
        );
      } else {
        session = await AuthService.registerCompany(
          companyName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          website: _websiteController.text,
          description: _companyDescController.text,
        );
      }

      if (!mounted) return;
      SessionController.instance.setSession(session);
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _quickDemoLogin(UserRole role) async {
    setState(() {
      _selectedRole = role;
      _emailController.text =
          role == UserRole.student ? 'student@kbtu.kz' : 'hr@kaspi.kz';
      _passwordController.text = '123456';
      _isLogin = true;
    });
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;

          if (isDesktop) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    color: Colors.white,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 32,
                        ),
                        child: _buildFormCard(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: _buildDesktopPromoPanel(),
                ),
              ],
            );
          }

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _buildFormCard(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormCard() {
    final isStudent = _selectedRole == UserRole.student;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.brandPurple.withAlpha(25),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.work_rounded,
                  size: 38,
                  color: AppTheme.brandPurple,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'SkillMatch',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isLogin ? 'Welcome Back!' : 'Create Account',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isLogin
                  ? 'Sign in to access your role workspace'
                  : 'Join SkillMatch as a Student or Hiring Company',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildRoleSegment(
                      role: UserRole.student,
                      icon: Icons.school_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildRoleSegment(
                      role: UserRole.company,
                      icon: Icons.business_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (!_isLogin) ...[
              _buildFieldLabel(isStudent ? 'Full Name' : 'Company Name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: AppTheme.inputDecoration(
                  hint: isStudent ? 'Zhumabek Askerbekuly' : 'Kaspi.kz',
                  icon: isStudent ? Icons.person_outline : Icons.apartment,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required field' : null,
              ),
              const SizedBox(height: 14),
            ],

            _buildFieldLabel('Email Address'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: AppTheme.inputDecoration(
                hint: isStudent ? 'student@kbtu.kz' : 'hr@company.kz',
                icon: Icons.email_outlined,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),

            if (!_isLogin && isStudent) ...[
              _buildFieldLabel('University'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _universityController,
                decoration: AppTheme.inputDecoration(
                  hint: 'Kazakh-British Technical University',
                  icon: Icons.account_balance_outlined,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter university' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Major'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _majorController,
                          decoration: AppTheme.inputDecoration(
                            hint: 'Information Systems',
                            icon: Icons.code_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Exp (yrs)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _experienceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: AppTheme.inputDecoration(
                            hint: '1.5',
                            icon: Icons.timeline_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            if (!_isLogin && !isStudent) ...[
              _buildFieldLabel('Website'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _websiteController,
                decoration: AppTheme.inputDecoration(
                  hint: 'https://company.kz',
                  icon: Icons.language_rounded,
                ),
              ),
              const SizedBox(height: 14),
              _buildFieldLabel('Short Description'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _companyDescController,
                decoration: AppTheme.inputDecoration(
                  hint: 'Fintech & Engineering team',
                  icon: Icons.description_outlined,
                ),
              ),
              const SizedBox(height: 14),
            ],

            _buildFieldLabel('Password'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: AppTheme.inputDecoration(
                hint: '••••••••',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: Colors.grey[500],
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter your password';
                if (v.length < 4) return 'Minimum 4 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isLogin
                            ? 'Sign In as ${_selectedRole.label}'
                            : 'Create ${_selectedRole.label} Account',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _quickDemoLogin(UserRole.student),
                    icon: const Icon(Icons.school, size: 16),
                    label: const Text(
                      'Demo Student',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.brandPurple,
                      side: BorderSide(color: AppTheme.brandPurple.withAlpha(80)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _quickDemoLogin(UserRole.company),
                    icon: const Icon(Icons.business, size: 16),
                    label: const Text(
                      'Demo Company',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.brandPurple,
                      side: BorderSide(color: AppTheme.brandPurple.withAlpha(80)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLogin
                      ? "Don't have an account? "
                      : 'Already have an account? ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _errorMessage = null;
                      _formKey.currentState?.reset();
                    });
                  },
                  child: Text(
                    _isLogin ? 'Sign up' : 'Sign in',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandPurple,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildRoleSegment({
    required UserRole role,
    required IconData icon,
  }) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedRole = role;
        _errorMessage = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppTheme.brandPurple : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              role.label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selected ? AppTheme.brandPurple : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopPromoPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.brandPurple, AppTheme.brandPurpleDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(64),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'AI-Assisted Career Platform',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bridge the gap\nbetween your skills\nand your dream career.',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Students match their tech stack & languages with real internships. Companies discover verified talent effortlessly.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withAlpha(210),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                const Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _PromoBadge('Flutter'),
                    _PromoBadge('Go'),
                    _PromoBadge('PostgreSQL'),
                    _PromoBadge('REST API'),
                    _PromoBadge('English B2+'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoBadge extends StatelessWidget {
  final String label;
  const _PromoBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(55)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}