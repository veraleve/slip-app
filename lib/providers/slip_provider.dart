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

  List<Slip> get slips {
    var result = _slips;
    if (_selectedExamFilter != 'All') {
      result = result.where((s) => s.examTag == _selectedExamFilter).toList();
    }
    if (_selectedTopicFilter == 'For You') {
      // Prioritize recommended peer blunders (unmastered, high sameCount, recent)
      final recs = List<Slip>.from(result);
      recs.sort((a, b) {
        final aScore = (a.sameCount * 2) + (a.keepCount * 3) - (a.hasCleared ? 10 : 0);
        final bScore = (b.sameCount * 2) + (b.keepCount * 3) - (b.hasCleared ? 10 : 0);
        return bScore.compareTo(aScore);
      });
      return recs;
    } else if (_selectedTopicFilter != 'All') {
      result = result.where((s) => s.topic == _selectedTopicFilter).toList();
    }
    return result;
  }

  List<TaskItem> get tasks => List.unmodifiable(_tasks);

  bool get isLoading => _isLoading;
  int get activeTabIndex => _activeTabIndex;
  String get selectedExamFilter => _selectedExamFilter;
  String get selectedTopicFilter => _selectedTopicFilter;
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

  // --- TASKS / MOCK TEST REMINDER ENGINE ---
  Future<void> _loadTasks() async {
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

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    await _persistTasks();
    notifyListeners();
  }

  // Cross-reference blunders relevant to a task's subject & syllabus topics
  List<Slip> getBlundersForTask(TaskItem task) {
    return _slips.where((slip) {
      // Match exam
      if (slip.examTag != task.examTag) return false;
      // Match subject
      final matchesSubject = slip.topic.trim().toLowerCase() == task.subject.trim().toLowerCase();
      // Match topics
      final matchesTopics = task.topics.any((topic) =>
          (slip.subtopic != null && slip.subtopic!.toLowerCase().contains(topic.toLowerCase())) ||
          slip.trapStatement.toLowerCase().contains(topic.toLowerCase()));
      return matchesSubject || matchesTopics;
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
    notifyListeners();
  }

  void setTopicFilter(String topic) {
    _selectedTopicFilter = topic;
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
  void toggleKeep(String slipId) {
    final index = _slips.indexWhere((s) => s.id == slipId);
    if (index == -1) return;

    final current = _slips[index];
    final newState = !current.hasKept;
    final newCount = newState ? current.keepCount + 1 : current.keepCount - 1;

    _slips[index] = current.copyWith(
      hasKept: newState,
      keepCount: newCount < 0 ? 0 : newCount,
    );
    notifyListeners();

    if (newState) {
      _service.recordInteraction(slipId: slipId, interactionType: 'keep');
    }
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

  // 5. Submit new slip (Public or Private)
  Future<bool> dropSlip({
    required String examTag,
    required String topic,
    required String subtopic,
    required String trapStatement,
    required String fixStatement,
    List<String> imageUris = const [],
    int audioDurationSeconds = 0,
    bool allowComments = true,
    bool isPublic = true,
  }) async {
    final newSlip = Slip(
      id: 'slip-${DateTime.now().millisecondsSinceEpoch}',
      examTag: examTag,
      topic: topic,
      subtopic: subtopic,
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
