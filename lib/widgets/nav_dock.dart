import 'package:flutter/material.dart';
import '../theme/slip_theme.dart';

class NavDock extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  const NavDock({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SlipTheme.canvas,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 0.8),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InstagramNavItem(
                icon: Icons.dynamic_feed_outlined,
                activeIcon: Icons.dynamic_feed_rounded,
                label: 'Feed',
                isActive: activeIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _InstagramNavItem(
                icon: Icons.add_box_outlined,
                activeIcon: Icons.add_box_rounded,
                label: 'Drop',
                isActive: activeIndex == 1,
                onTap: () => onTabSelected(1),
              ),
              _InstagramNavItem(
                icon: Icons.task_alt_outlined,
                activeIcon: Icons.task_alt_rounded,
                label: 'Tasks',
                isActive: activeIndex == 2,
                onTap: () => onTabSelected(2),
              ),
              _InstagramNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: activeIndex == 3,
                onTap: () => onTabSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstagramNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _InstagramNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? SlipTheme.carbon : SlipTheme.steel,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? SlipTheme.carbon : SlipTheme.steel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
