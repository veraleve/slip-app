import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../constants/gate_syllabus.dart';
import '../../models/slip.dart';
import '../../providers/slip_provider.dart';
import '../native_device_service.dart';
import '../supabase_service.dart';
import 'desktop_auth_handler.dart';

class DesktopFeedHandler {
  final DesktopAuthHandler authHandler;

  const DesktopFeedHandler({required this.authHandler});

  Future<void> handleGetFeed(HttpRequest request, SlipProvider? provider) async {
    try {
      final examFilter = request.uri.queryParameters['exam'];
      final typeFilter = request.uri.queryParameters['type'];
      final search = request.uri.queryParameters['q']?.toLowerCase().trim();

      List<Slip> list = [];
      if (provider != null) {
        list = List.from(provider.allSlips);
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
          return t.contains(search) ||
              tr.contains(search) ||
              fx.contains(search) ||
              tp.contains(search) ||
              h.contains(search);
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

  Future<void> handlePostSlip(HttpRequest request, SlipProvider? provider) async {
    try {
      final bodyStr = await utf8.decodeStream(request);
      final Map<String, dynamic> data = jsonDecode(bodyStr);

      if (!authHandler.isAuthorized(request, data)) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
            jsonEncode({'error': 'Unauthorized. Please authenticate desktop session.'}));
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
        request.response.write(
            jsonEncode({'error': 'Trap or context statement cannot be empty'}));
        await request.response.close();
        return;
      }

      final attachedImages = <String>[];
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        try {
          final cleanBase64 =
              imageBase64.contains(',') ? imageBase64.split(',').last : imageBase64;
          final bytes = base64Decode(cleanBase64);
          final cacheDir =
              await NativeDeviceService.getAppCacheDir() ?? Directory.systemTemp.path;
          final filePath =
              '$cacheDir/slip_desktop_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final file = File(filePath);
          await file.writeAsBytes(bytes);
          attachedImages.add(filePath);
        } catch (e) {
          debugPrint('Error saving desktop screenshot: $e');
        }
      }

      if (provider != null) {
        await provider.dropSlip(
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

  Future<void> handleToggleSame(HttpRequest request, SlipProvider? provider) async {
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

      final slipId = data['slip_id'] as String? ?? '';
      if (provider != null && slipId.isNotEmpty) {
        provider.toggleSame(slipId);
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

  Future<void> handleServeMedia(HttpRequest request) async {
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
    final contentType =
        ext == 'png' ? ContentType('image', 'png') : ContentType('image', 'jpeg');
    request.response.headers.contentType = contentType;
    await request.response.addStream(file.openRead());
    await request.response.close();
  }
}
