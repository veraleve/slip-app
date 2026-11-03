import 'package:flutter/material.dart';
import '../models/slip.dart';
import '../providers/slip_provider.dart';
import '../theme/slip_theme.dart';
import 'post_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  final SlipProvider? provider;
  final VoidCallback? onOpenReviewCycle;

  const NotificationsScreen({
    super.key,
    this.provider,
    this.onOpenReviewCycle,
  });

  void _handleAlertTap(BuildContext context, Map<String, dynamic> alert) {
    final type = alert['type'] as String?;
    final slip = alert['slip'] as Slip?;

    if (type == 'cycle') {
      Navigator.of(context).pop();
      onOpenReviewCycle?.call();
      return;
    }

    if (slip != null && provider != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            slip: slip,
            provider: provider!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSlips = provider?.allSlips ?? [];
    final currentUserId = provider?.currentUserId;

    final unmastered = allSlips
        .where((s) =>
            s.postType == PostType.mistake &&
            !s.hasCleared &&
            (s.hasKept || (currentUserId != null && s.authorId == currentUserId)))
        .toList();

    final doubts = allSlips
        .where((s) => s.postType == PostType.doubt && !s.isResolved)
        .toList();

    final List<Map<String, dynamic>> realAlerts = [];

    if (unmastered.isNotEmpty) {
      realAlerts.add({
        'title': 'Review Cycle: ${unmastered.length} mistakes due',
        'body': 'Inoculate your weak spots: ${unmastered.first.topic} · ${unmastered.first.trapStatement}',
        'time': 'Active',
        'icon': Icons.psychology_outlined,
        'color': const Color(0xFFD97706),
        'type': 'cycle',
        'slip': unmastered.first,
      });
    }

    for (final d in doubts.take(4)) {
      realAlerts.add({
        'title': 'Peer Doubt: ${d.topic}',
        'body': d.title ?? d.trapStatement,
        'time': 'Open',
        'icon': Icons.help_outline_rounded,
        'color': SlipTheme.carbon,
        'type': 'doubt',
        'slip': d,
      });
    }

    final recentMistakes = allSlips
        .where((s) => s.postType == PostType.mistake && !s.hasCleared)
        .take(3);
    for (final m in recentMistakes) {
      if (!unmastered.contains(m)) {
        realAlerts.add({
          'title': 'High-Yield Trap: ${m.topic}',
          'body': m.trapStatement,
          'time': 'Recent',
          'icon': Icons.warning_amber_rounded,
          'color': const Color(0xFFD97706),
          'type': 'mistake',
          'slip': m,
        });
      }
    }

    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      appBar: AppBar(
        backgroundColor: SlipTheme.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20, color: SlipTheme.carbon),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: SlipTheme.carbon,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            const Text(
              'ACTIVITY ALERTS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: SlipTheme.steel,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),

            if (realAlerts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: SlipTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 38, color: SlipTheme.steelLight),
                    SizedBox(height: 10),
                    Text(
                      'No new notifications',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SlipTheme.carbon),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Alerts for scheduled tasks, peer doubts, and mistake reviews will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: SlipTheme.steel, height: 1.4),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: realAlerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final alert = realAlerts[index];
                  final isCycle = alert['type'] == 'cycle';

                  return InkWell(
                    onTap: () => _handleAlertTap(context, alert),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: SlipTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: SlipTheme.hairline, width: 0.8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: (alert['color'] as Color).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              alert['icon'] as IconData,
                              size: 19,
                              color: alert['color'] as Color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        alert['title'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: SlipTheme.carbon,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      alert['time'] as String,
                                      style: const TextStyle(fontSize: 10, color: SlipTheme.steel),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  alert['body'] as String,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: SlipTheme.steel,
                                    height: 1.35,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: SlipTheme.carbon,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isCycle ? 'REVIEW NOW' : 'OPEN POST',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: SlipTheme.canvas,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
