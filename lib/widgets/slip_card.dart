import 'package:flutter/material.dart';
import '../models/slip.dart';
import '../theme/slip_theme.dart';
import 'audio_waveform_strip.dart';
import 'comment_thread_sheet.dart';
import 'image_gallery_grid.dart';

class SlipCard extends StatefulWidget {
  final int index;
  final Slip slip;
  final VoidCallback onSameTap;
  final VoidCallback onFixToggle;
  final VoidCallback onKeepTap;
  final VoidCallback onSolveTap;
  final VoidCallback onPassTap;

  const SlipCard({
    super.key,
    required this.index,
    required this.slip,
    required this.onSameTap,
    required this.onFixToggle,
    required this.onKeepTap,
    required this.onSolveTap,
    required this.onPassTap,
  });

  @override
  State<SlipCard> createState() => _SlipCardState();
}

class _SlipCardState extends State<SlipCard> {
  bool _showComments = false;

  @override
  Widget build(BuildContext context) {
    final slip = widget.slip;
    final examShort = slip.examTag.replaceAll('GATE ', '').replaceAll(' 2027', '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: SlipTheme.hairline, width: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Clean Subject & Exam Breadcrumb
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${slip.topic} · ${slip.subtopic ?? "General"}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: SlipTheme.steel,
                        letterSpacing: 0.2,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: SlipTheme.surface,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: SlipTheme.hairline, width: 0.6),
                ),
                child: Text(
                  examShort,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5,
                        color: SlipTheme.carbon,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. The Trap Blunder Statement
          Text(
            slip.trapStatement,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: SlipTheme.carbon,
                  height: 1.4,
                  fontSize: 15,
                ),
          ),

          // 3. Multi-image LinkedIn-Style Gallery Grid
          if (slip.imageUris.isNotEmpty) ...[
            ImageGalleryGrid(imageUris: slip.imageUris),
          ],

          // 4. Optional Audio Autopsy
          if (slip.audioDurationSeconds > 0) ...[
            const SizedBox(height: 10),
            AudioWaveformStrip(
              totalSeconds: slip.audioDurationSeconds,
              studentTranscript: 'Audio blunder note (${slip.audioDurationSeconds}s)',
            ),
          ],

          const SizedBox(height: 12),

          // 5. The Fix (Expandable & Clean)
          if (slip.isFixRevealed) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: SlipTheme.surface,
                borderRadius: BorderRadius.circular(3),
                border: const Border(
                  left: BorderSide(color: SlipTheme.clearedGreen, width: 2.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE FIX',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: SlipTheme.clearedGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    slip.fixStatement,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SlipTheme.carbon,
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // 6. Instagram-Style Clean Minimalist Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Reveal / Hide Fix text button
              InkWell(
                onTap: widget.onFixToggle,
                borderRadius: BorderRadius.circular(2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Text(
                    slip.isFixRevealed ? 'Hide fix' : 'Reveal fix',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: SlipTheme.carbon,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
              ),

              // Instagram-style clean icons row
              Row(
                children: [
                  // Same Reaction ("I fell for this too")
                  InkWell(
                    onTap: widget.onSameTap,
                    borderRadius: BorderRadius.circular(2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        children: [
                          Icon(
                            slip.hasSaidSame
                                ? Icons.warning_rounded
                                : Icons.warning_amber_rounded,
                            size: 17,
                            color: slip.hasSaidSame
                                ? SlipTheme.trapRed
                                : SlipTheme.steel,
                          ),
                          if (slip.sameCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${slip.sameCount}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: slip.hasSaidSame
                                    ? SlipTheme.trapRed
                                    : SlipTheme.steel,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Save / Bookmark (Adds to My Review Cycle)
                  InkWell(
                    onTap: widget.onKeepTap,
                    borderRadius: BorderRadius.circular(2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Icon(
                        slip.hasKept
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 17,
                        color: slip.hasKept
                            ? SlipTheme.carbon
                            : SlipTheme.steel,
                      ),
                    ),
                  ),

                  // Solve / Mastered Checkmark Icon
                  InkWell(
                    onTap: widget.onSolveTap,
                    borderRadius: BorderRadius.circular(2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Icon(
                        slip.hasCleared
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 17,
                        color: slip.hasCleared
                            ? SlipTheme.clearedGreen
                            : SlipTheme.steel,
                      ),
                    ),
                  ),

                  // Comment Toggle (Chat Bubble)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showComments = !_showComments;
                      });
                    },
                    borderRadius: BorderRadius.circular(2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Icon(
                        _showComments
                            ? Icons.chat_bubble_rounded
                            : Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: _showComments
                            ? SlipTheme.carbon
                            : SlipTheme.steel,
                      ),
                    ),
                  ),

                  // Bluetooth Share / Beam
                  InkWell(
                    onTap: widget.onPassTap,
                    borderRadius: BorderRadius.circular(2),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      child: Icon(
                        Icons.bluetooth_audio_rounded,
                        size: 17,
                        color: SlipTheme.steel,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 7. Toggleable Inline Comments Sheet
          if (_showComments) ...[
            CommentThreadSheet(slipId: slip.id),
          ],
        ],
      ),
    );
  }
}
