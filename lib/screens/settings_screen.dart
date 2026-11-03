import 'package:flutter/material.dart';
import '../constants/gate_syllabus.dart';
import '../services/native_device_service.dart';
import '../services/supabase_service.dart';
import '../theme/slip_theme.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onSignOut;

  const SettingsScreen({super.key, required this.onSignOut});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _meshEnabled = true;
  bool _offlineCacheEnabled = true;
  bool _dailyNotificationEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _peerMeshAlertsEnabled = true;
  bool _commentAlertsEnabled = true;

  Map<String, bool> _permissions = {
    'camera': false,
    'notifications': false,
    'bluetooth': false,
  };

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await NativeDeviceService.checkPermissions();
    if (mounted) {
      setState(() => _permissions = status);
    }
  }

  Future<void> _requestPermissions() async {
    final status = await NativeDeviceService.requestPermissions();
    if (mounted) {
      setState(() => _permissions = status);
    }
  }

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
    final userExams = SupabaseService().targetExams;
    final primary = userExams.isNotEmpty ? userExams.first : 'GATE';
    final sent = await NativeDeviceService.showNotification(
      title: 'Inoculation Alert · $primary',
      body: 'Today\'s high-yield blunder: Review matrix singularity vs nilpotency before your test.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sent
                ? 'Test alert dispatched to Android notification tray.'
                : 'Please enable notifications permission first.',
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: SlipTheme.carbon,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showEditPapersDialog() {
    final service = SupabaseService();
    final selected = Set<String>.from(service.targetExams);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: SlipTheme.canvas,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              title: Text(
                'TARGET GATE PAPERS',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select up to 2 papers for your preparation:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SlipTheme.steel),
                  ),
                  const SizedBox(height: 14),
                  ...GateSyllabus.supportedExams.map((exam) {
                    final isChecked = selected.contains(exam);
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: SlipTheme.carbon,
                      title: Text(
                        exam,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      value: isChecked,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            if (selected.length < 2) {
                              selected.add(exam);
                            }
                          } else {
                            if (selected.length > 1) {
                              selected.remove(exam);
                            }
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CANCEL', style: TextStyle(color: SlipTheme.steel)),
                ),
                ElevatedButton(
                  onPressed: () {
                    service.updateTargetExams(selected.toList());
                    Navigator.of(ctx).pop();
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SlipTheme.carbon,
                    foregroundColor: SlipTheme.canvas,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  ),
                  child: const Text('SAVE PAPERS'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SlipTheme.canvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text(
          'SIGN OUT',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
        ),
        content: const Text(
          'Are you sure you want to sign out and reset your active session on this device?',
          style: TextStyle(fontSize: 12.5, color: SlipTheme.steel, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: SlipTheme.steel)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await SupabaseService().signOut();
              widget.onSignOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SlipTheme.trapRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
            child: const Text('CONFIRM SIGN OUT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = SupabaseService();
    final username = service.currentUsername ?? 'peer_anonymous';
    final userExams = service.targetExams;

    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Back Button
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 20, color: SlipTheme.carbon),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SlipTheme.carbon,
                          letterSpacing: -0.5,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Text(
                  'Manage notifications, permissions, exam papers & offline mesh.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SlipTheme.steel,
                      ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: SlipTheme.hairline, height: 1),
              const SizedBox(height: 20),

              // 1. Device Capabilities & Permissions
              Text(
                'DEVICE CAPABILITIES & PERMISSIONS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.steel,
                      letterSpacing: 0.6,
                    ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SlipTheme.surface,
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Column(
                  children: [
                    _PermissionRow(
                      label: 'Camera (Photo Blunders)',
                      isGranted: _permissions['camera'] == true,
                    ),
                    const SizedBox(height: 8),
                    _PermissionRow(
                      label: 'Notifications (Daily Alerts)',
                      isGranted: _permissions['notifications'] == true,
                    ),
                    const SizedBox(height: 8),
                    _PermissionRow(
                      label: 'Bluetooth Mesh (Peer Exchange)',
                      isGranted: _permissions['bluetooth'] == true,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _requestPermissions,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: SlipTheme.carbon,
                          side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text(
                          'REQUEST / UPDATE PERMISSIONS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: SlipTheme.hairline, height: 1),
              const SizedBox(height: 20),

              // 2. Notifications & Alert Schedules
              Text(
                'DAILY INOCULATION & NOTIFICATIONS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.steel,
                      letterSpacing: 0.6,
                    ),
              ),
              const SizedBox(height: 14),

              _SettingToggle(
                title: 'DAILY MORNING INOCULATION',
                subtitle:
                    'Deliver 5 curated weak-spot blunders matching your syllabus every morning.',
                value: _dailyNotificationEnabled,
                onChanged: (val) async {
                  setState(() => _dailyNotificationEnabled = val);
                  if (val) await NativeDeviceService.requestPermissions();
                },
              ),
              const SizedBox(height: 12),

              // Schedule Time Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DELIVERY TIME',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: SlipTheme.carbon,
                              fontSize: 10,
                            ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Scheduled device alarm time',
                        style: TextStyle(fontSize: 10.5, color: SlipTheme.steel),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time_rounded, size: 14),
                    label: Text(
                      _reminderTime.format(context),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SlipTheme.carbon,
                      side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _SettingToggle(
                title: 'PEER MESH BLUNDER ALERTS',
                subtitle:
                    'Get notified when a peer shares a blunder in your active subjects.',
                value: _peerMeshAlertsEnabled,
                onChanged: (val) {
                  setState(() => _peerMeshAlertsEnabled = val);
                },
              ),
              const SizedBox(height: 14),

              _SettingToggle(
                title: 'COMMENT & DISCUSSION ALERTS',
                subtitle:
                    'Receive notifications when peers comment or discuss your shared blunders.',
                value: _commentAlertsEnabled,
                onChanged: (val) {
                  setState(() => _commentAlertsEnabled = val);
                },
              ),
              const SizedBox(height: 12),

              // Dispatch Test Notification
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _testAlert,
                  icon: const Icon(Icons.notifications_active_outlined, size: 14),
                  label: const Text('DISPATCH TEST NOTIFICATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SlipTheme.carbon,
                    foregroundColor: SlipTheme.canvas,
                    elevation: 0,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(color: SlipTheme.hairline, height: 1),
              const SizedBox(height: 20),

              // 3. Target Exam Papers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TARGET GATE PAPERS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: SlipTheme.steel,
                          letterSpacing: 0.6,
                        ),
                  ),
                  GestureDetector(
                    onTap: _showEditPapersDialog,
                    child: Text(
                      'CHANGE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: SlipTheme.carbon,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: SlipTheme.surface,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                ),
                child: Text(
                  userExams.join('  •  '),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SlipTheme.carbon,
                      ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(color: SlipTheme.hairline, height: 1),
              const SizedBox(height: 20),

              // 4. Campus BLE Mesh & Offline Cache
              _SettingToggle(
                title: 'CAMPUS OFFLINE BLE MESH',
                subtitle:
                    'Exchange mistake slips directly with nearby peers in your library or hostel without internet.',
                value: _meshEnabled,
                onChanged: (val) {
                  setState(() => _meshEnabled = val);
                },
              ),
              const SizedBox(height: 14),

              _SettingToggle(
                title: 'AUTO-CACHE FOR EXAM DAY',
                subtitle:
                    'Keep your saved mistakes and review cycle cached locally on device for rapid revision offline.',
                value: _offlineCacheEnabled,
                onChanged: (val) {
                  setState(() => _offlineCacheEnabled = val);
                },
              ),

              const SizedBox(height: 28),
              const Divider(color: SlipTheme.hairline, height: 1),
              const SizedBox(height: 20),

              // 5. Account & Session Management
              Row(
                children: [
                  Text(
                    'SIGNED IN AS: ',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: SlipTheme.steel,
                          fontSize: 10,
                        ),
                  ),
                  Text(
                    '@$username',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: SlipTheme.carbon,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _confirmSignOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SlipTheme.trapRed,
                    side: const BorderSide(color: SlipTheme.trapRed, width: 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'SIGN OUT / RESET SESSION',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: SlipTheme.trapRed,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Slip · Open Source Mistake Inoculation Ecosystem',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: SlipTheme.steel,
                        fontSize: 9.5,
                      ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.carbon,
                      letterSpacing: 0.5,
                      fontSize: 10,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SlipTheme.steel,
                      height: 1.35,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: SlipTheme.carbon,
        ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String label;
  final bool isGranted;

  const _PermissionRow({
    required this.label,
    required this.isGranted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: SlipTheme.carbon,
                fontSize: 11.5,
              ),
        ),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isGranted ? SlipTheme.clearedGreen : SlipTheme.trapRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isGranted ? 'ACTIVE' : 'NOT GRANTED',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    color: isGranted ? SlipTheme.clearedGreen : SlipTheme.trapRed,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
