import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../constants/app_constants.dart';
import '../../constants/gate_syllabus.dart';
import '../../models/slip.dart';
import '../../models/task_item.dart';
import '../../providers/slip_provider.dart';
import '../native_device_service.dart';
import '../supabase_service.dart';

class DesktopConnectService {
  static final DesktopConnectService _instance = DesktopConnectService._internal();
  factory DesktopConnectService() => _instance;
  DesktopConnectService._internal();

  HttpServer? _server;
  String? _localIp;
  int _port = 8080;
  SlipProvider? _provider;
  String _sessionToken = 'slip_token_initial';

  bool get isRunning => _server != null;
  String? get serverUrl => isRunning && _localIp != null ? 'http://$_localIp:$_port' : null;
  String? get localIp => _localIp;
  int get port => _port;

  Future<String?> getDeviceIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && !addr.isLinkLocal) {
            _localIp = addr.address;
            return _localIp;
          }
        }
      }
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        _localIp = interfaces.first.addresses.first.address;
        return _localIp;
      }
    } catch (e) {
      debugPrint('Error detecting local IP: $e');
    }
    _localIp = '127.0.0.1';
    return _localIp;
  }

  Future<String?> startServer(SlipProvider provider, {int port = 8080}) async {
    if (_server != null) {
      return serverUrl;
    }

    _provider = provider;
    _port = port;
    _sessionToken = 'slip_${DateTime.now().millisecondsSinceEpoch}_${Random.secure().nextInt(0xFFFFFF).toRadixString(16)}';
    await getDeviceIp();

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
    } catch (e) {
      _port = 8888;
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
    }

    _server!.listen((HttpRequest request) {
      _handleRequest(request);
    });

    return serverUrl;
  }

  Future<void> stopServer() async {
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
  }

  bool _isAuthorized(HttpRequest request, Map<String, dynamic>? bodyJson) {
    final authHeader = request.headers.value('Authorization');
    final reqToken = (authHeader != null && authHeader.startsWith('Bearer '))
        ? authHeader.substring(7).trim()
        : (bodyJson != null ? (bodyJson['token'] as String? ?? '').trim() : '');
    return reqToken == _sessionToken;
  }

  void _handleRequest(HttpRequest request) async {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept, Authorization');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    if (request.method == 'GET' && (path == '/' || path == '/index.html')) {
      _serveDesktopWebPage(request);
    } else if (request.method == 'GET' && path == '/api/status') {
      final service = SupabaseService();
      final data = {
        'status': 'online',
        'username': service.currentUsername ?? 'peer',
        'exams': service.targetExams,
        'supportedExams': GateSyllabus.supportedExams,
        'version': AppConstants.appVersion,
        'requiresAuth': true,
      };
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(data));
      await request.response.close();
    } else if (request.method == 'POST' && path == '/api/auth') {
      await _handleAuth(request);
    } else if (request.method == 'GET' && path == '/api/feed') {
      await _handleGetFeed(request);
    } else if (request.method == 'POST' && path == '/api/slips') {
      await _handlePostSlip(request);
    } else if (request.method == 'POST' && path == '/api/slips/same') {
      await _handleToggleSame(request);
    } else if (request.method == 'GET' && path == '/api/comments') {
      await _handleGetComments(request);
    } else if (request.method == 'POST' && path == '/api/comments') {
      await _handlePostComment(request);
    } else if (request.method == 'POST' && path == '/api/comments/accept') {
      await _handleAcceptComment(request);
    } else if (request.method == 'GET' && path == '/api/tasks') {
      await _handleGetTasks(request);
    } else if (request.method == 'POST' && path == '/api/tasks/toggle') {
      await _handleToggleTask(request);
    } else if (request.method == 'POST' && path == '/api/tasks/create') {
      await _handleCreateTask(request);
    } else if (request.method == 'GET' && path == '/api/media') {
      await _handleServeMedia(request);
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('Not Found');
      await request.response.close();
    }
  }

  Future<void> _handleAuth(HttpRequest request) async {
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
          'error': 'Incorrect account password for @${service.currentUsername ?? "user"}.',
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

  Future<void> _handleGetFeed(HttpRequest request) async {
    try {
      final examFilter = request.uri.queryParameters['exam'];
      final typeFilter = request.uri.queryParameters['type'];
      final search = request.uri.queryParameters['q']?.toLowerCase().trim();

      List<Slip> list = [];
      if (_provider != null) {
        list = List.from(_provider!.allSlips);
      } else {
        list = await SupabaseService().fetchStream(userPapers: ['All']);
      }

      if (examFilter != null && examFilter.isNotEmpty && examFilter != 'All') {
        final norm = GateSyllabus.normalizeExam(examFilter);
        list = list.where((s) =>
            GateSyllabus.normalizeExam(s.examTag) == norm ||
            s.examTag == 'General' ||
            s.topic == 'General').toList();
      }

      if (typeFilter != null && typeFilter.isNotEmpty && typeFilter != 'all') {
        if (typeFilter == 'doubt') {
          list = list.where((s) => s.postType == PostType.doubt).toList();
        } else if (typeFilter == 'mistake') {
          list = list.where((s) => s.postType == PostType.mistake).toList();
        }
      }

      if (search != null && search.isNotEmpty) {
        list = list.where((s) {
          final t = (s.title ?? '').toLowerCase();
          final tr = s.trapStatement.toLowerCase();
          final fx = s.fixStatement.toLowerCase();
          final tp = s.topic.toLowerCase();
          final h = (s.authorUsername ?? '').toLowerCase();
          return t.contains(search) || tr.contains(search) || fx.contains(search) || tp.contains(search) || h.contains(search);
        }).toList();
      }

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final jsonList = list.map((s) {
        final Map<String, dynamic> m = s.toJson();
        m['post_type'] = s.postType.name;
        if (s.imageUris.isNotEmpty) {
          m['image_urls'] = s.imageUris.map((img) {
            if (img.startsWith('http://') || img.startsWith('https://')) return img;
            return '/api/media?file=${Uri.encodeComponent(img)}';
          }).toList();
        } else {
          m['image_urls'] = [];
        }
        return m;
      }).toList();

      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'slips': jsonList}));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> _handlePostSlip(HttpRequest request) async {
    try {
      final bodyStr = await utf8.decodeStream(request);
      final Map<String, dynamic> data = jsonDecode(bodyStr);

      if (!_isAuthorized(request, data)) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'error': 'Unauthorized. Please authenticate desktop session.'}));
        await request.response.close();
        return;
      }

      final title = data['title'] as String? ?? '';
      final trap = data['trapStatement'] as String? ?? '';
      final fix = data['fixStatement'] as String? ?? '';
      final exam = data['examTag'] as String? ?? GateSyllabus.gateCS;
      final topic = data['topic'] as String? ?? 'General';
      final subtopic = data['subtopic'] as String? ?? 'General';
      final isDoubt = data['isDoubt'] == true;
      final imageBase64 = data['imageBase64'] as String?;

      if (trap.trim().isEmpty) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'error': 'Trap or context statement cannot be empty'}));
        await request.response.close();
        return;
      }

      final attachedImages = <String>[];
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        try {
          final cleanBase64 = imageBase64.contains(',') ? imageBase64.split(',').last : imageBase64;
          final bytes = base64Decode(cleanBase64);
          final cacheDir = await NativeDeviceService.getAppCacheDir() ?? Directory.systemTemp.path;
          final filePath = '$cacheDir/slip_desktop_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final file = File(filePath);
          await file.writeAsBytes(bytes);
          attachedImages.add(filePath);
        } catch (e) {
          debugPrint('Error saving desktop screenshot: $e');
        }
      }

      if (_provider != null) {
        await _provider!.dropSlip(
          title: title.isNotEmpty ? title : (isDoubt ? 'Doubt: $topic' : null),
          trapStatement: trap,
          fixStatement: fix,
          examTag: exam,
          topic: topic,
          subtopic: subtopic,
          imageUris: attachedImages,
          postType: isDoubt ? PostType.doubt : PostType.mistake,
          isPublic: true,
          allowComments: true,
        );
      }

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'success': true,
        'message': 'Post successfully logged into Slip app!',
      }));
      await request.response.close();
    } catch (e) {
      debugPrint('Error handling desktop slip post: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': 'Internal server error: $e'}));
      await request.response.close();
    }
  }

  Future<void> _handleToggleSame(HttpRequest request) async {
    try {
      final bodyStr = await utf8.decodeStream(request);
      final Map<String, dynamic> data = jsonDecode(bodyStr);

      if (!_isAuthorized(request, data)) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'error': 'Unauthorized'}));
        await request.response.close();
        return;
      }

      final slipId = data['slip_id'] as String? ?? '';
      if (_provider != null && slipId.isNotEmpty) {
        _provider!.toggleSame(slipId);
      }

      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'success': true}));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> _handleGetComments(HttpRequest request) async {
    try {
      final slipId = request.uri.queryParameters['slip_id'];
      if (slipId == null || slipId.isEmpty) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'error': 'slip_id required'}));
        await request.response.close();
        return;
      }

      final comments = await SupabaseService().fetchComments(slipId);
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'comments': comments}));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> _handlePostComment(HttpRequest request) async {
    try {
      final bodyStr = await utf8.decodeStream(request);
      final Map<String, dynamic> data = jsonDecode(bodyStr);

      if (!_isAuthorized(request, data)) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'error': 'Unauthorized'}));
        await request.response.close();
        return;
      }

      final slipId = data['slip_id'] as String? ?? '';
      final body = data['body'] as String? ?? '';
      final parentId = data['parent_id'] as String?;

      if (slipId.isEmpty || body.trim().isEmpty) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'error': 'slip_id and body required'}));
        await request.response.close();
        return;
      }

      bool success = false;
      if (_provider != null) {
        success = await _provider!.postComment(slipId: slipId, body: body.trim(), parentId: parentId);
      } else {
        success = await SupabaseService().postComment(slipId: slipId, body: body.trim(), parentId: parentId);
      }

      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'success': success}));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> _handleAcceptComment(HttpRequest request) async {
    try {
      final bodyStr = await utf8.decodeStream(request);
      final Map<String, dynamic> data = jsonDecode(bodyStr);

      if (!_isAuthorized(request, data)) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'error': 'Unauthorized'}));
        await request.response.close();
        return;
      }

      final slipId = data['slip_id'] as String? ?? '';
      final commentId = data['comment_id'] as String? ?? '';
      final isAccepted = data['is_accepted'] == true;

      final success = await SupabaseService().toggleCommentAccepted(
        slipId: slipId,
        commentId: commentId,
        isAccepted: isAccepted,
      );

      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'success': success}));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> _handleGetTasks(HttpRequest request) async {
    try {
      List<TaskItem> tasks = [];
      if (_provider != null) {
        tasks = _provider!.tasks;
      } else {
        final raw = await SupabaseService().loadTasksRaw();
        tasks = raw.map((str) => TaskItem.deserialize(str)).toList();
      }

      final jsonList = tasks.map((t) => t.toJson()).toList();
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'tasks': jsonList}));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> _handleToggleTask(HttpRequest request) async {
    try {
      final bodyStr = await utf8.decodeStream(request);
      final Map<String, dynamic> data = jsonDecode(bodyStr);

      if (!_isAuthorized(request, data)) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'error': 'Unauthorized'}));
        await request.response.close();
        return;
      }

      final taskId = data['task_id'] as String? ?? '';
      if (taskId.isNotEmpty && _provider != null) {
        await _provider!.toggleTaskCompleted(taskId);
      }

      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'success': true}));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> _handleCreateTask(HttpRequest request) async {
    try {
      final bodyStr = await utf8.decodeStream(request);
      final Map<String, dynamic> data = jsonDecode(bodyStr);

      if (!_isAuthorized(request, data)) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'error': 'Unauthorized'}));
        await request.response.close();
        return;
      }

      final title = (data['title'] as String? ?? '').trim();
      final exam = data['examTag'] as String? ?? GateSyllabus.gateCS;
      final subject = (data['subject'] as String? ?? 'General').trim();
      final scheduledStr = data['scheduledAt'] as String?;
      final scheduledAt = scheduledStr != null
          ? (DateTime.tryParse(scheduledStr) ?? DateTime.now().add(const Duration(days: 1)))
          : DateTime.now().add(const Duration(days: 1));

      if (title.isEmpty) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'error': 'Task title is required'}));
        await request.response.close();
        return;
      }

      final newTask = TaskItem(
        id: SupabaseService.generateUuid(),
        title: title,
        examTag: GateSyllabus.normalizeExam(exam),
        subject: subject,
        scheduledAt: scheduledAt,
        createdAt: DateTime.now(),
      );

      if (_provider != null) {
        await _provider!.addTask(newTask);
      }

      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'success': true, 'task': newTask.toJson()}));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }

  Future<void> _handleServeMedia(HttpRequest request) async {
    final filePath = request.uri.queryParameters['file'];
    if (filePath == null || filePath.isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }
    final file = File(filePath);
    if (!await file.exists()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final ext = filePath.split('.').last.toLowerCase();
    final contentType = ext == 'png' ? ContentType('image', 'png') : ContentType('image', 'jpeg');
    request.response.headers.contentType = contentType;
    await request.response.addStream(file.openRead());
    await request.response.close();
  }

  void _serveDesktopWebPage(HttpRequest request) async {
    final service = SupabaseService();
    final username = service.currentUsername ?? 'peer';
    final targetExams = service.targetExams;
    final primaryExam = targetExams.isNotEmpty ? targetExams.first : GateSyllabus.gateCS;

    final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Slip Desktop Portal - Inoculate Mistakes</title>
  <style>
    :root {
      --canvas: #FFFFFF;
      --bg: #F4F5F7;
      --surface: #FFFFFF;
      --surface-subtle: #F9FAFB;
      --carbon: #111827;
      --steel: #6B7280;
      --steel-light: #9CA3AF;
      --hairline: #E5E7EB;
      --trap-red: #DC2626;
      --trap-bg: #FEF2F2;
      --cleared-green: #16A34A;
      --cleared-bg: #F0FDF4;
      --doubt-blue: #2563EB;
      --doubt-bg: #EFF6FF;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Inter", sans-serif;
      background-color: var(--bg);
      color: var(--carbon);
      padding: 24px 16px;
      display: flex;
      justify-content: center;
      line-height: 1.5;
    }
    .container {
      width: 100%;
      max-width: 960px;
      background: var(--canvas);
      border-radius: 16px;
      border: 1px solid var(--hairline);
      box-shadow: 0 4px 24px rgba(0,0,0,0.05);
      padding: 28px;
      position: relative;
    }
    .header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      border-bottom: 1px solid var(--hairline);
      padding-bottom: 18px;
      margin-bottom: 20px;
    }
    .logo-area { display: flex; align-items: center; gap: 12px; }
    .logo-badge {
      width: 40px; height: 40px; background: var(--carbon); color: #fff;
      border-radius: 10px; display: flex; align-items: center; justify-content: center;
      font-weight: 900; font-size: 19px; letter-spacing: -0.5px;
    }
    .title-area h1 { font-size: 20px; font-weight: 800; letter-spacing: -0.4px; }
    .title-area p { font-size: 12px; color: var(--steel); margin-top: 2px; }
    .status-pill {
      display: flex; align-items: center; gap: 6px; font-size: 11.5px;
      background: var(--cleared-bg); color: var(--cleared-green); font-weight: 700;
      padding: 6px 12px; border-radius: 20px; border: 1px solid rgba(22,163,74,0.2);
    }
    .status-dot { width: 7px; height: 7px; background: var(--cleared-green); border-radius: 50%; }

    /* Main Navigation Tabs */
    .tabs-bar {
      display: flex; gap: 6px; border-bottom: 1px solid var(--hairline);
      margin-bottom: 24px; padding-bottom: 6px;
    }
    .tab-btn {
      padding: 10px 18px; border-radius: 8px; border: none; background: transparent;
      font-size: 13px; font-weight: 700; color: var(--steel); cursor: pointer;
      letter-spacing: 0.3px; transition: all 0.15s ease;
    }
    .tab-btn:hover { background: var(--surface-subtle); color: var(--carbon); }
    .tab-btn.active {
      background: var(--carbon); color: #fff;
    }

    /* Views */
    .view-panel { display: none; }
    .view-panel.active { display: block; }

    /* Feed Toolbar */
    .feed-toolbar {
      display: flex; flex-wrap: wrap; gap: 10px; align-items: center;
      justify-content: space-between; margin-bottom: 20px;
    }
    .search-input-wrap { flex: 1; min-width: 240px; position: relative; }
    .search-input {
      width: 100%; padding: 10px 14px; border-radius: 8px; border: 1px solid var(--hairline);
      font-size: 13.5px; font-family: inherit; outline: none;
    }
    .search-input:focus { border-color: var(--carbon); }
    .filter-group { display: flex; gap: 6px; align-items: center; }
    .filter-pill {
      padding: 6px 12px; border-radius: 16px; border: 1px solid var(--hairline);
      background: var(--surface-subtle); font-size: 11.5px; font-weight: 700;
      color: var(--steel); cursor: pointer; transition: all 0.15s ease;
    }
    .filter-pill.active {
      background: var(--carbon); color: #fff; border-color: var(--carbon);
    }
    .select-dropdown {
      padding: 8px 12px; border-radius: 8px; border: 1px solid var(--hairline);
      font-size: 12.5px; font-weight: 700; color: var(--carbon); outline: none;
      background: #fff; cursor: pointer;
    }

    /* Slip Cards */
    .slips-list { display: flex; flex-direction: column; gap: 16px; }
    .slip-card {
      background: var(--surface); border: 1px solid var(--hairline);
      border-radius: 12px; padding: 20px; transition: border-color 0.15s ease;
    }
    .slip-card:hover { border-color: var(--carbon); }
    .slip-card-header {
      display: flex; align-items: center; justify-content: space-between;
      margin-bottom: 12px; font-size: 12px;
    }
    .badges-row { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
    .badge {
      font-size: 10.5px; font-weight: 800; padding: 3px 8px; border-radius: 6px;
      letter-spacing: 0.4px; text-transform: uppercase;
    }
    .badge-doubt { background: var(--doubt-bg); color: var(--doubt-blue); border: 1px solid rgba(37,99,235,0.2); }
    .badge-mistake { background: var(--trap-bg); color: var(--trap-red); border: 1px solid rgba(220,38,38,0.2); }
    .badge-exam { background: var(--surface-subtle); color: var(--steel); border: 1px solid var(--hairline); }
    .badge-resolved { background: var(--cleared-bg); color: var(--cleared-green); border: 1px solid rgba(22,163,74,0.3); }
    
    .author-info { color: var(--steel); font-size: 11.5px; font-weight: 600; }
    .slip-title { font-size: 16px; font-weight: 800; margin-bottom: 10px; color: var(--carbon); }
    .trap-box {
      background: var(--surface-subtle); border-left: 3px solid var(--trap-red);
      padding: 12px 14px; border-radius: 0 8px 8px 0; font-size: 13.5px;
      margin-bottom: 12px; color: var(--carbon);
    }
    .fix-box {
      background: var(--cleared-bg); border-left: 3px solid var(--cleared-green);
      padding: 12px 14px; border-radius: 0 8px 8px 0; font-size: 13.5px;
      margin-bottom: 12px; color: var(--carbon);
    }
    .slip-img-preview {
      max-width: 100%; max-height: 280px; object-fit: contain;
      border-radius: 8px; border: 1px solid var(--hairline);
      margin-bottom: 12px; cursor: pointer;
    }

    /* Card Actions */
    .card-actions {
      display: flex; align-items: center; justify-content: space-between;
      border-top: 1px solid var(--hairline); padding-top: 12px; margin-top: 8px;
    }
    .action-left { display: flex; gap: 8px; }
    .btn-action {
      background: var(--surface-subtle); border: 1px solid var(--hairline);
      padding: 6px 12px; border-radius: 6px; font-size: 12px; font-weight: 700;
      color: var(--carbon); cursor: pointer; transition: all 0.15s ease;
    }
    .btn-action:hover { background: #E5E7EB; }
    .btn-action.active { background: var(--carbon); color: #fff; border-color: var(--carbon); }

    /* Comments Section */
    .comments-drawer {
      border-top: 1px solid var(--hairline); margin-top: 14px; padding-top: 14px;
      display: none;
    }
    .comments-drawer.open { display: block; }
    .comment-item {
      padding: 10px 12px; border-radius: 8px; background: var(--surface-subtle);
      border: 1px solid var(--hairline); margin-bottom: 8px; font-size: 13px;
    }
    .comment-header {
      display: flex; justify-content: space-between; font-size: 11px;
      color: var(--steel); font-weight: 700; margin-bottom: 4px;
    }
    .accepted-tag {
      background: var(--cleared-bg); color: var(--cleared-green);
      font-weight: 800; font-size: 9.5px; padding: 2px 6px; border-radius: 4px;
      border: 1px solid rgba(22,163,74,0.3); text-transform: uppercase;
    }
    .btn-accept {
      font-size: 11px; font-weight: 700; color: var(--cleared-green);
      background: transparent; border: 1px solid var(--cleared-green);
      border-radius: 4px; padding: 2px 8px; cursor: pointer; margin-top: 6px;
    }
    .comment-form { display: flex; gap: 8px; margin-top: 10px; }
    .comment-input {
      flex: 1; padding: 8px 12px; border-radius: 8px; border: 1px solid var(--hairline);
      font-size: 13px; font-family: inherit; outline: none;
    }
    .comment-input:focus { border-color: var(--carbon); }
    .btn-comment-submit {
      padding: 8px 16px; background: var(--carbon); color: #fff; border: none;
      border-radius: 8px; font-size: 12.5px; font-weight: 700; cursor: pointer;
    }

    /* Tasks View */
    .task-create-bar {
      display: grid; grid-template-columns: 2fr 1fr 1fr 1fr auto; gap: 10px;
      background: var(--surface-subtle); padding: 16px; border-radius: 12px;
      border: 1px solid var(--hairline); margin-bottom: 24px;
    }
    .tasks-list { display: flex; flex-direction: column; gap: 10px; }
    .task-card {
      display: flex; align-items: center; justify-content: space-between;
      padding: 14px 18px; border-radius: 10px; border: 1px solid var(--hairline);
      background: #fff; transition: all 0.15s ease;
    }
    .task-card.completed { background: #FAFAFA; opacity: 0.65; }
    .task-left { display: flex; align-items: center; gap: 14px; }
    .task-checkbox { width: 18px; height: 18px; cursor: pointer; accent-color: var(--carbon); }
    .task-text { font-size: 14px; font-weight: 700; color: var(--carbon); }
    .task-card.completed .task-text { text-decoration: line-through; }
    .task-meta { font-size: 11.5px; color: var(--steel); font-weight: 600; margin-top: 2px; }

    /* Form & Paste Box (Tab 2) */
    .form-group { margin-bottom: 18px; }
    .form-label {
      display: block; font-size: 11px; font-weight: 800; color: var(--steel);
      text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px;
    }
    input[type="text"], input[type="password"], select, textarea {
      width: 100%; padding: 12px 14px; border-radius: 10px;
      border: 1px solid var(--hairline); background: var(--canvas);
      font-size: 14px; color: var(--carbon); font-family: inherit;
      outline: none; transition: border-color 0.2s;
    }
    input[readonly] { background: #f0f0f3; color: var(--steel); cursor: not-allowed; }
    input:focus, select:focus, textarea:focus { border-color: var(--carbon); }
    textarea { resize: vertical; min-height: 90px; line-height: 1.5; }
    .row { display: flex; gap: 14px; }
    .row > .form-group { flex: 1; }

    .paste-box {
      border: 2px dashed var(--hairline); border-radius: 12px;
      padding: 24px; text-align: center; background: var(--surface-subtle);
      cursor: pointer; transition: border-color 0.2s, background 0.2s;
      margin-bottom: 20px;
    }
    .paste-box.dragover, .paste-box:hover {
      border-color: var(--carbon); background: #f0f0f3;
    }
    .paste-box p { font-size: 13.5px; font-weight: 700; color: var(--steel); }
    .paste-box small { font-size: 11.5px; color: #999; display: block; margin-top: 4px; }

    .preview-area {
      display: none; align-items: center; justify-content: space-between;
      padding: 10px 14px; background: #fff; border: 1px solid var(--hairline);
      border-radius: 10px; margin-bottom: 20px;
    }
    .preview-info { display: flex; align-items: center; gap: 12px; }
    .preview-thumb { width: 44px; height: 44px; object-fit: cover; border-radius: 6px; }
    .remove-img { color: var(--trap-red); font-size: 12px; font-weight: 700; cursor: pointer; }

    .submit-btn {
      width: 100%; padding: 14px; background: var(--carbon); color: #fff;
      border: none; border-radius: 10px; font-size: 14px; font-weight: 800;
      letter-spacing: 0.4px; cursor: pointer; transition: opacity 0.2s;
    }
    .submit-btn:hover { opacity: 0.92; }
    .submit-btn:disabled { opacity: 0.5; cursor: not-allowed; }

    .toast {
      display: none; padding: 14px 18px; border-radius: 10px;
      background: var(--cleared-bg); color: var(--cleared-green); font-size: 13px;
      font-weight: 700; margin-bottom: 20px; border: 1px solid rgba(22,163,74,0.3);
    }

    /* Auth Overlay */
    .auth-overlay {
      position: fixed; top: 0; left: 0; right: 0; bottom: 0;
      background: rgba(17, 17, 17, 0.6);
      display: flex; align-items: center; justify-content: center;
      z-index: 1000; backdrop-filter: blur(4px);
    }
    .auth-card {
      width: 90%; max-width: 440px; background: #fff;
      border-radius: 16px; padding: 32px; border: 1px solid var(--hairline);
      box-shadow: 0 8px 30px rgba(0,0,0,0.12);
    }
    .auth-title { font-size: 16px; font-weight: 800; letter-spacing: 0.5px; margin-bottom: 6px; }
    .auth-subtitle { font-size: 12px; color: var(--steel); line-height: 1.4; margin-bottom: 20px; }
    .auth-error {
      display: none; padding: 10px 12px; border-radius: 8px;
      background: var(--trap-bg); color: var(--trap-red); font-size: 12px; font-weight: 600;
      margin-bottom: 16px; border: 1px solid rgba(220,38,38,0.2);
    }
  </style>
</head>
<body>
  <!-- Embedded Authentication Modal -->
  <div id="authOverlay" class="auth-overlay">
    <div class="auth-card">
      <div class="auth-title">DESKTOP AUTHENTICATION</div>
      <p class="auth-subtitle">Verify your account password to securely access feed, post questions, and manage tasks on @$username's device.</p>
      
      <div id="authError" class="auth-error"></div>

      <div class="form-group">
        <label class="form-label">Phone Account Handle</label>
        <input type="text" value="@$username" readonly>
      </div>

      <div class="form-group">
        <label class="form-label">Account Password</label>
        <input type="password" id="authPasswordInput" placeholder="Enter account password" autofocus onkeydown="if(event.key==='Enter') verifyDesktopAuth()">
      </div>

      <button type="button" class="submit-btn" id="authSubmitBtn" onclick="verifyDesktopAuth()">UNLOCK DESKTOP BRIDGE</button>
    </div>
  </div>

  <div class="container">
    <div class="header">
      <div class="logo-area">
        <div class="logo-badge">S</div>
        <div class="title-area">
          <h1>Slip Desktop Bridge</h1>
          <p>Connected to @$username's Phone · <a href="javascript:void(0)" onclick="lockSession()" style="color:var(--steel); text-decoration:underline;">Lock Session</a></p>
        </div>
      </div>
      <div class="status-pill">
        <div class="status-dot"></div>
        <span>LIVE WI-FI LINK</span>
      </div>
    </div>

    <!-- Navigation Tabs Bar -->
    <div class="tabs-bar">
      <button class="tab-btn active" id="tabFeed" onclick="switchView('feed')">PEER FEED & DOUBTS</button>
      <button class="tab-btn" id="tabLog" onclick="switchView('log')">LOG MISTAKE / DOUBT</button>
      <button class="tab-btn" id="tabTasks" onclick="switchView('tasks')">REVISION & TASKS</button>
    </div>

    <div id="toastMsg" class="toast"></div>

    <!-- VIEW 1: PEER FEED & DOUBTS -->
    <div id="viewFeed" class="view-panel active">
      <div class="feed-toolbar">
        <div class="search-input-wrap">
          <input type="text" class="search-input" id="feedSearch" placeholder="Search doubts, traps, formulas, or handles..." oninput="filterFeed()">
        </div>
        <div class="filter-group">
          <div class="filter-pill active" id="filterTypeAll" onclick="setTypeFilter('all')">ALL</div>
          <div class="filter-pill" id="filterTypeDoubt" onclick="setTypeFilter('doubt')">DOUBTS</div>
          <div class="filter-pill" id="filterTypeMistake" onclick="setTypeFilter('mistake')">MISTAKES</div>
          <select class="select-dropdown" id="feedExamSelect" onchange="loadFeed()">
            <option value="All">All Registered Papers</option>
            <option value="GATE CS">GATE CS</option>
            <option value="GATE DA">GATE DA</option>
            <option value="GATE EC">GATE EC</option>
            <option value="GATE ME">GATE ME</option>
            <option value="General">General</option>
          </select>
          <button class="filter-pill" onclick="loadFeed()">REFRESH</button>
        </div>
      </div>

      <div id="feedContainer" class="slips-list">
        <div style="text-align:center; padding: 40px; color: var(--steel);">Loading live peer feed...</div>
      </div>
    </div>

    <!-- VIEW 2: LOG MISTAKE / DOUBT -->
    <div id="viewLog" class="view-panel">
      <div class="tabs-bar" style="margin-bottom:16px;">
        <button class="filter-pill active" id="modeMistake" onclick="setMode('mistake')">EXAM MISTAKE / TRAP</button>
        <button class="filter-pill" id="modeDoubt" onclick="setMode('doubt')">QUESTION DOUBT</button>
      </div>

      <form id="slipForm" onsubmit="submitSlipForm(event)">
        <div class="row">
          <div class="form-group">
            <label class="form-label">Target Exam</label>
            <select id="examSelect">
              <option value="$primaryExam">$primaryExam</option>
              <option value="GATE CS">GATE CS</option>
              <option value="GATE DA">GATE DA</option>
              <option value="GATE EC">GATE EC</option>
              <option value="GATE ME">GATE ME</option>
              <option value="General">General</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Subject</label>
            <input type="text" id="subjectInput" placeholder="e.g. Algorithms / Linear Algebra" value="General">
          </div>
        </div>

        <div class="form-group" id="titleGroup" style="display:none;">
          <label class="form-label">Doubt Title / Core Question</label>
          <input type="text" id="titleInput" placeholder="e.g. Why is quicksort worst case O(n^2)?">
        </div>

        <div class="form-group">
          <label class="form-label" id="trapLabel">The Conceptual Mistake / Trap You Fell For</label>
          <textarea id="trapInput" required placeholder="Describe what went wrong in your thought process during the mock test..."></textarea>
        </div>

        <div class="form-group" id="fixGroup">
          <label class="form-label">The Fix / Correct Rigorous Logic</label>
          <textarea id="fixInput" placeholder="What is the exact formula, theorem, or edge case to remember next time?"></textarea>
        </div>

        <!-- Screenshot Clipboard Paste Area -->
        <div class="paste-box" id="pasteBox">
          <p>Click here and press <strong>Ctrl + V</strong> to paste question screenshot</p>
          <small>Or drag and drop an image file from your laptop</small>
        </div>

        <div class="preview-area" id="previewArea">
          <div class="preview-info">
            <img id="previewImg" class="preview-thumb" src="" alt="Screenshot">
            <span style="font-size:12px; font-weight:600;" id="previewText">Clipboard Screenshot</span>
          </div>
          <span class="remove-img" onclick="removeImage()">REMOVE</span>
        </div>

        <button type="submit" class="submit-btn" id="submitBtn">LOG BLUNDER TO SLIP APP</button>
      </form>
    </div>

    <!-- VIEW 3: REVISION & TASKS -->
    <div id="viewTasks" class="view-panel">
      <!-- Create Task Bar -->
      <div class="task-create-bar">
        <input type="text" id="newTaskTitle" class="search-input" placeholder="New study task / mock test reminder...">
        <select id="newTaskExam" class="select-dropdown">
          <option value="$primaryExam">$primaryExam</option>
          <option value="GATE CS">GATE CS</option>
          <option value="GATE DA">GATE DA</option>
          <option value="GATE EC">GATE EC</option>
          <option value="GATE ME">GATE ME</option>
        </select>
        <input type="text" id="newTaskSubject" class="search-input" placeholder="Subject" value="General">
        <input type="date" id="newTaskDate" class="search-input">
        <button type="button" class="btn-comment-submit" onclick="submitCreateTask()">SCHEDULE</button>
      </div>

      <div id="tasksContainer" class="tasks-list">
        <div style="text-align:center; padding: 40px; color: var(--steel);">Loading tasks...</div>
      </div>
    </div>
  </div>

  <script>
    let activeView = 'feed';
    let activeMode = 'mistake';
    let activeTypeFilter = 'all';
    let base64Image = null;
    let desktopToken = sessionStorage.getItem('slip_desktop_token');
    let feedSlips = [];
    let currentUsername = '$username';

    if (desktopToken) {
      document.getElementById('authOverlay').style.display = 'none';
      initPortal();
    }

    async function verifyDesktopAuth() {
      const pass = document.getElementById('authPasswordInput').value;
      const errBox = document.getElementById('authError');
      const authBtn = document.getElementById('authSubmitBtn');
      errBox.style.display = 'none';

      if (!pass || pass.trim().length === 0) {
        errBox.textContent = 'Please enter your account password.';
        errBox.style.display = 'block';
        return;
      }

      authBtn.disabled = true;
      authBtn.textContent = 'VERIFYING...';

      try {
        const res = await fetch('/api/auth', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ password: pass })
        });
        const data = await res.json();
        if (res.ok && data.success && data.token) {
          desktopToken = data.token;
          if (data.username) currentUsername = data.username;
          sessionStorage.setItem('slip_desktop_token', desktopToken);
          document.getElementById('authOverlay').style.display = 'none';
          initPortal();
        } else {
          errBox.textContent = data.error || 'Authentication failed. Please check password.';
          errBox.style.display = 'block';
        }
      } catch (e) {
        errBox.textContent = 'Could not communicate with phone: ' + e.message;
        errBox.style.display = 'block';
      } finally {
        authBtn.disabled = false;
        authBtn.textContent = 'UNLOCK DESKTOP BRIDGE';
      }
    }

    function lockSession() {
      sessionStorage.removeItem('slip_desktop_token');
      desktopToken = null;
      document.getElementById('authPasswordInput').value = '';
      document.getElementById('authOverlay').style.display = 'flex';
    }

    function initPortal() {
      // Set default task date to tomorrow
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      document.getElementById('newTaskDate').value = tomorrow.toISOString().split('T')[0];

      loadFeed();
      loadTasks();
    }

    function switchView(view) {
      activeView = view;
      document.getElementById('tabFeed').classList.toggle('active', view === 'feed');
      document.getElementById('tabLog').classList.toggle('active', view === 'log');
      document.getElementById('tabTasks').classList.toggle('active', view === 'tasks');

      document.getElementById('viewFeed').classList.toggle('active', view === 'feed');
      document.getElementById('viewLog').classList.toggle('active', view === 'log');
      document.getElementById('viewTasks').classList.toggle('active', view === 'tasks');

      if (view === 'feed') loadFeed();
      if (view === 'tasks') loadTasks();
    }

    function setTypeFilter(type) {
      activeTypeFilter = type;
      document.getElementById('filterTypeAll').classList.toggle('active', type === 'all');
      document.getElementById('filterTypeDoubt').classList.toggle('active', type === 'doubt');
      document.getElementById('filterTypeMistake').classList.toggle('active', type === 'mistake');
      loadFeed();
    }

    async function loadFeed() {
      const container = document.getElementById('feedContainer');
      const exam = document.getElementById('feedExamSelect').value;
      const q = document.getElementById('feedSearch').value.trim();

      try {
        const res = await fetch('/api/feed?exam=' + encodeURIComponent(exam) + '&type=' + activeTypeFilter + '&q=' + encodeURIComponent(q), {
          headers: { 'Authorization': 'Bearer ' + desktopToken }
        });
        const data = await res.json();
        if (res.ok && data.slips) {
          feedSlips = data.slips;
          renderFeed(feedSlips);
        } else {
          container.innerHTML = '<div style="text-align:center; padding: 40px; color: var(--steel);">No peer posts found.</div>';
        }
      } catch (e) {
        container.innerHTML = '<div style="text-align:center; padding: 40px; color: var(--trap-red);">Error loading feed: ' + e.message + '</div>';
      }
    }

    function filterFeed() {
      const q = document.getElementById('feedSearch').value.toLowerCase().trim();
      if (!q) {
        renderFeed(feedSlips);
        return;
      }
      const filtered = feedSlips.filter(s => {
        const t = (s.title || '').toLowerCase();
        const tr = (s.trap_statement || '').toLowerCase();
        const fx = (s.fix_statement || '').toLowerCase();
        const tp = (s.topic || '').toLowerCase();
        const h = (s.author_handle || '').toLowerCase();
        return t.includes(q) || tr.includes(q) || fx.includes(q) || tp.includes(q) || h.includes(q);
      });
      renderFeed(filtered);
    }

    function renderFeed(slips) {
      const container = document.getElementById('feedContainer');
      if (!slips || slips.length === 0) {
        container.innerHTML = '<div style="text-align:center; padding: 40px; color: var(--steel);">No posts found matching the active filters.</div>';
        return;
      }

      container.innerHTML = slips.map(s => {
        const isDoubt = s.post_type === 'doubt';
        const typeBadge = isDoubt
            ? '<span class="badge badge-doubt">QUESTION DOUBT</span>'
            : '<span class="badge badge-mistake">MISTAKE / TRAP</span>';
        const resolvedBadge = s.is_resolved
            ? '<span class="badge badge-resolved">RESOLVED</span>'
            : '';
        const author = s.author_handle ? '@' + s.author_handle : '@peer';
        const imagesHtml = (s.image_urls && s.image_urls.length > 0)
            ? '<img class="slip-img-preview" src="' + s.image_urls[0] + '" alt="Screenshot" onclick="window.open(this.src)">'
            : '';
        const titleHtml = s.title ? '<div class="slip-title">' + escapeHtml(s.title) + '</div>' : '';

        return `
          <div class="slip-card" id="slip-\${s.id}">
            <div class="slip-card-header">
              <div class="badges-row">
                \${typeBadge}
                <span class="badge badge-exam">\${s.exam_tag || 'General'} · \${s.topic || 'General'}</span>
                \${resolvedBadge}
              </div>
              <div class="author-info">\${author}</div>
            </div>

            \${titleHtml}

            <div class="trap-box">
              <strong style="display:block; font-size:11px; text-transform:uppercase; color:var(--steel); margin-bottom:4px;">
                \${isDoubt ? 'Doubt Context / Confusion' : 'Conceptual Trap / Mistake'}
              </strong>
              \${escapeHtml(s.trap_statement || '')}
            </div>

            \${s.fix_statement ? `
              <div class="fix-box" id="fix-\${s.id}">
                <strong style="display:block; font-size:11px; text-transform:uppercase; color:var(--steel); margin-bottom:4px;">
                  \${isDoubt ? 'Verified Solution' : 'Inoculation Rule / Correct Logic'}
                </strong>
                \${escapeHtml(s.fix_statement)}
              </div>
            ` : ''}

            \${imagesHtml}

            <div class="card-actions">
              <div class="action-left">
                <button class="btn-action \${s.has_said_same ? 'active' : ''}" onclick="toggleSame('\${s.id}')">
                  I Fell For This (\${s.same_count || 0})
                </button>
                <button class="btn-action" onclick="toggleComments('\${s.id}')">
                  Discussion (\${s.comments_count || 0})
                </button>
              </div>
            </div>

            <!-- Comments Drawer -->
            <div class="comments-drawer" id="comments-\${s.id}">
              <div id="comments-list-\${s.id}"><small style="color:var(--steel)">Loading replies...</small></div>
              <div class="comment-form">
                <input type="text" class="comment-input" id="comment-input-\${s.id}" placeholder="Write an answer or helpful insight..." onkeydown="if(event.key==='Enter') postComment('\${s.id}')">
                <button class="btn-comment-submit" onclick="postComment('\${s.id}')">POST</button>
              </div>
            </div>
          </div>
        `;
      }).join('');
    }

    async function toggleSame(slipId) {
      if (!desktopToken) return;
      try {
        const res = await fetch('/api/slips/same', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + desktopToken },
          body: JSON.stringify({ slip_id: slipId })
        });
        if (res.ok) {
          loadFeed();
        }
      } catch (_) {}
    }

    async function toggleComments(slipId) {
      const drawer = document.getElementById('comments-' + slipId);
      const isOpen = drawer.classList.contains('open');
      if (isOpen) {
        drawer.classList.remove('open');
      } else {
        drawer.classList.add('open');
        loadComments(slipId);
      }
    }

    async function loadComments(slipId) {
      const listContainer = document.getElementById('comments-list-' + slipId);
      try {
        const res = await fetch('/api/comments?slip_id=' + slipId, {
          headers: { 'Authorization': 'Bearer ' + desktopToken }
        });
        const data = await res.json();
        if (res.ok && data.comments) {
          if (data.comments.length === 0) {
            listContainer.innerHTML = '<div style="font-size:12px; color:var(--steel); margin-bottom:8px;">No replies yet. Be the first to answer!</div>';
            return;
          }
          listContainer.innerHTML = data.comments.map(c => {
            const isAccepted = c.is_accepted_answer === true;
            return `
              <div class="comment-item">
                <div class="comment-header">
                  <span>@\${c.author_handle || 'peer'}</span>
                  \${isAccepted ? '<span class="accepted-tag">ACCEPTED SOLUTION</span>' : ''}
                </div>
                <div>\${escapeHtml(c.body || '')}</div>
                <button class="btn-accept" onclick="acceptComment('\${slipId}', '\${c.id}', \${!isAccepted})">
                  \${isAccepted ? 'Unmark Solution' : 'Mark as Accepted Solution'}
                </button>
              </div>
            `;
          }).join('');
        }
      } catch (e) {
        listContainer.innerHTML = '<div style="color:var(--trap-red); font-size:12px;">Failed to load comments</div>';
      }
    }

    async function postComment(slipId) {
      const input = document.getElementById('comment-input-' + slipId);
      const text = input.value.trim();
      if (!text || !desktopToken) return;

      try {
        const res = await fetch('/api/comments', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + desktopToken },
          body: JSON.stringify({ slip_id: slipId, body: text })
        });
        if (res.ok) {
          input.value = '';
          loadComments(slipId);
          showToast('Answer posted successfully!');
        }
      } catch (_) {}
    }

    async function acceptComment(slipId, commentId, isAccepted) {
      if (!desktopToken) return;
      try {
        const res = await fetch('/api/comments/accept', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + desktopToken },
          body: JSON.stringify({ slip_id: slipId, comment_id: commentId, is_accepted: isAccepted })
        });
        if (res.ok) {
          loadComments(slipId);
          loadFeed();
        }
      } catch (_) {}
    }

    // Tasks Management
    async function loadTasks() {
      const container = document.getElementById('tasksContainer');
      try {
        const res = await fetch('/api/tasks', {
          headers: { 'Authorization': 'Bearer ' + desktopToken }
        });
        const data = await res.json();
        if (res.ok && data.tasks) {
          if (data.tasks.length === 0) {
            container.innerHTML = '<div style="text-align:center; padding: 40px; color: var(--steel);">No study tasks scheduled yet. Add one above!</div>';
            return;
          }
          container.innerHTML = data.tasks.map(t => {
            const isDone = t.is_completed === true;
            const dateStr = t.scheduled_at ? new Date(t.scheduled_at).toLocaleDateString() : 'Scheduled';
            return `
              <div class="task-card \${isDone ? 'completed' : ''}">
                <div class="task-left">
                  <input type="checkbox" class="task-checkbox" \${isDone ? 'checked' : ''} onchange="toggleTask('\${t.id}')">
                  <div>
                    <div class="task-text">\${escapeHtml(t.title || 'Untitled Task')}</div>
                    <div class="task-meta">\${t.exam_tag || 'GATE'} · \${t.subject || 'General'} · Due \${dateStr}</div>
                  </div>
                </div>
              </div>
            `;
          }).join('');
        }
      } catch (e) {
        container.innerHTML = '<div style="color:var(--trap-red); text-align:center; padding:40px;">Failed to load tasks: ' + e.message + '</div>';
      }
    }

    async function toggleTask(taskId) {
      if (!desktopToken) return;
      try {
        const res = await fetch('/api/tasks/toggle', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + desktopToken },
          body: JSON.stringify({ task_id: taskId })
        });
        if (res.ok) {
          loadTasks();
        }
      } catch (_) {}
    }

    async function submitCreateTask() {
      const title = document.getElementById('newTaskTitle').value.trim();
      const exam = document.getElementById('newTaskExam').value;
      const subject = document.getElementById('newTaskSubject').value.trim() || 'General';
      const dateVal = document.getElementById('newTaskDate').value;

      if (!title || !desktopToken) {
        alert('Please enter a task title');
        return;
      }

      try {
        const res = await fetch('/api/tasks/create', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + desktopToken },
          body: JSON.stringify({
            title: title,
            examTag: exam,
            subject: subject,
            scheduledAt: dateVal ? new Date(dateVal).toISOString() : new Date().toISOString()
          })
        });
        if (res.ok) {
          document.getElementById('newTaskTitle').value = '';
          loadTasks();
          showToast('Task scheduled on Slip app!');
        }
      } catch (e) {
        alert('Error scheduling task: ' + e.message);
      }
    }

    // Tab 2 Log Slip Logic
    function setMode(mode) {
      activeMode = mode;
      document.getElementById('modeMistake').classList.toggle('active', mode === 'mistake');
      document.getElementById('modeDoubt').classList.toggle('active', mode === 'doubt');
      
      const titleGroup = document.getElementById('titleGroup');
      const fixGroup = document.getElementById('fixGroup');
      const trapLabel = document.getElementById('trapLabel');
      const submitBtn = document.getElementById('submitBtn');

      if (mode === 'doubt') {
        titleGroup.style.display = 'block';
        fixGroup.style.display = 'none';
        trapLabel.textContent = 'Doubt Context / What Confused You';
        submitBtn.textContent = 'POST DOUBT TO SLIP APP';
      } else {
        titleGroup.style.display = 'none';
        fixGroup.style.display = 'block';
        trapLabel.textContent = 'The Conceptual Mistake / Trap You Fell For';
        submitBtn.textContent = 'LOG BLUNDER TO SLIP APP';
      }
    }

    window.addEventListener('paste', (e) => {
      const items = (e.clipboardData || e.originalEvent.clipboardData).items;
      for (let item of items) {
        if (item.type.indexOf('image') !== -1) {
          const file = item.getAsFile();
          handleImageFile(file);
          break;
        }
      }
    });

    const pasteBox = document.getElementById('pasteBox');
    pasteBox.addEventListener('dragover', (e) => { e.preventDefault(); pasteBox.classList.add('dragover'); });
    pasteBox.addEventListener('dragleave', () => pasteBox.classList.remove('dragover'));
    pasteBox.addEventListener('drop', (e) => {
      e.preventDefault();
      pasteBox.classList.remove('dragover');
      if (e.dataTransfer.files.length > 0) {
        handleImageFile(e.dataTransfer.files[0]);
      }
    });

    function handleImageFile(file) {
      if (!file || !file.type.startsWith('image/')) return;
      const reader = new FileReader();
      reader.onload = (event) => {
        base64Image = event.target.result;
        document.getElementById('previewImg').src = base64Image;
        document.getElementById('previewText').textContent = file.name || 'Pasted Image (' + (file.size/1024).toFixed(0) + ' KB)';
        document.getElementById('previewArea').style.display = 'flex';
        pasteBox.style.display = 'none';
      };
      reader.readAsDataURL(file);
    }

    function removeImage() {
      base64Image = null;
      document.getElementById('previewArea').style.display = 'none';
      pasteBox.style.display = 'block';
    }

    async function submitSlipForm(e) {
      e.preventDefault();
      if (!desktopToken) {
        lockSession();
        return;
      }

      const submitBtn = document.getElementById('submitBtn');
      submitBtn.disabled = true;
      submitBtn.textContent = 'SAVING TO SLIP APP...';

      const payload = {
        title: document.getElementById('titleInput').value.trim(),
        trapStatement: document.getElementById('trapInput').value.trim(),
        fixStatement: document.getElementById('fixInput').value.trim(),
        examTag: document.getElementById('examSelect').value,
        topic: document.getElementById('subjectInput').value.trim() || 'General',
        subtopic: 'General',
        isDoubt: activeMode === 'doubt',
        imageBase64: base64Image
      };

      try {
        const res = await fetch('/api/slips', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + desktopToken
          },
          body: JSON.stringify(payload)
        });
        const result = await res.json();
        if (res.ok) {
          showToast((payload.isDoubt ? 'Doubt' : 'Mistake') + ' successfully logged into Slip!');
          document.getElementById('titleInput').value = '';
          document.getElementById('trapInput').value = '';
          document.getElementById('fixInput').value = '';
          removeImage();
          switchView('feed');
        } else if (res.status === 401) {
          alert('Desktop session expired or unauthorized. Please re-enter your password.');
          lockSession();
        } else {
          alert('Error: ' + (result.error || 'Failed to save'));
        }
      } catch (err) {
        alert('Network error communicating with phone: ' + err.message);
      } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = activeMode === 'doubt' ? 'POST DOUBT TO SLIP APP' : 'LOG BLUNDER TO SLIP APP';
      }
    }

    function showToast(msg) {
      const toast = document.getElementById('toastMsg');
      toast.textContent = msg;
      toast.style.display = 'block';
      setTimeout(() => toast.style.display = 'none', 3500);
    }

    function escapeHtml(text) {
      if (!text) return '';
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }
  </script>
</body>
</html>
''';

    request.response.headers.contentType = ContentType.html;
    request.response.write(html);
    await request.response.close();
  }
}
