import 'package:flutter/services.dart';

class NativeDeviceService {
  static const MethodChannel _channel = MethodChannel('com.veraleve.slip/native');

  // Check current granted permissions
  static Future<Map<String, bool>> checkPermissions() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('checkPermissions');
      if (res != null) {
        return res.map((k, v) => MapEntry(k.toString(), v == true));
      }
    } catch (_) {}
    return {'camera': false, 'notifications': false, 'bluetooth': false};
  }

  // Request camera, notifications, and bluetooth permissions
  static Future<Map<String, bool>> requestPermissions() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('requestPermissions');
      if (res != null) {
        return res.map((k, v) => MapEntry(k.toString(), v == true));
      }
    } catch (_) {}
    return {'camera': false, 'notifications': false, 'bluetooth': false};
  }

  // Show a rich system notification
  static Future<bool> showNotification({
    required String title,
    required String body,
    int id = 101,
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('showNotification', {
        'title': title,
        'body': body,
        'id': id,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  // Launch camera intent and capture photo
  static Future<String?> capturePhoto() async {
    try {
      final res = await _channel.invokeMethod<String>('openCamera');
      return res;
    } catch (_) {
      return null;
    }
  }
}
