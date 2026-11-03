import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../services/supabase_service.dart';
import '../theme/slip_theme.dart';

class CommentThreadSheet extends StatefulWidget {
  final String slipId;

  const CommentThreadSheet({super.key, required this.slipId});

  @override
  State<CommentThreadSheet> createState() => _CommentThreadSheetState();
}

class _CommentThreadSheetState extends State<CommentThreadSheet> {
  final TextEditingController _commentController = TextEditingController();
  final SupabaseService _service = SupabaseService();
  List<SlipComment> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final raw = await _service.fetchComments(widget.slipId);
    if (mounted) {
      setState(() {
        _comments = raw.map((m) => SlipComment.fromJson(m)).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();
    await _service.postComment(slipId: widget.slipId, body: text);
    await _loadComments();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SlipTheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: SlipTheme.hairline, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PEER ANSWERS & DISCUSSION (${_comments.length})',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.steel,
                      letterSpacing: 0.5,
                      fontSize: 10,
                    ),
              ),
              Text(
                'OFFLINE BLE MESH SYNCED',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: SlipTheme.clearedGreen,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(SlipTheme.carbon)),
                ),
              ),
            ),
          ] else if (_comments.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'No peer answers yet. Write an explanation, hint, or solution below.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SlipTheme.steel,
                      fontSize: 11,
                    ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final c = _comments[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${c.authorHandle}: ',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SlipTheme.carbon,
                            fontSize: 11.5,
                          ),
                    ),
                    Expanded(
                      child: Text(
                        c.body,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: SlipTheme.carbon,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                      ),
                    ),
                    if (c.isAcceptedAnswer) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: SlipTheme.clearedGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'ACCEPTED',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            color: SlipTheme.clearedGreen,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Answer doubt or write conceptual note...',
                    hintStyle: TextStyle(fontSize: 11, color: SlipTheme.steel),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: SlipTheme.hairline, width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: SlipTheme.carbon, width: 1.0),
                    ),
                  ),
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: _submitComment,
                icon: const Icon(Icons.send_rounded, size: 16, color: SlipTheme.carbon),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
