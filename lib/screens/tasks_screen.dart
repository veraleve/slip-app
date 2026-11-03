import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/gate_syllabus.dart';
import '../models/slip.dart';
import '../models/task_item.dart';
import '../providers/slip_provider.dart';
import '../services/native_device_service.dart';
import '../theme/slip_theme.dart';
import '../widgets/hairline_input.dart';
import '../widgets/slip_card.dart';

class TasksScreen extends StatefulWidget {
  final SlipProvider provider;

  const TasksScreen({super.key, required this.provider});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _filter = 'All'; // 'All', 'Upcoming', 'Completed'
  String? _expandedTaskId;

  @override
  Widget build(BuildContext context) {
    final allTasks = widget.provider.tasks;
    final filteredTasks = allTasks.where((t) {
      if (_filter == 'Upcoming') return !t.isCompleted;
      if (_filter == 'Completed') return t.isCompleted;
      return true;
    }).toList();

    final pendingCount = allTasks.where((t) => !t.isCompleted).length;

    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Google Tasks Style Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasks & Tests',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: SlipTheme.carbon,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pendingCount == 0
                            ? 'All caught up'
                            : '$pendingCount scheduled · Inoculation linked',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: SlipTheme.steel,
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: _showAddTaskSheet,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'NEW TASK',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SlipTheme.carbon,
                      side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'ALL',
                    count: allTasks.length,
                    isSelected: _filter == 'All',
                    onTap: () => setState(() => _filter = 'All'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'UPCOMING',
                    count: pendingCount,
                    isSelected: _filter == 'Upcoming',
                    onTap: () => setState(() => _filter = 'Upcoming'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'COMPLETED',
                    count: allTasks.length - pendingCount,
                    isSelected: _filter == 'Completed',
                    onTap: () => setState(() => _filter = 'Completed'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(color: SlipTheme.hairline, height: 1),

            // 3. Task List
            Expanded(
              child: filteredTasks.isEmpty
                  ? _EmptyTasksState(filter: _filter, onAddTask: _showAddTaskSheet)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        final blunders = widget.provider.getBlundersForTask(task);
                        final isExpanded = _expandedTaskId == task.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: SlipTheme.surface,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: SlipTheme.hairline, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Main Task Row
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _expandedTaskId = isExpanded ? null : task.id;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Google Tasks circular checkbox
                                      GestureDetector(
                                        onTap: () {
                                          widget.provider.toggleTaskCompleted(task.id);
                                        },
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          margin: const EdgeInsets.only(top: 2, right: 12),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: task.isCompleted
                                                  ? SlipTheme.clearedGreen
                                                  : SlipTheme.steel,
                                              width: 1.5,
                                            ),
                                            color: task.isCompleted
                                                ? SlipTheme.clearedGreen
                                                : Colors.transparent,
                                          ),
                                          child: task.isCompleted
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  size: 14,
                                                  color: SlipTheme.canvas,
                                                )
                                              : null,
                                        ),
                                      ),

                                      // Task Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.title,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: task.isCompleted
                                                        ? SlipTheme.steel
                                                        : SlipTheme.carbon,
                                                    decoration: task.isCompleted
                                                        ? TextDecoration.lineThrough
                                                        : null,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 5, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: SlipTheme.carbon.withOpacity(0.06),
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                  child: Text(
                                                    task.examTag,
                                                    style: const TextStyle(
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: SlipTheme.carbon,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  task.subject,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: SlipTheme.steel,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.calendar_today_rounded,
                                                  size: 11,
                                                  color: SlipTheme.steel,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat('EEE, MMM d · h:mm a')
                                                      .format(task.scheduledAt),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: SlipTheme.steel,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Attached Blunder Badge
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: blunders.isNotEmpty
                                                  ? SlipTheme.trapRed.withOpacity(0.08)
                                                  : SlipTheme.hairline,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  size: 11,
                                                  color: blunders.isNotEmpty
                                                      ? SlipTheme.trapRed
                                                      : SlipTheme.steel,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${blunders.length} TRAPS',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: blunders.isNotEmpty
                                                      ? SlipTheme.trapRed
                                                      : SlipTheme.steel,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Icon(
                                            isExpanded
                                                ? Icons.keyboard_arrow_up_rounded
                                                : Icons.keyboard_arrow_down_rounded,
                                            size: 16,
                                            color: SlipTheme.steel,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Expanded Inoculation Mistake Checklist
                              if (isExpanded) ...[
                                const Divider(color: SlipTheme.hairline, height: 1),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  color: SlipTheme.canvas,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'TOPIC INOCULATION CHECKLIST (${blunders.length})',
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                              color: SlipTheme.steel,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded,
                                                size: 16, color: SlipTheme.trapRed),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              widget.provider.deleteTask(task.id);
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (blunders.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 8),
                                          child: Text(
                                            'No blunders logged yet for this topic. Drop mistakes or explore peer stream to attach revision traps.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: SlipTheme.steel,
                                              height: 1.35,
                                            ),
                                          ),
                                        )
                                      else
                                        ...blunders.map((b) => _BlunderPreviewRow(slip: b)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskSheet() {
    final userExams = widget.provider.userExams;
    String selectedExam = userExams.isNotEmpty ? userExams.first : GateSyllabus.gateCS;
    final subjects = GateSyllabus.getSubjectsForExam(selectedExam);
    String selectedSubject = subjects.first;
    List<String> selectedTopics = [];
    DateTime scheduledDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay scheduledTime = const TimeOfDay(hour: 9, minute: 0);

    final titleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SlipTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setSheetState) {
            final availableSubtopics =
                GateSyllabus.getSubtopics(selectedExam, selectedSubject);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SCHEDULE A TASK / TEST',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
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
                    const SizedBox(height: 14),

                    // Task Title
                    HairlineInput(
                      controller: titleController,
                      placeholder: 'e.g. Mock Test 2, DP Practice, Formula Revision',
                      maxLines: 1,
                    ),
                    const SizedBox(height: 14),

                    // Exam Selector
                    Text(
                      'PAPER',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: SlipTheme.steel,
                            fontSize: 9.5,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: GateSyllabus.supportedExams.map((exam) {
                        final isSelected = exam == selectedExam;
                        return ChoiceChip(
                          label: Text(
                            exam,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? SlipTheme.canvas : SlipTheme.carbon,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: SlipTheme.carbon,
                          backgroundColor: SlipTheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                            side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                          ),
                          onSelected: (_) {
                            setSheetState(() {
                              selectedExam = exam;
                              final newSubjects = GateSyllabus.getSubjectsForExam(exam);
                              selectedSubject = newSubjects.first;
                              selectedTopics.clear();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Subject Selector
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
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: SlipTheme.hairline, width: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSubject,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: SlipTheme.carbon,
                            fontWeight: FontWeight.w600,
                          ),
                          items: subjects.map((subj) {
                            return DropdownMenuItem(
                              value: subj,
                              child: Text(subj, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                selectedSubject = val;
                                selectedTopics.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Topics Selector
                    if (availableSubtopics.isNotEmpty) ...[
                      Text(
                        'SYLLABUS TOPICS (FOR BLUNDER INOCULATION)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: SlipTheme.steel,
                              fontSize: 9.5,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: availableSubtopics.map((t) {
                          final isChosen = selectedTopics.contains(t);
                          return FilterChip(
                            label: Text(
                              t,
                              style: TextStyle(
                                fontSize: 10,
                                color: isChosen ? SlipTheme.canvas : SlipTheme.carbon,
                              ),
                            ),
                            selected: isChosen,
                            selectedColor: SlipTheme.carbon,
                            backgroundColor: SlipTheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                              side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                            ),
                            onSelected: (val) {
                              setSheetState(() {
                                if (val) {
                                  selectedTopics.add(t);
                                } else {
                                  selectedTopics.remove(t);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Date & Time Picker Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: scheduledDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (pickedDate != null) {
                                setSheetState(() => scheduledDate = pickedDate);
                              }
                            },
                            icon: const Icon(Icons.calendar_today_rounded, size: 14),
                            label: Text(
                              DateFormat('MMM d, yyyy').format(scheduledDate),
                              style: const TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SlipTheme.carbon,
                              side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: scheduledTime,
                              );
                              if (pickedTime != null) {
                                setSheetState(() => scheduledTime = pickedTime);
                              }
                            },
                            icon: const Icon(Icons.access_time_rounded, size: 14),
                            label: Text(
                              scheduledTime.format(context),
                              style: const TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SlipTheme.carbon,
                              side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          final scheduledDateTime = DateTime(
                            scheduledDate.year,
                            scheduledDate.month,
                            scheduledDate.day,
                            scheduledTime.hour,
                            scheduledTime.minute,
                          );

                          final task = TaskItem(
                            id: 'task_${DateTime.now().millisecondsSinceEpoch}',
                            title: title,
                            examTag: selectedExam,
                            subject: selectedSubject,
                            topics: selectedTopics,
                            scheduledAt: scheduledDateTime,
                            createdAt: DateTime.now(),
                          );

                          widget.provider.addTask(task);

                          // Trigger native confirmation notification
                          NativeDeviceService.showNotification(
                            title: 'Task Scheduled · $title',
                            body: 'Inoculation blunders for $selectedSubject have been prepared.',
                          );

                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SlipTheme.carbon,
                          foregroundColor: SlipTheme.canvas,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'SCHEDULE TASK',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? SlipTheme.carbon : SlipTheme.surface,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isSelected ? SlipTheme.carbon : SlipTheme.hairline,
            width: 0.8,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: isSelected ? SlipTheme.canvas : SlipTheme.steel,
          ),
        ),
      ),
    );
  }
}

class _BlunderPreviewRow extends StatelessWidget {
  final Slip slip;

  const _BlunderPreviewRow({required this.slip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: SlipTheme.surface,
        border: Border.all(color: SlipTheme.hairline, width: 0.6),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: SlipTheme.trapRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  slip.subtopic ?? slip.topic,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: SlipTheme.trapRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            slip.trapStatement,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: SlipTheme.carbon,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'FIX: ${slip.fixStatement}',
            style: const TextStyle(
              fontSize: 10.5,
              color: SlipTheme.steel,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTasksState extends StatelessWidget {
  final String filter;
  final VoidCallback onAddTask;

  const _EmptyTasksState({required this.filter, required this.onAddTask});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.task_alt_rounded,
              size: 40,
              color: SlipTheme.steelLight,
            ),
            const SizedBox(height: 12),
            Text(
              filter == 'Completed'
                  ? 'No completed tasks yet.'
                  : 'No scheduled tasks or mock tests.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SlipTheme.carbon,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Schedule your test series, quizzes, or subject revisions here. We\'ll automatically link and remind your topic blunders before you begin.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SlipTheme.steel,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onAddTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: SlipTheme.carbon,
                foregroundColor: SlipTheme.canvas,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
              ),
              child: const Text(
                'SCHEDULE FIRST TASK',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
