import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
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
  String _selectedExam = AppConstants.supportedExams.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'SYSTEM SETTINGS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'PREFERENCES // NETWORK & TELEMETRY CONTROLS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: SlipTheme.steel,
                    ),
              ),
              const SizedBox(height: 24),
              const Divider(),

              // 1. Campus Offline BLE Mesh
              _SettingToggle(
                title: 'CAMPUS OFFLINE BLE MESH',
                subtitle:
                    'Share and receive mistake slips over Bluetooth Low Energy with peers in the same library or hostel without internet.',
                value: _meshEnabled,
                onChanged: (val) {
                  setState(() => _meshEnabled = val);
                },
              ),
              const SizedBox(height: 16),
              const Divider(),

              // 2. Offline Cache for Test Centers
              _SettingToggle(
                title: 'AUTO-CACHE SLIPS FOR OFFLINE STUDY',
                subtitle:
                    'Keep top 100 high-yield exam traps cached for quick revision right before entering the test hall.',
                value: _offlineCacheEnabled,
                onChanged: (val) {
                  setState(() => _offlineCacheEnabled = val);
                },
              ),
              const SizedBox(height: 16),
              const Divider(),

              // 3. Target Exam Selector
              Text(
                'TARGET EXAM STREAM',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Filters all mistake recommendations to your curriculum',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: SlipTheme.surface,
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedExam,
                    isExpanded: true,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SlipTheme.carbon,
                          fontWeight: FontWeight.w600,
                        ),
                    items: AppConstants.supportedExams.map((exam) {
                      return DropdownMenuItem(
                        value: exam,
                        child: Text(exam),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedExam = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),

              // 4. Cloud Infrastructure Status
              Text(
                'INFRASTRUCTURE ENDPOINTS',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              _EndpointRow(
                label: 'SUPABASE REGION',
                value: 'ap-south-1 (Mumbai)',
                status: 'ACTIVE',
              ),
              const SizedBox(height: 6),
              _EndpointRow(
                label: 'KAGGLE ENGINE',
                value: 'Gemma-2 CPU Batch (12h Cycle)',
                status: 'ONLINE',
              ),
              const SizedBox(height: 6),
              _EndpointRow(
                label: 'NOSTR RELAYS',
                value: 'wss://relay.damus.io',
                status: 'CONNECTED',
              ),
              const SizedBox(height: 28),
              const Divider(),

              // 5. Sign Out / Reset
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'DISCONNECT SESSION & SIGN OUT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: SlipTheme.trapRed,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Text(
                  'Slip v1.0.0 · Open Source (github.com/veraleve/slip-app)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: SlipTheme.steelLight,
                        fontSize: 9,
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
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
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

class _EndpointRow extends StatelessWidget {
  final String label;
  final String value;
  final String status;

  const _EndpointRow({
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: SlipTheme.steel,
                fontSize: 9.5,
              ),
        ),
        Row(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 9.5,
                  ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: SlipTheme.clearedGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                status,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: SlipTheme.clearedGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 8,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
