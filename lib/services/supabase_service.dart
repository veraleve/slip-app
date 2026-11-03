import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
  bool _isLoggedIn = false;
  bool _rememberDevice = true;
  String? _savedUsername;
  String? _savedPassword;
  List<String> _targetExams = [GateSyllabus.gateCS];

  Future<void> initialize() async {
    try {
      // 1. Restore local preferences FIRST (guarantees offline & session reliability)
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('slip_is_logged_in') ?? false;
      _rememberDevice = prefs.getBool('slip_remember_device') ?? true;
      _currentUsername = prefs.getString('slip_username');
      _currentUserId = prefs.getString('slip_user_id');
      _savedUsername = prefs.getString('slip_saved_username');
      _savedPassword = prefs.getString('slip_saved_password');

      final savedExams = prefs.getStringList('slip_target_exams');
      if (savedExams != null && savedExams.isNotEmpty) {
        _targetExams = savedExams;
      }

      // Generate persistent ID only if missing (NEVER wipe non-UUID handles/mesh IDs)
      if (_currentUserId == null || _currentUserId!.isEmpty) {
        _currentUserId = generateUuid();
        await prefs.setString('slip_user_id', _currentUserId!);
      }

      if (_currentUsername == null || _currentUsername!.isEmpty) {
        final randomHex = (Random().nextInt(0xFFFFFF) + 0x100000).toRadixString(16);
        _currentUsername = 'peer_$randomHex';
        await prefs.setString('slip_username', _currentUsername!);
      }

      // 2. Initialize Supabase Client in safe isolated block
      if (AppConstants.supabaseAnonKey.isNotEmpty) {
        try {
          _client = SupabaseClient(
            AppConstants.supabaseUrl,
            AppConstants.supabaseAnonKey,
          );
        } catch (e) {
          debugPrint('Supabase client connection warning: $e');
        }
      }
    } catch (e) {
      debugPrint('SupabaseService initialize error: $e');
    }
  }

  SupabaseClient? get client => _client;

  bool get isAuthenticated {
    if (_isLoggedIn) return true;
    if (_rememberDevice && _currentUsername != null && _currentUsername!.isNotEmpty) {
      return true;
    }
    return false;
  }

  bool get isLoggedIn => _isLoggedIn;
  bool get rememberDevice => _rememberDevice;
  String? get savedUsername => _savedUsername ?? _currentUsername;
  String? get savedPassword => _savedPassword;
  String? get currentUsername => _currentUsername;
  String? get currentUserId => _currentUserId ?? 'peer_local';
  List<String> get targetExams => List.unmodifiable(_targetExams);
  String get primaryExam => _targetExams.isNotEmpty ? _targetExams.first : GateSyllabus.gateCS;

  Future<void> setLoggedIn(
    bool value, {
    bool rememberDevice = true,
    String? username,
    String? password,
  }) async {
    _isLoggedIn = value;
    _rememberDevice = rememberDevice;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('slip_is_logged_in', value);
    await prefs.setBool('slip_remember_device', rememberDevice);
    if (username != null) {
      _currentUsername = username;
      _savedUsername = username;
      await prefs.setString('slip_username', username);
      await prefs.setString('slip_saved_username', username);
    }
    if (rememberDevice && password != null) {
      _savedPassword = password;
      await prefs.setString('slip_saved_password', password);
    } else if (!rememberDevice) {
      await prefs.remove('slip_saved_password');
    }
  }

  Future<void> updateTargetExams(List<String> exams) async {
    if (exams.isEmpty) return;
    _targetExams = List.from(exams);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('slip_target_exams', _targetExams);

    if (_client != null && _currentUserId != null) {
      try {
        await _client!.from('profiles').update({
          'target_exams': _targetExams,
          'target_exam': primaryExam,
        }).eq('id', _currentUserId!);
      } catch (_) {}
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
    final cleanPassword = password.trim();
    if (cleanUsername.isEmpty || cleanPassword.isEmpty) return false;

    if (_client != null) {
      try {
        final profileRes = await _client!
            .from('profiles')
            .select()
            .ilike('handle', cleanUsername)
            .limit(1);
        final list = profileRes as List;
        if (list.isNotEmpty) {
          final p = list.first as Map<String, dynamic>;
          final storedPass = p['password_hash'] as String?;
          if (storedPass != null && storedPass.isNotEmpty && storedPass != cleanPassword) {
            // Password mismatch
            return false;
          }
          // If password_hash wasn't set, set it now
          if (storedPass == null || storedPass.isEmpty) {
            try {
              await _client!.from('profiles').update({'password_hash': cleanPassword}).eq('id', p['id']);
            } catch (_) {}
          }

          final pObj = Profile.fromJson(p);
          await _persistSession(pObj.handle, pObj.id, pObj.targetExams);
          return true;
        } else {
          // No such profile in Supabase
          return false;
        }
      } catch (e) {
        debugPrint('Sign in check warning: $e');
      }
    }

    // Local cached session fallback if credentials match
    if (_savedUsername != null && _savedUsername!.toLowerCase() == cleanUsername.toLowerCase()) {
      if (_savedPassword != null && _savedPassword!.isNotEmpty && _savedPassword != cleanPassword) {
        return false;
      }
      await _persistSession(cleanUsername, _currentUserId ?? generateUuid(), _targetExams);
      return true;
    }

    return false;
  }

  Future<bool> signUpWithUsername({
    required String username,
    required String password,
    List<String> targetExams = const [GateSyllabus.gateCS],
  }) async {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();
    if (cleanUsername.isEmpty || cleanPassword.isEmpty) return false;

    final resolvedExams = targetExams.isNotEmpty ? targetExams : [GateSyllabus.gateCS];
    final uid = generateUuid();

    if (_client != null) {
      try {
        final existing = await _client!
            .from('profiles')
            .select()
            .ilike('handle', cleanUsername)
            .limit(1);
        if ((existing as List).isNotEmpty) {
          return false; // Handle already registered
        }

        await _client!.from('profiles').insert({
          'id': uid,
          'handle': cleanUsername,
          'password_hash': cleanPassword,
          'target_exams': resolvedExams,
          'target_exam': resolvedExams.first,
          'avatar_glyph': cleanUsername.substring(0, 1).toUpperCase(),
        });
      } catch (e) {
        debugPrint('Sign up error: $e');
      }
    }

    await _persistSession(cleanUsername, uid, resolvedExams);
    return true;
  }

  Future<void> _persistSession(String username, String userId, List<String> exams) async {
    _currentUsername = username;
    _currentUserId = userId;
    _targetExams = List.from(exams);
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('slip_username', username);
    await prefs.setString('slip_user_id', userId);
    await prefs.setStringList('slip_target_exams', _targetExams);
    await prefs.setBool('slip_is_logged_in', true);
  }

  Future<void> signOut() async {
    _currentUsername = null;
    _currentUserId = null;
    _isLoggedIn = false;
    _savedPassword = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('slip_username');
    await prefs.remove('slip_user_id');
    await prefs.setBool('slip_is_logged_in', false);
    await prefs.setBool('slip_remember_device', false);
    await prefs.remove('slip_saved_password');

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

  // --- LOCAL-FIRST OFFLINE STORAGE & DELTA SYNC ---
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

  Future<List<Slip>> loadSavedPeerSlips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList('slip_saved_peer_slips') ?? [];
      return rawList.map((str) => Slip.fromJson(jsonDecode(str) as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSavedPeerSlips(List<Slip> slips) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> rawList = slips.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList('slip_saved_peer_slips', rawList);
    } catch (_) {}
  }

  Future<Set<String>> getSavedSlipIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('slip_saved_slip_ids') ?? [];
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> setSlipSaved(Slip slip, bool isSaved) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIds = (prefs.getStringList('slip_saved_slip_ids') ?? []).toSet();
      if (isSaved) {
        savedIds.add(slip.id);
      } else {
        savedIds.remove(slip.id);
      }
      await prefs.setStringList('slip_saved_slip_ids', savedIds.toList());

      // Update saved slips cache
      final savedSlips = await loadSavedPeerSlips();
      savedSlips.removeWhere((s) => s.id == slip.id);
      if (isSaved) {
        savedSlips.insert(0, slip.copyWith(hasKept: true));
      }
      await saveSavedPeerSlips(savedSlips);

      // Record interaction on Supabase
      if (isSaved) {
        await recordInteraction(slipId: slip.id, interactionType: 'keep');
      }
    } catch (_) {}
  }

  Future<List<Slip>> loadCachedFeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList('slip_cached_public_feed') ?? [];
      return rawList.map((str) => Slip.fromJson(jsonDecode(str) as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCachedFeed(List<Slip> slips) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> rawList = slips.take(150).map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList('slip_cached_public_feed', rawList);
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

    // 1. Instant Local Load: load local slips, saved peer slips, and cached feed
    final localUserSlips = await loadLocalUserSlips();
    final savedPeerSlips = await loadSavedPeerSlips();
    final cachedFeed = await loadCachedFeed();
    final savedIds = await getSavedSlipIds();

    final Map<String, Slip> combinedMap = {};
    for (final s in cachedFeed) {
      combinedMap[s.id] = s;
    }
    for (final s in savedPeerSlips) {
      combinedMap[s.id] = s.copyWith(hasKept: true);
    }
    for (final s in localUserSlips) {
      combinedMap[s.id] = s;
    }

    // Ensure saved state is accurately reflected
    for (final entry in combinedMap.entries) {
      if (savedIds.contains(entry.key)) {
        combinedMap[entry.key] = entry.value.copyWith(hasKept: true);
      }
    }

    // 2. High-Efficiency Delta Sync: Query ONLY new records created after our latest cached item
    if (_client != null) {
      try {
        DateTime? latestCachedCreatedAt;
        if (cachedFeed.isNotEmpty) {
          for (final s in cachedFeed) {
            if (latestCachedCreatedAt == null || s.createdAt.isAfter(latestCachedCreatedAt)) {
              latestCachedCreatedAt = s.createdAt;
            }
          }
        }

        List<dynamic> list = [];
        if (latestCachedCreatedAt != null) {
          // Delta sync: fetch ONLY rows newer than our newest cached post
          final response = await _client!
              .from('slips')
              .select()
              .gt('created_at', latestCachedCreatedAt.toUtc().toIso8601String())
              .order('created_at', ascending: false)
              .limit(50);
          list = response as List;
        } else {
          // Initial cold load: fetch the first page of 25 records
          final response = await _client!
              .from('slips')
              .select()
              .order('created_at', ascending: false)
              .limit(25);
          list = response as List;
        }

        if (list.isNotEmpty) {
          for (final item in list) {
            final slip = Slip.fromJson(item as Map<String, dynamic>);
            combinedMap[slip.id] = slip.copyWith(hasKept: savedIds.contains(slip.id));
          }

          // Cache the updated feed for instant offline access
          final sortedForCache = combinedMap.values.where((s) => s.isPublic).toList();
          sortedForCache.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          await saveCachedFeed(sortedForCache);
        }

        // Also fetch this signed-in user's slips from Supabase so reinstalling never loses them!
        if (_currentUsername != null && _currentUsername!.isNotEmpty) {
          try {
            final userPosts = await _client!
                .from('slips')
                .select()
                .ilike('author_handle', _currentUsername!)
                .order('created_at', ascending: false);
            for (final item in (userPosts as List)) {
              final s = Slip.fromJson(item as Map<String, dynamic>);
              combinedMap[s.id] = s.copyWith(hasKept: savedIds.contains(s.id));
            }
          } catch (_) {}
        }
      } catch (_) {
        // Offline or connection failure: gracefully proceed with cached data
      }
    }

    // 3. Filter and Sort by createdAt descending (newest posts at top)
    var result = combinedMap.values.toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Flexible Paper Filter using normalization so peer doubts are never lost
    if (allowedPapers.isNotEmpty && !allowedPapers.contains('All')) {
      final normSet = allowedPapers.map(GateSyllabus.normalizeExam).toSet();
      result = result.where((s) {
        if (s.examTag == null || s.examTag!.isEmpty) return true;
        // Always preserve General doubts across all paper filters
        if (s.examTag == 'General' || s.topic == 'General') return true;
        return normSet.contains(GateSyllabus.normalizeExam(s.examTag));
      }).toList();
    }

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
  }

  // --- LAZY LOADING / CURSOR-BASED PAGINATION ---
  Future<List<Slip>> fetchOlderSlips({
    required DateTime beforeTimestamp,
    int pageSize = 15,
  }) async {
    if (_client == null) return [];
    try {
      final savedIds = await getSavedSlipIds();
      final response = await _client!
          .from('slips')
          .select()
          .lt('created_at', beforeTimestamp.toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .limit(pageSize);
      final list = response as List;

      if (list.isNotEmpty) {
        final olderSlips = list.map((item) {
          final slip = Slip.fromJson(item as Map<String, dynamic>);
          return slip.copyWith(hasKept: savedIds.contains(slip.id));
        }).toList();

        // Append to cached feed
        final cached = await loadCachedFeed();
        final Map<String, Slip> combined = {for (final s in cached) s.id: s};
        for (final s in olderSlips) {
          combined[s.id] = s;
        }
        final updatedList = combined.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await saveCachedFeed(updatedList);

        return olderSlips;
      }
    } catch (_) {}
    return [];
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

  Future<String?> uploadImageFile(String localPath) async {
    if (_client == null) return null;
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final ext = localPath.split('.').last.toLowerCase();
      final mime = (ext == 'png') ? 'image/png' : 'image/jpeg';
      final fileName = 'slip_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}.$ext';

      await _client!.storage.from('slip_media').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(contentType: mime, upsert: true),
      );
      final publicUrl = _client!.storage.from('slip_media').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading slip image: $e');
      return null;
    }
  }

  Future<bool> submitSlip(Slip slip) async {
    // 1. Immediately cache locally for offline access
    final local = await loadLocalUserSlips();
    local.removeWhere((s) => s.id == slip.id);
    local.insert(0, slip);
    await saveLocalUserSlips(local);

    // Also insert into cached public feed if public
    if (slip.isPublic) {
      final cached = await loadCachedFeed();
      cached.removeWhere((s) => s.id == slip.id);
      cached.insert(0, slip);
      await saveCachedFeed(cached);
    }

    if (_client == null) return true;
    try {
      final validAuthorId = (slip.authorId != null && isUuid(slip.authorId!))
          ? slip.authorId!
          : ((_currentUserId != null && isUuid(_currentUserId!)) ? _currentUserId! : generateUuid());

      String? imageUrl;
      if (slip.imageUris.isNotEmpty) {
        final firstImg = slip.imageUris.first;
        if (firstImg.startsWith('http://') || firstImg.startsWith('https://')) {
          imageUrl = firstImg;
        } else {
          imageUrl = await uploadImageFile(firstImg);
        }
      }

      await _client!.from('slips').insert({
        'id': slip.id,
        'topic': slip.topic.isNotEmpty ? slip.topic : 'General',
        'subtopic': (slip.subtopic != null && slip.subtopic!.isNotEmpty) ? slip.subtopic : 'General',
        'exam_tag': (slip.examTag != null && slip.examTag!.isNotEmpty) ? slip.examTag : 'General',
        'post_type': slip.postType.name,
        'title': slip.title ?? '',
        'is_resolved': slip.isResolved,
        'is_public': slip.isPublic,
        'trap_statement': slip.trapStatement.isNotEmpty ? slip.trapStatement : '',
        'fix_statement': slip.fixStatement.isNotEmpty ? slip.fixStatement : '',
        'scratchpad_image_url': imageUrl ?? (slip.imageUris.isNotEmpty ? slip.imageUris.first : null),
        'voice_audio_url': slip.voiceAudioUrl,
        'author_id': validAuthorId,
        'author_handle': slip.authorUsername ?? _currentUsername ?? 'peer',
        'audio_duration_seconds': slip.audioDurationSeconds,
        'created_at': slip.createdAt.toUtc().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Submit slip to Supabase error: $e');
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

    if (slip.isPublic) {
      final cached = await loadCachedFeed();
      final cIdx = cached.indexWhere((s) => s.id == slip.id);
      if (cIdx != -1) {
        cached[cIdx] = slip;
        await saveCachedFeed(cached);
      }
    }

    if (_client == null) return true;
    try {
      String? imageUrl;
      if (slip.imageUris.isNotEmpty) {
        final firstImg = slip.imageUris.first;
        if (firstImg.startsWith('http://') || firstImg.startsWith('https://')) {
          imageUrl = firstImg;
        } else {
          imageUrl = await uploadImageFile(firstImg);
        }
      }

      await _client!.from('slips').update({
        'topic': slip.topic.isNotEmpty ? slip.topic : 'General',
        'subtopic': (slip.subtopic != null && slip.subtopic!.isNotEmpty) ? slip.subtopic : 'General',
        'exam_tag': (slip.examTag != null && slip.examTag!.isNotEmpty) ? slip.examTag : 'General',
        'post_type': slip.postType.name,
        'title': slip.title ?? '',
        'is_resolved': slip.isResolved,
        'trap_statement': slip.trapStatement.isNotEmpty ? slip.trapStatement : '',
        'fix_statement': slip.fixStatement.isNotEmpty ? slip.fixStatement : '',
        'scratchpad_image_url': imageUrl ?? (slip.imageUris.isNotEmpty ? slip.imageUris.first : null),
        'audio_duration_seconds': slip.audioDurationSeconds,
      }).eq('id', slip.id);
      return true;
    } catch (e) {
      debugPrint('Submit slip to Supabase error: $e');
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
    } catch (e) {
      debugPrint('Submit slip to Supabase error: $e');
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
    String? parentId,
    bool isAcceptedAnswer = false,
  }) async {
    final comment = {
      'id': generateUuid(),
      'slip_id': slipId,
      if (parentId != null) 'parent_id': parentId,
      'author_id': _currentUserId,
      'author_handle': _currentUsername ?? 'peer',
      'body': body,
      'is_accepted_answer': isAcceptedAnswer,
      'created_at': DateTime.now().toUtc().toIso8601String(),
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
