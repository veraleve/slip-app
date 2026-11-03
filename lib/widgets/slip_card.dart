import 'package:flutter/material.dart';
import '../models/slip.dart';
import '../theme/slip_theme.dart';
import 'audio_waveform_strip.dart';

class SlipCard extends StatelessWidget {
  final int index;
  final Slip slip;
  final VoidCallback onSameTap;
  final VoidCallback onFixToggle;
  final VoidCallback onKeepTap;
  final VoidCallback onPassTap;

  const SlipCard({
    super.key,
    required this.index,
    required this.slip,
    required this.onSameTap,
    required this.onFixToggle,
    required this.onKeepTap,
    required this.onPassTap,
  });

  @override
  Widget build(BuildContext context) {
    final slipNumber = (index + 1).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Whisper Metadata Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$slipNumber // ${slip.topic.toUpperCase()} · ${slip.subtopic?.toUpperCase() ?? "GENERAL"}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: SlipTheme.steel,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  slip.examTag,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: SlipTheme.carbon,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. The Trap Statement
          Text(
            slip.trapStatement,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),

          // 3. Audio Waveform Autopsy
          if (slip.audioDurationSeconds > 0) ...[
            AudioWaveformStrip(
              totalSeconds: slip.audioDurationSeconds,
              studentTranscript:
                  'Audio note: "I confused the null space condition with nilpotency..."',
            ),
            const SizedBox(height: 14),
          ],

          // 4. Cognitive Shift: The Fix (Revealed or Toggle)
          if (slip.isFixRevealed) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SlipTheme.canvas,
                border: Border.all(color: SlipTheme.hairline, width: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 14,
                        color: SlipTheme.clearedGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'THE FIX // CONCEPTUAL TRUTH',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: SlipTheme.clearedGreen,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    slip.fixStatement,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: SlipTheme.carbon,
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 5. Tactile Action Controls (Same, The Fix, Keep, Pass)
          Row(
            children: [
              // Same ("I fell for this too")
              _ActionButton(
                label: 'Same',
                count: slip.sameCount,
                isActive: slip.hasSaidSame,
                activeColor: SlipTheme.trapRed,
                icon: slip.hasSaidSame
                    ? Icons.trending_up_rounded
                    : Icons.trending_up_rounded,
                onTap: onSameTap,
              ),
              const SizedBox(width: 8),

              // The Fix Toggle
              _ActionButton(
                label: slip.isFixRevealed ? 'Hide Fix' : 'The Fix',
                isActive: slip.isFixRevealed,
                activeColor: SlipTheme.clearedGreen,
                icon: slip.isFixRevealed
                    ? Icons.visibility_off_outlined
                    : Icons.lightbulb_outline_rounded,
                onTap: onFixToggle,
              ),
              const Spacer(),

              // Keep (Save)
              IconButton(
                onPressed: onKeepTap,
                icon: Icon(
                  slip.hasKept
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 18,
                  color: slip.hasKept ? SlipTheme.carbon : SlipTheme.steel,
                ),
                tooltip: 'Keep for revision',
                visualDensity: VisualDensity.compact,
              ),

              // Pass (Share)
              IconButton(
                onPressed: onPassTap,
                icon: const Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: SlipTheme.steel,
                ),
                tooltip: 'Pass to peer',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final int? count;
  final bool isActive;
  final Color activeColor;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    this.count,
    required this.isActive,
    required this.activeColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.08) : Colors.transparent,
          border: Border.all(
            color: isActive ? activeColor : SlipTheme.hairline,
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? activeColor : SlipTheme.steel,
            ),
            const SizedBox(width: 5),
            Text(
              count != null ? '$label ($count)' : label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isActive ? activeColor : SlipTheme.carbon,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
