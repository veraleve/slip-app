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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SlipTheme.carbon,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: SlipTheme.carbon.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _DockItem(
            label: 'STREAM',
            icon: Icons.dynamic_feed_rounded,
            isActive: activeIndex == 0,
            onTap: () => onTabSelected(0),
          ),
          _DockItem(
            label: 'DROP',
            icon: Icons.add_circle_outline_rounded,
            isActive: activeIndex == 1,
            onTap: () => onTabSelected(1),
          ),
          _DockItem(
            label: 'ALERTS',
            icon: Icons.notifications_none_rounded,
            isActive: activeIndex == 2,
            onTap: () => onTabSelected(2),
          ),
          _DockItem(
            label: 'PROFILE',
            icon: Icons.person_outline_rounded,
            isActive: activeIndex == 3,
            onTap: () => onTabSelected(3),
          ),
        ],
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _DockItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? SlipTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? SlipTheme.carbon : SlipTheme.steelLight,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isActive ? SlipTheme.carbon : SlipTheme.steelLight,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
