import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../../services/database_service.dart';

class AiLocalDataSource {
  static const _channel = MethodChannel('com.daiary.offline/gemma');
  final _uuid = const Uuid();

  Future<bool> isModelReady() async {
    try {
      final result = await _channel.invokeMethod<bool>('isModelReady');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> generateHashtags({
    required String photoLocalPath,
    required String language,
    required int count,
    required String usage,
  }) async {
    final stopwatch = Stopwatch()..start();

    final result = await _channel.invokeMethod<String>('generateHashtags', {
      'photoPath': photoLocalPath,
      'language': language,
      'count': count,
      'usage': usage,
    });

    stopwatch.stop();

    final parsed = _parseJsonResponse(result ?? '{"hashtags": []}');
    final hashtags = (parsed['hashtags'] as List<dynamic>).cast<String>();

    // Save to DB
    await _saveGeneration(
      photoPath: photoLocalPath,
      generationType: 'hashtags',
      result: jsonEncode({'hashtags': hashtags}),
      language: language,
      latencyMs: stopwatch.elapsedMilliseconds,
    );

    return {'hashtags': hashtags};
  }

  Future<Map<String, dynamic>> generateCaption({
    required String photoLocalPath,
    required String language,
    required String style,
    required String length,
    String? customPrompt,
  }) async {
    final stopwatch = Stopwatch()..start();

    final result = await _channel.invokeMethod<String>('generateCaption', {
      'photoPath': photoLocalPath,
      'language': language,
      'style': style,
      'length': length,
      'customPrompt': customPrompt,
    });

    stopwatch.stop();

    final parsed = _parseJsonResponse(result ?? '{"caption": ""}');
    final caption = parsed['caption'] as String;

    // Save to DB
    await _saveGeneration(
      photoPath: photoLocalPath,
      generationType: 'caption',
      result: jsonEncode({'caption': caption}),
      style: style,
      language: language,
      latencyMs: stopwatch.elapsedMilliseconds,
    );

    return {'caption': caption};
  }

  Map<String, dynamic> _parseJsonResponse(String response) {
    // Strip markdown code fences if present
    var cleaned = response.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
    }
    return jsonDecode(cleaned.trim()) as Map<String, dynamic>;
  }

  Future<void> _saveGeneration({
    required String photoPath,
    required String generationType,
    required String result,
    String? style,
    required String language,
    required int latencyMs,
  }) async {
    final db = await DatabaseService.database;
    await db.insert('ai_generations', {
      'id': _uuid.v4(),
      'photo_id': photoPath, // Using path as reference for offline
      'generation_type': generationType,
      'model': 'gemma-4-e2b',
      'result': result,
      'style': style,
      'language': language,
      'latency_ms': latencyMs,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
