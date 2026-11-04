import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/slip.dart';
import '../models/task_item.dart';
import '../services/supabase_service.dart';

class SlipProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<Slip> _slips = [];
  List<TaskItem> _tasks = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _activeTabIndex = 0;
  String _selectedExamFilter = 'All';
  String _selectedTopicFilter = 'All';
  String _selectedSubjectFilter = 'All';
  String _selectedSubtopicFilter = 'All Topics';
  PostType? _selectedPostTypeFilter;

  List<Slip> get slips {
    var result = _slips;
    if (_selectedExamFilter != 'All') {
      final normFilter = GateSyllabus.normalizeExam(_selectedExamFilter);
      result = result.where((s) =>
          GateSyllabus.normalizeExam(s.examTag) == normFilter ||
          s.examTag == 'General' ||
          s.topic == 'General').toList();
    } else {
      // When 'All' is selected, include all slips matching ANY of the user's registered exams
      final userExamSet = _service.targetExams.map(GateSyllabus.normalizeExam).toSet();
      result = result.where((s) {
        if (s.examTag == null || s.examTag!.isEmpty) return true;
        if (s.examTag == 'General' || s.topic == 'General') return true;
        return userExamSet.isEmpty || userExamSet.contains(GateSyllabus.normalizeExam(s.examTag));
      }).toList();
    }

    if (_selectedPostTypeFilter != null) {
      result = result.where((s) => s.postType == _selectedPostTypeFilter).toList();
    }

    if (_selectedSubjectFilter != 'All') {
      if (_selectedSubjectFilter == 'General') {
        result = result.where((s) => s.examTag == 'General' || s.topic == 'General' || s.subtopic == 'General').toList();
      } else {
        result = result.where((s) => s.topic == _selectedSubjectFilter).toList();
      }
    }

    if (_selectedSubtopicFilter != 'All Topics') {
      result = result.where((s) => s.subtopic == _selectedSubtopicFilter).toList();
    }

    if (_selectedTopicFilter != 'All' && _selectedTopicFilter != 'For You' && _selectedSubjectFilter == 'All') {
      if (_selectedTopicFilter == 'General') {
        result = result.where((s) => s.examTag == 'General' || s.topic == 'General' || s.subtopic == 'General').toList();
      } else {
        result = result.where((s) => s.topic == _selectedTopicFilter).toList();
      }
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  List<TaskItem> get tasks => List.unmodifiable(_tasks);

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  int get activeTabIndex => _activeTabIndex;
  String get selectedExamFilter => _selectedExamFilter;
  String get selectedTopicFilter => _selectedTopicFilter;
  String get selectedSubjectFilter => _selectedSubjectFilter;
  String get selectedSubtopicFilter => _selectedSubtopicFilter;
  PostType? get selectedPostTypeFilter => _selectedPostTypeFilter;
  List<String> get userExams => _service.targetExams;
  String? get currentUserId => _service.currentUserId;
  String? get currentUsername => _service.currentUsername;
  List<Slip> get allSlips => List.unmodifiable(_slips);

  // Counts for profile (accurately reflects user's own doubts & blunders)
  int get sharedCount {
    final uid = _service.currentUserId;
    final uname = _service.currentUsername?.toLowerCase().trim();
    return _slips.where((s) {
      final matchesId = uid != null && s.authorId == uid;
      final matchesName = uname != null && s.authorUsername?.toLowerCase().trim() == uname;
      return matchesId || matchesName;
    }).length;
  }

  int get sharedDoubtsCount {
    final uid = _service.currentUserId;
    final uname = _service.currentUsername?.toLowerCase().trim();
    return _slips.where((s) {
      final isAuthor = (uid != null && s.authorId == uid) ||
          (uname != null && s.authorUsername?.toLowerCase().trim() == uname);
      return isAuthor && s.postType == PostType.doubt;
    }).length;
  }

  int get sharedMistakesCount {
    final uid = _service.currentUserId;
    final uname = _service.currentUsername?.toLowerCase().trim();
    return _slips.where((s) {
      final isAuthor = (uid != null && s.authorId == uid) ||
          (uname != null && s.authorUsername?.toLowerCase().trim() == uname);
      return isAuthor && s.postType == PostType.mistake;
    }).length;
  }

  int get clearedCount => _slips.where((s) => s.hasCleared).length;
  int get savedCount => _slips.where((s) => s.hasKept).length;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    // Allow all papers the user targets (or All if none)
    _slips = await _service.fetchStream(userPapers: _service.targetExams.isNotEmpty ? _service.targetExams : ['All']);
    await _loadTasks();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshStream() async {
    _isLoading = true;
    notifyListeners();
    final allowedPapers = _selectedExamFilter == 'All'
        ? (_service.targetExams.isNotEmpty ? _service.targetExams : ['All'])
        : [_selectedExamFilter];
    _slips = await _service.fetchStream(userPapers: allowedPapers);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUserExams(List<String> exams) async {
    await _service.updateTargetExams(exams);
    _selectedExamFilter = 'All';
    _selectedSubjectFilter = 'All';
    _selectedSubtopicFilter = 'All Topics';
    _selectedTopicFilter = 'All';
    await refreshStream();
    notifyListeners();
  }

  Future<void> updateTargetExams(List<String> exams) => updateUserExams(exams);

  Future<void> loadMoreSlips() async {
    if (_isLoadingMore || _slips.isEmpty) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final oldestTimestamp = _slips.last.createdAt;
      final olderSlips = await _service.fetchOlderSlips(beforeTimestamp: oldestTimestamp);
      if (olderSlips.isNotEmpty) {
        final existingIds = _slips.map((s) => s.id).toSet();
        for (final slip in olderSlips) {
          if (!existingIds.contains(slip.id)) {
            _slips.add(slip);
          }
        }
      }
    } catch (_) {}
    _isLoadingMore = false;
    notifyListeners();
  }

  List<String> _customLists = [];
  List<String> get customLists => List.unmodifiable(_customLists);

  String get _scopedCustomListsKey {
    final user = (_service.currentUsername ?? 'guest').toLowerCase().trim();
    return 'slip_custom_task_lists_$user';
  }

  // --- TASKS / MOCK TEST REMINDER ENGINE ---
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    _customLists = prefs.getStringList(_scopedCustomListsKey) ?? prefs.getStringList('slip_custom_task_lists') ?? [];

    final raw = await _service.loadTasksRaw();
    if (raw.isNotEmpty) {
      _tasks = raw.map((str) => TaskItem.deserialize(str)).toList();
      _tasks.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    } else {
      // Empty slate (no placeholder tasks)
      _tasks = [];
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
    await prefs.setStringList(_scopedCustomListsKey, _customLists);
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
    await prefs.setStringList(_scopedCustomListsKey, _customLists);
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
    await prefs.setStringList(_scopedCustomListsKey, _customLists);
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
      // Must be a blunder/mistake OR saved by user from peer feed
      final isBlunder = slip.postType == PostType.mistake || slip.hasKept;
      if (!isBlunder) return false;

      // Match subject or title keywords
      final matchesSubject = slip.topic.trim().toLowerCase() == task.subject.trim().toLowerCase();
      final matchesTitle = task.title.toLowerCase().contains(slip.topic.toLowerCase()) ||
          (slip.subtopic != null && task.title.toLowerCase().contains(slip.subtopic!.toLowerCase()));

      if (!matchesSubject && !matchesTitle) return false;

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
    _selectedTopicFilter = 'All'; // Reset to All on exam switch
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
    _selectedTopicFilter = 'All';
    notifyListeners();
  }

  // 1. Same reaction ("I fell for this too")
  void toggleSame(String slipId) {
    final index = _slips.indexWhere((s) => s.id == slipId);
    if (index == -1) return;

    final current = _slips[index];
    final newState = !current.hasSaidSame;
    final newCount = newState ? current.sameCount + 1 : current.sameCount - 1;
    final safeCount = newCount < 0 ? 0 : newCount;

    _slips[index] = current.copyWith(
      hasSaidSame: newState,
      sameCount: safeCount,
    );
    notifyListeners();

    _service.updateSlipSameCount(slipId, safeCount, hasSaidSame: newState);
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

    // If user is saving someone else's blunder, auto-record a task in Tasks if no active task matches
    if (newState) {
      final hasMatchingTask = _tasks.any((t) =>
          !t.isCompleted &&
          (t.subject.trim().toLowerCase() == updated.topic.trim().toLowerCase() ||
              t.title.toLowerCase().contains(updated.topic.toLowerCase())));
      if (!hasMatchingTask) {
        final autoTask = TaskItem(
          id: 'task_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Revise ${updated.topic} Traps',
          examTag: updated.examTag,
          subject: updated.topic,
          topics: updated.subtopic != null ? [updated.subtopic!] : ['All Topics'],
          scheduledAt: DateTime.now().add(const Duration(days: 2)),
          listName: 'My Tasks',
          createdAt: DateTime.now(),
        );
        _tasks.insert(0, autoTask);
        await _persistTasks();
      }
    }

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

    _service.setSlipCleared(slipId, newState);
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

  // 4c. Toggle Comment Accepted Solution
  Future<void> toggleCommentAccepted({
    required String slipId,
    required String commentId,
    required bool isAccepted,
  }) async {
    await _service.toggleCommentAccepted(
      slipId: slipId,
      commentId: commentId,
      isAccepted: isAccepted,
    );
    if (isAccepted) {
      final index = _slips.indexWhere((s) => s.id == slipId);
      if (index != -1) {
        _slips[index] = _slips[index].copyWith(isResolved: true);
      }
    }
    notifyListeners();
  }

  void setPostTypeFilter(PostType? filter) {
    _selectedPostTypeFilter = filter;
    notifyListeners();
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
    String? voiceAudioUrl,
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
      voiceAudioUrl: voiceAudioUrl,
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

  // --- Comments & Reddit-style Threaded Replies ---
  Future<List<Map<String, dynamic>>> fetchComments(String slipId) async {
    return await _service.fetchComments(slipId);
  }

  Future<bool> postComment({
    required String slipId,
    required String body,
    String? parentId,
  }) async {
    final success = await _service.postComment(
      slipId: slipId,
      body: body,
      parentId: parentId,
    );
    if (success) {
      final index = _slips.indexWhere((s) => s.id == slipId);
      if (index != -1) {
        _slips[index] = _slips[index].copyWith(
          commentsCount: _slips[index].commentsCount + 1,
        );
      }
    }
    notifyListeners();
    return success;
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
