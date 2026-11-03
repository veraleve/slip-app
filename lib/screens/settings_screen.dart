import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
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

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SlipTheme.canvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SlipTheme.trapRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: const Color(0xFFF4F5F7), // Telegram-style light group background
      appBar: AppBar(
        backgroundColor: SlipTheme.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20, color: SlipTheme.carbon),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: SlipTheme.carbon,
                letterSpacing: -0.3,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // 1. Profile Header Block (Telegram Style)
          Container(
            color: SlipTheme.canvas,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: SlipTheme.carbon,
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: SlipTheme.canvas,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@$username',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: SlipTheme.carbon,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        userExams.isNotEmpty ? userExams.join(' • ') : 'GATE CS',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: SlipTheme.steel,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Session Active · Supabase Network',
                        style: TextStyle(
                          fontSize: 11,
                          color: SlipTheme.clearedGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // GROUP 1: PREFERENCES & SYLLABUS
          _SectionHeader(title: 'PREFERENCES & SYLLABUS'),
          _GroupCard(
            children: [
              _SettingGroupTile(
                icon: Icons.school_outlined,
                iconColor: SlipTheme.carbon,
                title: 'Target Exam Papers',
                subtitle: userExams.join(', '),
                onTap: () => _navigateTo(
                  context,
                  _ExamPapersSettingsPage(
                    initialExams: userExams,
                    onSave: (updated) {
                      setState(() {});
                    },
                  ),
                ),
              ),
              const _GroupDivider(),
              _SettingGroupTile(
                icon: Icons.notifications_none_rounded,
                iconColor: SlipTheme.carbon,
                title: 'Notifications & Alerts',
                subtitle: _dailyNotificationEnabled
                    ? 'Daily ${_reminderTime.format(context)}, Peer Alerts'
                    : 'Alerts muted',
                onTap: () => _navigateTo(
                  context,
                  _NotificationsSettingsPage(
                    dailyEnabled: _dailyNotificationEnabled,
                    reminderTime: _reminderTime,
                    peerAlerts: _peerMeshAlertsEnabled,
                    commentAlerts: _commentAlertsEnabled,
                    onDailyToggle: (val) {
                      setState(() => _dailyNotificationEnabled = val);
                      if (val) NativeDeviceService.requestPermissions();
                    },
                    onTimePicked: (t) => setState(() => _reminderTime = t),
                    onPeerToggle: (val) => setState(() => _peerMeshAlertsEnabled = val),
                    onCommentToggle: (val) => setState(() => _commentAlertsEnabled = val),
                    onTestAlert: _testAlert,
                  ),
                ),
              ),
              const _GroupDivider(),
              _SettingGroupTile(
                icon: Icons.security_outlined,
                iconColor: SlipTheme.carbon,
                title: 'Device Permissions',
                subtitle: _permissions.values.every((v) => v)
                    ? 'All permissions active'
                    : 'Camera, notifications & Bluetooth',
                onTap: () => _navigateTo(
                  context,
                  _PermissionsSettingsPage(
                    permissions: _permissions,
                    onRequest: () async {
                      await _requestPermissions();
                      setState(() {});
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // GROUP 2: NETWORK & STORAGE
          _SectionHeader(title: 'NETWORK & STORAGE'),
          _GroupCard(
            children: [
              _SettingGroupTile(
                icon: Icons.wifi_tethering_rounded,
                iconColor: SlipTheme.carbon,
                title: 'Data & Campus BLE Mesh',
                subtitle: _meshEnabled ? 'Mesh exchange active, auto-cache on' : 'Mesh disabled',
                onTap: () => _navigateTo(
                  context,
                  _DataMeshSettingsPage(
                    meshEnabled: _meshEnabled,
                    cacheEnabled: _offlineCacheEnabled,
                    onMeshToggle: (val) => setState(() => _meshEnabled = val),
                    onCacheToggle: (val) => setState(() => _offlineCacheEnabled = val),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // GROUP 3: ACCOUNT & ABOUT
          _SectionHeader(title: 'ACCOUNT & SYSTEM'),
          _GroupCard(
            children: [
              _SettingGroupTile(
                icon: Icons.person_outline_rounded,
                iconColor: SlipTheme.carbon,
                title: 'Account & Session',
                subtitle: '@$username',
                onTap: () => _navigateTo(
                  context,
                  _AccountSettingsPage(
                    username: username,
                    userId: service.currentUserId ?? 'local_peer',
                    onSignOut: _confirmSignOut,
                  ),
                ),
              ),
              const _GroupDivider(),
              _SettingGroupTile(
                icon: Icons.info_outline_rounded,
                iconColor: SlipTheme.carbon,
                title: 'About Slip & Principles',
                subtitle: '${AppConstants.appName} ${AppConstants.appVersion}',
                onTap: () => _navigateTo(context, const _AboutSettingsPage()),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Sign Out Button at Bottom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton(
              onPressed: _confirmSignOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: SlipTheme.trapRed,
                side: const BorderSide(color: SlipTheme.trapRed, width: 0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: SlipTheme.canvas,
              ),
              child: const Text(
                'SIGN OUT / RESET SESSION',
                style: TextStyle(
                  color: SlipTheme.trapRed,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              'Slip · Peer Mistake Inoculation Network',
              style: TextStyle(
                color: SlipTheme.steel.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

// ==========================================
// TELEGRAM-STYLE GROUP CARDS & TILES
// ==========================================

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: SlipTheme.steel,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final List<Widget> children;

  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: SlipTheme.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E5E8), width: 0.8),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.6,
      color: Color(0xFFEEEEEE),
      indent: 52,
    );
  }
}

class _SettingGroupTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingGroupTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: SlipTheme.carbon,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SlipTheme.steel,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: SlipTheme.steelLight,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SUB-PAGE 1: TARGET EXAM PAPERS
// ==========================================

class _ExamPapersSettingsPage extends StatefulWidget {
  final List<String> initialExams;
  final ValueChanged<List<String>> onSave;

  const _ExamPapersSettingsPage({
    required this.initialExams,
    required this.onSave,
  });

  @override
  State<_ExamPapersSettingsPage> createState() => _ExamPapersSettingsPageState();
}

class _ExamPapersSettingsPageState extends State<_ExamPapersSettingsPage> {
  late Set<String> _selectedExams;

  @override
  void initState() {
    super.initState();
    _selectedExams = Set<String>.from(widget.initialExams);
  }

  @override
  Widget build(BuildContext context) {
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
          'Target Exam Papers',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: SlipTheme.carbon),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'SELECT YOUR GATE BRANCHES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SlipTheme.steel),
          ),
          const SizedBox(height: 6),
          const Text(
            'The peer stream and review cycle will tailor blunders and doubts specifically to the exams you select.',
            style: TextStyle(fontSize: 12, color: SlipTheme.steel, height: 1.4),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: SlipTheme.hairline),
          for (final exam in GateSyllabus.supportedExams) ...[
            CheckboxListTile(
              value: _selectedExams.contains(exam),
              activeColor: SlipTheme.carbon,
              title: Text(
                exam,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                '${GateSyllabus.getSubjectsForExam(exam).length} syllabus subjects',
                style: const TextStyle(fontSize: 11, color: SlipTheme.steel),
              ),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedExams.add(exam);
                  } else {
                    if (_selectedExams.length > 1) {
                      _selectedExams.remove(exam);
                    }
                  }
                });
              },
            ),
            const Divider(height: 1, color: SlipTheme.hairline),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final list = _selectedExams.toList();
              SupabaseService().updateTargetExams(list);
              widget.onSave(list);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Target exam papers updated.'),
                  backgroundColor: SlipTheme.carbon,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SlipTheme.carbon,
              foregroundColor: SlipTheme.canvas,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('SAVE TARGET PAPERS', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SUB-PAGE 2: NOTIFICATIONS & ALERTS
// ==========================================

class _NotificationsSettingsPage extends StatelessWidget {
  final bool dailyEnabled;
  final TimeOfDay reminderTime;
  final bool peerAlerts;
  final bool commentAlerts;
  final ValueChanged<bool> onDailyToggle;
  final ValueChanged<TimeOfDay> onTimePicked;
  final ValueChanged<bool> onPeerToggle;
  final ValueChanged<bool> onCommentToggle;
  final VoidCallback onTestAlert;

  const _NotificationsSettingsPage({
    required this.dailyEnabled,
    required this.reminderTime,
    required this.peerAlerts,
    required this.commentAlerts,
    required this.onDailyToggle,
    required this.onTimePicked,
    required this.onPeerToggle,
    required this.onCommentToggle,
    required this.onTestAlert,
  });

  @override
  Widget build(BuildContext context) {
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
          'Notifications & Alerts',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: SlipTheme.carbon),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SubSettingToggle(
            title: 'DAILY MORNING INOCULATION',
            subtitle: 'Deliver 5 curated weak-spot blunders matching your syllabus every morning.',
            value: dailyEnabled,
            onChanged: onDailyToggle,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DELIVERY TIME',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SlipTheme.steel),
                  ),
                  SizedBox(height: 2),
                  Text('Scheduled device alarm time', style: TextStyle(fontSize: 11, color: SlipTheme.steel)),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: reminderTime,
                  );
                  if (picked != null) onTimePicked(picked);
                },
                icon: const Icon(Icons.access_time_rounded, size: 14),
                label: Text(
                  reminderTime.format(context),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SlipTheme.carbon,
                  side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: SlipTheme.hairline),
          const SizedBox(height: 16),
          _SubSettingToggle(
            title: 'PEER MESH BLUNDER ALERTS',
            subtitle: 'Get notified when a nearby peer shares a blunder in your active subjects.',
            value: peerAlerts,
            onChanged: onPeerToggle,
          ),
          const SizedBox(height: 16),
          _SubSettingToggle(
            title: 'COMMENT & DISCUSSION ALERTS',
            subtitle: 'Receive notifications when peers comment or discuss your shared blunders.',
            value: commentAlerts,
            onChanged: onCommentToggle,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTestAlert,
              icon: const Icon(Icons.notifications_active_outlined, size: 16),
              label: const Text('DISPATCH TEST NOTIFICATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: SlipTheme.carbon,
                foregroundColor: SlipTheme.canvas,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SUB-PAGE 3: DEVICE PERMISSIONS
// ==========================================

class _PermissionsSettingsPage extends StatelessWidget {
  final Map<String, bool> permissions;
  final VoidCallback onRequest;

  const _PermissionsSettingsPage({
    required this.permissions,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
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
          'Device Permissions',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: SlipTheme.carbon),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'HARDWARE & SYSTEM PRIVILEGES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SlipTheme.steel),
          ),
          const SizedBox(height: 6),
          const Text(
            'Slip uses these capabilities strictly on-device for blunder capture and local peer mesh.',
            style: TextStyle(fontSize: 12, color: SlipTheme.steel, height: 1.4),
          ),
          const SizedBox(height: 20),
          _PermissionDetailTile(
            title: 'Camera',
            description: 'Capture photo blunders and scratchpad rough work',
            isGranted: permissions['camera'] == true,
            icon: Icons.camera_alt_outlined,
          ),
          const Divider(height: 1, color: SlipTheme.hairline),
          _PermissionDetailTile(
            title: 'Notifications',
            description: 'Morning inoculation alerts and peer mistake triggers',
            isGranted: permissions['notifications'] == true,
            icon: Icons.notifications_none_rounded,
          ),
          const Divider(height: 1, color: SlipTheme.hairline),
          _PermissionDetailTile(
            title: 'Bluetooth Mesh',
            description: 'Offline peer-to-peer blunder exchange without internet',
            isGranted: permissions['bluetooth'] == true,
            icon: Icons.bluetooth_rounded,
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: onRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: SlipTheme.carbon,
              foregroundColor: SlipTheme.canvas,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('REQUEST / UPDATE PERMISSIONS', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _PermissionDetailTile extends StatelessWidget {
  final String title;
  final String description;
  final bool isGranted;
  final IconData icon;

  const _PermissionDetailTile({
    required this.title,
    required this.description,
    required this.isGranted,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: isGranted ? SlipTheme.carbon : SlipTheme.steel),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 11, color: SlipTheme.steel)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isGranted ? SlipTheme.clearedGreen.withOpacity(0.1) : SlipTheme.trapRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              isGranted ? 'GRANTED' : 'DENIED',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: isGranted ? SlipTheme.clearedGreen : SlipTheme.trapRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SUB-PAGE 4: DATA & CAMPUS BLE MESH
// ==========================================

class _DataMeshSettingsPage extends StatelessWidget {
  final bool meshEnabled;
  final bool cacheEnabled;
  final ValueChanged<bool> onMeshToggle;
  final ValueChanged<bool> onCacheToggle;

  const _DataMeshSettingsPage({
    required this.meshEnabled,
    required this.cacheEnabled,
    required this.onMeshToggle,
    required this.onCacheToggle,
  });

  @override
  Widget build(BuildContext context) {
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
          'Data & Campus BLE Mesh',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: SlipTheme.carbon),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SubSettingToggle(
            title: 'CAMPUS OFFLINE BLE MESH',
            subtitle: 'Exchange blunder slips directly with nearby peers in your library or hostel without internet.',
            value: meshEnabled,
            onChanged: onMeshToggle,
          ),
          const SizedBox(height: 18),
          _SubSettingToggle(
            title: 'AUTO-CACHE FOR EXAM DAY',
            subtitle: 'Keep your saved mistakes and review cycle cached locally on device for rapid revision offline.',
            value: cacheEnabled,
            onChanged: onCacheToggle,
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: SlipTheme.hairline),
          const SizedBox(height: 16),
          const Text(
            'CACHE STATUS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SlipTheme.steel),
          ),
          const SizedBox(height: 6),
          const Text(
            'Local-first database stores up to 150 offline blunder slips and cached peer interactions.',
            style: TextStyle(fontSize: 12, color: SlipTheme.steel, height: 1.4),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Offline feed cache refreshed.'),
                  backgroundColor: SlipTheme.carbon,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: SlipTheme.carbon,
              side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('PURGE & RE-SYNC LOCAL CACHE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SUB-PAGE 5: ACCOUNT & SESSION
// ==========================================

class _AccountSettingsPage extends StatelessWidget {
  final String username;
  final String userId;
  final VoidCallback onSignOut;

  const _AccountSettingsPage({
    required this.username,
    required this.userId,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
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
          'Account & Session',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: SlipTheme.carbon),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SlipTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: SlipTheme.hairline, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVE HANDLE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SlipTheme.steel),
                ),
                const SizedBox(height: 4),
                Text(
                  '@$username',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: SlipTheme.carbon),
                ),
                const SizedBox(height: 12),
                const Text(
                  'SESSION ID (UUID)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SlipTheme.steel),
                ),
                const SizedBox(height: 4),
                Text(
                  userId,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: SlipTheme.steel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onSignOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: SlipTheme.trapRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('SIGN OUT / RESET DEVICE SESSION', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SUB-PAGE 6: ABOUT & PRINCIPLES
// ==========================================

class _AboutSettingsPage extends StatelessWidget {
  const _AboutSettingsPage();

  @override
  Widget build(BuildContext context) {
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
          'About Slip',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: SlipTheme.carbon),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: SlipTheme.carbon,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'S',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: SlipTheme.canvas),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Slip',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Version 0.1.5 · Release Build',
                  style: TextStyle(fontSize: 12, color: SlipTheme.steel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Divider(height: 1, color: SlipTheme.hairline),
          const SizedBox(height: 20),
          const Text(
            'THE 4 PRINCIPLES OF INOCULATION',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: SlipTheme.steel),
          ),
          const SizedBox(height: 12),
          _PrincipleItem(
            num: '1',
            title: 'MISTAKES ARE TEACHERS',
            body: 'You do not learn from questions you solve easily on day 1. Breakthroughs happen when you stumble, identify the trap, and inoculate against it.',
          ),
          _PrincipleItem(
            num: '2',
            title: 'PEER PROXIMITY',
            body: 'Your classmate made a blunder in today\'s mock test that you would have fallen for next Sunday. Inoculate early by learning together.',
          ),
          _PrincipleItem(
            num: '3',
            title: 'LOCAL-FIRST RESILIENCE',
            body: 'Works offline in your study room, campus library, and hostel. Bluetooth mesh synchronizes peer mistakes without server dependencies.',
          ),
          _PrincipleItem(
            num: '4',
            title: 'ZERO EGO, ZERO BLOAT',
            body: 'No leaderboards, no vanity metrics. Only raw conceptual errors, trap descriptions, and the immediate fix.',
          ),
        ],
      ),
    );
  }
}

class _PrincipleItem extends StatelessWidget {
  final String num;
  final String title;
  final String body;

  const _PrincipleItem({
    required this.num,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: SlipTheme.carbon.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: SlipTheme.carbon),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: SlipTheme.carbon)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(fontSize: 11.5, color: SlipTheme.steel, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubSettingToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SubSettingToggle({
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
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: SlipTheme.carbon,
                  letterSpacing: 0.5,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: SlipTheme.steel,
                  height: 1.35,
                  fontSize: 11.5,
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
