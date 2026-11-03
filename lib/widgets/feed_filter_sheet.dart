import 'package:flutter/material.dart';
import '../constants/gate_syllabus.dart';
import '../models/slip.dart';
import '../providers/slip_provider.dart';
import '../theme/slip_theme.dart';

/// Modal bottom sheet for filtering feed items by syllabus and post type.
class FeedFilterSheet extends StatefulWidget {
  final SlipProvider provider;
  final String currentExam;
  final List<String> allSubjects;

  const FeedFilterSheet({
    super.key,
    required this.provider,
    required this.currentExam,
    required this.allSubjects,
  });

  static Future<void> show(
    BuildContext context, {
    required SlipProvider provider,
    required String currentExam,
    required List<String> allSubjects,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: SlipTheme.canvas,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => FeedFilterSheet(
        provider: provider,
        currentExam: currentExam,
        allSubjects: allSubjects,
      ),
    );
  }

  @override
  State<FeedFilterSheet> createState() => _FeedFilterSheetState();
}

class _FeedFilterSheetState extends State<FeedFilterSheet> {
  late String _tempSubject;
  late String _tempTopic;
  PostType? _tempPostType;

  @override
  void initState() {
    super.initState();
    _tempSubject = widget.provider.selectedSubjectFilter;
    _tempTopic = widget.provider.selectedSubtopicFilter;
    _tempPostType = widget.provider.selectedPostTypeFilter;
  }

  @override
  Widget build(BuildContext context) {
    final availableSubtopics = _tempSubject != 'All'
        ? GateSyllabus.getSubtopics(widget.currentExam, _tempSubject)
        : <String>[];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: SlipTheme.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FEED FILTERS',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: SlipTheme.carbon,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: SlipTheme.hairline, height: 1),
            const SizedBox(height: 16),

            // Post Type Selector: All Posts | Doubts | Mistakes
            Text(
              'POST TYPE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SlipTheme.steel,
                    fontSize: 9.5,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPostTypePill(
                  label: 'All Posts',
                  isSelected: _tempPostType == null,
                  onTap: () => setState(() => _tempPostType = null),
                ),
                const SizedBox(width: 8),
                _buildPostTypePill(
                  label: 'Doubts Only',
                  isSelected: _tempPostType == PostType.doubt,
                  onTap: () => setState(() => _tempPostType = PostType.doubt),
                ),
                const SizedBox(width: 8),
                _buildPostTypePill(
                  label: 'Mistakes Only',
                  isSelected: _tempPostType == PostType.mistake,
                  onTap: () => setState(() => _tempPostType = PostType.mistake),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cascading Selector 1: Subject Dropdown
            Text(
              'SUBJECT',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SlipTheme.steel,
                    fontSize: 9.5,
                  ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: SlipTheme.hairline, width: 0.8),
                borderRadius: BorderRadius.circular(12),
                color: SlipTheme.surface,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _tempSubject,
                  isExpanded: true,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: SlipTheme.carbon,
                    fontWeight: FontWeight.w600,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'All',
                      child: Text('All Subjects', overflow: TextOverflow.ellipsis),
                    ),
                    ...widget.allSubjects.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s, overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _tempSubject = val;
                        _tempTopic = 'All Topics';
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Cascading Selector 2: Topic Dropdown
            Text(
              'TOPIC / CONCEPT',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SlipTheme.steel,
                    fontSize: 9.5,
                  ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: SlipTheme.hairline, width: 0.8),
                borderRadius: BorderRadius.circular(12),
                color: SlipTheme.surface,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _tempTopic,
                  isExpanded: true,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: SlipTheme.carbon,
                    fontWeight: FontWeight.w600,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'All Topics',
                      child: Text('All Topics', overflow: TextOverflow.ellipsis),
                    ),
                    ...availableSubtopics.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t, overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _tempTopic = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Actions: Reset & Apply
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () {
                        widget.provider.resetCascadingFilters();
                        widget.provider.setPostTypeFilter(null);
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SlipTheme.steel,
                        side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'RESET',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.provider.setPostTypeFilter(_tempPostType);
                        if (_tempSubject == 'All') {
                          widget.provider.setTopicFilter('All');
                          widget.provider.setSubjectFilter('All');
                          widget.provider.setSubtopicFilter('All Topics');
                        } else {
                          widget.provider.setSubjectFilter(_tempSubject);
                          widget.provider.setSubtopicFilter(_tempTopic);
                        }
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SlipTheme.carbon,
                        foregroundColor: SlipTheme.canvas,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'APPLY FILTERS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
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

  Widget _buildPostTypePill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? SlipTheme.carbon : SlipTheme.surface,
            border: Border.all(
              color: isSelected ? SlipTheme.carbon : SlipTheme.hairline,
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? SlipTheme.canvas : SlipTheme.carbon,
            ),
          ),
        ),
      ),
    );
  }
}
