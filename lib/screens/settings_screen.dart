import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final service = SupabaseService();
    final userExams = service.targetExams;

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
                'Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: SlipTheme.carbon,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Offline mesh, notifications, and exam preferences.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SlipTheme.steel,
                    ),
              ),
              const SizedBox(height: 24),
              const Divider(color: SlipTheme.hairline, height: 1),
              const SizedBox(height: 16),

              // 1. Campus Offline BLE Mesh
              _SettingToggle(
                title: 'CAMPUS BLE MESH',
                subtitle:
                    'Broadcast and receive mistake slips directly with nearby peers in your college library or hostel without internet.',
                value: _meshEnabled,
                onChanged: (val) {
                  setState(() => _meshEnabled = val);
                },
              ),
              const SizedBox(height: 16),
              const Divider(color: SlipTheme.hairline, height: 1),
              const SizedBox(height: 16),

              // 2. Daily Mistake Notifications
              _SettingToggle(
                title: 'DAILY INOCULATION ALERTS',
                subtitle:
                    'Receive a focused morning notification with high-yield conceptual traps for your exam syllabus.',
                value: _dailyNotificationEnabled,
                onChanged: (val) async {
                  setState(() => _dailyNotificationEnabled = val);
                  if (val) {
                    await NativeDeviceService.requestPermissions();
                  }
                },
              ),
              const SizedBox(height: 16),
              const Divider(color: SlipTheme.hairline, height: 1),
              const SizedBox(height: 16),

              // 3. Offline Cache
              _SettingToggle(
                title: 'AUTO-CACHE FOR EXAM DAY',
                subtitle:
                    'Persist your saved and high-yield mistake slips locally on device for quick offline revision at the exam center.',
                value: _offlineCacheEnabled,
                onChanged: (val) {
                  setState(() => _offlineCacheEnabled = val);
                },
              ),
              const SizedBox(height: 20),
              const Divider(color: SlipTheme.hairline, height: 1),
              const SizedBox(height: 20),

              // 4. Current Target Papers
              Text(
                'REGISTERED EXAM PAPERS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.steel,
                      letterSpacing: 0.6,
                    ),
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

              const SizedBox(height: 32),

              // 5. Sign Out
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await SupabaseService().signOut();
                    widget.onSignOut();
                  },
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
                  'Slip v1.0.0 · Open Source Peer Inoculation Ecosystem',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: SlipTheme.steel,
                        fontSize: 9.5,
                      ),
                ),
              ),
              const SizedBox(height: 16),
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
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SlipTheme.steel,
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: SlipTheme.carbon,
        ),
      ],
    );
  }
}
