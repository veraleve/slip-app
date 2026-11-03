import 'package:flutter/material.dart';
import '../constants/gate_syllabus.dart';
import '../services/supabase_service.dart';
import '../theme/slip_theme.dart';
import '../widgets/hairline_input.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _rememberDevice = true;
  String? _errorMessage;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // A student can select 1 or 2 papers (e.g. CS + DA, EC + EE)
  final Set<String> _selectedExams = {GateSyllabus.gateCS};

  @override
  void initState() {
    super.initState();
    final saved = SupabaseService().savedUsername;
    if (saved != null && saved.isNotEmpty) {
      _usernameController.text = saved;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleExam(String exam) {
    setState(() {
      if (_selectedExams.contains(exam)) {
        if (_selectedExams.length > 1) {
          _selectedExams.remove(exam);
        }
      } else {
        if (_selectedExams.length >= 2) {
          // If already 2 selected, remove the first one to allow the new one
          _selectedExams.remove(_selectedExams.first);
        }
        _selectedExams.add(exam);
      }
    });
  }

  Future<void> _enterViaMesh() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final service = SupabaseService();
    final handle = _usernameController.text.trim().isNotEmpty
        ? _usernameController.text.trim()
        : null;

    final success = await service.signInAsMeshPeer(
      customHandle: handle,
      targetExams: _selectedExams.toList(),
    );

    setState(() => _isLoading = false);

    if (success) {
      await service.setLoggedIn(
        true,
        rememberDevice: _rememberDevice,
        username: username,
        password: password,
      );
      widget.onAuthenticated();
    } else {
      setState(() => _errorMessage = 'COULD NOT INITIALIZE PEER MESH.');
    }
  }

  Future<void> _handleAuth() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'PLEASE ENTER USERNAME AND PASSWORD.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final service = SupabaseService();
    bool success = false;

    if (_isSignUp) {
      success = await service.signUpWithUsername(
        username: username,
        password: password,
        targetExams: _selectedExams.toList(),
      );
    } else {
      success = await service.signInWithUsername(
        username: username,
        password: password,
      );
    }

    setState(() => _isLoading = false);

    if (success) {
      await service.setLoggedIn(
        true,
        rememberDevice: _rememberDevice,
        username: username,
        password: password,
      );
      widget.onAuthenticated();
    } else {
      setState(() {
        _errorMessage = 'COULD NOT SIGN IN. TRY ENTERING VIA MESH.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clean Logo & Subtitle
                  Text(
                    'Slip',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SlipTheme.carbon,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ask doubts. Learn from mistakes. Master together',
                    style: TextStyle(
                      color: SlipTheme.steel,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // SELECT PAPERS SECTION (UP TO 2)
                  Text(
                    'SELECT YOUR PAPERS (UP TO 2)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SlipTheme.steel,
                          letterSpacing: 0.6,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: GateSyllabus.supportedExams.map((exam) {
                      final isSelected = _selectedExams.contains(exam);
                      final label = exam;
                      return InkWell(
                        onTap: () => _toggleExam(exam),
                        borderRadius: BorderRadius.circular(3),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? SlipTheme.carbon
                                : SlipTheme.surface,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: isSelected
                                  ? SlipTheme.carbon
                                  : SlipTheme.hairline,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            label,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? SlipTheme.canvas
                                      : SlipTheme.carbon,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You will only see mistake logs for your selected papers.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: SlipTheme.steel,
                          fontSize: 11,
                        ),
                  ),

                  const SizedBox(height: 28),

                  // 1-TAP INSTANT MESH ACCESS
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: SlipTheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: SlipTheme.hairline, width: 0.8),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OFFLINE PEER ACCESS',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: SlipTheme.steel,
                                    letterSpacing: 0.8,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter instantly as an anonymous peer via BLE Mesh. No email or password needed.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: SlipTheme.carbon,
                                    height: 1.4,
                                  ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _enterViaMesh,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SlipTheme.carbon,
                              foregroundColor: SlipTheme.canvas,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          SlipTheme.canvas),
                                    ),
                                  )
                                : Text(
                                    'ENTER VIA BLE MESH',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: SlipTheme.canvas,
                                          letterSpacing: 0.6,
                                        ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Minimalist Divider
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: SlipTheme.hairline, height: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR USE ACCOUNT',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: SlipTheme.steel,
                                    fontSize: 10,
                                    letterSpacing: 0.6,
                                  ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: SlipTheme.hairline, height: 1),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Username Input
                  HairlineInput(
                    label: 'USERNAME',
                    hint: 'Choose your peer handle (e.g. arya)',
                    controller: _usernameController,
                  ),
                  const SizedBox(height: 14),

                  // Password Input
                  HairlineInput(
                    label: 'PASSWORD',
                    hint: '••••••••',
                    isPassword: true,
                    controller: _passwordController,
                  ),

                  const SizedBox(height: 12),

                  // Remember This Device Checkbox
                  Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _rememberDevice,
                          activeColor: SlipTheme.carbon,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setState(() => _rememberDevice = val ?? true);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Remember this device',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: SlipTheme.carbon,
                        ),
                      ),
                    ],
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: SlipTheme.trapRed,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Sign In / Create Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SlipTheme.carbon,
                        foregroundColor: SlipTheme.canvas,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isSignUp ? 'CREATE ACCOUNT' : 'SIGN IN',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: SlipTheme.canvas,
                                  letterSpacing: 0.6,
                                ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Toggle between Sign In and Sign Up
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                          _errorMessage = null;
                        });
                      },
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign in'
                            : 'Don\'t have an account? Create one',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: SlipTheme.steel,
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
