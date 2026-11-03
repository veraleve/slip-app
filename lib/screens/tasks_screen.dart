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
import '../widgets/task_traps_drawer.dart';

class TasksScreen extends StatefulWidget {
  final SlipProvider provider;

  const TasksScreen({super.key, required this.provider});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentTabIndex = 1; // 0: Starred, 1: My Tasks, 2+: Custom lists

  String? _expandedTaskId;
  final Set<String> _selectedTaskIds = {};
  bool _isCompletedExpanded = false;
  String _sortOrder = 'My order'; // 'My order', 'Date', 'Starred recently'

  bool get _isMultiSelect => _selectedTaskIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentTabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleSelectTask(String id) {
    setState(() {
      if (_selectedTaskIds.contains(id)) {
        _selectedTaskIds.remove(id);
      } else {
        _selectedTaskIds.add(id);
      }
    });
  }

  void _selectAllTasks(List<TaskItem> tasks) {
    setState(() {
      if (_selectedTaskIds.length == tasks.length) {
        _selectedTaskIds.clear();
      } else {
        _selectedTaskIds.addAll(tasks.map((t) => t.id));
      }
    });
  }

  void _exitMultiSelect() {
    setState(() {
      _selectedTaskIds.clear();
    });
  }

  Future<void> _confirmDeleteSelectedTasks() async {
    final count = _selectedTaskIds.length;
    if (count == 0) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SlipTheme.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
        ),
        title: Text(
          'Delete $count task${count > 1 ? "s" : ""}?',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: SlipTheme.carbon,
          ),
        ),
        content: const Text(
          'Selected scheduled tasks and their revision traps will be permanently removed.',
          style: TextStyle(
            fontSize: 12,
            color: SlipTheme.steel,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: SlipTheme.steel,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SlipTheme.trapRed,
              foregroundColor: SlipTheme.canvas,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'DELETE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await widget.provider.deleteMultipleTasks(_selectedTaskIds);
      _exitMultiSelect();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count task${count > 1 ? "s" : ""} deleted.'),
            backgroundColor: SlipTheme.carbon,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showNewListSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: SlipTheme.canvas,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: SlipTheme.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Create new list',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: SlipTheme.carbon,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(fontSize: 14, color: SlipTheme.carbon),
                decoration: InputDecoration(
                  hintText: 'Enter list title',
                  hintStyle: const TextStyle(fontSize: 14, color: SlipTheme.steel),
                  filled: true,
                  fillColor: SlipTheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: SlipTheme.carbon, width: 1.2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: SlipTheme.steel,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isNotEmpty) {
                        widget.provider.addTaskList(name);
                        Navigator.of(ctx).pop();
                        final newIndex = 1 + widget.provider.customLists.length;
                        setState(() => _currentTabIndex = newIndex);
                        _pageController.animateToPage(
                          newIndex,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SlipTheme.carbon,
                      foregroundColor: SlipTheme.canvas,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SlipTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'SORT BY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: SlipTheme.steel,
                ),
              ),
            ),
            ListTile(
              dense: true,
              leading: Icon(
                Icons.sort_rounded,
                size: 18,
                color: _sortOrder == 'My order' ? SlipTheme.carbon : SlipTheme.steel,
              ),
              title: const Text('My order', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              trailing: _sortOrder == 'My order' ? const Icon(Icons.check_rounded, size: 18, color: SlipTheme.carbon) : null,
              onTap: () {
                setState(() => _sortOrder = 'My order');
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              dense: true,
              leading: Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: _sortOrder == 'Date' ? SlipTheme.carbon : SlipTheme.steel,
              ),
              title: const Text('Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              trailing: _sortOrder == 'Date' ? const Icon(Icons.check_rounded, size: 18, color: SlipTheme.carbon) : null,
              onTap: () {
                setState(() => _sortOrder = 'Date');
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              dense: true,
              leading: Icon(
                Icons.star_rounded,
                size: 18,
                color: _sortOrder == 'Starred recently' ? SlipTheme.carbon : SlipTheme.steel,
              ),
              title: const Text('Starred recently', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              trailing: _sortOrder == 'Starred recently' ? const Icon(Icons.check_rounded, size: 18, color: SlipTheme.carbon) : null,
              onTap: () {
                setState(() => _sortOrder = 'Starred recently');
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showListOverflowMenu(String listName) {
    final isCustom = listName != 'My Tasks' && listName != 'Starred';
    showModalBottomSheet(
      context: context,
      backgroundColor: SlipTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                listName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: SlipTheme.steel,
                ),
              ),
            ),
            if (isCustom) ...[
              ListTile(
                dense: true,
                leading: const Icon(Icons.edit_outlined, size: 18, color: SlipTheme.carbon),
                title: const Text('Rename list', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showRenameListDialog(listName);
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.delete_outline_rounded, size: 18, color: SlipTheme.trapRed),
                title: const Text('Delete list', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SlipTheme.trapRed)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  widget.provider.deleteTaskList(listName);
                  setState(() => _currentTabIndex = 1);
                  _pageController.animateToPage(1, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
                },
              ),
            ],
            ListTile(
              dense: true,
              leading: const Icon(Icons.clear_all_rounded, size: 18, color: SlipTheme.steel),
              title: const Text('Delete all completed tasks', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.of(ctx).pop();
                final completedIds = widget.provider.tasks
                    .where((t) => t.isCompleted && (listName == 'Starred' ? t.isStarred : (listName == 'My Tasks' ? t.listName == 'My Tasks' : t.listName == listName)))
                    .map((t) => t.id)
                    .toList();
                if (completedIds.isNotEmpty) {
                  await widget.provider.deleteMultipleTasks(completedIds);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameListDialog(String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SlipTheme.canvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: const Text('Rename list', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        content: HairlineInput(controller: controller, placeholder: 'List title', maxLines: 1),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SlipTheme.steel)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                widget.provider.renameTaskList(oldName, newName);
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: SlipTheme.carbon, foregroundColor: SlipTheme.canvas),
            child: const Text('SAVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customLists = widget.provider.customLists;
    // Tabs list: [ 'Starred', 'My Tasks', ...customLists, '+ New list' ]
    final tabs = <String>['Starred', 'My Tasks', ...customLists];

    return Scaffold(
      backgroundColor: SlipTheme.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Google Tasks Top Sliding Tabs Bar (or Multi-Select Context Bar)
            if (_isMultiSelect)
              Container(
                height: 52,
                color: SlipTheme.canvas,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22, color: SlipTheme.carbon),
                      onPressed: _exitMultiSelect,
                      tooltip: 'Cancel',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedTaskIds.length} selected',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: SlipTheme.carbon,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.select_all_rounded, size: 20, color: SlipTheme.carbon),
                      onPressed: () {
                        final activeList = _getTasksForTab(_currentTabIndex, tabs);
                        _selectAllTasks(activeList);
                      },
                      tooltip: 'Select All',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 22, color: SlipTheme.trapRed),
                      onPressed: _confirmDeleteSelectedTasks,
                      tooltip: 'Delete Selected',
                    ),
                  ],
                ),
              )
            else
              Container(
                color: SlipTheme.canvas,
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Tab 0: Starred (★)
                    _buildTabItem(
                      index: 0,
                      child: Icon(
                        _currentTabIndex == 0 ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 20,
                        color: _currentTabIndex == 0 ? SlipTheme.carbon : SlipTheme.steel,
                      ),
                    ),
                    const SizedBox(width: 18),

                    // Tab 1: My Tasks
                    _buildTabItem(
                      index: 1,
                      child: Text(
                        'My Tasks',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _currentTabIndex == 1 ? FontWeight.w800 : FontWeight.w600,
                          color: _currentTabIndex == 1 ? SlipTheme.carbon : SlipTheme.steel,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),

                    // Custom Lists Tabs
                    for (int i = 0; i < customLists.length; i++) ...[
                      _buildTabItem(
                        index: 2 + i,
                        child: Text(
                          customLists[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _currentTabIndex == 2 + i ? FontWeight.w800 : FontWeight.w600,
                            color: _currentTabIndex == 2 + i ? SlipTheme.carbon : SlipTheme.steel,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                    ],

                    // + New list action tab
                    InkWell(
                      onTap: _showNewListSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 16, color: SlipTheme.steel),
                            SizedBox(width: 4),
                            Text(
                              'New list',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: SlipTheme.steel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 2. Sliding PageView between Lists
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: tabs.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentTabIndex = index;
                    _selectedTaskIds.clear();
                  });
                },
                itemBuilder: (context, pageIndex) {
                  final listName = tabs[pageIndex];
                  final tasksForList = _getTasksForTab(pageIndex, tabs);
                  final activeTasks = tasksForList.where((t) => !t.isCompleted).toList();
                  final completedTasks = tasksForList.where((t) => t.isCompleted).toList();

                  _applySort(activeTasks);
                  _applySort(completedTasks);

                  return _buildListCard(
                    listTitle: listName == 'Starred' ? 'Starred' : listName,
                    activeTasks: activeTasks,
                    completedTasks: completedTasks,
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // 3. Google Tasks Right Bottom Floating Action Button (Positioned just above NavDock)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 10),
        child: FloatingActionButton(
          onPressed: () => _showAddTaskSheet(
            defaultList: _currentTabIndex == 0
                ? 'My Tasks'
                : (_currentTabIndex == 1 ? 'My Tasks' : tabs[_currentTabIndex]),
          ),
          backgroundColor: SlipTheme.carbon,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.add_rounded, size: 28, color: SlipTheme.canvas),
        ),
      ),
    );
  }

  Widget _buildTabItem({required int index, required Widget child}) {
    final isSelected = _currentTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _currentTabIndex = index);
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(
                  bottom: BorderSide(color: SlipTheme.carbon, width: 2.5),
                )
              : null,
        ),
        child: child,
      ),
    );
  }

  List<TaskItem> _getTasksForTab(int tabIndex, List<String> tabs) {
    final all = widget.provider.tasks;
    if (tabIndex == 0) {
      // Starred
      return all.where((t) => t.isStarred).toList();
    } else if (tabIndex == 1) {
      // My Tasks (default)
      return all.where((t) => t.listName == 'My Tasks').toList();
    } else {
      final customName = tabs[tabIndex];
      return all.where((t) => t.listName == customName).toList();
    }
  }

  void _applySort(List<TaskItem> list) {
    if (_sortOrder == 'Date') {
      list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    } else if (_sortOrder == 'Starred recently') {
      list.sort((a, b) {
        if (a.isStarred != b.isStarred) {
          return a.isStarred ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    } else {
      // 'My order': by creation date descending
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  String _formatGoogleTaskDate(DateTime scheduledAt, DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(scheduledAt);
    if (diff.isNegative) {
      final remainingDays = scheduledAt.difference(now).inDays;
      if (remainingDays == 0) return 'Due today';
      if (remainingDays == 1) return 'Due tomorrow';
      if (remainingDays < 7) return 'Due in $remainingDays days';
      final weeks = (remainingDays / 7).round();
      return 'Due in $weeks week${weeks > 1 ? "s" : ""}';
    } else {
      final pastDays = diff.inDays;
      if (pastDays == 0) return 'Due today';
      if (pastDays == 1) return 'Due yesterday';
      if (pastDays < 7) return 'Due $pastDays days ago';
      final weeks = (pastDays / 7).floor();
      if (weeks < 52) {
        return '$weeks weeks ago';
      } else {
        final years = (weeks / 52).floor();
        return '$years year${years > 1 ? "s" : ""} ago';
      }
    }
  }

  Widget _buildListCard({
    required String listTitle,
    required List<TaskItem> activeTasks,
    required List<TaskItem> completedTasks,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      children: [
        // List Header: Title + Sort + 3-dots (Rendered directly on screen)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 0, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  listTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: SlipTheme.carbon,
                    letterSpacing: -0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_vert_rounded, size: 22, color: SlipTheme.carbon),
                onPressed: _showSortMenu,
                tooltip: 'Sort',
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: SlipTheme.carbon),
                onPressed: () => _showListOverflowMenu(listTitle),
                tooltip: 'Options',
              ),
            ],
          ),
        ),

        if (activeTasks.isEmpty && completedTasks.isEmpty)
          _EmptyTasksState(
            listName: listTitle,
            onAddTask: () => _showAddTaskSheet(
              defaultList: listTitle == 'Starred' ? 'My Tasks' : listTitle,
            ),
          )
        else if (activeTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: Text(
                'All tasks completed!',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SlipTheme.steel,
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < activeTasks.length; i++) ...[
                _buildGoogleTaskRow(activeTasks[i]),
                if (i < activeTasks.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Color(0xFFF0F0F0),
                    indent: 48,
                    endIndent: 8,
                  ),
              ],
            ],
          ),

        // Completed Tasks Section (Rendered directly on canvas)
        if (completedTasks.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFEEEEEE)),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _isCompletedExpanded = !_isCompletedExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              child: Row(
                children: [
                  Text(
                    'Completed (${completedTasks.length})',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: SlipTheme.carbon,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isCompletedExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: SlipTheme.carbon,
                  ),
                ],
              ),
            ),
          ),
          if (_isCompletedExpanded) ...[
            for (int i = 0; i < completedTasks.length; i++) ...[
              _buildGoogleTaskRow(completedTasks[i]),
              if (i < completedTasks.length - 1)
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Color(0xFFF0F0F0),
                  indent: 48,
                  endIndent: 8,
                ),
            ],
          ],
        ],
      ],
    );
  }

  Widget _buildGoogleTaskRow(TaskItem task) {
    final blunders = widget.provider.getBlundersForTask(task);
    final isSelected = _selectedTaskIds.contains(task.id);
    final hasSavedPeerMistake = blunders.any((s) => s.hasKept && s.authorId != widget.provider.currentUserId);

    final diff = task.scheduledAt.difference(DateTime.now());
    final isOverdue = !task.isCompleted && diff.isNegative;
    final String timeLabel = _formatGoogleTaskDate(task.scheduledAt, task.createdAt);

    return InkWell(
      onTap: () {
        if (_isMultiSelect) {
          _toggleSelectTask(task.id);
        } else {
          _showTrapsDrawer(context, task);
        }
      },
      onLongPress: () {
        _toggleSelectTask(task.id);
      },
      child: Container(
        color: isSelected ? SlipTheme.carbon.withOpacity(0.06) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Google Tasks Round Checkbox (or Circular Checkbox in Multi-Select)
            if (_isMultiSelect)
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 14),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelectTask(task.id),
                    activeColor: SlipTheme.carbon,
                    checkColor: SlipTheme.canvas,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const CircleBorder(),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  widget.provider.toggleTaskCompleted(task.id);
                },
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2, right: 14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isCompleted ? const Color(0xFF747775) : const Color(0xFF747775),
                      width: 1.5,
                    ),
                    color: task.isCompleted ? const Color(0xFF747775) : Colors.transparent,
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

            // Title + Due Date/Time + Mistakes Indicator
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: task.isCompleted ? const Color(0xFF747775) : const Color(0xFF1F1F1F),
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Meta row: Date in red with clock icon + Warm Yellow/Amber Mistake pill badge
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      // Date with clock icon (brick red like screenshot)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: isOverdue ? const Color(0xFFB3261E) : SlipTheme.steel,
                          ),
                          const SizedBox(width: 3.5),
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isOverdue ? const Color(0xFFB3261E) : SlipTheme.steel,
                            ),
                          ),
                        ],
                      ),

                      // Warm Yellow/Amber Mistake indicator pill
                      if (blunders.isNotEmpty)
                        GestureDetector(
                          onTap: () => _showTrapsDrawer(context, task),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFD97706).withOpacity(0.45),
                                width: 0.8,
                              ),
                              color: const Color(0xFFFEF3C7).withOpacity(0.6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 12.5,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 3.5),
                                Text(
                                  hasSavedPeerMistake
                                      ? '${blunders.length} MISTAKES · SAVED PEER'
                                      : '${blunders.length} MISTAKES',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Star Button on the right
            GestureDetector(
              onTap: () {
                widget.provider.toggleTaskStarred(task.id);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(
                  task.isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 22,
                  color: task.isStarred ? const Color(0xFFF9A825) : const Color(0xFF747775),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrapsDrawer(BuildContext context, TaskItem task) {
    TaskTrapsDrawer.show(context, provider: widget.provider, task: task);
  }

  void _showAddTaskSheet({String defaultList = 'My Tasks'}) {
    final userExams = widget.provider.userExams;
    String selectedExam = userExams.isNotEmpty ? userExams.first : GateSyllabus.gateCS;
    final subjects = GateSyllabus.getSubjectsForExam(selectedExam);
    String selectedSubject = subjects.first;
    String selectedTopic = 'All Topics';
    List<String> selectedTopics = [];
    DateTime scheduledDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay scheduledTime = const TimeOfDay(hour: 9, minute: 0);
    String targetList = defaultList;

    final titleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SlipTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setSheetState) {
            final availableSubtopics =
                GateSyllabus.getSubtopics(selectedExam, selectedSubject);

            if (selectedTopic != 'All Topics' && !availableSubtopics.contains(selectedTopic)) {
              selectedTopic = 'All Topics';
            }

            final allLists = ['My Tasks', ...widget.provider.customLists];

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
                        const Text(
                          'SCHEDULE A TASK',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
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
                    const SizedBox(height: 14),

                    // Task Title
                    HairlineInput(
                      controller: titleController,
                      placeholder: 'e.g. Do probability homework, Formula revision',
                      maxLines: 1,
                    ),
                    const SizedBox(height: 14),

                    // Target List Selector
                    const Text(
                      'LIST',
                      style: TextStyle(
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
                        borderRadius: BorderRadius.circular(14),
                        color: SlipTheme.surface,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: targetList,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: SlipTheme.carbon,
                            fontWeight: FontWeight.w600,
                          ),
                          items: allLists.map((name) {
                            return DropdownMenuItem(
                              value: name,
                              child: Text(name, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => targetList = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Exam Selector
                    const Text(
                      'PAPER',
                      style: TextStyle(
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
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
                          ),
                          onSelected: (_) {
                            setSheetState(() {
                              selectedExam = exam;
                              final newSubjects = GateSyllabus.getSubjectsForExam(exam);
                              selectedSubject = newSubjects.first;
                              selectedTopic = 'All Topics';
                              selectedTopics.clear();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Cascading Subject Selector Dropdown
                    const Text(
                      'SUBJECT',
                      style: TextStyle(
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
                        borderRadius: BorderRadius.circular(14),
                        color: SlipTheme.surface,
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
                                selectedTopic = 'All Topics';
                                selectedTopics.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Cascading Syllabus Topic Selector Dropdown
                    const Text(
                      'SYLLABUS TOPIC (FOR INOCULATION TRAPS)',
                      style: TextStyle(
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
                        borderRadius: BorderRadius.circular(14),
                        color: SlipTheme.surface,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedTopic,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: SlipTheme.carbon,
                            fontWeight: FontWeight.w600,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'All Topics',
                              child: Text('All Topics (Full Subject Inoculation)', overflow: TextOverflow.ellipsis),
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
                              setSheetState(() {
                                selectedTopic = val;
                                if (val == 'All Topics') {
                                  selectedTopics = List<String>.from(availableSubtopics);
                                } else {
                                  selectedTopics = [val];
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
                            listName: targetList,
                            createdAt: DateTime.now(),
                          );

                          widget.provider.addTask(task);

                          NativeDeviceService.showNotification(
                            title: 'Task Scheduled · $title',
                            body: 'Inoculation traps for $selectedSubject have been prepared.',
                          );

                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SlipTheme.carbon,
                          foregroundColor: SlipTheme.canvas,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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

class _EmptyTasksState extends StatelessWidget {
  final String listName;
  final VoidCallback onAddTask;

  const _EmptyTasksState({required this.listName, required this.onAddTask});

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
              size: 44,
              color: SlipTheme.steelLight,
            ),
            const SizedBox(height: 14),
            Text(
              listName == 'Starred' ? 'No starred tasks' : 'A fresh start',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: SlipTheme.carbon,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              listName == 'Starred'
                  ? 'Star tasks you want to prioritize or revise frequently.'
                  : 'Tasks added here will automatically link and inoculate your subject blunders.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'ADD A TASK',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
