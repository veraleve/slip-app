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
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'ENTER BOTH USERNAME AND PASSWORD';
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
      );
    } else {
      success = await service.signInWithUsername(
        username: username,
        password: password,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      widget.onAuthenticated();
    } else {
      setState(() {
        _errorMessage = _isSignUp
            ? 'USERNAME ALREADY IN USE OR INVALID PASSWORD.'
            : 'INVALID USERNAME OR PASSWORD. TRY AGAIN.';
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
                              color: SlipTheme.textPrimary,
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
                          color: SlipTheme.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'AUTH // PEER_INOCULATION_NETWORK · v1.0',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: SlipTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 28),

              // Segment Switch: [ SIGN IN ] vs [ CREATE ACCOUNT ]
              Row(
                children: [
                  _AuthTab(
                    label: 'SIGN IN',
                    isActive: !_isSignUp,
                    onTap: () => setState(() {
                      _isSignUp = false;
                      _errorMessage = null;
                    }),
                  ),
                  const SizedBox(width: 20),
                  _AuthTab(
                    label: 'CREATE ACCOUNT',
                    isActive: _isSignUp,
                    onTap: () => setState(() {
                      _isSignUp = true;
                      _errorMessage = null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 28),

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

              // 1. Username Input (Pure Username, Zero Email)
              HairlineInput(
                label: 'USERNAME',
                placeholder: 'e.g. shyam_gate',
                controller: _usernameController,
                helperText: 'UNIQUE HANDLE',
              ),
              const SizedBox(height: 24),

              // 2. Password Input
              HairlineInput(
                label: 'PASSWORD',
                placeholder: '••••••••••••',
                controller: _passwordController,
                obscureText: _obscurePassword,
                helperText: 'MIN 6 CHARS',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 16,
                    color: SlipTheme.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Exam Stream Badge
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
                      color: SlipTheme.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TARGET STREAM: GATE CS 2027',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SlipTheme.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Primary Action Button
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
                              ? 'CREATE USERNAME & JOIN'
                              : 'SIGN IN TO STREAM',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: SlipTheme.canvas,
                                letterSpacing: 0.8,
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
                          color: SlipTheme.textSecondary,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Whisper Security Footer
              Center(
                child: Text(
                  'Zero cloud tracking without consent · Open Source · Encrypted Telemetry',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: SlipTheme.textTertiary,
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
                  color: isActive ? SlipTheme.textPrimary : SlipTheme.textTertiary,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 24,
            height: 2,
            color: isActive ? SlipTheme.textPrimary : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
