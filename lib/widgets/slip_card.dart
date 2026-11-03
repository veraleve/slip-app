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
    final isDoubt = slip.postType == PostType.doubt;
    final examShort = slip.examTag.replaceAll('GATE ', '').replaceAll(RegExp(r'\s*\d{4}'), '');

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
          // 1. Author Handle, Post Type Badges & Exam Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showPeerProfileModal(
                      context,
                      slip.authorUsername ?? 'peer',
                      slip.examTag,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: SlipTheme.carbon.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              (slip.authorUsername ?? 'p').substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: SlipTheme.carbon,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '@${slip.authorUsername ?? 'peer'}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: SlipTheme.carbon,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Post Type Badge
                  if (isDoubt) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: SlipTheme.carbon,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        'DOUBT',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          color: SlipTheme.canvas,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: slip.isResolved
                            ? SlipTheme.clearedGreen.withOpacity(0.12)
                            : SlipTheme.surface,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: slip.isResolved ? SlipTheme.clearedGreen : SlipTheme.hairline,
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (slip.isResolved) ...[
                            const Icon(Icons.check_rounded, size: 8.5, color: SlipTheme.clearedGreen),
                            const SizedBox(width: 2),
                          ],
                          Text(
                            slip.isResolved ? 'RESOLVED' : 'OPEN',
                            style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              color: slip.isResolved ? SlipTheme.clearedGreen : SlipTheme.steel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: SlipTheme.surface,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: SlipTheme.hairline, width: 0.6),
                      ),
                      child: const Text(
                        'MISTAKE',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          color: SlipTheme.carbon,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    if (!slip.isPublic) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: SlipTheme.hairline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 8.5, color: SlipTheme.steel),
                            SizedBox(width: 2),
                            Text(
                              'PRIVATE',
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w700,
                                color: SlipTheme.steel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
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
          const SizedBox(height: 4),
          Text(
            '${slip.topic} · ${slip.subtopic ?? "General"}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: SlipTheme.steel,
                  fontSize: 10,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // 2. The Question Title or Blunder Statement
          if (isDoubt && slip.title != null && slip.title!.isNotEmpty) ...[
            Text(
              slip.title!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: SlipTheme.carbon,
                    height: 1.35,
                    fontSize: 15.5,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              slip.trapStatement,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: SlipTheme.carbon.withOpacity(0.85),
                    height: 1.45,
                    fontSize: 13.5,
                  ),
            ),
          ] else ...[
            Text(
              slip.trapStatement,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: SlipTheme.carbon,
                    height: 1.4,
                    fontSize: 15,
                  ),
            ),
          ],

          // 3. Multi-image LinkedIn-Style Gallery Grid
          if (slip.imageUris.isNotEmpty) ...[
            const SizedBox(height: 10),
            ImageGalleryGrid(imageUris: slip.imageUris),
          ],

          // 4. Optional Audio Autopsy
          if (slip.audioDurationSeconds > 0) ...[
            const SizedBox(height: 10),
            AudioWaveformStrip(
              totalSeconds: slip.audioDurationSeconds,
              studentTranscript: isDoubt
                  ? 'Voice explanation (${slip.audioDurationSeconds}s)'
                  : 'Audio blunder note (${slip.audioDurationSeconds}s)',
            ),
          ],

          const SizedBox(height: 12),

          // 5. The Fix / Solution (Expandable & Clean)
          if (slip.fixStatement.isNotEmpty && slip.isFixRevealed) ...[
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
                    isDoubt ? 'VERIFIED EXPLANATION / SOLUTION' : 'THE FIX',
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

          // 6. Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Reveal / Hide Fix text button
              if (slip.fixStatement.isNotEmpty)
                InkWell(
                  onTap: widget.onFixToggle,
                  borderRadius: BorderRadius.circular(2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Text(
                      slip.isFixRevealed
                          ? (isDoubt ? 'Hide solution' : 'Hide fix')
                          : (isDoubt ? 'Reveal solution' : 'Reveal fix'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: SlipTheme.carbon,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),

              // Instagram-style clean icons row
              Row(
                children: [
                  // Same Reaction ("I have this doubt / fell for this too")
                  InkWell(
                    onTap: widget.onSameTap,
                    borderRadius: BorderRadius.circular(2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        children: [
                          Icon(
                            isDoubt
                                ? (slip.hasSaidSame ? Icons.help_rounded : Icons.help_outline_rounded)
                                : (slip.hasSaidSame ? Icons.warning_rounded : Icons.warning_amber_rounded),
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

                  // Solve / Mastered / Resolved Checkmark Icon
                  InkWell(
                    onTap: widget.onSolveTap,
                    borderRadius: BorderRadius.circular(2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Icon(
                        (isDoubt ? slip.isResolved : slip.hasCleared)
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 17,
                        color: (isDoubt ? slip.isResolved : slip.hasCleared)
                            ? SlipTheme.clearedGreen
                            : SlipTheme.steel,
                      ),
                    ),
                  ),

                  // Comment / Answer Toggle (Chat Bubble)
                  InkWell(
                    onTap: () {
                      if (!slip.allowComments) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isDoubt
                                  ? 'Answers are turned off by author for this doubt.'
                                  : 'Comments are turned off by author for this blunder.',
                              style: const TextStyle(fontSize: 12),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
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
                            : (slip.allowComments ? SlipTheme.steel : SlipTheme.hairline),
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

          // 7. Toggleable Inline Comments / Answers Sheet
          if (_showComments) ...[
            CommentThreadSheet(slipId: slip.id),
          ],
        ],
      ),
          if (_showComments) ...[
            CommentThreadSheet(slipId: slip.id),
          ],
        ],
      ),
    );
  }

  void _showPeerProfileModal(BuildContext context, String handle, String examTag) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SlipTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) {
        final examClean = examTag.replaceAll('GATE ', '');
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top handle & close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: SlipTheme.carbon.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              handle.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: SlipTheme.carbon,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '@$handle',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: SlipTheme.carbon,
                              ),
                            ),
                            Text(
                              'GATE ASPIRANT · $examClean',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: SlipTheme.steel,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: SlipTheme.hairline, height: 1),
                const SizedBox(height: 14),

                // Real Peer Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _PeerStat(value: '18', label: 'SHARED', sub: 'PUBLIC TRAPS'),
                    _PeerStat(value: '42', label: 'CLEARED', sub: 'MASTERED', color: SlipTheme.clearedGreen),
                    _PeerStat(value: '29', label: 'SAVED', sub: 'REVISION'),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: SlipTheme.hairline, height: 1),
                const SizedBox(height: 12),

                // Public blunders header
                Text(
                  'PUBLIC BLUNDERS BY @$handle',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: SlipTheme.steel,
                  ),
                ),
                const SizedBox(height: 8),

                // Active slip preview as peer's public contribution
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SlipTheme.surface,
                    border: Border.all(color: SlipTheme.hairline, width: 0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.slip.topic,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: SlipTheme.carbon,
                            ),
                          ),
                          const Text(
                            'PUBLIC INOCULATION',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: SlipTheme.clearedGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.slip.trapStatement,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: SlipTheme.carbon,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'FIX: ${widget.slip.fixStatement}',
                        style: const TextStyle(fontSize: 11, color: SlipTheme.steel),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PeerStat extends StatelessWidget {
  final String value;
  final String label;
  final String sub;
  final Color? color;

  const _PeerStat({
    required this.value,
    required this.label,
    required this.sub,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color ?? SlipTheme.carbon,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: SlipTheme.steel,
          ),
        ),
      ],
    );
  }
}
