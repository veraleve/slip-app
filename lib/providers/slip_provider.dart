import 'package:flutter/foundation.dart';
import '../models/slip.dart';
import '../models/task_item.dart';
import '../services/supabase_service.dart';

class SlipProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<Slip> _slips = [];
  List<TaskItem> _tasks = [];
  bool _isLoading = false;
  int _activeTabIndex = 0;
  String _selectedExamFilter = 'All';
  String _selectedTopicFilter = 'For You';
  String _selectedSubjectFilter = 'All';
  String _selectedSubtopicFilter = 'All Topics';

  List<Slip> get slips {
    var result = _slips;
    if (_selectedExamFilter != 'All') {
      result = result.where((s) => s.examTag == _selectedExamFilter).toList();
    }

    if (_selectedSubjectFilter != 'All') {
      result = result.where((s) => s.topic == _selectedSubjectFilter).toList();
    }

    if (_selectedSubtopicFilter != 'All Topics') {
      result = result.where((s) => s.subtopic == _selectedSubtopicFilter).toList();
    }

    if (_selectedTopicFilter == 'For You') {
      // Prioritize fresh posts and recommended peer blunders & doubts
      final recs = List<Slip>.from(result);
      final now = DateTime.now();
      recs.sort((a, b) {
        final hoursA = now.difference(a.createdAt).inHours;
        final hoursB = now.difference(b.createdAt).inHours;
        // Strong recency boost: brand-new posts appear directly at top
        final freshA = hoursA < 1 ? 500 : (hoursA < 6 ? 200 : (hoursA < 24 ? 60 : 0));
        final freshB = hoursB < 1 ? 500 : (hoursB < 6 ? 200 : (hoursB < 24 ? 60 : 0));

        final aScore = freshA + (a.sameCount * 2) + (a.keepCount * 3) - (a.hasCleared ? 20 : 0);
        final bScore = freshB + (b.sameCount * 2) + (b.keepCount * 3) - (b.hasCleared ? 20 : 0);
        if (aScore != bScore) return bScore.compareTo(aScore);
        return b.createdAt.compareTo(a.createdAt);
      });
      return recs;
    } else if (_selectedTopicFilter != 'All' && _selectedSubjectFilter == 'All') {
      result = result.where((s) => s.topic == _selectedTopicFilter).toList();
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  List<TaskItem> get tasks => List.unmodifiable(_tasks);

  bool get isLoading => _isLoading;
  int get activeTabIndex => _activeTabIndex;
  String get selectedExamFilter => _selectedExamFilter;
  String get selectedTopicFilter => _selectedTopicFilter;
  String get selectedSubjectFilter => _selectedSubjectFilter;
  String get selectedSubtopicFilter => _selectedSubtopicFilter;
  List<String> get userExams => _service.targetExams;

  // Counts for profile
  int get sharedCount => _slips.where((s) => s.authorId != null).length;
  int get clearedCount => _slips.where((s) => s.hasCleared).length;
  int get savedCount => _slips.where((s) => s.hasKept).length;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    // Strictly isolate to the user's registered papers
    _slips = await _service.fetchStream(userPapers: _service.targetExams);
    await _loadTasks();
    _isLoading = false;
    notifyListeners();
  }

  List<String> _customLists = [];
  List<String> get customLists => List.unmodifiable(_customLists);

  // --- TASKS / MOCK TEST REMINDER ENGINE ---
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    _customLists = prefs.getStringList('slip_custom_task_lists') ?? [];

    final raw = await _service.loadTasksRaw();
    if (raw.isNotEmpty) {
      _tasks = raw.map((str) => TaskItem.deserialize(str)).toList();
      _tasks.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    } else {
      // Default initial mock test reminder
      final userExams = _service.targetExams;
      final primary = userExams.isNotEmpty ? userExams.first : 'GATE CS';
      _tasks = [
        TaskItem(
          id: 'task-init-01',
          title: 'Full Length Mock Test 1',
          examTag: primary,
          subject: 'Linear Algebra',
          topics: ['Eigenvalues & Eigenvectors', 'Matrices & Determinants'],
          scheduledAt: DateTime.now().add(const Duration(days: 2, hours: 4)),
          createdAt: DateTime.now(),
        ),
      ];
      await _persistTasks();
    }
  }

  Future<void> _persistTasks() async {
    final raw = _tasks.map((t) => t.serialize()).toList();
    await _service.saveTasksRaw(raw);
  }

  Future<void> addTask(TaskItem task) async {
    _tasks.add(task);
    _tasks.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    await _persistTasks();
    notifyListeners();
  }

  Future<void> toggleTaskCompleted(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final current = _tasks[index];
    _tasks[index] = current.copyWith(isCompleted: !current.isCompleted);
    await _persistTasks();
    notifyListeners();
  }

  Future<void> toggleTaskStarred(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final current = _tasks[index];
    _tasks[index] = current.copyWith(isStarred: !current.isStarred);
    await _persistTasks();
    notifyListeners();
  }

  Future<void> addTaskList(String name) async {
    final clean = name.trim();
    if (clean.isEmpty || clean == 'My Tasks' || clean == 'Starred' || _customLists.contains(clean)) return;
    _customLists.add(clean);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('slip_custom_task_lists', _customLists);
    notifyListeners();
  }

  Future<void> deleteTaskList(String name) async {
    _customLists.remove(name);
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].listName == name) {
        _tasks[i] = _tasks[i].copyWith(listName: 'My Tasks');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('slip_custom_task_lists', _customLists);
    await _persistTasks();
    notifyListeners();
  }

  Future<void> renameTaskList(String oldName, String newName) async {
    final clean = newName.trim();
    if (clean.isEmpty || clean == oldName) return;
    final idx = _customLists.indexOf(oldName);
    if (idx != -1) {
      _customLists[idx] = clean;
    }
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].listName == oldName) {
        _tasks[i] = _tasks[i].copyWith(listName: clean);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('slip_custom_task_lists', _customLists);
    await _persistTasks();
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    await _persistTasks();
    notifyListeners();
  }

  Future<void> deleteMultipleTasks(Iterable<String> taskIds) async {
    final idSet = taskIds.toSet();
    _tasks.removeWhere((t) => idSet.contains(t.id));
    await _persistTasks();
    notifyListeners();
  }

  // Cross-reference blunders relevant to a task's subject & syllabus topics
  // Includes blunders authored by user AND blunders saved by user from peers
  List<Slip> getBlundersForTask(TaskItem task) {
    return _slips.where((slip) {
      // Match exam
      if (slip.examTag != task.examTag) return false;

      // Must be a blunder/mistake OR saved by user from peer feed
      final isBlunder = slip.postType == PostType.mistake || slip.hasKept;
      if (!isBlunder) return false;

      // Match subject
      final matchesSubject = slip.topic.trim().toLowerCase() == task.subject.trim().toLowerCase();
      if (!matchesSubject) return false;

      // If task has specific subtopics (not empty, and not 'All Topics')
      if (task.topics.isNotEmpty && !task.topics.contains('All Topics')) {
        final matchesTopics = task.topics.any((topic) =>
            (slip.subtopic != null && slip.subtopic!.toLowerCase().contains(topic.toLowerCase())) ||
            slip.trapStatement.toLowerCase().contains(topic.toLowerCase()) ||
            (slip.title != null && slip.title!.toLowerCase().contains(topic.toLowerCase())));
        return matchesTopics;
      }

      // If 'All Topics' or no subtopic restriction, all subject blunders (authored + saved) match
      return true;
    }).toList();
  }

  void setTabIndex(int index) {
    if (_activeTabIndex != index) {
      _activeTabIndex = index;
      notifyListeners();
    }
  }

  void setExamFilter(String exam) {
    _selectedExamFilter = exam;
    _selectedTopicFilter = 'For You'; // Reset topic filter to recommendation on exam switch
    _selectedSubjectFilter = 'All';
    _selectedSubtopicFilter = 'All Topics';
    notifyListeners();
  }

  void setTopicFilter(String topic) {
    _selectedTopicFilter = topic;
    notifyListeners();
  }

  void setSubjectFilter(String subject) {
    _selectedSubjectFilter = subject;
    _selectedSubtopicFilter = 'All Topics';
    _selectedTopicFilter = subject;
    notifyListeners();
  }

  void setSubtopicFilter(String subtopic) {
    _selectedSubtopicFilter = subtopic;
    notifyListeners();
  }

  void resetCascadingFilters() {
    _selectedSubjectFilter = 'All';
    _selectedSubtopicFilter = 'All Topics';
    _selectedTopicFilter = 'For You';
    notifyListeners();
  }

  // 1. Same reaction ("I fell for this too")
  void toggleSame(String slipId) {
    final index = _slips.indexWhere((s) => s.id == slipId);
    if (index == -1) return;

    final current = _slips[index];
    final newState = !current.hasSaidSame;
    final newCount = newState ? current.sameCount + 1 : current.sameCount - 1;

    _slips[index] = current.copyWith(
      hasSaidSame: newState,
      sameCount: newCount < 0 ? 0 : newCount,
    );
    notifyListeners();

    if (newState) {
      _service.recordInteraction(slipId: slipId, interactionType: 'same');
    }
  }

  // 2. The Fix toggle (reveal solution)
  void toggleFixRevealed(String slipId) {
    final index = _slips.indexWhere((s) => s.id == slipId);
    if (index == -1) return;

    final current = _slips[index];
    _slips[index] = current.copyWith(
      isFixRevealed: !current.isFixRevealed,
    );
    notifyListeners();

    _service.recordInteraction(slipId: slipId, interactionType: 'fix_revealed');
  }

  // 3. Keep (Save to revision)
  Future<void> toggleKeep(String slipId) async {
    final index = _slips.indexWhere((s) => s.id == slipId);
    if (index == -1) return;

    final current = _slips[index];
    final newState = !current.hasKept;
    final newCount = newState ? current.keepCount + 1 : current.keepCount - 1;

    final updated = current.copyWith(
      hasKept: newState,
      keepCount: newCount < 0 ? 0 : newCount,
    );
    _slips[index] = updated;
    notifyListeners();

    await _service.setSlipSaved(updated, newState);
  }

  // 4. Cleared (Mastered)
  void toggleCleared(String slipId) {
    final index = _slips.indexWhere((s) => s.id == slipId);
    if (index == -1) return;

    final current = _slips[index];
    final newState = !current.hasCleared;
    final newCount =
        newState ? current.clearedCount + 1 : current.clearedCount - 1;

    _slips[index] = current.copyWith(
      hasCleared: newState,
      clearedCount: newCount < 0 ? 0 : newCount,
    );
    notifyListeners();

    if (newState) {
      _service.recordInteraction(slipId: slipId, interactionType: 'cleared');
    }
  }

  // 4b. Toggle Doubt Resolved Status
  void toggleDoubtResolved(String slipId) {
    final index = _slips.indexWhere((s) => s.id == slipId);
    if (index == -1) return;

    final current = _slips[index];
    final newState = !current.isResolved;

    _slips[index] = current.copyWith(isResolved: newState);
    notifyListeners();

    _service.toggleDoubtResolved(slipId, newState);
  }

  // 5. Submit new slip (Doubt or Mistake, Public or Private)
  Future<bool> dropSlip({
    required String examTag,
    required String topic,
    required String subtopic,
    required String trapStatement,
    String fixStatement = '',
    PostType postType = PostType.doubt,
    String? title,
    bool isResolved = false,
    List<String> imageUris = const [],
    int audioDurationSeconds = 0,
    bool allowComments = true,
    bool isPublic = true,
  }) async {
    final newSlip = Slip(
      id: SupabaseService.generateUuid(),
      examTag: examTag,
      topic: topic,
      subtopic: subtopic,
      postType: postType,
      title: title,
      isResolved: isResolved,
      trapStatement: trapStatement,
      fixStatement: fixStatement,
      imageUris: imageUris,
      audioDurationSeconds: audioDurationSeconds,
      createdAt: DateTime.now(),
      authorId: _service.currentUserId ?? 'current_user',
      authorUsername: _service.currentUsername ?? 'peer_you',
      allowComments: allowComments,
      isPublic: isPublic,
    );

    _slips.insert(0, newSlip);
    notifyListeners();

    if (isPublic) {
      final success = await _service.submitSlip(newSlip);
      return success;
    } else {
      // Private: strictly stored in local device space
      final local = await _service.loadLocalUserSlips();
      local.insert(0, newSlip);
      await _service.saveLocalUserSlips(local);
      return true;
    }
  }

  // 6. Update existing slip
  Future<bool> updateSlip(Slip updatedSlip) async {
    final index = _slips.indexWhere((s) => s.id == updatedSlip.id);
    if (index != -1) {
      _slips[index] = updatedSlip;
      notifyListeners();
    }
    return await _service.updateSlip(updatedSlip);
  }

  // 7. Delete blunder post
  Future<bool> deleteSlip(String slipId) async {
    _slips.removeWhere((s) => s.id == slipId);
    notifyListeners();
    return await _service.deleteSlip(slipId);
  }
}
