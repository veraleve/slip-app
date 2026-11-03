import 'package:flutter/material.dart';
import '../providers/slip_provider.dart';
import '../theme/slip_theme.dart';
import '../widgets/nav_dock.dart';
import 'drop_slip_screen.dart';
import 'profile_screen.dart';
import 'stream_screen.dart';
import 'tasks_screen.dart';

class MainScaffold extends StatefulWidget {
  final VoidCallback onSignOut;

  const MainScaffold({super.key, required this.onSignOut});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final SlipProvider _slipProvider = SlipProvider();

  @override
  void initState() {
    super.initState();
    _slipProvider.init();
    _slipProvider.addListener(_onProviderUpdate);
  }

  @override
  void dispose() {
    _slipProvider.removeListener(_onProviderUpdate);
    _slipProvider.dispose();
    super.dispose();
  }

  void _onProviderUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      body: Stack(
        children: [
          // Active Screen
          Positioned.fill(
            child: IndexedStack(
              index: _slipProvider.activeTabIndex,
              children: [
                StreamScreen(provider: _slipProvider),
                DropSlipScreen(provider: _slipProvider),
                TasksScreen(provider: _slipProvider),
                ProfileScreen(
                  provider: _slipProvider,
                  onSignOut: widget.onSignOut,
                ),
              ],
            ),
          ),

          // Floating Bottom Navigation Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NavDock(
              activeIndex: _slipProvider.activeTabIndex,
              onTabSelected: (index) {
                _slipProvider.setTabIndex(index);
              },
            ),
          ),
        ],
      ),
    );
  }
}
