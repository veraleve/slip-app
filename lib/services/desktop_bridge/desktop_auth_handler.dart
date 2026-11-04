import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../supabase_service.dart';

class DesktopAuthHandler {
  String _sessionToken;

  DesktopAuthHandler([String? initialToken])
      : _sessionToken = initialToken ??
            'slip_${DateTime.now().millisecondsSinceEpoch}_${Random.secure().nextInt(0xFFFFFF).toRadixString(16)}';

  String get sessionToken => _sessionToken;

  void refreshToken() {
    _sessionToken =
        'slip_${DateTime.now().millisecondsSinceEpoch}_${Random.secure().nextInt(0xFFFFFF).toRadixString(16)}';
  }

  bool isAuthorized(HttpRequest request, Map<String, dynamic>? bodyJson) {
    final authHeader = request.headers.value('Authorization');
    final reqToken = (authHeader != null && authHeader.startsWith('Bearer '))
        ? authHeader.substring(7).trim()
        : (bodyJson != null ? (bodyJson['token'] as String? ?? '').trim() : '');
    return reqToken == _sessionToken;
  }

  Future<void> handleAuth(HttpRequest request) async {
    try {
      final bodyStr = await utf8.decodeStream(request);
      final Map<String, dynamic> data = jsonDecode(bodyStr);
      final submittedPass = (data['password'] as String? ?? '').trim();

      final service = SupabaseService();
      final currentPass = service.savedPassword?.trim();

      bool isValid = false;
      if (submittedPass.isNotEmpty) {
        if (currentPass != null && currentPass.isNotEmpty) {
          isValid = (submittedPass == currentPass);
        } else if (service.client != null && service.currentUsername != null) {
          final res = await service.client!
              .from('profiles')
              .select('password_hash')
              .eq('handle', service.currentUsername!)
              .limit(1);
          if ((res as List).isNotEmpty) {
            final hash = (res.first['password_hash'] as String? ?? '').trim();
            if (hash.isNotEmpty && hash == submittedPass) {
              isValid = true;
            }
          }
        }
      }

      request.response.headers.contentType = ContentType.json;
      if (isValid) {
        refreshToken();
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({
          'success': true,
          'token': _sessionToken,
          'username': service.currentUsername ?? 'peer',
          'exams': service.targetExams,
        }));
      } else {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.write(jsonEncode({
          'success': false,
          'error':
              'Incorrect account password for @${service.currentUsername ?? "user"}.',
        }));
      }
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }
}
