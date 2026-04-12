import 'package:flutter/services.dart';

class AiModelService {
  static const _channel = MethodChannel('com.daiary.offline/gemma');

  static Future<bool> isModelReady() async {
    try {
      final result = await _channel.invokeMethod<bool>('isModelReady');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
