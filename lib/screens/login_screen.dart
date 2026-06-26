import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../theme.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'student/student_home_screen.dart';
import 'student/join_mess_screen.dart';
import 'admin/admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  int _selectedRole = 0; // 0 = student, 1 = admin
  bool _isLogin = true;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _messNameCtrl = TextEditingController();
  final _messIdCtrl = TextEditingController();
  
  final _prnCtrl = TextEditingController();
  final _hostelCtrl = TextEditingController();
  String? _selectedBranch;
  String? _selectedPassoutYear;
  
  bool _obscurePass = true;
  bool _isLoading = false;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    _setDefaultCredentials();
  }

  void _setDefaultCredentials() {
    if (_isLogin) {
      if (_selectedRole == 0) {
        _emailCtrl.text = 'pranav@mess.com';
        _passCtrl.text = 'student123';
      } else {
        _emailCtrl.text = 'admin@mess.com';
        _passCtrl.text = 'admin123';
      }
    } else {
      _emailCtrl.clear();
      _passCtrl.clear();
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _messNameCtrl.clear();
      _messIdCtrl.clear();
      _prnCtrl.clear();
      _hostelCtrl.clear();
      _selectedBranch = null;
      _selectedPassoutYear = null;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _messNameCtrl.dispose();
    _messIdCtrl.dispose();
    _prnCtrl.dispose();
    _hostelCtrl.dispose();
    super.dispose();
  }

  void _onRoleChange(int role) {
    setState(() {
      _selectedRole = role;
      _error = null;
      _setDefaultCredentials();
    });
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
      _setDefaultCredentials();
    });
  }

  Future<void> _biometricLogin() async {
    bool authenticated = false;
    try {
      setState(() => _isLoading = true);
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      
      if (canAuthenticate) {
        authenticated = await auth.authenticate(
          localizedReason: 'Please authenticate to login',
          options: const AuthenticationOptions(stickyAuth: true),
        );
      } else {
        setState(() {
          _error = 'Biometric authentication not supported on this device.';
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      setState(() {
        _error = 'Error using biometrics: $e';
        _isLoading = false;
      });
      return;
    }

    if (authenticated) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.biometricLogin("local_device_user_id"); // Mock ID, real app would use secure storage stored ID

      if (success && authProvider.currentUser != null) {
        if (!mounted) return;
        _navigateBasedOnRole(authProvider.currentUser);
      } else {
        setState(() {
          _error = 'No biometric profile found for this device.';
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 600));
    
    final role = _selectedRole == 0 ? 'student' : 'admin';
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;

    if (_isLogin) {
      success = await authProvider.login(_emailCtrl.text.trim(), _passCtrl.text.trim(), role);
    } else {
      if (role == 'admin') {
        success = await authProvider.signupAdmin(
          _nameCtrl.text.trim(), 
          _emailCtrl.text.trim(), 
          _phoneCtrl.text.trim(), 
          _passCtrl.text.trim(), 
          _messNameCtrl.text.trim(),
          _messIdCtrl.text.trim(),
          2000, // default mock fee
          '', // default address
          ''  // default description
        );
      } else {
        success = await authProvider.signupStudent(
          _nameCtrl.text.trim(), 
          _emailCtrl.text.trim(), 
          _phoneCtrl.text.trim(), 
          _passCtrl.text.trim(), 
          '', // pass empty string for roll number to backend to maintain API contract
          _prnCtrl.text.trim(),
          _selectedBranch ?? '',
          _selectedPassoutYear ?? '',
          _hostelCtrl.text.trim(),
        );
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    
    if (success && authProvider.currentUser != null) {
      _navigateBasedOnRole(authProvider.currentUser);
    } else {
      setState(() => _error = authProvider.lastError ?? (_isLogin ? 'Invalid credentials. Please try again.' : 'Signup failed.'));
    }
  }

  void _navigateBasedOnRole(user) {
    if (user.isAdmin) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
    } else {
      if (user.messId.isEmpty) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const JoinMessScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentHomeScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                      ),
                      child: const Icon(Icons.restaurant_menu, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'SMART MESS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form Card
            Expanded(
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_isLogin ? 'Welcome Back!' : 'Create Account',
                                style: Theme.of(context).textTheme.headlineLarge),
                            const SizedBox(height: 4),
                            Text(_isLogin ? 'Sign in to continue' : 'Sign up to get started', 
                                style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 24),

                            // Role Toggle
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.divider,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  _roleTab(0, 'Student', Icons.school),
                                  _roleTab(1, 'Admin', Icons.admin_panel_settings),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline, color: AppColors.primary)),
                                validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary)),
                                validator: (v) => v == null || v.isEmpty ? 'Enter phone' : null,
                              ),
                              const SizedBox(height: 16),
                                if (_selectedRole == 1) ...[
                                  TextFormField(
                                    controller: _messNameCtrl,
                                    decoration: const InputDecoration(labelText: 'Mess Name', prefixIcon: Icon(Icons.apartment, color: AppColors.primary)),
                                    validator: (v) => v == null || v.isEmpty ? 'Enter mess name' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _messIdCtrl,
                                    decoration: const InputDecoration(labelText: 'Mess ID (e.g. AB1234)', prefixIcon: Icon(Icons.pin_outlined, color: AppColors.primary)),
                                    validator: (v) => v == null || !RegExp(r'^[A-Z]{2}\d{4}$').hasMatch(v) ? 'Enter valid ID (2 caps, 4 digits)' : null,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (_selectedRole == 0) ...[
                                  TextFormField(
                                    controller: _prnCtrl,
                                    decoration: const InputDecoration(labelText: 'PRN', prefixIcon: Icon(Icons.numbers_outlined, color: AppColors.primary)),
                                    validator: (v) => v == null || v.isEmpty ? 'Enter PRN' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _selectedBranch,
                                    decoration: const InputDecoration(labelText: 'Branch', prefixIcon: Icon(Icons.book_outlined, color: AppColors.primary)),
                                    items: const [
                                      DropdownMenuItem(value: 'CSE', child: Text('Computer Science (CSE)')),
                                      DropdownMenuItem(value: 'IT', child: Text('Information Technology (IT)')),
                                      DropdownMenuItem(value: 'ENTC', child: Text('Electronics & Telecommunication (ENTC)')),
                                      DropdownMenuItem(value: 'MECH', child: Text('Mechanical (MECH)')),
                                      DropdownMenuItem(value: 'CIVIL', child: Text('Civil (CIVIL)')),
                                      DropdownMenuItem(value: 'ELEC', child: Text('Electrical (ELEC)')),
                                    ],
                                    onChanged: (val) => setState(() => _selectedBranch = val),
                                    validator: (v) => v == null ? 'Select branch' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _selectedPassoutYear,
                                    decoration: const InputDecoration(labelText: 'Passout Year', prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.primary)),
                                    items: const [
                                      DropdownMenuItem(value: '2026', child: Text('2026')),
                                      DropdownMenuItem(value: '2027', child: Text('2027')),
                                      DropdownMenuItem(value: '2028', child: Text('2028')),
                                      DropdownMenuItem(value: '2029', child: Text('2029')),
                                      DropdownMenuItem(value: '2030', child: Text('2030')),
                                    ],
                                    onChanged: (val) => setState(() => _selectedPassoutYear = val),
                                    validator: (v) => v == null ? 'Select passout year' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _hostelCtrl,
                                    decoration: const InputDecoration(labelText: 'Hostel Name', prefixIcon: Icon(Icons.home_outlined, color: AppColors.primary)),
                                    validator: (v) => v == null || v.isEmpty ? 'Enter hostel name' : null,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                            ],

                            // Email
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
                            ),
                            const SizedBox(height: 16),

                            // Password
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscurePass,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility,
                                      color: AppColors.textLight),
                                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
                            ),
                            const SizedBox(height: 12),

                            if (_error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(_error!,
                                        style: const TextStyle(color: AppColors.error, fontSize: 13))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            if (_isLogin)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _selectedRole == 0
                                      ? '🎓 Demo: pranav@mess.com / student123'
                                      : '🔑 Demo: admin@mess.com / admin123',
                                  style: TextStyle(fontSize: 12, color: AppColors.accent.withOpacity(0.9)),
                                ),
                              ),
                            const SizedBox(height: 24),

                            // Login / Signup Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(_isLogin ? 'LOGIN' : 'SIGN UP'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            if (_isLogin)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading ? null : _biometricLogin,
                                  icon: const Icon(Icons.fingerprint),
                                  label: const Text('Login with Fingerprint'),
                                ),
                              ),

                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: _toggleAuthMode,
                                child: Text(_isLogin 
                                  ? "Don't have an account? Sign Up" 
                                  : "Already have an account? Login"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleTab(int index, String label, IconData icon) {
    final isSelected = _selectedRole == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onRoleChange(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textLight),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textLight,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
