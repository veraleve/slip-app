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

    // Auto-proceed after 2 seconds
    _timer = Timer(const Duration(milliseconds: 2000), () {
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
      onTap: widget.onComplete, // Tap anywhere to skip immediately
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: SlipTheme.canvas,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Centered Minimalist Geometric Logo
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: SlipTheme.carbon,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 22,
                              height: 3,
                              decoration: BoxDecoration(
                                color: SlipTheme.canvas,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              width: 14,
                              height: 2,
                              decoration: BoxDecoration(
                                color: SlipTheme.steelLight,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App Name
                    Text(
                      'Slip',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: SlipTheme.carbon,
                            fontSize: 34,
                            letterSpacing: -0.8,
                          ),
                    ),

                    const SizedBox(height: 28),

                    // Minimalist Core Principle
                    Text(
                      '“Learn from others’ mistakes too.”',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SlipTheme.carbon,
                            fontSize: 18,
                            height: 1.35,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'You won\'t have time to make them all yourself before the exam.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: SlipTheme.steel,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                    ),

                    const Spacer(flex: 4),

                    // Subtle Centered Footer
                    Text(
                      'GATE · MISTAKE INOCULATION NETWORK',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: SlipTheme.steel,
                            fontSize: 9.5,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'OFFLINE BLE MESH · PEER LEARNING',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: SlipTheme.steelLight,
                            fontSize: 8.5,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
