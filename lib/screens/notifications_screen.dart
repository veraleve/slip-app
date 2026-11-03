import 'package:flutter/material.dart';
import '../services/native_device_service.dart';
import '../services/supabase_service.dart';
import '../theme/slip_theme.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback onOpenReviewCycle;

  const NotificationsScreen({super.key, required this.onOpenReviewCycle});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _morningReminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _peerMeshAlertsEnabled = true;
  bool _commentAlertsEnabled = true;

  final List<Map<String, dynamic>> _alerts = [
    {
      'title': 'Morning Inoculation Cycle Active',
      'body': '5 high-yield unmastered traps scheduled for your daily review.',
      'time': 'Today, 8:00 AM',
      'type': 'cycle',
      'isRead': false,
    },
    {
      'title': 'Peer Blunder Broadcast Received',
      'body': 'Peer @arya shared a trap in Machine Learning > SVM Slack Regularization.',
      'time': 'Yesterday, 6:45 PM',
      'type': 'peer',
      'isRead': true,
    },
    {
      'title': 'Peer Comment on Your Blunder',
      'body': 'Peer @kunal replied to your Deadlock Avoidance fix note.',
      'time': '2 days ago',
      'type': 'comment',
      'isRead': true,
    },
  ];

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
      title: 'Slip Inoculation Alert · $primaryExam',
      body: 'Morning trap check: Review eigenvalues of singular matrices before your mock test.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test alert dispatched to Android notification tray.'),
          backgroundColor: SlipTheme.carbon,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: SlipTheme.carbon,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Inoculation reminders and peer mesh blunder alerts.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SlipTheme.steel,
                    ),
              ),
              const SizedBox(height: 20),
              const Divider(color: SlipTheme.hairline, height: 1),
              const SizedBox(height: 16),

              // 1. Notification Schedule Preferences
              Text(
                'ALERT PREFERENCES',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.steel,
                      letterSpacing: 0.6,
                    ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SlipTheme.surface,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                ),
                child: Column(
                  children: [
                    // Morning Inoculation Toggle + Time Picker
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Morning Inoculation Reminder',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Daily digest of active weak spots at ${_reminderTime.format(context)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: SlipTheme.steel, fontSize: 11),
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
                    if (_morningReminderEnabled) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time_rounded, size: 14, color: SlipTheme.carbon),
                          label: Text(
                            'CHANGE TIME (${_reminderTime.format(context)})',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: SlipTheme.carbon),
                          ),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                        ),
                      ),
                    ],

                    const Divider(color: SlipTheme.hairline, height: 18),

                    // Peer Mesh Alert Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Campus Peer Blunder Alerts',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Alert when nearby library peer shares a slip in your paper',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: SlipTheme.steel, fontSize: 11),
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

                    const Divider(color: SlipTheme.hairline, height: 18),

                    // Comments Alert Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Peer Discussion Replies',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Notify when a peer adds a conceptual note to your trap',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: SlipTheme.steel, fontSize: 11),
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

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _testAlert,
                        icon: const Icon(Icons.notifications_active_outlined, size: 14),
                        label: const Text('DISPATCH TEST NOTIFICATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SlipTheme.carbon,
                          side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Notification History Ledger
              Text(
                'ALERT HISTORY (${_alerts.length})',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.steel,
                      letterSpacing: 0.6,
                    ),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final alert = _alerts[index];
                  final isUnread = alert['isRead'] == false;
                  return InkWell(
                    onTap: () {
                      setState(() => alert['isRead'] = true);
                      if (alert['type'] == 'cycle') {
                        widget.onOpenReviewCycle();
                      }
                    },
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUnread ? SlipTheme.surface : SlipTheme.canvas,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: isUnread ? SlipTheme.carbon : SlipTheme.hairline,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            alert['type'] == 'cycle'
                                ? Icons.restart_alt_rounded
                                : alert['type'] == 'peer'
                                    ? Icons.bluetooth_audio_rounded
                                    : Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: isUnread ? SlipTheme.carbon : SlipTheme.steel,
                          ),
                          const SizedBox(width: 10),
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                                              color: SlipTheme.carbon,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      alert['time'] as String,
                                      style: const TextStyle(fontSize: 9.5, color: SlipTheme.steel),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  alert['body'] as String,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: SlipTheme.steel,
                                        fontSize: 11,
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

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
