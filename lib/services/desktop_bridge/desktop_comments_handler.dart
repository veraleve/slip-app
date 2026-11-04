import 'dart:convert';
import 'dart:io';
import '../../providers/slip_provider.dart';
import '../supabase_service.dart';
import 'desktop_auth_handler.dart';

class DesktopCommentsHandler {
  final DesktopAuthHandler authHandler;

  const DesktopCommentsHandler({required this.authHandler});

  Future<void> handleGetComments(HttpRequest request) async {
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

  Future<void> handlePostComment(HttpRequest request, SlipProvider? provider) async {
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
      if (provider != null) {
        success = await provider.postComment(
          slipId: slipId,
          body: body.trim(),
          parentId: parentId,
        );
      } else {
        success = await SupabaseService().postComment(
          slipId: slipId,
          body: body.trim(),
          parentId: parentId,
        );
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

  Future<void> handleAcceptComment(HttpRequest request) async {
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
}
