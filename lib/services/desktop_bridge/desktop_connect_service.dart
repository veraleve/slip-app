import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../constants/app_constants.dart';
import '../../constants/gate_syllabus.dart';
import '../../providers/slip_provider.dart';
import '../supabase_service.dart';
import 'desktop_auth_handler.dart';
import 'desktop_comments_handler.dart';
import 'desktop_feed_handler.dart';
import 'desktop_tasks_handler.dart';
import 'desktop_web_template.dart';

class DesktopConnectService {
  static final DesktopConnectService _instance =
      DesktopConnectService._internal();
  factory DesktopConnectService() => _instance;
  DesktopConnectService._internal()
      : authHandler = DesktopAuthHandler() {
    feedHandler = DesktopFeedHandler(authHandler: authHandler);
    commentsHandler = DesktopCommentsHandler(authHandler: authHandler);
    tasksHandler = DesktopTasksHandler(authHandler: authHandler);
  }

  HttpServer? _server;
  String? _localIp;
  int _port = 8080;
  SlipProvider? _provider;

  final DesktopAuthHandler authHandler;
  late final DesktopFeedHandler feedHandler;
  late final DesktopCommentsHandler commentsHandler;
  late final DesktopTasksHandler tasksHandler;

  bool get isRunning => _server != null;
  String? get serverUrl =>
      isRunning && _localIp != null ? 'http://$_localIp:$_port' : null;
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
    authHandler.refreshToken();
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

  void _handleRequest(HttpRequest request) async {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add(
        'Access-Control-Allow-Headers', 'Origin, Content-Type, Accept, Authorization');

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
      await authHandler.handleAuth(request);
    } else if (request.method == 'GET' && path == '/api/feed') {
      await feedHandler.handleGetFeed(request, _provider);
    } else if (request.method == 'POST' && path == '/api/slips') {
      await feedHandler.handlePostSlip(request, _provider);
    } else if (request.method == 'POST' && path == '/api/slips/same') {
      await feedHandler.handleToggleSame(request, _provider);
    } else if (request.method == 'GET' && path == '/api/comments') {
      await commentsHandler.handleGetComments(request);
    } else if (request.method == 'POST' && path == '/api/comments') {
      await commentsHandler.handlePostComment(request, _provider);
    } else if (request.method == 'POST' && path == '/api/comments/accept') {
      await commentsHandler.handleAcceptComment(request);
    } else if (request.method == 'GET' && path == '/api/tasks') {
      await tasksHandler.handleGetTasks(request, _provider);
    } else if (request.method == 'POST' && path == '/api/tasks/toggle') {
      await tasksHandler.handleToggleTask(request, _provider);
    } else if (request.method == 'POST' && path == '/api/tasks/create') {
      await tasksHandler.handleCreateTask(request, _provider);
    } else if (request.method == 'GET' && path == '/api/media') {
      await feedHandler.handleServeMedia(request);
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('Not Found');
      await request.response.close();
    }
  }

  void _serveDesktopWebPage(HttpRequest request) async {
    final service = SupabaseService();
    final username = service.currentUsername ?? 'peer';
    final targetExams = service.targetExams;
    final primaryExam =
        targetExams.isNotEmpty ? targetExams.first : GateSyllabus.gateCS;

    final html = DesktopWebTemplate.render(
      username: username,
      primaryExam: primaryExam,
    );

    request.response.headers.contentType = ContentType.html;
    request.response.write(html);
    await request.response.close();
  }
}
