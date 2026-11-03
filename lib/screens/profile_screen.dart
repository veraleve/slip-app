import 'package:flutter/material.dart';
import '../constants/gate_syllabus.dart';
import '../providers/slip_provider.dart';
import '../services/native_device_service.dart';
import '../services/supabase_service.dart';
import '../theme/slip_theme.dart';
import '../widgets/slip_card.dart';

class ProfileScreen extends StatefulWidget {
  final SlipProvider provider;
  final VoidCallback? onSignOut;

  const ProfileScreen({super.key, required this.provider, this.onSignOut});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  Future<void> _testNotification() async {
    final userExams = widget.provider.userExams;
    final primary = userExams.isNotEmpty ? userExams.first : 'GATE 2027';
    final sent = await NativeDeviceService.showNotification(
      title: 'Morning Inoculation · $primary',
      body: 'Today\'s high-yield blunder: Review matrix singularity vs nilpotency before your evening mock test.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sent ? 'Notification dispatched to device tray.' : 'Please allow notification permission.',
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
                'YOUR GATE 2027 PAPERS',
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
                    'Select up to 2 papers you are preparing for:',
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
                    widget.provider.init();
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

  @override
  Widget build(BuildContext context) {
    final service = SupabaseService();
    final username = service.currentUsername ?? 'peer_anonymous';
    final userExams = service.targetExams;

    // Filter saved slips for revision
    final savedSlips = widget.provider.slips.where((s) => s.hasKept).toList();

    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. User Handle & Registered Papers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@$username',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: SlipTheme.carbon,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'GATE 2027 ASPIRANT',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: SlipTheme.steel,
                              fontSize: 9.5,
                              letterSpacing: 0.8,
                            ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: _showEditPapersDialog,
                    icon: const Icon(Icons.edit_note_rounded, size: 14),
                    label: Text(
                      userExams.map((e) => e.replaceAll(' 2027', '')).join(' + '),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SlipTheme.carbon,
                      side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: SlipTheme.hairline, height: 1),
              const SizedBox(height: 20),

              // 2. Real Numbers (Living Stats)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatBlock(
                    label: 'SHARED',
                    value: widget.provider.sharedCount.toString(),
                    sublabel: 'TRAPS LOGGED',
                  ),
                  _StatBlock(
                    label: 'CLEARED',
                    value: widget.provider.clearedCount.toString(),
                    sublabel: 'MASTERED',
                    color: SlipTheme.clearedGreen,
                  ),
                  _StatBlock(
                    label: 'SAVED',
                    value: widget.provider.savedCount.toString(),
                    sublabel: 'BOOKMARKED',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: SlipTheme.hairline, height: 1),
              const SizedBox(height: 20),

              // 3. System Permissions & Native Alert Controls
              Text(
                'DEVICE CAPABILITIES & NOTIFICATIONS',
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
                    const SizedBox(height: 6),
                    _PermissionRow(
                      label: 'Notifications (Daily Inoculation)',
                      isGranted: _permissions['notifications'] == true,
                    ),
                    const SizedBox(height: 6),
                    _PermissionRow(
                      label: 'Bluetooth Mesh (Peer Exchange)',
                      isGranted: _permissions['bluetooth'] == true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _requestPermissions,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SlipTheme.carbon,
                              side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('GRANT PERMISSIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _testNotification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SlipTheme.carbon,
                              foregroundColor: SlipTheme.canvas,
                              visualDensity: VisualDensity.compact,
                              elevation: 0,
                            ),
                            child: const Text('TEST ALERT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Saved Mistakes for Revision
              Text(
                'SAVED FOR PRE-EXAM REVISION (${savedSlips.length})',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.steel,
                      letterSpacing: 0.6,
                    ),
              ),
              const SizedBox(height: 10),
              if (savedSlips.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: SlipTheme.surface,
                    border: Border.all(color: SlipTheme.hairline, width: 0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Text(
                      'No saved mistakes yet.\nTap the bookmark icon on any mistake in the stream to save it here for rapid revision.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: SlipTheme.steel,
                            height: 1.4,
                          ),
                    ),
                  ),
                ),
              ] else ...[
                ...savedSlips.map((slip) {
                  return SlipCard(
                    index: 0,
                    slip: slip,
                    onSameTap: () => widget.provider.toggleSame(slip.id),
                    onFixToggle: () => widget.provider.toggleFixRevealed(slip.id),
                    onKeepTap: () => widget.provider.toggleKeep(slip.id),
                    onSolveTap: () => widget.provider.toggleCleared(slip.id),
                    onPassTap: () {},
                  );
                }),
              ],

              const SizedBox(height: 32),

              // Sign Out Button
              if (widget.onSignOut != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await SupabaseService().signOut();
                      widget.onSignOut!();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SlipTheme.trapRed,
                      side: const BorderSide(color: SlipTheme.trapRed, width: 0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final Color? color;

  const _StatBlock({
    required this.label,
    required this.value,
    required this.sublabel,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: SlipTheme.steel,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color ?? SlipTheme.carbon,
              ),
        ),
        Text(
          sublabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: SlipTheme.steel,
                fontSize: 8.5,
              ),
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
