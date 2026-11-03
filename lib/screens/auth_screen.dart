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
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _errorMessage = 'PLEASE ENTER A PASSWORD TO SECURE YOUR PROFILE.');
      return;
    }

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
        username: handle ?? service.currentUsername ?? 'peer',
        password: password,
      );
      widget.onAuthenticated();
    } else {
      setState(() => _errorMessage = 'COULD NOT INITIALIZE PEER MESH.');
    }
  }

  Future<void> _handleAuth() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'PLEASE ENTER A USERNAME.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'PLEASE ENTER A PASSWORD TO SIGN IN OR CREATE ACCOUNT.';
      });
      return;
    }

    if (password.length < 4) {
      setState(() {
        _errorMessage = 'PASSWORD MUST BE AT LEAST 4 CHARACTERS.';
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
        _errorMessage = _isSignUp
            ? 'USERNAME ALREADY REGISTERED. PLEASE SIGN IN.'
            : 'INVALID USERNAME OR PASSWORD.';
      });
    }
  }

  void _promptMeshConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SlipTheme.canvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'GUEST MESH SESSION',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: SlipTheme.carbon,
          ),
        ),
        content: const Text(
          'Entering via Bluetooth mesh is temporary. Your session and device data will not be backed up to the cloud. If you clear app data, local notes and blunders will be lost.\n\nDo you want to proceed as a guest peer?',
          style: TextStyle(
            fontSize: 12.5,
            color: SlipTheme.steel,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: SlipTheme.steel)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _enterViaMesh();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SlipTheme.carbon,
              foregroundColor: SlipTheme.canvas,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('PROCEED AS PEER'),
          ),
        ],
      ),
    );
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
                  // Centered Clean Logo & Subtitle
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Slip',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 36,
                                color: SlipTheme.carbon,
                                letterSpacing: -0.6,
                              ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ask doubts. Learn from mistakes. Master together',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: SlipTheme.steel,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? SlipTheme.carbon
                                : SlipTheme.surface,
                            borderRadius: BorderRadius.circular(16),
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

                  const SizedBox(height: 24),

                  // Username Input (Curved)
                  Text(
                    'USERNAME',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: SlipTheme.steel,
                        ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(fontSize: 14, color: SlipTheme.carbon, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Choose your peer handle (e.g. arya)',
                      hintStyle: const TextStyle(fontSize: 13, color: SlipTheme.steelLight),
                      filled: true,
                      fillColor: SlipTheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: SlipTheme.carbon, width: 1.2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password Input (Curved)
                  Text(
                    'PASSWORD',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: SlipTheme.steel,
                        ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(fontSize: 14, color: SlipTheme.carbon, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(fontSize: 13, color: SlipTheme.steelLight),
                      filled: true,
                      fillColor: SlipTheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: SlipTheme.carbon, width: 1.2),
                      ),
                    ),
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
                            borderRadius: BorderRadius.circular(6),
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
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SlipTheme.carbon,
                        foregroundColor: SlipTheme.canvas,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: SlipTheme.canvas),
                            )
                          : Text(
                              _isSignUp ? 'CREATE ACCOUNT' : 'SIGN IN',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
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

                  const SizedBox(height: 16),

                  // Subtle Small Enter via Bluetooth Mesh
                  Center(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _promptMeshConfirmation,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SlipTheme.carbon,
                        side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Enter via Bluetooth mesh',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
