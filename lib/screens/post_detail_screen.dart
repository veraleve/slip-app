import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/comment.dart';
import '../models/slip.dart';
import '../providers/slip_provider.dart';
import '../theme/slip_theme.dart';
import '../widgets/audio_waveform_strip.dart';
import '../widgets/clickable_text.dart';
import '../widgets/image_gallery_grid.dart';
import 'profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Slip slip;
  final SlipProvider provider;

  const PostDetailScreen({
    super.key,
    required this.slip,
    required this.provider,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  List<SlipComment> _comments = [];
  bool _isLoadingComments = true;
  bool _isSubmitting = false;

  // Active reply target state
  SlipComment? _replyingToComment;
  bool _isSolutionRevealed = false;

  late AnimationController _saveController;
  late Animation<double> _saveAnimation;
  late AnimationController _sameController;
  late Animation<double> _sameAnimation;
  late AnimationController _solveController;
  late Animation<double> _solveAnimation;
  bool _showSameOverlay = false;

  @override
  void initState() {
    super.initState();
    _isSolutionRevealed = widget.slip.isFixRevealed;
    widget.provider.addListener(_onProviderUpdated);

    _saveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _saveAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 50),
    ]).animate(_saveController);

    _sameController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _sameAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOutBack)), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeInQuad)), weight: 55),
    ]).animate(_sameController);

    _solveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _solveAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOutBack)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.easeInQuad)), weight: 50),
    ]).animate(_solveController);

    _loadComments();
  }

  void _onProviderUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onProviderUpdated);
    _saveController.dispose();
    _sameController.dispose();
    _solveController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final raw = await widget.provider.fetchComments(widget.slip.id);
    if (mounted) {
      setState(() {
        _comments = raw.map((m) => SlipComment.fromJson(m)).toList();
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    _commentController.clear();

    final parentId = _replyingToComment?.id;

    await widget.provider.postComment(
      slipId: widget.slip.id,
      body: text,
      parentId: parentId,
    );

    setState(() {
      _isSubmitting = false;
      _replyingToComment = null;
    });

    await _loadComments();
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }

  bool _isAuthor(String? authorHandle, String? authorId) {
    final slipAuthorHandle = widget.slip.authorUsername;
    final slipAuthorId = widget.slip.authorId;

    if (authorHandle != null &&
        slipAuthorHandle != null &&
        authorHandle.toLowerCase() == slipAuthorHandle.toLowerCase()) {
      return true;
    }
    if (authorId != null && slipAuthorId != null && authorId == slipAuthorId) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final slip = widget.provider.allSlips.firstWhere(
      (s) => s.id == widget.slip.id,
      orElse: () => widget.slip,
    );
    final isDoubt = slip.postType == PostType.doubt;

    // Separate top-level comments and map child replies
    final topLevelComments = _comments.where((c) => !c.isReply).toList();
    final Map<String, List<SlipComment>> repliesMap = {};
    for (final c in _comments) {
      if (c.isReply && c.parentId != null) {
        repliesMap.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }

    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      appBar: AppBar(
        backgroundColor: SlipTheme.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SlipTheme.carbon),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isDoubt ? 'Doubt Discussion' : 'Mistake Inoculation',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: SlipTheme.carbon,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: ScaleTransition(
              scale: _saveAnimation,
              child: Icon(
                slip.hasKept ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: slip.hasKept ? SlipTheme.carbon : SlipTheme.steel,
                size: 22,
              ),
            ),
            tooltip: 'Save to revision',
            onPressed: () {
              HapticFeedback.lightImpact();
              _saveController.forward(from: 0.0);
              widget.provider.toggleKeep(slip.id);
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                // 1. Author & Metadata Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(
                              provider: widget.provider,
                              targetUsername: slip.authorUsername,
                              targetExamTag: slip.examTag,
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: SlipTheme.carbon.withOpacity(0.08),
                        child: Text(
                          (slip.authorUsername ?? 'P')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: SlipTheme.carbon,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProfileScreen(
                                        provider: widget.provider,
                                        targetUsername: slip.authorUsername,
                                        targetExamTag: slip.examTag,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  '@${slip.authorUsername ?? "peer"}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: SlipTheme.carbon,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• ${_formatTimeAgo(slip.createdAt)}',
                                style: const TextStyle(fontSize: 11, color: SlipTheme.steel),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${slip.topic} › ${slip.subtopic}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: SlipTheme.steel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Post type & resolved badges
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isDoubt ? SlipTheme.carbon : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isDoubt ? 'DOUBT' : 'MISTAKE',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: isDoubt ? SlipTheme.canvas : const Color(0xFFD97706),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 2. Post Title (if doubt)
                if (slip.title != null && slip.title!.isNotEmpty) ...[
                  Text(
                    slip.title!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: SlipTheme.carbon,
                      letterSpacing: -0.4,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // 3. Question / Trap Context Statement
                Text(
                  slip.trapStatement,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: Color(0xFF262626),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Scratchpad Photos Gallery (if any)
                if (slip.imageUris.isNotEmpty) ...[
                  ImageGalleryGrid(imageUris: slip.imageUris),
                  const SizedBox(height: 14),
                ],

                // 5. Compact Audio Waveform Player (if voice note attached)
                if (slip.audioDurationSeconds > 0) ...[
                  AudioWaveformStrip(
                    totalSeconds: slip.audioDurationSeconds,
                    audioUrl: slip.voiceAudioUrl,
                    studentTranscript: isDoubt ? 'Voice question explanation' : 'Voice mistake autopsy',
                  ),
                  const SizedBox(height: 14),
                ],

                // 6. Fix / Solution Section (Expandable or Revealed)
                if (slip.fixStatement.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isSolutionRevealed
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isSolutionRevealed
                            ? const Color(0xFFBBF7D0)
                            : const Color(0xFFE5E7EB),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isSolutionRevealed ? Icons.check_circle_outline_rounded : Icons.lightbulb_outline_rounded,
                                  size: 16,
                                  color: _isSolutionRevealed ? const Color(0xFF16A34A) : SlipTheme.steel,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isDoubt ? 'VERIFIED ANSWER' : 'THE FIX & CORRECT REASONING',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: _isSolutionRevealed ? const Color(0xFF16A34A) : SlipTheme.steel,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            if (!_isSolutionRevealed)
                              TextButton(
                                onPressed: () {
                                  setState(() => _isSolutionRevealed = true);
                                  widget.provider.toggleFixRevealed(slip.id);
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Reveal Solution',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: SlipTheme.carbon,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (_isSolutionRevealed) ...[
                          const SizedBox(height: 8),
                          Text(
                            slip.fixStatement,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF1F2937),
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 7. Post Action Bar (Same, Cleared/Mastered) with Micro-Animations & Haptics
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ScaleTransition(
                          scale: _sameAnimation,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _sameController.forward(from: 0.0);
                              if (!slip.hasSaidSame) {
                                setState(() => _showSameOverlay = true);
                                Future.delayed(const Duration(milliseconds: 1400), () {
                                  if (mounted) setState(() => _showSameOverlay = false);
                                });
                              }
                              widget.provider.toggleSame(slip.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: slip.hasSaidSame ? SlipTheme.carbon : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isDoubt ? Icons.help_outline_rounded : Icons.warning_amber_rounded,
                                    size: 14,
                                    color: slip.hasSaidSame ? SlipTheme.canvas : SlipTheme.carbon,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${isDoubt ? "Same Doubt" : "Same Mistake"} (${slip.sameCount})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: slip.hasSaidSame ? SlipTheme.canvas : SlipTheme.carbon,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_showSameOverlay)
                          Positioned(
                            top: -26,
                            left: 0,
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: SlipTheme.carbon,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                                  ],
                                ),
                                child: Text(
                                  isDoubt ? '+1 Same doubt!' : '+1 Me too!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    if (isDoubt)
                      ScaleTransition(
                        scale: _solveAnimation,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _solveController.forward(from: 0.0);
                            widget.provider.toggleDoubtResolved(slip.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: slip.isResolved ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  slip.isResolved ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  size: 14,
                                  color: slip.isResolved ? const Color(0xFF16A34A) : SlipTheme.steel,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  slip.isResolved ? 'Resolved' : 'Mark Resolved',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: slip.isResolved ? const Color(0xFF16A34A) : SlipTheme.carbon,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // 8. Comments Section Header
                const Divider(color: Color(0xFFEEEEEE), height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'COMMENTS & ANSWERS (${_comments.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: SlipTheme.carbon,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 9. Threaded Comments & Replies List
                if (_isLoadingComments)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(strokeWidth: 2, color: SlipTheme.carbon),
                    ),
                  )
                else if (topLevelComments.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    alignment: Alignment.center,
                    child: const Column(
                      children: [
                        const Icon(Icons.forum_outlined, size: 36, color: SlipTheme.steelLight),
                        const SizedBox(height: 8),
                        const Text(
                          'No comments yet',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SlipTheme.carbon),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Be the first to comment or answer!',
                          style: TextStyle(fontSize: 11, color: SlipTheme.steel),
                        ),
                      ],
                    ),
                  )
                else
                  for (final comment in topLevelComments) ...[
                    _buildCommentNode(comment, repliesMap[comment.id] ?? []),
                    const SizedBox(height: 14),
                  ],
              ],
            ),
          ),

          // 10. Bottom Pinned Reply Input Bar (Curved & Clean)
          _buildReplyInputBar(),
        ],
      ),
    );
  }

  // Reddit-style Comment Node with Threaded Replies
  Widget _buildCommentNode(SlipComment comment, List<SlipComment> replies) {
    final isAuthorOfPost = _isAuthor(comment.authorHandle, comment.authorId);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 0.8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment Author Header
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: SlipTheme.carbon.withOpacity(0.08),
                child: Text(
                  comment.authorHandle.isNotEmpty ? comment.authorHandle[0].toUpperCase() : 'P',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: SlipTheme.carbon),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '@${comment.authorHandle}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: SlipTheme.carbon,
                ),
              ),
              // Author / OP Chip
              if (isAuthorOfPost) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Author',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                _formatTimeAgo(comment.createdAt),
                style: const TextStyle(fontSize: 10, color: SlipTheme.steel),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Comment Body Text
          ClickableText(
            text: comment.body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF262626),
            ),
          ),
          const SizedBox(height: 8),

          // Action row: Reply Button
          InkWell(
            onTap: () {
              setState(() {
                _replyingToComment = comment;
              });
              _commentFocusNode.requestFocus();
            },
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.reply_rounded, size: 14, color: SlipTheme.steel),
                  SizedBox(width: 4),
                  Text(
                    'Reply',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SlipTheme.steel),
                  ),
                ],
              ),
            ),
          ),

          // Threaded Nested Replies (Indented with a left thread line)
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final reply in replies) _buildReplyItem(reply),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyItem(SlipComment reply) {
    final isReplyAuthorOfPost = _isAuthor(reply.authorHandle, reply.authorId);

    return Container(
      margin: const EdgeInsets.only(left: 14, top: 6),
      padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xFFE5E7EB), width: 2.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '@${reply.authorHandle}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: SlipTheme.carbon,
                ),
              ),
              if (isReplyAuthorOfPost) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Author',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                _formatTimeAgo(reply.createdAt),
                style: const TextStyle(fontSize: 9.5, color: SlipTheme.steel),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClickableText(
            text: reply.body,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  // Curved Bottom Reply Bar
  Widget _buildReplyInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: SlipTheme.canvas,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 0.8),
        ),
      ),
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner if replying to a specific comment
          if (_replyingToComment != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, size: 14, color: SlipTheme.steel),
                  const SizedBox(width: 4),
                  Text(
                    'Replying to @${_replyingToComment!.authorHandle}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: SlipTheme.steel,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _replyingToComment = null),
                    child: const Icon(Icons.close_rounded, size: 16, color: SlipTheme.steel),
                  ),
                ],
              ),
            ),
          ],

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  style: const TextStyle(fontSize: 13.5, color: SlipTheme.carbon),
                  decoration: InputDecoration(
                    hintText: _replyingToComment != null
                        ? 'Write a reply...'
                        : 'Write an answer or thought...',
                    hintStyle: const TextStyle(fontSize: 13, color: SlipTheme.steel),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _isSubmitting ? null : _submitComment,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: SlipTheme.carbon,
                    shape: BoxShape.circle,
                  ),
                  child: _isSubmitting
                      ? const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: SlipTheme.canvas),
                          ),
                        )
                      : const Icon(Icons.arrow_upward_rounded, color: SlipTheme.canvas, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
