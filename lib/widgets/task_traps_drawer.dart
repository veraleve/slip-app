import 'package:flutter/material.dart';
import '../constants/gate_syllabus.dart';
import '../models/slip.dart';
import '../models/task_item.dart';
import '../providers/slip_provider.dart';
import '../theme/slip_theme.dart';
import '../widgets/slip_card.dart';

/// Bottom sheet drawer displaying 3 slides of mistakes linked to a task:
/// Slide 1: Task / Mock Mistakes (with multi-subject breakdown for mocks)
/// Slide 2: Topic-wise mistakes with subtopic filter
/// Slide 3: Peer & community mistakes
class TaskTrapsDrawer extends StatefulWidget {
  final SlipProvider provider;
  final TaskItem task;

  const TaskTrapsDrawer({super.key, required this.provider, required this.task});

  static Future<void> show(BuildContext context, {required SlipProvider provider, required TaskItem task}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SlipTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => TaskTrapsDrawer(provider: provider, task: task),
    );
  }

  @override
  State<TaskTrapsDrawer> createState() => _TaskTrapsDrawerState();
}

class _TaskTrapsDrawerState extends State<TaskTrapsDrawer> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSubtopic;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showBlunderCardModal(BuildContext context, Slip slip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SlipTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (sheetCtx, scrollController) {
            return Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SlipTheme.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MISTAKE INSPECTION',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD97706),
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: SlipTheme.hairline),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      SlipCard(
                        index: 0,
                        slip: slip,
                        provider: widget.provider,
                        onSameTap: () => widget.provider.toggleSame(slip.id),
                        onFixToggle: () => widget.provider.toggleFixRevealed(slip.id),
                        onKeepTap: () => widget.provider.toggleKeep(slip.id),
                        onSolveTap: () => widget.provider.toggleCleared(slip.id),
                        onPassTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openSubtopicFilterSheet(BuildContext context, List<String> availableSubtopics) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SlipTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (filterCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FILTER BY SUBTOPIC',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(filterCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: SlipTheme.hairline),
                const SizedBox(height: 8),
                ListTile(
                  dense: true,
                  title: const Text('All Topics', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  trailing: _selectedSubtopic == null ? const Icon(Icons.check_rounded, color: SlipTheme.carbon) : null,
                  onTap: () {
                    setState(() => _selectedSubtopic = null);
                    Navigator.of(filterCtx).pop();
                  },
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableSubtopics.length,
                    itemBuilder: (ctx, i) {
                      final sub = availableSubtopics[i];
                      final isSelected = _selectedSubtopic == sub;
                      return ListTile(
                        dense: true,
                        title: Text(sub, style: const TextStyle(fontSize: 13)),
                        trailing: isSelected ? const Icon(Icons.check_rounded, color: SlipTheme.carbon) : null,
                        onTap: () {
                          setState(() => _selectedSubtopic = sub);
                          Navigator.of(filterCtx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final allSlips = widget.provider.allSlips;
    final isMock = task.title.toLowerCase().contains('mock') ||
        task.title.toLowerCase().contains('full') ||
        task.subject == 'All' ||
        task.subject == 'General';

    // Slide 1: Task Mistakes
    final taskMistakes = widget.provider.getBlundersForTask(task);

    // Grouping for Mock Test: by subject
    final Map<String, List<Slip>> mistakesBySubject = {};
    if (isMock) {
      for (final s in allSlips.where((s) => s.postType == PostType.mistake || s.hasKept)) {
        mistakesBySubject.putIfAbsent(s.topic, () => []).add(s);
      }
    }

    // Slide 2: Topic-wise mistakes
    final availableSubtopics = GateSyllabus.getSubtopics(task.examTag, task.subject);
    final subjectMistakes = allSlips.where((s) {
      final matchesSubject = s.topic.trim().toLowerCase() == task.subject.trim().toLowerCase() ||
          task.title.toLowerCase().contains(s.topic.toLowerCase());
      if (!matchesSubject) return false;
      if (_selectedSubtopic != null && _selectedSubtopic!.isNotEmpty) {
        return s.subtopic != null && s.subtopic!.toLowerCase() == _selectedSubtopic!.toLowerCase();
      }
      return true;
    }).toList();

    // Slide 3: Peer mistakes
    final peerMistakes = allSlips.where((s) {
      final isPeer = s.authorId != widget.provider.currentUserId;
      final matchesSubject = isMock ||
          s.topic.trim().toLowerCase() == task.subject.trim().toLowerCase() ||
          task.title.toLowerCase().contains(s.topic.toLowerCase());
      return isPeer && matchesSubject;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.74,
      minChildSize: 0.35,
      maxChildSize: 0.94,
      expand: false,
      builder: (sheetCtx, scrollController) {
        return Column(
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: SlipTheme.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row: Title & Close
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 14, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFD97706)),
                            const SizedBox(width: 5),
                            const Text(
                              'TASK INOCULATION MISTAKES',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD97706),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: SlipTheme.carbon,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${task.subject} • ${task.examTag}',
                          style: const TextStyle(fontSize: 11, color: SlipTheme.steel),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                  ),
                ],
              ),
            ),

            // 3-Tab Sliding Segment Bar (Curved borders)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: SlipTheme.canvas,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: SlipTheme.carbon,
                unselectedLabelColor: SlipTheme.steel,
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: isMock ? 'Mock Mistakes' : 'Task Mistakes'),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Topic-Wise'),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _openSubtopicFilterSheet(context, availableSubtopics),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: _selectedSubtopic != null ? const Color(0xFFD97706) : SlipTheme.steel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Tab(text: 'Peer Mistakes'),
                ],
              ),
            ),

            const Divider(height: 1, color: SlipTheme.hairline),

            // 3-Slide TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // SLIDE 1: Task / Mock Test Mistakes
                  _buildSlide1TaskMistakes(
                    isMock: isMock,
                    taskMistakes: taskMistakes,
                    mistakesBySubject: mistakesBySubject,
                  ),

                  // SLIDE 2: Topic-Wise Mistakes (with Filter Icon)
                  _buildSlide2TopicMistakes(
                    subjectMistakes: subjectMistakes,
                    availableSubtopics: availableSubtopics,
                  ),

                  // SLIDE 3: Peer & Community Mistakes
                  _buildSlide3PeerMistakes(peerMistakes: peerMistakes),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSlide1TaskMistakes({
    required bool isMock,
    required List<Slip> taskMistakes,
    required Map<String, List<Slip>> mistakesBySubject,
  }) {
    if (isMock) {
      if (mistakesBySubject.isEmpty) {
        return _buildEmptyState('No mock test mistakes logged yet.');
      }
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        children: [
          for (final entry in mistakesBySubject.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
                    ),
                    child: Text(
                      '${entry.key.toUpperCase()} (${entry.value.length})',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final slip in entry.value) ...[
              _buildMistakeCard(slip),
              const SizedBox(height: 8),
            ],
          ],
        ],
      );
    }

    if (taskMistakes.isEmpty) {
      return _buildEmptyState('No mistakes linked to this task yet.');
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      itemCount: taskMistakes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _buildMistakeCard(taskMistakes[i]),
    );
  }

  Widget _buildSlide2TopicMistakes({
    required List<Slip> subjectMistakes,
    required List<String> availableSubtopics,
  }) {
    return Column(
      children: [
        // Subtopic Filter Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedSubtopic != null
                    ? 'FILTERED: ${_selectedSubtopic!.toUpperCase()}'
                    : 'ALL TOPICS (${subjectMistakes.length})',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB45309),
                  letterSpacing: 0.5,
                ),
              ),
              InkWell(
                onTap: () => _openSubtopicFilterSheet(context, availableSubtopics),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: _selectedSubtopic != null ? const Color(0xFFD97706) : SlipTheme.steel,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedSubtopic != null ? 'Change' : 'Filter',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _selectedSubtopic != null ? const Color(0xFFD97706) : SlipTheme.steel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: SlipTheme.hairline),
        Expanded(
          child: subjectMistakes.isEmpty
              ? _buildEmptyState('No mistakes found for this subtopic.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  itemCount: subjectMistakes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _buildMistakeCard(subjectMistakes[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildSlide3PeerMistakes({required List<Slip> peerMistakes}) {
    if (peerMistakes.isEmpty) {
      return _buildEmptyState('No peer mistakes found for this subject.');
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      itemCount: peerMistakes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _buildMistakeCard(peerMistakes[i]),
    );
  }

  Widget _buildMistakeCard(Slip slip) {
    final isSavedPeer = slip.hasKept && slip.authorId != widget.provider.currentUserId;
    final isMine = slip.authorId == widget.provider.currentUserId;

    return InkWell(
      onTap: () => _showBlunderCardModal(context, slip),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7).withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFDE68A).withOpacity(0.8),
            width: 0.9,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 13,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 5),
                Text(
                  isSavedPeer
                      ? 'SAVED PEER MISTAKE · @${slip.authorUsername ?? "peer"}'
                      : (isMine ? 'MY LOGGED MISTAKE' : 'PEER MISTAKE · @${slip.authorUsername ?? "peer"}'),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: SlipTheme.carbon.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    slip.subtopic ?? slip.topic,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.carbon,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              slip.trapStatement,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: SlipTheme.carbon,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              'FIX: ${slip.fixStatement}',
              style: const TextStyle(
                fontSize: 11.5,
                color: SlipTheme.steel,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Tap to inspect card',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 12,
                  color: Color(0xFFD97706),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb_outline_rounded, size: 38, color: SlipTheme.steelLight),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SlipTheme.carbon),
            ),
          ],
        ),
      ),
    );
  }
}
