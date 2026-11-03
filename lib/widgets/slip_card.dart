import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/slip.dart';
import '../providers/slip_provider.dart';
import '../screens/post_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../theme/slip_theme.dart';
import 'audio_waveform_strip.dart';
import 'image_gallery_grid.dart';

class SlipCard extends StatefulWidget {
  final int index;
  final Slip slip;
  final VoidCallback onSameTap;
  final VoidCallback onFixToggle;
  final VoidCallback onKeepTap;
  final VoidCallback onSolveTap;
  final VoidCallback onPassTap;
  final SlipProvider? provider;

  const SlipCard({
    super.key,
    required this.index,
    required this.slip,
    required this.onSameTap,
    required this.onFixToggle,
    required this.onKeepTap,
    required this.onSolveTap,
    required this.onPassTap,
    this.provider,
  });

  @override
  State<SlipCard> createState() => _SlipCardState();
}

class _SlipCardState extends State<SlipCard> {
  String _formatInstagramTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '${weeks}w';
    } else {
      return DateFormat('MMM d').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slip = widget.slip;
    final isDoubt = slip.postType == PostType.doubt;
    final examShort = slip.examTag.replaceAll('GATE ', '').replaceAll(RegExp(r'\s*\d{4}'), '');

    return InkWell(
      onTap: () => _openPostDetail(context),
      splashColor: Colors.transparent,
      highlightColor: Colors.black.withOpacity(0.015),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: SlipTheme.hairline, width: 0.8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Author Handle, Timestamp, Post Type Badges & Exam Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _openFullProfile(
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

                  // Instagram Style Date & Time
                  const SizedBox(width: 4),
                  Text(
                    '· ${_formatInstagramTime(slip.createdAt)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: SlipTheme.steel,
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
              audioUrl: slip.voiceAudioUrl,
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

          // 6. Action Row: Design Principle (Reactions, Comment, Cleared on Left; Save on Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LEFT: Question-mark / Warning Reaction, Comment, and Cleared Checkmark
              Row(
                children: [
                  // Reaction ("I have this doubt / fell for this too")
                  InkWell(
                    onTap: widget.onSameTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDoubt
                                ? (slip.hasSaidSame ? Icons.help_rounded : Icons.help_outline_rounded)
                                : (slip.hasSaidSame ? Icons.warning_rounded : Icons.warning_amber_rounded),
                            size: 18,
                            color: slip.hasSaidSame
                                ? (isDoubt ? SlipTheme.carbon : SlipTheme.trapRed)
                                : SlipTheme.steel,
                          ),
                          if (slip.sameCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${slip.sameCount}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: slip.hasSaidSame
                                    ? (isDoubt ? SlipTheme.carbon : SlipTheme.trapRed)
                                    : SlipTheme.steel,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Comment / Answer Icon (Opens PostDetailScreen)
                  InkWell(
                    onTap: () => _openPostDetail(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 17,
                            color: SlipTheme.steel,
                          ),
                          if (slip.commentsCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${slip.commentsCount}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: SlipTheme.steel,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Solved / Cleared / Mastered Checkmark Icon
                  InkWell(
                    onTap: widget.onSolveTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      child: Icon(
                        (isDoubt ? slip.isResolved : slip.hasCleared)
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 18,
                        color: (isDoubt ? slip.isResolved : slip.hasCleared)
                            ? SlipTheme.clearedGreen
                            : SlipTheme.steel,
                      ),
                    ),
                  ),

                  // Optional Reveal / Hide Solution toggle inline
                  if (slip.fixStatement.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: widget.onFixToggle,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        child: Text(
                          slip.isFixRevealed
                              ? (isDoubt ? 'Hide answer' : 'Hide fix')
                              : (isDoubt ? 'Answer' : 'Fix'),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: SlipTheme.carbon,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // RIGHT: Bookmark / Save to Revision
              InkWell(
                onTap: widget.onKeepTap,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Icon(
                    slip.hasKept
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 19,
                    color: slip.hasKept
                        ? SlipTheme.carbon
                        : SlipTheme.steel,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openPostDetail(BuildContext context) {
    if (widget.provider != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            slip: widget.slip,
            provider: widget.provider!,
          ),
        ),
      );
    }
  }

  void _openFullProfile(BuildContext context, String handle, String examTag) {
    if (widget.provider != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            provider: widget.provider!,
            targetUsername: handle,
            targetExamTag: examTag,
          ),
        ),
      );
    }
  }
}
