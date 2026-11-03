import 'package:flutter/material.dart';
import '../providers/slip_provider.dart';
import '../theme/slip_theme.dart';
import '../widgets/nav_dock.dart';
import 'drop_slip_screen.dart';
import 'profile_screen.dart';
import 'feed_screen.dart';
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
      body: IndexedStack(
        index: _slipProvider.activeTabIndex,
        children: [
          FeedScreen(provider: _slipProvider),
          DropSlipScreen(provider: _slipProvider),
          TasksScreen(provider: _slipProvider),
          ProfileScreen(
            provider: _slipProvider,
            onSignOut: widget.onSignOut,
          ),
        ],
      ),
      // Instagram-style bottom navigation fully down at the bottom of the screen
      bottomNavigationBar: NavDock(
        activeIndex: _slipProvider.activeTabIndex,
        onTabSelected: (index) {
          _slipProvider.setTabIndex(index);
        },
      ),
    );
  }
}
