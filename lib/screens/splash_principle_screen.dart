import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/slip_theme.dart';

class SplashPrincipleScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashPrincipleScreen({super.key, required this.onComplete});

  @override
  State<SplashPrincipleScreen> createState() => _SplashPrincipleScreenState();
}

class _SplashPrincipleScreenState extends State<SplashPrincipleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    _animController.forward();

    // Auto-proceed after 1.8 seconds
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onComplete, // tap to skip immediately
      child: Scaffold(
        backgroundColor: SlipTheme.canvas,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 3),

                  // Minimalist Geometric Logo
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: SlipTheme.carbon,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Container(
                        width: 14,
                        height: 2,
                        decoration: BoxDecoration(
                          color: SlipTheme.canvas,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // App Title
                  Text(
                    'Slip',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SlipTheme.carbon,
                          fontSize: 32,
                          letterSpacing: -0.8,
                        ),
                  ),

                  const SizedBox(height: 18),

                  // Core Principle Statement
                  Text(
                    '“Learn from others’ mistakes too.”',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SlipTheme.carbon,
                          fontSize: 18,
                          height: 1.35,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You won\'t have time to make them all yourself before GATE 2027.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SlipTheme.steel,
                          fontSize: 13,
                          height: 1.45,
                        ),
                  ),

                  const Spacer(flex: 4),

                  // Subtle Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GATE 2027 · INOCULATION NETWORK',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: SlipTheme.steel,
                              fontSize: 9,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'OFFLINE BLE MESH',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: SlipTheme.steel,
                              fontSize: 9,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
