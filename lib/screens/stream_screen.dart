import 'package:flutter/material.dart';
import '../constants/gate_syllabus.dart';
import '../models/slip.dart';
import '../providers/slip_provider.dart';
import '../services/supabase_service.dart';
import '../theme/slip_theme.dart';
import '../widgets/slip_card.dart';

class StreamScreen extends StatefulWidget {
  final SlipProvider provider;

  const StreamScreen({super.key, required this.provider});

  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();

  bool _isSolvedArchiveExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final userExams = provider.userExams;
    final currentUserId = SupabaseService().currentUserId;

    final currentExam = provider.selectedExamFilter == 'All'
        ? (userExams.isNotEmpty ? userExams.first : GateSyllabus.gateCS)
        : provider.selectedExamFilter;

    final subjects = ['All', ...GateSyllabus.getSubjectsForExam(currentExam)];

    // Slips for My Review Cycle: (authored by user OR kept/saved by user)
    final allReviewSlips = provider.slips.where((s) {
      final isMine = s.authorId != null && s.authorId == currentUserId;
      final isSaved = s.hasKept;
      return isMine || isSaved;
    }).toList();

    final activeCycleSlips =
        allReviewSlips.where((s) => !s.hasCleared).toList();
    final solvedSlips = allReviewSlips.where((s) => s.hasCleared).toList();

    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Minimalist App Bar with Paper Selector & Dual Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Slip',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: SlipTheme.carbon,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(width: 10),
                      if (userExams.length > 1) ...[
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: SlipTheme.surface,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                                color: SlipTheme.hairline, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ExamFilterPill(
                                label: 'All',
                                isSelected: provider.selectedExamFilter == 'All',
                                onTap: () => provider.setExamFilter('All'),
                              ),
                              ...userExams.map((exam) {
                                final short = exam
                                    .replaceAll('GATE ', '')
                                    .replaceAll(RegExp(r'\s*\d{4}$'), '');
                                return _ExamFilterPill(
                                  label: short,
                                  isSelected:
                                      provider.selectedExamFilter == exam,
                                  onTap: () => provider.setExamFilter(exam),
                                );
                              }),
                            ],
                          ),
                        ),
                      ] else if (userExams.isNotEmpty) ...[
                        Text(
                          userExams.first
                              .replaceAll('GATE ', '')
                              .replaceAll(RegExp(r'\s*\d{4}$'), ''),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: SlipTheme.steel,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ],
                  ),

                  // Notification Bell with unread indicator (Replaces refresh icon)
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () => _showNotificationsSheet(context),
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                          color: SlipTheme.carbon,
                        ),
                        tooltip: 'Notifications',
                        visualDensity: VisualDensity.compact,
                      ),
                      Positioned(
                        top: 9,
                        right: 9,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: SlipTheme.trapRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Dual-Stream Tabs Header: [ MY REVIEW CYCLE ] | [ PEER FEED ]
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: SlipTheme.hairline, width: 0.8),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: SlipTheme.carbon,
                indicatorWeight: 2,
                labelColor: SlipTheme.carbon,
                unselectedLabelColor: SlipTheme.steel,
                labelStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
                onTap: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
                tabs: [
                  Tab(text: 'MY REVIEW CYCLE (${activeCycleSlips.length})'),
                  const Tab(text: 'PEER BLUNDER FEED'),
                ],
              ),
            ),

            // 3. Compact Filter Bar: [ Filter Icon ] + [ FOR YOU ] + [ ALL ] + [ Top Topics ]
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: SizedBox(
                height: 30,
                child: Builder(builder: (context) {
                  final allSubjects = GateSyllabus.getSubjectsForExam(currentExam);

                  // Extract top 2 most frequently logged topics by user
                  final topicCounts = <String, int>{};
                  for (final s in provider.slips) {
                    topicCounts[s.topic] = (topicCounts[s.topic] ?? 0) + 1;
                  }
                  final sortedTopics = topicCounts.keys.toList()
                    ..sort((a, b) => (topicCounts[b] ?? 0).compareTo(topicCounts[a] ?? 0));
                  final frequentTopics = sortedTopics.isNotEmpty
                      ? sortedTopics.take(2).toList()
                      : allSubjects.take(2).toList();

                  // Quick chips list: 'For You', 'All', frequent topics
                  final quickChips = <String>['For You', 'All', ...frequentTopics];
                  if (!quickChips.contains(provider.selectedTopicFilter)) {
                    quickChips.add(provider.selectedTopicFilter);
                  }

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Filter Icon Button (opens full syllabus subjects sheet)
                      GestureDetector(
                        onTap: () => _showTopicFilterSheet(context, allSubjects),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: SlipTheme.surface,
                            border: Border.all(color: SlipTheme.hairline, width: 0.8),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune_rounded, size: 14, color: SlipTheme.carbon),
                              SizedBox(width: 4),
                              Text(
                                'FILTER',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: SlipTheme.carbon,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Quick Chips
                      ...quickChips.map((topic) {
                        final isSelected = provider.selectedTopicFilter == topic;
                        final isForYou = topic == 'For You';

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => provider.setTopicFilter(topic),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? SlipTheme.carbon : SlipTheme.surface,
                                border: Border.all(
                                  color: isSelected ? SlipTheme.carbon : SlipTheme.hairline,
                                  width: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isForYou) ...[
                                    Icon(
                                      Icons.bolt_rounded,
                                      size: 13,
                                      color: isSelected ? SlipTheme.canvas : SlipTheme.carbon,
                                    ),
                                    const SizedBox(width: 2),
                                  ],
                                  Text(
                                    topic.toUpperCase(),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                          color: isSelected ? SlipTheme.canvas : SlipTheme.carbon,
                                          fontSize: 9.5,
                                          letterSpacing: 0.4,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ),
            ),

            // 4. Swipeable Dual Stream PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  _tabController.animateTo(index);
                },
                children: [
                  // --- TAB 1: MY REVIEW CYCLE ---
                  _buildReviewCycleTab(activeCycleSlips, solvedSlips),

                  // --- TAB 2: PEER BLUNDER FEED ---
                  _buildPeerFeedTab(provider.slips),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET FOR TAB 1: MY REVIEW CYCLE ---
  Widget _buildReviewCycleTab(
      List<Slip> activeSlips, List<Slip> solvedSlips) {
    if (widget.provider.isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(SlipTheme.carbon)),
        ),
      );
    }

    if (activeSlips.isEmpty && solvedSlips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.psychology_outlined,
                  size: 36, color: SlipTheme.steel),
              const SizedBox(height: 12),
              Text(
                'Your Review Cycle is empty.',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.carbon,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Log test mistakes using "+ DROP" or bookmark peer blunders from the Peer Feed to inoculate your weak spots.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SlipTheme.steel,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Daily Smart Cycle Banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAILY INOCULATION CYCLE (${activeSlips.length} ACTIVE)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: SlipTheme.steel,
                      letterSpacing: 0.6,
                      fontSize: 10,
                    ),
              ),
              Text(
                'TAP ✓ TO MASTER',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.clearedGreen,
                      fontSize: 9,
                    ),
              ),
            ],
          ),
        ),

        // Active Blunders List
        ...activeSlips.asMap().entries.map((entry) {
          final index = entry.key;
          final slip = entry.value;
          return SlipCard(
            index: index,
            slip: slip,
            onSameTap: () => widget.provider.toggleSame(slip.id),
            onFixToggle: () => widget.provider.toggleFixRevealed(slip.id),
            onKeepTap: () => widget.provider.toggleKeep(slip.id),
            onSolveTap: () {
              widget.provider.toggleCleared(slip.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Blunder marked as Mastered and archived.'),
                  backgroundColor: SlipTheme.carbon,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            onPassTap: () => _broadcastMesh(slip),
          );
        }),

        // Solved & Mastered Archive Section
        if (solvedSlips.isNotEmpty) ...[
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              setState(() {
                _isSolvedArchiveExpanded = !_isSolvedArchiveExpanded;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: SlipTheme.surface,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: SlipTheme.hairline, width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: SlipTheme.clearedGreen),
                      const SizedBox(width: 8),
                      Text(
                        'MASTERED & SOLVED ARCHIVE (${solvedSlips.length})',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: SlipTheme.carbon,
                                  fontSize: 10.5,
                                ),
                      ),
                    ],
                  ),
                  Icon(
                    _isSolvedArchiveExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: SlipTheme.steel,
                  ),
                ],
              ),
            ),
          ),
          if (_isSolvedArchiveExpanded) ...[
            ...solvedSlips.asMap().entries.map((entry) {
              final index = entry.key;
              final slip = entry.value;
              return Opacity(
                opacity: 0.85,
                child: SlipCard(
                  index: index,
                  slip: slip,
                  onSameTap: () => widget.provider.toggleSame(slip.id),
                  onFixToggle: () => widget.provider.toggleFixRevealed(slip.id),
                  onKeepTap: () => widget.provider.toggleKeep(slip.id),
                  onSolveTap: () {
                    // Reopen blunder
                    widget.provider.toggleCleared(slip.id);
                  },
                  onPassTap: () => _broadcastMesh(slip),
                ),
              );
            }),
          ],
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  // --- WIDGET FOR TAB 2: PEER BLUNDER FEED ---
  Widget _buildPeerFeedTab(List<Slip> slips) {
    if (widget.provider.isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(SlipTheme.carbon)),
        ),
      );
    }

    if (slips.isEmpty) {
      return Center(
        child: Text(
          'No peer blunders found for this subject.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: SlipTheme.steel,
              ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: slips.length,
      itemBuilder: (context, index) {
        final slip = slips[index];
        return SlipCard(
          index: index,
          slip: slip,
          onSameTap: () => widget.provider.toggleSame(slip.id),
          onFixToggle: () => widget.provider.toggleFixRevealed(slip.id),
          onKeepTap: () {
            widget.provider.toggleKeep(slip.id);
            final msg = slip.hasKept
                ? 'Removed from your Review Cycle.'
                : 'Saved to your Review Cycle!';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: SlipTheme.carbon,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          onSolveTap: () => widget.provider.toggleCleared(slip.id),
          onPassTap: () => _broadcastMesh(slip),
        );
      },
    );
  }

  void _broadcastMesh(Slip slip) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Broadcasting blunder over BLE mesh: ${slip.topic}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: SlipTheme.canvas),
        ),
        backgroundColor: SlipTheme.carbon,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    final notifications = [
      {
        'title': 'Recommended blunder for your syllabus',
        'body': 'Instruction Pipelining & Pipeline Hazards: Load-to-Use 1-cycle bubble trap.',
        'time': '20m ago',
        'icon': Icons.lightbulb_outline_rounded,
        'color': SlipTheme.carbon,
        'tab': 1,
      },
      {
        'title': 'Peer @arya shared a high-yield trap',
        'body': 'Linear Algebra: Assuming det(A)=0 implies all eigenvalues are zero.',
        'time': '2h ago',
        'icon': Icons.warning_amber_rounded,
        'color': SlipTheme.trapRed,
        'tab': 1,
      },
      {
        'title': 'Peer reacted to your blunder',
        'body': '“I fell for this too (+1)” on Operating Systems Deadlock Avoidance.',
        'time': '5h ago',
        'icon': Icons.thumb_up_alt_outlined,
        'color': SlipTheme.clearedGreen,
        'tab': 0,
      },
      {
        'title': 'Peer discussion active',
        'body': 'New comment on your blunder: “Forwarding cannot bypass time in hardware.”',
        'time': '1d ago',
        'icon': Icons.chat_bubble_outline_rounded,
        'color': SlipTheme.steel,
        'tab': 0,
      },
      {
        'title': 'Daily Morning Inoculation',
        'body': 'Your 5-mistake daily review cycle is ready for pre-test revision.',
        'time': '1d ago',
        'icon': Icons.notifications_active_outlined,
        'color': SlipTheme.carbon,
        'tab': 0,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: SlipTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'IN-APP NOTIFICATIONS',
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
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: SlipTheme.hairline, height: 1),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: SlipTheme.hairline, height: 1),
                    itemBuilder: (context, i) {
                      final item = notifications[i];
                      return InkWell(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          final targetTab = item['tab'] as int;
                          _tabController.animateTo(targetTab);
                          _pageController.animateToPage(
                            targetTab,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: (item['color'] as Color).withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item['icon'] as IconData,
                                  size: 16,
                                  color: item['color'] as Color,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['title'] as String,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: SlipTheme.carbon,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          item['time'] as String,
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            color: SlipTheme.steel,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item['body'] as String,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: SlipTheme.steel,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
  void _showTopicFilterSheet(BuildContext context, List<String> allSubjects) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SlipTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SYLLABUS SUBJECT FILTERS',
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
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: SlipTheme.hairline, height: 1),
                const SizedBox(height: 6),

                // Special presets: 'For You' and 'All'
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          widget.provider.setTopicFilter('For You');
                          Navigator.of(ctx).pop();
                        },
                        icon: const Icon(Icons.bolt_rounded, size: 14),
                        label: const Text('FOR YOU (AI REC)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.provider.selectedTopicFilter == 'For You'
                              ? SlipTheme.carbon
                              : SlipTheme.steel,
                          side: BorderSide(
                            color: widget.provider.selectedTopicFilter == 'For You'
                                ? SlipTheme.carbon
                                : SlipTheme.hairline,
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          widget.provider.setTopicFilter('All');
                          Navigator.of(ctx).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.provider.selectedTopicFilter == 'All'
                              ? SlipTheme.carbon
                              : SlipTheme.steel,
                          side: BorderSide(
                            color: widget.provider.selectedTopicFilter == 'All'
                                ? SlipTheme.carbon
                                : SlipTheme.hairline,
                            width: 0.8,
                          ),
                        ),
                        child: const Text('ALL TOPICS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: allSubjects.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: SlipTheme.hairline, height: 1),
                    itemBuilder: (context, i) {
                      final subj = allSubjects[i];
                      final isSelected = widget.provider.selectedTopicFilter == subj;

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        title: Text(
                          subj,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected ? SlipTheme.carbon : SlipTheme.steel,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded, size: 16, color: SlipTheme.carbon)
                            : null,
                        onTap: () {
                          widget.provider.setTopicFilter(subj);
                          Navigator.of(ctx).pop();
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
}

class _ExamFilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExamFilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? SlipTheme.carbon : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? SlipTheme.canvas : SlipTheme.steel,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
