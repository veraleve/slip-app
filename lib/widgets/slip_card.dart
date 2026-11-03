import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/slip.dart';
import '../providers/slip_provider.dart';
import '../screens/post_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../services/supabase_service.dart';
import '../theme/slip_theme.dart';
import 'audio_waveform_strip.dart';
import 'clickable_text.dart';
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

class _SlipCardState extends State<SlipCard> with TickerProviderStateMixin {
  late AnimationController _bookmarkController;
  late Animation<double> _bookmarkAnimation;
  late AnimationController _solveController;
  late Animation<double> _solveAnimation;
  late AnimationController _sameController;
  late Animation<double> _sameAnimation;
  bool _showSameTooltip = false;

  @override
  void initState() {
    super.initState();
    _bookmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bookmarkAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4).chain(CurveTween(curve: Curves.easeOutBack)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_bookmarkController);

    _solveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _solveAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45).chain(CurveTween(curve: Curves.easeOutBack)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_solveController);

    _sameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sameAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOutBack)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_sameController);
  }

  @override
  void dispose() {
    _bookmarkController.dispose();
    _solveController.dispose();
    _sameController.dispose();
    super.dispose();
  }

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
    final isGeneralDoubt = isDoubt && (slip.examTag == 'General' || slip.topic == 'General' || slip.subtopic == 'General');
    final examShort = slip.examTag.replaceAll('GATE ', '').replaceAll(RegExp(r'\s*\d{4}'), '');
    final currentUsername = SupabaseService().currentUsername;
    final isAuthor = currentUsername != null &&
        slip.authorUsername != null &&
        currentUsername.toLowerCase() == slip.authorUsername!.toLowerCase();

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
                      child: Text(
                        isGeneralDoubt ? 'GENERAL DOUBT' : 'DOUBT',
                        style: const TextStyle(
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isGeneralDoubt)
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
                  if (isAuthor) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz_rounded, size: 18, color: SlipTheme.steel),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      elevation: 3,
                      color: SlipTheme.canvas,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onSelected: (val) {
                        if (val == 'delete') {
                          _confirmDelete(context);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'delete',
                          height: 36,
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 16, color: SlipTheme.trapRed),
                              SizedBox(width: 8),
                              Text(
                                'Delete Post',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: SlipTheme.trapRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (!isGeneralDoubt && slip.topic.isNotEmpty && slip.topic != 'General') ...[
            const SizedBox(height: 4),
            Text(
              slip.subtopic != null && slip.subtopic!.isNotEmpty && slip.subtopic != 'General'
                  ? '${slip.topic} · ${slip.subtopic}'
                  : slip.topic,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: SlipTheme.steel,
                    fontSize: 10,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
            ClickableText(
              text: slip.trapStatement,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: SlipTheme.carbon.withOpacity(0.85),
                    height: 1.45,
                    fontSize: 13.5,
                  ),
            ),
          ] else ...[
            ClickableText(
              text: slip.trapStatement,
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
                  ClickableText(
                    text: slip.fixStatement,
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
                  // Reaction ("I have this doubt / fell for this too") with micro-pop and overlay pill
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        onTap: _handleSameTap,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                          child: ScaleTransition(
                            scale: _sameAnimation,
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
                      ),
                      if (_showSameTooltip)
                        Positioned(
                          top: -24,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SlipTheme.carbon,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              isDoubt ? '+1 Same doubt!' : '+1 Me too!',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: SlipTheme.canvas,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 6),

                  // Comment / Answer Icon (Opens PostDetailScreen)
                  InkWell(
                    onTap: () => _openPostDetail(context),
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: SlipTheme.steel,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Solved / Cleared / Mastered Checkmark Icon with burst animation
                  InkWell(
                    onTap: _handleSolveTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      child: ScaleTransition(
                        scale: _solveAnimation,
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

              // RIGHT: Bookmark / Save to Revision (Instagram-style Pop)
              InkWell(
                onTap: _handleKeepTap,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ScaleTransition(
                    scale: _bookmarkAnimation,
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
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  void _handleSameTap() {
    _sameController.forward(from: 0.0);
    HapticFeedback.lightImpact();
    widget.onSameTap();
    setState(() => _showSameTooltip = true);
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showSameTooltip = false);
    });
  }

  void _handleSolveTap() {
    _solveController.forward(from: 0.0);
    HapticFeedback.mediumImpact();
    widget.onSolveTap();
  }

  void _handleKeepTap() {
    _bookmarkController.forward(from: 0.0);
    HapticFeedback.lightImpact();
    widget.onKeepTap();
  }

  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SlipTheme.canvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'DELETE POST',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
        ),
        content: const Text(
          'Are you sure you want to permanently delete this post from the feed, database, and your profile?',
          style: TextStyle(fontSize: 12, color: SlipTheme.steel, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: SlipTheme.steel)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SlipTheme.trapRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirm == true && widget.provider != null) {
      await widget.provider!.deleteSlip(widget.slip.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post deleted permanently.'),
            backgroundColor: SlipTheme.carbon,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
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
