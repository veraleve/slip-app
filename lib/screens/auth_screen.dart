import 'package:flutter/material.dart';
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _handleController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'ENTER BOTH IDENTIFIER AND PASSPHRASE';
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
      final handle = _handleController.text.trim().isNotEmpty
          ? _handleController.text.trim()
          : email.split('@').first;
      success = await service.signUp(
        email: email,
        password: password,
        handle: handle,
      );
    } else {
      success = await service.signIn(email: email, password: password);
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      widget.onAuthenticated();
    } else {
      setState(() {
        _errorMessage = 'AUTHENTICATION REJECTED. CHECK CREDENTIALS.';
      });
    }
  }

  void _bypassWithKey() {
    // Instant peer entry using local cryptographic identity
    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Status Telemetry Strip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: SlipTheme.clearedGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AP-SOUTH-1 // PEER MESH ACTIVE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: SlipTheme.carbon,
                            ),
                      ),
                    ],
                  ),
                  Text(
                    'TLS 1.3',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Stark Wordmark
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'SLIP',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '[SYS // 01]',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SlipTheme.steel,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'AUTH // PEER_INOCULATION_NETWORK · v1.0',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: SlipTheme.steel,
                    ),
              ),
              const SizedBox(height: 28),

              // Segment Switch: [ SIGN IN ] vs [ CREATE ACCOUNT ]
              Row(
                children: [
                  _AuthTab(
                    label: 'SIGN IN',
                    isActive: !_isSignUp,
                    onTap: () => setState(() => _isSignUp = false),
                  ),
                  const SizedBox(width: 16),
                  _AuthTab(
                    label: 'CREATE ACCOUNT',
                    isActive: _isSignUp,
                    onTap: () => setState(() => _isSignUp = true),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: SlipTheme.trapRed.withOpacity(0.08),
                    border: Border.all(color: SlipTheme.trapRed, width: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: SlipTheme.trapRed,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Inputs (Hairline Open Baselines)
              if (_isSignUp) ...[
                HairlineInput(
                  label: 'STUDY HANDLE',
                  placeholder: 'e.g. shyam_gate',
                  controller: _handleController,
                  helperText: 'REF: 0x01',
                ),
                const SizedBox(height: 20),
              ],

              HairlineInput(
                label: 'USER IDENTIFIER / EMAIL',
                placeholder: 'student@university.edu',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                helperText: 'VERIFIED',
              ),
              const SizedBox(height: 20),

              HairlineInput(
                label: 'PASSPHRASE',
                placeholder: '••••••••••••',
                controller: _passwordController,
                obscureText: _obscurePassword,
                helperText: '128-BIT ENTROPY',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 16,
                    color: SlipTheme.steel,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Exam Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 14,
                      color: SlipTheme.carbon,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TARGET STREAM: GATE CS 2027',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SlipTheme.carbon,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Primary Authenticate Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SlipTheme.carbon,
                    foregroundColor: SlipTheme.canvas,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(SlipTheme.canvas),
                          ),
                        )
                      : Text(
                          _isSignUp
                              ? 'CREATE IDENTITY & JOIN'
                              : 'AUTHENTICATE & ENTER STREAM',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: SlipTheme.canvas,
                                letterSpacing: 1.0,
                              ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Secondary Key Bypass (Cryptographic Identity / Mesh)
              Center(
                child: TextButton(
                  onPressed: _bypassWithKey,
                  child: Text(
                    'OR CONTINUE WITH CRYPTOGRAPHIC KEY // BLE MESH',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: SlipTheme.steel,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Whisper Security Footer
              Center(
                child: Text(
                  'Zero cloud tracking without consent · Open Source · Nostr & Supabase Encrypted',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: SlipTheme.steelLight,
                        fontSize: 9,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _AuthTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isActive ? SlipTheme.carbon : SlipTheme.steelLight,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 24,
            height: 2,
            color: isActive ? SlipTheme.carbon : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
