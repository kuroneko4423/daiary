import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
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

    final photoBytes = await _safeFileLength(photoLocalPath);
    debugPrint(
      '[AiLocal] generateHashtags photo=$photoLocalPath bytes=$photoBytes '
      'lang=$language count=$count usage=$usage',
    );

    final result = await _channel.invokeMethod<String>('generateHashtags', {
      'photoPath': photoLocalPath,
      'language': language,
      'count': count,
      'usage': usage,
    });

    stopwatch.stop();
    _logRawResponse('hashtags', result);

    final parsed = _parseJsonResponseStrict('hashtags', result ?? '{"hashtags": []}');
    final hashtags = (parsed['hashtags'] as List<dynamic>).cast<String>();

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

    final photoBytes = await _safeFileLength(photoLocalPath);
    debugPrint(
      '[AiLocal] generateCaption photo=$photoLocalPath bytes=$photoBytes '
      'lang=$language style=$style length=$length',
    );

    final result = await _channel.invokeMethod<String>('generateCaption', {
      'photoPath': photoLocalPath,
      'language': language,
      'style': style,
      'length': length,
      'customPrompt': customPrompt,
    });

    stopwatch.stop();
    _logRawResponse('caption', result);

    final parsed = _parseJsonResponseStrict('caption', result ?? '{"caption": ""}');
    final caption = parsed['caption'] as String;

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

  Future<int> _safeFileLength(String path) async {
    try {
      return await File(path).length();
    } catch (_) {
      return -1;
    }
  }

  void _logRawResponse(String kind, String? raw) {
    final value = raw ?? '';
    final head = value.substring(0, min(300, value.length));
    debugPrint(
      '[AiLocal] $kind raw response (${value.length} chars): $head',
    );
  }

  Map<String, dynamic> _parseJsonResponseStrict(String kind, String response) {
    var cleaned = response.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
    }
    try {
      return jsonDecode(cleaned.trim()) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[AiLocal] $kind JSON parse failed: $e raw=$response');
      rethrow;
    }
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
    final rows = await db.query(
      'photos',
      columns: ['id'],
      where: 'local_path = ?',
      whereArgs: [photoPath],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final photoId = rows.first['id'] as String;

    await db.insert('ai_generations', {
      'id': _uuid.v4(),
      'photo_id': photoId,
      'generation_type': generationType,
      'model': 'gemma-3n-e2b',
      'result': result,
      'style': style,
      'language': language,
      'latency_ms': latencyMs,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
