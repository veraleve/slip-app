import 'package:flutter/material.dart';
import '../providers/slip_provider.dart';
import '../services/supabase_service.dart';
import '../theme/slip_theme.dart';

class ProfileScreen extends StatelessWidget {
  final SlipProvider provider;

  const ProfileScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final username = SupabaseService().currentUsername ?? 'shyam_gate';
    final userHandle = '@$username';

    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Identity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userHandle,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: SlipTheme.clearedGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'NOSTR SECP256K1 · VERIFIED PEER',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: SlipTheme.textSecondary,
                                  fontSize: 9,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: SlipTheme.hairline, width: 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'GATE CS 2027',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SlipTheme.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),

              // The 3 Living Numbers (Zero Boxy Containers)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatBlock(
                    label: 'SHARED',
                    value: provider.sharedCount.toString(),
                    sublabel: 'TRAPS LOGGED',
                  ),
                  _StatBlock(
                    label: 'CLEARED',
                    value: provider.clearedCount.toString(),
                    sublabel: 'MASTERED',
                    color: SlipTheme.clearedGreen,
                  ),
                  _StatBlock(
                    label: 'SAVED',
                    value: provider.savedCount.toString(),
                    sublabel: 'PRE-EXAM REVISION',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),

              // Topic Vulnerability Radar / Status
              Text(
                'TOPIC VULNERABILITY RADAR',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Calculated from your trap reactions and blunder history',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 16),

              _VulnerabilityRow(
                topic: 'Linear Algebra',
                mastery: 0.92,
                status: 'INOCULATED',
                isHighRisk: false,
              ),
              const SizedBox(height: 12),

              _VulnerabilityRow(
                topic: 'Operating Systems',
                mastery: 0.42,
                status: 'HIGH RISK (3 TRAPS REMAINING)',
                isHighRisk: true,
              ),
              const SizedBox(height: 12),

              _VulnerabilityRow(
                topic: 'Discrete Mathematics',
                mastery: 0.85,
                status: 'STABLE',
                isHighRisk: false,
              ),
              const SizedBox(height: 12),

              _VulnerabilityRow(
                topic: 'Computer Architecture',
                mastery: 0.60,
                status: 'WARNING: PIPELINE HAZARDS',
                isHighRisk: true,
              ),
              const SizedBox(height: 28),

              // Cryptographic Nostr Key String
              Text(
                'PEER IDENTITY FINGERPRINT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SlipTheme.surface,
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.key_rounded, size: 14, color: SlipTheme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'npub1g83m9fx27zll44p80a...94zk21m',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontFamily: 'monospace',
                              color: SlipTheme.textSecondary,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'PUBLIC KEY COPIED TO CLIPBOARD',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: SlipTheme.canvas),
                            ),
                            backgroundColor: SlipTheme.textPrimary,
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: SlipTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                color: SlipTheme.textSecondary,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 28,
                color: color ?? SlipTheme.textPrimary,
              ),
        ),
        Text(
          sublabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 8.5,
                color: SlipTheme.textTertiary,
              ),
        ),
      ],
    );
  }
}

class _VulnerabilityRow extends StatelessWidget {
  final String topic;
  final double mastery;
  final String status;
  final bool isHighRisk;

  const _VulnerabilityRow({
    required this.topic,
    required this.mastery,
    required this.status,
    required this.isHighRisk,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              topic,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: SlipTheme.textPrimary,
                  ),
            ),
            Text(
              '${(mastery * 100).toInt()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isHighRisk ? SlipTheme.trapRed : SlipTheme.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Progress bar
        Stack(
          children: [
            Container(
              height: 3,
              width: double.infinity,
              color: SlipTheme.hairline,
            ),
            FractionallySizedBox(
              widthFactor: mastery,
              child: Container(
                height: 3,
                color: isHighRisk ? SlipTheme.trapRed : SlipTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          status,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isHighRisk ? SlipTheme.trapRed : SlipTheme.textSecondary,
              ),
        ),
      ],
    );
  }
}
