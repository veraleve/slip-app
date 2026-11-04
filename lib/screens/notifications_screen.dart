import 'package:flutter/material.dart';
import '../models/slip.dart';
import '../providers/slip_provider.dart';
import '../services/supabase_service.dart';
import '../theme/slip_theme.dart';
import 'post_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final SlipProvider? provider;
  final VoidCallback? onOpenReviewCycle;

  const NotificationsScreen({
    super.key,
    this.provider,
    this.onOpenReviewCycle,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _broadcasts = [];

  @override
  void initState() {
    super.initState();
    _loadBroadcasts();
  }

  Future<void> _loadBroadcasts() async {
    final list = await SupabaseService().fetchBroadcastNotifications();
    if (mounted) {
      setState(() => _broadcasts = list);
    }
  }

  void _showPolicySheet(BuildContext context, Map<String, dynamic> alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SlipTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: SlipTheme.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              alert['title'] as String? ?? 'POLICY UPDATE',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: SlipTheme.carbon,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              alert['body'] as String? ?? '',
              style: const TextStyle(
                fontSize: 12.5,
                color: SlipTheme.carbon,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: SlipTheme.hairline, height: 1),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SlipTheme.carbon,
                  foregroundColor: SlipTheme.canvas,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('ACKNOWLEDGE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAlertTap(BuildContext context, Map<String, dynamic> alert) {
    final type = alert['type'] as String?;
    final slip = alert['slip'] as Slip?;

    if (type == 'policy_update') {
      _showPolicySheet(context, alert);
      return;
    }

    if (type == 'cycle') {
      Navigator.of(context).pop();
      widget.onOpenReviewCycle?.call();
      return;
    }

    if (slip != null && widget.provider != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            slip: slip,
            provider: widget.provider!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSlips = widget.provider?.allSlips ?? [];
    final currentUserId = widget.provider?.currentUserId;

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

    // Prepend Broadcast Policy & Community Notifications
    for (final b in _broadcasts) {
      realAlerts.add({
        'title': b['title']?.toString() ?? 'Community Notice',
        'body': b['message']?.toString() ?? '',
        'time': b['version'] != null ? 'v${b['version']}' : 'Notice',
        'icon': Icons.security_rounded,
        'color': SlipTheme.carbon,
        'type': 'policy_update',
        'slip': null,
      });
    }

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
