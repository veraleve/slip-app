import 'package:flutter/material.dart';
import '../constants/gate_syllabus.dart';
import '../models/slip.dart';
import '../providers/slip_provider.dart';
import '../services/supabase_service.dart';
import '../theme/slip_theme.dart';
import '../widgets/feed_filter_sheet.dart';
import '../widgets/slip_card.dart';
import 'notifications_screen.dart';

class FeedScreen extends StatefulWidget {
  final SlipProvider provider;

  const FeedScreen({super.key, required this.provider});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  final ScrollController _peerScrollController = ScrollController();

  bool _isSolvedArchiveExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _peerScrollController.addListener(_onPeerScroll);
  }

  void _onPeerScroll() {
    if (_peerScrollController.position.pixels >=
        _peerScrollController.position.maxScrollExtent - 250) {
      widget.provider.loadMoreSlips();
    }
  }

  @override
  void dispose() {
    _peerScrollController.removeListener(_onPeerScroll);
    _peerScrollController.dispose();
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final userExams = provider.userExams;
    final currentUserId = SupabaseService().currentUserId;
    final currentUsername = SupabaseService().currentUsername;

    final currentExam = provider.selectedExamFilter == 'All'
        ? (userExams.isNotEmpty ? userExams.first : GateSyllabus.gateCS)
        : provider.selectedExamFilter;

    final subjects = ['All', ...GateSyllabus.getSubjectsForExam(currentExam)];

    // Slips for My Review Cycle: (authored by user OR kept/saved by user)
    // CRITICAL: Filter from allSlips (not filtered slips) so personal blunders are never hidden
    final allReviewSlips = provider.allSlips.where((s) {
      final isMine = (s.authorId != null && s.authorId == currentUserId) ||
          (s.authorUsername != null && s.authorUsername == currentUsername);
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
            // 1. Top Minimalist App Bar with Paper Selector & Notification Bell
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
                            borderRadius: BorderRadius.circular(12),
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

                  Row(
                    children: [
                      IconButton(
                        onPressed: () => provider.refreshStream(),
                        icon: const Icon(Icons.refresh_rounded, size: 21, color: SlipTheme.carbon),
                        tooltip: 'Refresh feed',
                        visualDensity: VisualDensity.compact,
                      ),
                      // Notification Bell with unread indicator
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => NotificationsScreen(
                                    provider: widget.provider,
                                    onOpenReviewCycle: () {
                                      Navigator.of(context).pop();
                                      _tabController.animateTo(1);
                                      _pageController.animateToPage(
                                        1,
                                        duration: const Duration(milliseconds: 250),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
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
                ],
              ),
            ),

            // 2. Dual Tabs Header: [ PEER DOUBTS & Q&A ] | [ MY MISTAKES & REVISION ]
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
                  const Tab(text: 'PEER DOUBTS & Q&A'),
                  Tab(text: 'MY MISTAKES & REVISION (${activeCycleSlips.length})'),
                ],
              ),
            ),

            // 3. Compact Curved Filter Bar: [ FILTER ] + [ ALL ] + [ DOUBTS ] + [ MISTAKES ] + [ Topics ]
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: SizedBox(
                height: 32,
                child: Builder(builder: (context) {
                  final allSubjects = GateSyllabus.getSubjectsForExam(currentExam);

                  // Extract top 3 most frequently logged topics by user
                  final topicCounts = <String, int>{};
                  for (final s in provider.slips) {
                    topicCounts[s.topic] = (topicCounts[s.topic] ?? 0) + 1;
                  }
                  final sortedTopics = topicCounts.keys.toList()
                    ..sort((a, b) => (topicCounts[b] ?? 0).compareTo(topicCounts[a] ?? 0));
                  final frequentTopics = sortedTopics.isNotEmpty
                    ? sortedTopics.take(3).toList()
                    : allSubjects.take(3).toList();

                  final isAllActive = provider.selectedPostTypeFilter == null &&
                      provider.selectedTopicFilter == 'All' &&
                      provider.selectedSubjectFilter == 'All';
                  final isDoubtsActive = provider.selectedPostTypeFilter == PostType.doubt;
                  final isMistakesActive = provider.selectedPostTypeFilter == PostType.mistake;

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Filter Icon Button (opens modular cascading filter sheet)
                      GestureDetector(
                        onTap: () => FeedFilterSheet.show(
                          context,
                          provider: provider,
                          currentExam: currentExam,
                          allSubjects: allSubjects,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: SlipTheme.surface,
                            border: Border.all(color: SlipTheme.hairline, width: 0.8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune_rounded, size: 14, color: SlipTheme.carbon),
                              SizedBox(width: 4),
                              Text(
                                'FILTER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: SlipTheme.carbon,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 1. All Filter Pill
                      _buildFilterChip(
                        label: 'All',
                        isSelected: isAllActive,
                        onTap: () {
                          provider.setPostTypeFilter(null);
                          provider.setTopicFilter('All');
                          provider.setSubjectFilter('All');
                        },
                      ),

                      // 2. Doubts Only Pill
                      _buildFilterChip(
                        label: 'Doubts',
                        isSelected: isDoubtsActive,
                        onTap: () {
                          provider.setPostTypeFilter(
                            isDoubtsActive ? null : PostType.doubt,
                          );
                        },
                      ),

                      // 3. Mistakes Only Pill
                      _buildFilterChip(
                        label: 'Mistakes',
                        isSelected: isMistakesActive,
                        onTap: () {
                          provider.setPostTypeFilter(
                            isMistakesActive ? null : PostType.mistake,
                          );
                        },
                      ),

                      // 4. General Doubts Pill
                      _buildFilterChip(
                        label: 'General',
                        isSelected: provider.selectedSubjectFilter == 'General' || provider.selectedTopicFilter == 'General',
                        onTap: () {
                          final isGeneral = provider.selectedSubjectFilter == 'General' || provider.selectedTopicFilter == 'General';
                          if (isGeneral) {
                            provider.setTopicFilter('All');
                            provider.setSubjectFilter('All');
                          } else {
                            provider.setSubjectFilter('General');
                            provider.setTopicFilter('General');
                          }
                        },
                      ),

                      // 4. Frequent Subject Pills
                      ...frequentTopics.map((subject) {
                        final isSelected = provider.selectedSubjectFilter == subject ||
                            provider.selectedTopicFilter == subject;
                        return _buildFilterChip(
                          label: subject,
                          isSelected: isSelected,
                          onTap: () {
                            if (isSelected) {
                              provider.setTopicFilter('All');
                              provider.setSubjectFilter('All');
                            } else {
                              provider.setSubjectFilter(subject);
                              provider.setTopicFilter(subject);
                            }
                          },
                        );
                      }),
                    ],
                  );
                }),
              ),
            ),

            // 4. Swipeable Dual Feed PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  _tabController.animateTo(index);
                },
                children: [
                  // --- TAB 1: PEER DOUBTS & Q&A ---
                  _buildPeerFeedTab(provider.slips.where((s) => s.isPublic).toList()),

                  // --- TAB 2: MY MISTAKES & REVISION ---
                  _buildReviewCycleTab(activeCycleSlips, solvedSlips),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? SlipTheme.carbon : SlipTheme.surface,
            border: Border.all(
              color: isSelected ? SlipTheme.carbon : SlipTheme.hairline,
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? SlipTheme.canvas : SlipTheme.carbon,
              fontSize: 9.5,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET FOR TAB 2: MY MISTAKES & REVISION ---
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
      return RefreshIndicator(
        onRefresh: () => widget.provider.refreshStream(),
        color: SlipTheme.carbon,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
          children: [
            const Icon(Icons.psychology_outlined, size: 36, color: SlipTheme.steel),
            const SizedBox(height: 12),
            Text(
              'Your Review Cycle is empty.',
              textAlign: TextAlign.center,
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
      );
    }

    return RefreshIndicator(
      onRefresh: () => widget.provider.refreshStream(),
      color: SlipTheme.carbon,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  'TAP Check TO MASTER',
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
              provider: widget.provider,
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
                  borderRadius: BorderRadius.circular(14),
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
                    provider: widget.provider,
                    onSameTap: () => widget.provider.toggleSame(slip.id),
                    onFixToggle: () => widget.provider.toggleFixRevealed(slip.id),
                    onKeepTap: () => widget.provider.toggleKeep(slip.id),
                    onSolveTap: () {
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
      ),
    );
  }

  // --- WIDGET FOR TAB 1: PEER DOUBTS & Q&A ---
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
      return RefreshIndicator(
        onRefresh: () => widget.provider.refreshStream(),
        color: SlipTheme.carbon,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
          children: [
            const Icon(Icons.forum_outlined, size: 40, color: SlipTheme.steelLight),
            const SizedBox(height: 12),
            Text(
              'No peer posts found for this filter.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SlipTheme.carbon,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ask a doubt or share a blunder to start the peer feed! Pull down to refresh.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SlipTheme.steel),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => widget.provider.refreshStream(),
      color: SlipTheme.carbon,
      child: ListView.builder(
        controller: _peerScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: slips.length + (widget.provider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == slips.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SlipTheme.carbon,
                  ),
                ),
              ),
            );
          }

          final slip = slips[index];
          return SlipCard(
            index: index,
            slip: slip,
            provider: widget.provider,
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
      ),
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
          borderRadius: BorderRadius.circular(10),
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
