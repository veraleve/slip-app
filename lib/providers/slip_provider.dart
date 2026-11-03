import 'package:flutter/foundation.dart';
import '../models/slip.dart';
import '../services/supabase_service.dart';

class SlipProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<Slip> _slips = [];
  bool _isLoading = false;
  int _activeTabIndex = 0;
  String _selectedTopicFilter = 'All';

  List<Slip> get slips {
    if (_selectedTopicFilter == 'All') return _slips;
    return _slips.where((s) => s.topic == _selectedTopicFilter).toList();
  }

  bool get isLoading => _isLoading;
  int get activeTabIndex => _activeTabIndex;
  String get selectedTopicFilter => _selectedTopicFilter;

  // Counts for profile
  int get sharedCount => _slips.where((s) => s.authorId != null).length;
  int get clearedCount => _slips.where((s) => s.hasCleared).length;
  int get savedCount => _slips.where((s) => s.hasKept).length;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    _slips = await _service.fetchStream();
    _isLoading = false;
    notifyListeners();
  }

  void setTabIndex(int index) {
    if (_activeTabIndex != index) {
      _activeTabIndex = index;
      notifyListeners();
    }
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

  // 5. Submit new slip
  Future<bool> dropSlip({
    required String topic,
    required String subtopic,
    required String trapStatement,
    required String fixStatement,
    int audioDurationSeconds = 0,
  }) async {
    final newSlip = Slip(
      id: 'slip-${DateTime.now().millisecondsSinceEpoch}',
      topic: topic,
      subtopic: subtopic,
      trapStatement: trapStatement,
      fixStatement: fixStatement,
      audioDurationSeconds: audioDurationSeconds,
      createdAt: DateTime.now(),
      authorId: _service.currentUserId ?? 'current_user',
    );

    _slips.insert(0, newSlip);
    notifyListeners();

    final success = await _service.submitSlip(newSlip);
    return success;
  }
}
