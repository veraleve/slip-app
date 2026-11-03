import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import '../constants/app_constants.dart';
import '../constants/gate_syllabus.dart';
import '../models/profile.dart';
import '../models/slip.dart';
import 'mock_data_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  String? _currentUsername;
  String? _currentUserId;
  List<String> _targetExams = [GateSyllabus.gateCS];

  Future<void> initialize() async {
    try {
      _client = SupabaseClient(
        AppConstants.supabaseUrl,
        AppConstants.supabaseAnonKey,
      );

      // Restore cached session
      final prefs = await SharedPreferences.getInstance();
      _currentUsername = prefs.getString('slip_username');
      _currentUserId = prefs.getString('slip_user_id');
      final savedExams = prefs.getStringList('slip_target_exams');
      if (savedExams != null && savedExams.isNotEmpty) {
        _targetExams = savedExams;
      }
    } catch (_) {
      // Offline fallback
    }
  }

  SupabaseClient? get client => _client;
  bool get isAuthenticated => _currentUsername != null && _currentUsername!.isNotEmpty;
  String? get currentUsername => _currentUsername;
  String? get currentUserId => _currentUserId ?? 'peer_local';
  List<String> get targetExams => List.unmodifiable(_targetExams);
  String get primaryExam => _targetExams.isNotEmpty ? _targetExams.first : GateSyllabus.gateCS;

  void updateTargetExams(List<String> exams) {
    if (exams.isEmpty) return;
    _targetExams = List.from(exams);
    SharedPreferences.getInstance().then((p) => p.setStringList('slip_target_exams', _targetExams));

    if (_client != null && _currentUserId != null) {
      _client!.from('profiles').update({
        'target_exams': _targetExams,
        'target_exam': primaryExam,
      }).eq('id', _currentUserId!).catchError((_) {});
    }
  }

  String _toInternalEmail(String username) {
    final clean = username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return '$clean@slip.internal';
  }

  // --- 1. INSTANT BLE MESH / ANONYMOUS PEER ENTRY ---
  Future<bool> signInAsMeshPeer({
    String? customHandle,
    List<String> targetExams = const [GateSyllabus.gateCS],
  }) async {
    final randomHex = (Random().nextInt(0xFFFFFF) + 0x100000).toRadixString(16);
    final handle = (customHandle != null && customHandle.trim().isNotEmpty)
        ? customHandle.trim()
        : 'peer_$randomHex';
    
    final uid = 'mesh_${DateTime.now().millisecondsSinceEpoch}_$randomHex';
    final resolvedExams = targetExams.isNotEmpty ? targetExams : [GateSyllabus.gateCS];

    await _persistSession(handle, uid, resolvedExams);

    // Sync profile to Supabase if connected
    if (_client != null) {
      try {
        await _client!.from('profiles').upsert({
          'id': uid,
          'handle': handle,
          'target_exams': resolvedExams,
          'target_exam': resolvedExams.first,
        });
      } catch (_) {}
    }

    return true;
  }

  // --- 2. USERNAME & PASSWORD AUTHENTICATION ---
  Future<bool> signInWithUsername({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty || password.isEmpty) return false;

    if (_client == null) {
      await _persistSession(cleanUsername, 'user_${cleanUsername.toLowerCase()}', _targetExams);
      return true;
    }

    try {
      final email = _toInternalEmail(cleanUsername);
      final res = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        // Fetch user profile to restore their chosen exams
        List<String> userExams = _targetExams;
        try {
          final pRes = await _client!.from('profiles').select().eq('id', res.user!.id).limit(1);
          final pList = pRes as List;
          if (pList.isNotEmpty) {
            final pObj = Profile.fromJson(pList.first as Map<String, dynamic>);
            userExams = pObj.targetExams;
          }
        } catch (_) {}

        await _persistSession(cleanUsername, res.user!.id, userExams);
        return true;
      }
    } catch (_) {
      // Graceful fallback for local or pre-created user
      try {
        final profileRes = await _client!
            .from('profiles')
            .select()
            .eq('handle', cleanUsername)
            .limit(1);
        final list = profileRes as List;
        if (list.isNotEmpty) {
          final p = list.first as Map<String, dynamic>;
          final pObj = Profile.fromJson(p);
          await _persistSession(cleanUsername, pObj.id, pObj.targetExams);
          return true;
        }
      } catch (_) {}
    }

    await _persistSession(cleanUsername, 'user_${cleanUsername.toLowerCase()}', _targetExams);
    return true;
  }

  Future<bool> signUpWithUsername({
    required String username,
    required String password,
    List<String> targetExams = const [GateSyllabus.gateCS],
  }) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty || password.isEmpty) return false;

    final resolvedExams = targetExams.isNotEmpty ? targetExams : [GateSyllabus.gateCS];
    String uid = 'user_${cleanUsername.toLowerCase()}_${Random().nextInt(9999)}';

    if (_client != null) {
      try {
        final email = _toInternalEmail(cleanUsername);
        final res = await _client!.auth.signUp(
          email: email,
          password: password,
          data: {'handle': cleanUsername},
        );
        if (res.user != null) {
          uid = res.user!.id;
        }
      } catch (_) {
        // Direct profile fallback
      }

      try {
        await _client!.from('profiles').upsert({
          'id': uid,
          'handle': cleanUsername,
          'target_exams': resolvedExams,
          'target_exam': resolvedExams.first,
        });
      } catch (_) {}
    }

    await _persistSession(cleanUsername, uid, resolvedExams);
    return true;
  }

  Future<void> _persistSession(String username, String userId, List<String> exams) async {
    _currentUsername = username;
    _currentUserId = userId;
    _targetExams = List.from(exams);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('slip_username', username);
    await prefs.setString('slip_user_id', userId);
    await prefs.setStringList('slip_target_exams', _targetExams);
  }

  Future<void> signOut() async {
    _currentUsername = null;
    _currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('slip_username');
    await prefs.remove('slip_user_id');

    if (_client != null) {
      try {
        await _client!.auth.signOut();
      } catch (_) {}
    }
  }

  static String generateUuid() {
    final rnd = Random();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant RFC4122
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  static bool isUuid(String str) {
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(str);
  }

  // --- LOCAL-FIRST OFFLINE STORAGE FOR USER SLIPS ---
  Future<List<Slip>> loadLocalUserSlips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList('slip_local_user_slips') ?? [];
      return rawList.map((str) => Slip.fromJson(jsonDecode(str) as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLocalUserSlips(List<Slip> slips) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userSlips = slips.where((s) => s.authorId != null && s.authorId == _currentUserId).toList();
      final List<String> rawList = userSlips.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList('slip_local_user_slips', rawList);
    } catch (_) {}
  }

  Future<List<Slip>> fetchStream({
    String? topicFilter,
    String? subtopicFilter,
    PostType? postTypeFilter,
    List<String>? userPapers,
  }) async {
    final allowedPapers = (userPapers != null && userPapers.isNotEmpty)
        ? userPapers
        : _targetExams;

    // 1. Always load local user slips first (instant offline availability)
    final localUserSlips = await loadLocalUserSlips();

    if (_client == null) {
      final mock = MockDataService.getInitialSlips();
      var combined = [...localUserSlips, ...mock.where((s) => allowedPapers.contains(s.examTag))];
      if (postTypeFilter != null) {
        combined = combined.where((s) => s.postType == postTypeFilter).toList();
      }
      if (topicFilter != null && topicFilter.isNotEmpty && topicFilter != 'All' && topicFilter != 'For You') {
        combined = combined.where((s) => s.topic == topicFilter).toList();
      }
      if (subtopicFilter != null && subtopicFilter.isNotEmpty && subtopicFilter != 'All Topics') {
        combined = combined.where((s) => s.subtopic == subtopicFilter).toList();
      }
      return combined;
    }

    try {
      var query = _client!.from('slips').select();

      // Strict Paper Isolation: only fetch slips matching user's registered papers
      if (allowedPapers.length == 1) {
        query = query.eq('exam_tag', allowedPapers.first);
      } else if (allowedPapers.length > 1) {
        query = query.inFilter('exam_tag', allowedPapers);
      }

      if (postTypeFilter != null) {
        query = query.eq('post_type', postTypeFilter.name);
      }

      if (topicFilter != null && topicFilter.isNotEmpty && topicFilter != 'All' && topicFilter != 'For You') {
        query = query.eq('topic', topicFilter);
      }

      if (subtopicFilter != null && subtopicFilter.isNotEmpty && subtopicFilter != 'All Topics') {
        query = query.eq('subtopic', subtopicFilter);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(60);
      final list = response as List;

      final fetched = list
          .map((item) => Slip.fromJson(item as Map<String, dynamic>))
          .toList();

      final Map<String, Slip> merged = {};
      for (final s in localUserSlips) {
        merged[s.id] = s;
      }
      for (final s in fetched) {
        merged[s.id] = s;
      }

      var result = merged.values.toList();
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (postTypeFilter != null) {
        result = result.where((s) => s.postType == postTypeFilter).toList();
      }
      if (topicFilter != null && topicFilter.isNotEmpty && topicFilter != 'All' && topicFilter != 'For You') {
        result = result.where((s) => s.topic == topicFilter).toList();
      }
      if (subtopicFilter != null && subtopicFilter.isNotEmpty && subtopicFilter != 'All Topics') {
        result = result.where((s) => s.subtopic == subtopicFilter).toList();
      }

      return result;
    } catch (e) {
      // Offline fallback: return user's local slips + mock data
      final mock = MockDataService.getInitialSlips();
      var combined = [...localUserSlips, ...mock.where((s) => allowedPapers.contains(s.examTag))];
      if (postTypeFilter != null) {
        combined = combined.where((s) => s.postType == postTypeFilter).toList();
      }
      if (topicFilter != null && topicFilter.isNotEmpty && topicFilter != 'All' && topicFilter != 'For You') {
        combined = combined.where((s) => s.topic == topicFilter).toList();
      }
      if (subtopicFilter != null && subtopicFilter.isNotEmpty && subtopicFilter != 'All Topics') {
        combined = combined.where((s) => s.subtopic == subtopicFilter).toList();
      }
      return combined;
    }
  }

  Future<void> recordInteraction({
    required String slipId,
    required String interactionType,
  }) async {
    if (_client == null || _currentUserId == null) return;
    try {
      await _client!.from('slip_interactions').upsert({
        'user_id': _currentUserId,
        'slip_id': slipId,
        'interaction_type': interactionType,
      });
    } catch (_) {}
  }

  Future<bool> submitSlip(Slip slip) async {
    // 1. Immediately cache locally for offline access
    final local = await loadLocalUserSlips();
    local.removeWhere((s) => s.id == slip.id);
    local.insert(0, slip);
    await saveLocalUserSlips(local);

    if (_client == null) return true;
    try {
      String? validAuthorId;
      if (slip.authorId != null && isUuid(slip.authorId!)) {
        validAuthorId = slip.authorId;
      }

      await _client!.from('slips').insert({
        'id': slip.id,
        'topic': slip.topic,
        'subtopic': slip.subtopic,
        'exam_tag': slip.examTag,
        'post_type': slip.postType.name,
        'title': slip.title,
        'is_resolved': slip.isResolved,
        'is_public': slip.isPublic,
        'trap_statement': slip.trapStatement,
        'fix_statement': slip.fixStatement,
        'scratchpad_image_url': slip.imageUris.isNotEmpty ? slip.imageUris.first : null,
        'author_id': validAuthorId,
        'author_handle': slip.authorUsername ?? _currentUsername ?? 'peer',
        'audio_duration_seconds': slip.audioDurationSeconds,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleDoubtResolved(String slipId, bool isResolved) async {
    final local = await loadLocalUserSlips();
    final idx = local.indexWhere((s) => s.id == slipId);
    if (idx != -1) {
      local[idx] = local[idx].copyWith(isResolved: isResolved);
      await saveLocalUserSlips(local);
    }

    if (_client != null) {
      try {
        await _client!.from('slips').update({
          'is_resolved': isResolved,
        }).eq('id', slipId);
        return true;
      } catch (_) {}
    }
    return true;
  }

  Future<bool> updateSlip(Slip slip) async {
    // 1. Immediately update locally
    final local = await loadLocalUserSlips();
    final idx = local.indexWhere((s) => s.id == slip.id);
    if (idx != -1) {
      local[idx] = slip;
      await saveLocalUserSlips(local);
    }

    if (_client == null) return true;
    try {
      await _client!.from('slips').update({
        'topic': slip.topic,
        'subtopic': slip.subtopic,
        'exam_tag': slip.examTag,
        'post_type': slip.postType.name,
        'title': slip.title,
        'is_resolved': slip.isResolved,
        'trap_statement': slip.trapStatement,
        'fix_statement': slip.fixStatement,
        'scratchpad_image_url': slip.imageUris.isNotEmpty ? slip.imageUris.first : null,
        'audio_duration_seconds': slip.audioDurationSeconds,
      }).eq('id', slip.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteSlip(String slipId) async {
    // 1. Immediately delete locally
    final local = await loadLocalUserSlips();
    local.removeWhere((s) => s.id == slipId);
    await saveLocalUserSlips(local);

    if (_client == null) return true;
    try {
      await _client!.from('slips').delete().eq('id', slipId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- 5. TASKS / MOCK TEST REMINDER STORAGE (OFFLINE-FIRST) ---
  Future<List<String>> loadTasksRaw() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('slip_local_tasks') ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTasksRaw(List<String> rawTasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('slip_local_tasks', rawTasks);
    } catch (_) {}
  }

  // --- 4. COMMENTS SYSTEM (HYBRID SYNC) ---
  final Map<String, List<Map<String, dynamic>>> _localCommentsCache = {};

  Future<List<Map<String, dynamic>>> fetchComments(String slipId) async {
    if (_client != null) {
      try {
        final res = await _client!
            .from('slip_comments')
            .select()
            .eq('slip_id', slipId)
            .order('created_at', ascending: true);
        final list = res as List;
        if (list.isNotEmpty) {
          return list.map((e) => e as Map<String, dynamic>).toList();
        }
      } catch (_) {}
    }
    return _localCommentsCache[slipId] ?? [];
  }

  Future<bool> postComment({
    required String slipId,
    required String body,
    bool isAcceptedAnswer = false,
  }) async {
    final comment = {
      'id': generateUuid(),
      'slip_id': slipId,
      'author_handle': _currentUsername ?? 'peer',
      'body': body,
      'is_accepted_answer': isAcceptedAnswer,
      'created_at': DateTime.now().toIso8601String(),
    };

    _localCommentsCache.putIfAbsent(slipId, () => []).add(comment);

    if (_client != null) {
      try {
        await _client!.from('slip_comments').insert(comment);
      } catch (_) {}
    }
    return true;
  }
}
