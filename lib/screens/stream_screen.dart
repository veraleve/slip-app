import 'package:flutter/material.dart';
import '../providers/slip_provider.dart';
import '../theme/slip_theme.dart';
import '../widgets/slip_card.dart';

class StreamScreen extends StatelessWidget {
  final SlipProvider provider;

  const StreamScreen({super.key, required this.provider});

  static const List<String> _topics = [
    'All',
    'Linear Algebra',
    'Computer Architecture',
    'Operating Systems',
    'Discrete Mathematics',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'SLIP',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '// STREAM',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: SlipTheme.steel,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: SlipTheme.clearedGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '48 PEERS ACTIVE ON MESH',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: SlipTheme.steel,
                                  fontSize: 9,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => provider.init(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    tooltip: 'Refresh Stream',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Daily Horizon Telemetry Meter
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SlipTheme.surface,
                border: Border.all(color: SlipTheme.hairline, width: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TODAY: 4 TRAPS ENCOUNTERED · 1 ACTIVE BLINDSPOT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 9.5,
                        ),
                  ),
                  Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      color: SlipTheme.clearedGreen,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Topic Filter Chips (Horizontal Scroll)
            SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _topics.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final topic = _topics[index];
                  final isSelected = provider.selectedTopicFilter == topic;
                  return GestureDetector(
                    onTap: () => provider.setTopicFilter(topic),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? SlipTheme.carbon : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? SlipTheme.carbon
                              : SlipTheme.hairline,
                          width: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Text(
                          topic.toUpperCase(),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? SlipTheme.canvas
                                        : SlipTheme.steel,
                                    fontSize: 9.5,
                                  ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            const Divider(),

            // Stream Feed
            Expanded(
              child: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(SlipTheme.carbon),
                      ),
                    )
                  : provider.slips.isEmpty
                      ? Center(
                          child: Text(
                            'NO SLIPS LOGGED FOR THIS TOPIC YET.',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: provider.init,
                          color: SlipTheme.carbon,
                          child: ListView.builder(
                            itemCount: provider.slips.length,
                            itemBuilder: (context, index) {
                              final slip = provider.slips[index];
                              return SlipCard(
                                index: index,
                                slip: slip,
                                onSameTap: () => provider.toggleSame(slip.id),
                                onFixToggle: () =>
                                    provider.toggleFixRevealed(slip.id),
                                onKeepTap: () => provider.toggleKeep(slip.id),
                                onPassTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'PASSED TO BLUETOOTH MESH: ${slip.topic}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(color: SlipTheme.canvas),
                                      ),
                                      backgroundColor: SlipTheme.carbon,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
