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
  bool _isLogin = true;
  UserRole _selectedRole = UserRole.student;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showRegisterSuggestion = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Поля регистрации студента
  final _fullNameCtrl = TextEditingController();
  final _universityCtrl = TextEditingController(text: 'KBTU');
  final _majorCtrl = TextEditingController(text: 'Information Systems');
  final _educationCtrl = TextEditingController(text: 'Bachelor, 4th Year');
  final _experienceCtrl = TextEditingController(text: '0');

  // Поля регистрации компании
  final _companyNameCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fullNameCtrl.dispose();
    _universityCtrl.dispose();
    _majorCtrl.dispose();
    _educationCtrl.dispose();
    _experienceCtrl.dispose();
    _companyNameCtrl.dispose();
    _websiteCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showRegisterSuggestion = false;
    });

    try {
      AuthSession session;

      if (_isLogin) {
        session = await AuthService.login(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          expectedRole: _selectedRole,
        );
      } else if (_selectedRole == UserRole.student) {
        if (_fullNameCtrl.text.trim().isEmpty) {
          throw AuthException('Please enter your full name.');
        }
        session = await AuthService.registerStudent(
          fullName: _fullNameCtrl.text,
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          university: _universityCtrl.text,
          major: _majorCtrl.text,
          education: _educationCtrl.text,
          experienceYears: double.tryParse(_experienceCtrl.text.trim()) ?? 0.0,
        );
      } else {
        if (_companyNameCtrl.text.trim().isEmpty) {
          throw AuthException('Please enter your company name.');
        }
        session = await AuthService.registerCompany(
          companyName: _companyNameCtrl.text,
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          website: _websiteCtrl.text,
          description: _descriptionCtrl.text,
        );
      }

      if (!mounted) return;
      SessionController.instance.setSession(session);
      Navigator.pushReplacementNamed(context, '/main');
    } on UserNotFoundException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _showRegisterSuggestion = true;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _showRegisterSuggestion = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _showRegisterSuggestion = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleTab(
              icon: Icons.school_outlined,
              label: 'Student',
              selected: _selectedRole == UserRole.student,
              onTap: () => setState(() {
                _selectedRole = UserRole.student;
                _errorMessage = null;
                _showRegisterSuggestion = false;
              }),
            ),
          ),
          Expanded(
            child: _RoleTab(
              icon: Icons.business_outlined,
              label: 'Company',
              selected: _selectedRole == UserRole.company,
              onTap: () => setState(() {
                _selectedRole = UserRole.company;
                _errorMessage = null;
                _showRegisterSuggestion = false;
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submitText = _isLogin
        ? 'Sign In'
        : (_selectedRole == UserRole.student
            ? 'Create Student Account'
            : 'Create Company Account');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.brandPurpleLight,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.work_rounded,
                      color: AppTheme.brandPurple,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'SkillMatch',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _isLogin ? 'Welcome Back' : 'Create Account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLogin
                      ? 'Sign in to access your SkillMatch workspace'
                      : 'Join SkillMatch as a Student or Hiring Company',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),
                _buildRoleSelector(),
                const SizedBox(height: 20),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
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
                        if (_showRegisterSuggestion) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isLogin = false;
                                  _errorMessage = null;
                                  _showRegisterSuggestion = false;
                                });
                              },
                              icon:
                                  const Icon(Icons.person_add_alt_1, size: 16),
                              label: const Text(
                                'Register now →',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (!_isLogin && _selectedRole == UserRole.student) ...[
                  TextField(
                    controller: _fullNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!_isLogin && _selectedRole == UserRole.company) ...[
                  TextField(
                    controller: _companyNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                if (!_isLogin && _selectedRole == UserRole.student) ...[
                  TextField(
                    controller: _universityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'University',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _majorCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Major',
                            prefixIcon: Icon(Icons.menu_book_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _experienceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Exp (yrs)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _educationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Education / Course',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!_isLogin && _selectedRole == UserRole.company) ...[
                  TextField(
                    controller: _websiteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Website',
                      prefixIcon: Icon(Icons.language_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Short Description',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPurple,
                      foregroundColor: Colors.white,
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
                            submitText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? "Don't have an account?"
                          : 'Already have an account?',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _errorMessage = null;
                          _showRegisterSuggestion = false;
                        });
                      },
                      child: Text(
                        _isLogin ? 'Sign up' : 'Sign in',
                        style: const TextStyle(
                          color: AppTheme.brandPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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

class _RoleTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppTheme.brandPurple : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? AppTheme.brandPurple : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}