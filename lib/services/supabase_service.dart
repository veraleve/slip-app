import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import '../constants/app_constants.dart';
import '../models/slip.dart';
import 'mock_data_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  String? _currentUsername;
  String? _currentUserId;

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
    } catch (_) {
      // Offline fallback
    }
  }

  SupabaseClient? get client => _client;
  bool get isAuthenticated => _currentUsername != null && _currentUsername!.isNotEmpty;
  String? get currentUsername => _currentUsername;
  String? get currentUserId => _currentUserId ?? 'peer_local';

  // Format username to internal identifier
  String _toInternalEmail(String username) {
    final clean = username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return '$clean@slip.internal';
  }

  // --- 1. USERNAME & PASSWORD AUTHENTICATION ---
  Future<bool> signInWithUsername({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty || password.isEmpty) return false;

    if (_client == null) {
      // Offline mode
      await _persistSession(cleanUsername, 'user_${cleanUsername.toLowerCase()}');
      return true;
    }

    try {
      final email = _toInternalEmail(cleanUsername);
      final res = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        await _persistSession(cleanUsername, res.user!.id);
        return true;
      }
      return false;
    } catch (e) {
      // If server rejection, check local fallback
      return false;
    }
  }

  Future<bool> signUpWithUsername({
    required String username,
    required String password,
    String targetExam = 'GATE CS 2027',
  }) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty || password.isEmpty) return false;

    if (_client == null) {
      await _persistSession(cleanUsername, 'user_${cleanUsername.toLowerCase()}');
      return true;
    }

    try {
      final email = _toInternalEmail(cleanUsername);
      final res = await _client!.auth.signUp(
        email: email,
        password: password,
        data: {'handle': cleanUsername},
      );

      final uid = res.user?.id ?? 'user_${cleanUsername.toLowerCase()}';
      await _persistSession(cleanUsername, uid);

      // Create profile record in Supabase
      try {
        await _client!.from('profiles').upsert({
          'id': uid,
          'handle': cleanUsername,
          'target_exam': targetExam,
        });
      } catch (_) {}

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _persistSession(String username, String userId) async {
    _currentUsername = username;
    _currentUserId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('slip_username', username);
    await prefs.setString('slip_user_id', userId);
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

  // --- 2. STREAM & MISTAKE TELEMETRY ---
  Future<List<Slip>> fetchStream() async {
    if (_client == null) {
      return MockDataService.getInitialSlips();
    }

    try {
      final response = await _client!
          .from('slips')
          .select()
          .order('created_at', ascending: false)
          .limit(30);

      final list = response as List;
      if (list.isEmpty) {
        return MockDataService.getInitialSlips();
      }

      return list
          .map((item) => Slip.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return MockDataService.getInitialSlips();
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
    if (_client == null) return true;
    try {
      await _client!.from('slips').insert({
        'topic': slip.topic,
        'subtopic': slip.subtopic,
        'exam_tag': slip.examTag,
        'trap_statement': slip.trapStatement,
        'fix_statement': slip.fixStatement,
        'author_id': _currentUserId,
        'audio_duration_seconds': slip.audioDurationSeconds,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
