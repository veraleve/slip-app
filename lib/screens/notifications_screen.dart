import 'package:flutter/material.dart';
import '../constants/gate_syllabus.dart';
import '../models/slip.dart';
import '../providers/slip_provider.dart';
import '../services/native_device_service.dart';
import '../services/supabase_service.dart';
import '../theme/slip_theme.dart';

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
  bool _morningReminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _peerMeshAlertsEnabled = true;
  bool _commentAlertsEnabled = true;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  Future<void> _testAlert() async {
    final primaryExam = SupabaseService().targetExams.isNotEmpty
        ? SupabaseService().targetExams.first
        : GateSyllabus.gateCS;
    await NativeDeviceService.showNotification(
      title: 'Inoculation Alert · $primaryExam',
      body: 'Morning mistake check: Review eigenvalues of singular matrices before your test.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification dispatched to Android notification tray.'),
          backgroundColor: SlipTheme.carbon,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate real notifications from active slips
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

    if (unmastered.isNotEmpty) {
      realAlerts.add({
        'title': 'Review Cycle: ${unmastered.length} mistakes due',
        'body': 'Inoculate your weak spots: ${unmastered.first.topic} · ${unmastered.first.trapStatement}',
        'time': 'Active',
        'icon': Icons.psychology_outlined,
        'color': const Color(0xFFD97706),
        'type': 'cycle',
      });
    }

    for (final d in doubts.take(3)) {
      realAlerts.add({
        'title': 'Peer Doubt: ${d.topic}',
        'body': d.title ?? d.trapStatement,
        'time': 'Open',
        'icon': Icons.help_outline_rounded,
        'color': SlipTheme.carbon,
        'type': 'doubt',
      });
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
            // 1. Live Alerts Section
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
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: SlipTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 36, color: SlipTheme.steelLight),
                    SizedBox(height: 10),
                    Text(
                      'No new notifications',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SlipTheme.carbon),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Alerts for your scheduled tasks, mistake reviews, and peer discussions will appear here.',
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
                  return InkWell(
                    onTap: () {
                      if (alert['type'] == 'cycle') {
                        widget.onOpenReviewCycle?.call();
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: SlipTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: SlipTheme.hairline, width: 0.8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: (alert['color'] as Color).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              alert['icon'] as IconData,
                              size: 18,
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
                                  style: const TextStyle(fontSize: 11.5, color: SlipTheme.steel, height: 1.35),
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

            const SizedBox(height: 28),
            const Divider(color: SlipTheme.hairline, height: 1),
            const SizedBox(height: 20),

            // 2. Alert Preferences (Smooth curved container)
            const Text(
              'ALERT PREFERENCES',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: SlipTheme.steel,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SlipTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SlipTheme.hairline, width: 0.8),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAILY MORNING INOCULATION',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: SlipTheme.carbon),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Deliver 5 curated weak-spot mistakes matching your syllabus every morning',
                              style: TextStyle(color: SlipTheme.steel, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _morningReminderEnabled,
                        onChanged: (v) => setState(() => _morningReminderEnabled = v),
                        activeColor: SlipTheme.carbon,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DELIVERY TIME', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: SlipTheme.steel)),
                          SizedBox(height: 2),
                          Text('Scheduled device alarm', style: TextStyle(fontSize: 11, color: SlipTheme.steel)),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time_rounded, size: 14),
                        label: Text(_reminderTime.format(context), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SlipTheme.carbon,
                          side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: SlipTheme.hairline, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PEER MESH BLUNDER ALERTS',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: SlipTheme.carbon),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Get notified when a nearby peer shares a mistake in your active subjects',
                              style: TextStyle(color: SlipTheme.steel, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _peerMeshAlertsEnabled,
                        onChanged: (v) => setState(() => _peerMeshAlertsEnabled = v),
                        activeColor: SlipTheme.carbon,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COMMENT & DISCUSSION ALERTS',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: SlipTheme.carbon),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Notify when a peer adds a conceptual note to your mistake',
                              style: TextStyle(color: SlipTheme.steel, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _commentAlertsEnabled,
                        onChanged: (v) => setState(() => _commentAlertsEnabled = v),
                        activeColor: SlipTheme.carbon,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _testAlert,
                      icon: const Icon(Icons.notifications_active_outlined, size: 14),
                      label: const Text('DISPATCH TEST NOTIFICATION', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SlipTheme.carbon,
                        side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
