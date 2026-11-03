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
                                    .replaceAll(' 2027', '');
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
                          userExams.first.replaceAll(' 2027', ''),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: SlipTheme.steel,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    onPressed: () => provider.init(),
                    icon: const Icon(Icons.refresh_rounded,
                        size: 20, color: SlipTheme.steel),
                    tooltip: 'Refresh',
                    visualDensity: VisualDensity.compact,
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

            // 3. Subject Filter Chips (Dynamic from Syllabus)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: subjects.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final topic = subjects[index];
                    final isSelected = provider.selectedTopicFilter == topic;
                    return GestureDetector(
                      onTap: () => provider.setTopicFilter(topic),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? SlipTheme.carbon : SlipTheme.surface,
                          border: Border.all(
                            color: isSelected
                                ? SlipTheme.carbon
                                : SlipTheme.hairline,
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Center(
                          child: Text(
                            topic,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? SlipTheme.canvas
                                      : SlipTheme.carbon,
                                  fontSize: 10.5,
                                ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
