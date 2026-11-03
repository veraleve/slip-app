import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/gate_syllabus.dart';
import '../models/slip.dart';
import '../models/task_item.dart';
import '../providers/slip_provider.dart';
import '../services/native_device_service.dart';
import '../theme/slip_theme.dart';
import '../widgets/hairline_input.dart';

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
          borderRadius: BorderRadius.circular(6),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
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

  void _showNewListDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SlipTheme.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: SlipTheme.hairline, width: 0.8),
        ),
        title: const Text(
          'Create new list',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: SlipTheme.carbon,
          ),
        ),
        content: HairlineInput(
          controller: controller,
          placeholder: 'Enter list title',
          maxLines: 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
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
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                widget.provider.addTaskList(name);
                Navigator.of(ctx).pop();
                // Switch to the newly created list
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            ),
            child: const Text(
              'DONE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortMenu() {
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
      backgroundColor: const Color(0xFFF2F3F5), // Google Tasks light grey background
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
                color: const Color(0xFFF2F3F5),
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
                      onTap: _showNewListDialog,
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

      // 3. Google Tasks Right Bottom Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(
          defaultList: _currentTabIndex == 0
              ? 'My Tasks'
              : (_currentTabIndex == 1 ? 'My Tasks' : tabs[_currentTabIndex]),
        ),
        backgroundColor: SlipTheme.carbon,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28, color: SlipTheme.canvas),
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

  Widget _buildListCard({
    required String listTitle,
    required List<TaskItem> activeTasks,
    required List<TaskItem> completedTasks,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: SlipTheme.canvas, // Pure white inner sheet card
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List Header inside white card: Title + Sort + 3-dots
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 10, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      listTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
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

            // Task List
            Expanded(
              child: activeTasks.isEmpty && completedTasks.isEmpty
                  ? _EmptyTasksState(
                      listName: listTitle,
                      onAddTask: () => _showAddTaskSheet(defaultList: listTitle == 'Starred' ? 'My Tasks' : listTitle),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 84),
                      children: [
                        // Active Tasks
                        for (final task in activeTasks) ...[
                          _buildGoogleTaskRow(task),
                        ],

                        // Completed Tasks Section (collapsible card at bottom)
                        if (completedTasks.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isCompletedExpanded = !_isCompletedExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                children: [
                                  Text(
                                    'Completed (${completedTasks.length})',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: SlipTheme.carbon,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    _isCompletedExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 20,
                                    color: SlipTheme.steel,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isCompletedExpanded) ...[
                            for (final task in completedTasks) ...[
                              _buildGoogleTaskRow(task),
                            ],
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleTaskRow(TaskItem task) {
    final blunders = widget.provider.getBlundersForTask(task);
    final isExpanded = _expandedTaskId == task.id;
    final isSelected = _selectedTaskIds.contains(task.id);
    final hasSavedPeerTrap = blunders.any((s) => s.hasKept && s.authorId != widget.provider.currentUserId);

    final diff = task.scheduledAt.difference(DateTime.now());
    final isOverdue = !task.isCompleted && diff.isNegative;
    final String formattedDate = DateFormat('EEE, d MMM').format(task.scheduledAt);

    return InkWell(
      onTap: () {
        if (_isMultiSelect) {
          _toggleSelectTask(task.id);
        } else {
          setState(() {
            _expandedTaskId = isExpanded ? null : task.id;
          });
        }
      },
      onLongPress: () {
        _toggleSelectTask(task.id);
      },
      child: Container(
        color: isSelected ? SlipTheme.carbon.withOpacity(0.06) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Google Tasks Round Checkbox (or Checkbox in Multi-Select)
                if (_isMultiSelect)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleSelectTask(task.id),
                        activeColor: SlipTheme.carbon,
                        checkColor: SlipTheme.canvas,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
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
                          color: task.isCompleted ? SlipTheme.clearedGreen : SlipTheme.steel,
                          width: 1.5,
                        ),
                        color: task.isCompleted ? SlipTheme.clearedGreen : Colors.transparent,
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

                // Title + Due Date/Time + Traps Indicator
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: task.isCompleted ? SlipTheme.steel : SlipTheme.carbon,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Meta row: Date in red if due/overdue + Trap pill
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
                                color: isOverdue ? SlipTheme.trapRed : SlipTheme.steel,
                              ),
                              const SizedBox(width: 3.5),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isOverdue ? SlipTheme.trapRed : SlipTheme.steel,
                                ),
                              ),
                            ],
                          ),

                          // Trap indicator pill
                          if (blunders.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: SlipTheme.trapRed.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasSavedPeerTrap ? Icons.bookmark_added_rounded : Icons.warning_amber_rounded,
                                    size: 11,
                                    color: SlipTheme.trapRed,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    hasSavedPeerTrap
                                        ? '${blunders.length} TRAPS (SAVED PEER TRAP)'
                                        : '${blunders.length} TRAPS',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: SlipTheme.trapRed,
                                    ),
                                  ),
                                ],
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
                      task.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 20,
                      color: task.isStarred ? const Color(0xFFF9A825) : SlipTheme.steel,
                    ),
                  ),
                ),
              ],
            ),

            // Inoculation Trap Checklist (Expanded view)
            if (isExpanded) ...[
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.only(left: 36),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SlipTheme.surface,
                  border: Border.all(color: SlipTheme.hairline, width: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOPIC INOCULATION TRAPS (${blunders.length})',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: SlipTheme.steel,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (blunders.isEmpty)
                      const Text(
                        'No blunders logged yet for this topic. Tap "KEEP" on peer blunders or log your mistakes to attach revision traps here.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: SlipTheme.steel,
                          height: 1.35,
                        ),
                      )
                    else
                      ...blunders.map((b) => _BlunderPreviewRow(
                            slip: b,
                            currentUserId: widget.provider.currentUserId,
                          )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
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
                      placeholder: 'e.g. Do probability homework, Mock test, Formula revision',
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
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: SlipTheme.hairline, width: 0.8),
                        borderRadius: BorderRadius.circular(2),
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
                            borderRadius: BorderRadius.circular(2),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: SlipTheme.hairline, width: 0.8),
                        borderRadius: BorderRadius.circular(2),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: SlipTheme.hairline, width: 0.8),
                        borderRadius: BorderRadius.circular(2),
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

class _BlunderPreviewRow extends StatelessWidget {
  final Slip slip;
  final String? currentUserId;

  const _BlunderPreviewRow({required this.slip, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final isSavedPeer = slip.hasKept && slip.authorId != currentUserId;
    final isMine = slip.authorId != null && slip.authorId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: SlipTheme.canvas,
        border: Border.all(color: SlipTheme.hairline, width: 0.6),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSavedPeer ? Icons.bookmark_added_rounded : Icons.warning_amber_rounded,
                size: 11,
                color: SlipTheme.trapRed,
              ),
              const SizedBox(width: 4),
              Text(
                isSavedPeer
                    ? 'SAVED PEER TRAP · @${slip.authorUsername ?? "peer"}'
                    : (isMine ? 'MY LOGGED TRAP' : 'PEER TRAP · @${slip.authorUsername ?? "peer"}'),
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: SlipTheme.trapRed,
                ),
              ),
              const Spacer(),
              Text(
                slip.subtopic ?? slip.topic,
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: SlipTheme.steel,
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
              fontSize: 10,
              color: SlipTheme.steel,
            ),
          ),
        ],
      ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
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
