import 'dart:convert';
import 'dart:io';
import '../../constants/gate_syllabus.dart';
import '../../models/task_item.dart';
import '../../providers/slip_provider.dart';
import '../supabase_service.dart';
import 'desktop_auth_handler.dart';

class DesktopTasksHandler {
  final DesktopAuthHandler authHandler;

  const DesktopTasksHandler({required this.authHandler});

  Future<void> handleGetTasks(HttpRequest request, SlipProvider? provider) async {
    try {
      List<TaskItem> tasks = [];
      if (provider != null) {
        tasks = provider.tasks;
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

  Future<void> handleToggleTask(HttpRequest request, SlipProvider? provider) async {
    try {
      final bodyStr = await utf8.decodeStream(request);
      final Map<String, dynamic> data = jsonDecode(bodyStr);

      if (!authHandler.isAuthorized(request, data)) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'error': 'Unauthorized'}));
        await request.response.close();
        return;
      }

      final taskId = data['task_id'] as String? ?? '';
      if (taskId.isNotEmpty && provider != null) {
        await provider.toggleTaskCompleted(taskId);
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

  Future<void> handleCreateTask(HttpRequest request, SlipProvider? provider) async {
    try {
      final bodyStr = await utf8.decodeStream(request);
      final Map<String, dynamic> data = jsonDecode(bodyStr);

      if (!authHandler.isAuthorized(request, data)) {
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
          ? (DateTime.tryParse(scheduledStr) ??
              DateTime.now().add(const Duration(days: 1)))
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

      if (provider != null) {
        await provider.addTask(newTask);
      }

      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'success': true,
        'task': newTask.toJson(),
      }));
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    }
  }
}
