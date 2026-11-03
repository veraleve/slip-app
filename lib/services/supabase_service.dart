import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../models/slip.dart';
import 'mock_data_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;
  SupabaseClient? _client;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
    } catch (e) {
      // Offline or network initialization fallback
      _isInitialized = false;
    }
  }

  SupabaseClient? get client => _client;
  bool get isAuthenticated => _client?.auth.currentUser != null;
  String? get currentUserId => _client?.auth.currentUser?.id;

  // Authentication
  Future<bool> signIn({required String email, required String password}) async {
    if (!_isInitialized || _client == null) return true; // offline mock mode
    try {
      final res = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res.user != null;
    } catch (_) {
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String handle,
  }) async {
    if (!_isInitialized || _client == null) return true;
    try {
      final res = await _client!.auth.signUp(
        email: email,
        password: password,
        data: {'handle': handle},
      );
      if (res.user != null) {
        // Create profile
        await _client!.from('profiles').upsert({
          'id': res.user!.id,
          'handle': handle,
          'target_exam': 'GATE CS 2027',
        });
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    if (_isInitialized && _client != null) {
      await _client!.auth.signOut();
    }
  }

  // Feed Data
  Future<List<Slip>> fetchStream() async {
    if (!_isInitialized || _client == null) {
      return MockDataService.getInitialSlips();
    }

    try {
      final data = await _client!
          .from('slips')
          .select()
          .order('created_at', ascending: false)
          .limit(30);

      if (data.isEmpty) {
        return MockDataService.getInitialSlips();
      }

      return (data as List)
          .map((item) => Slip.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return MockDataService.getInitialSlips();
    }
  }

  // Interactions
  Future<void> recordInteraction({
    required String slipId,
    required String interactionType,
  }) async {
    if (!_isInitialized || _client == null || currentUserId == null) return;
    try {
      await _client!.from('slip_interactions').upsert({
        'user_id': currentUserId,
        'slip_id': slipId,
        'interaction_type': interactionType,
      });

      // Increment counters
      if (interactionType == 'same') {
        await _client!.rpc('increment_same_count', params: {'slip_id': slipId});
      }
    } catch (_) {
      // Non-blocking interaction recording
    }
  }

  // Submit Slip
  Future<bool> submitSlip(Slip slip) async {
    if (!_isInitialized || _client == null) return true;
    try {
      await _client!.from('slips').insert({
        'topic': slip.topic,
        'subtopic': slip.subtopic,
        'exam_tag': slip.examTag,
        'trap_statement': slip.trapStatement,
        'fix_statement': slip.fixStatement,
        'author_id': currentUserId,
        'audio_duration_seconds': slip.audioDurationSeconds,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
