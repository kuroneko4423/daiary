import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static const String _shareTempDirName = 'ai_photographer_share';

  // --- Existing methods ---

  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<void> shareText(String text) async {
    await Share.share(text);
  }

  static Future<void> shareTextWithPhoto(
      String text, String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: text);
  }

  // --- BL-001: Image sharing ---

  static Future<void> shareImage(String imagePath) async {
    await Share.shareXFiles([XFile(imagePath)]);
  }

  static Future<void> shareImageWithText(
    String imagePath, {
    String? text,
  }) async {
    await Share.shareXFiles([XFile(imagePath)], text: text);
  }

  // --- BL-003: Base64 to temp file ---

  static Future<String> saveTempFileFromBase64(
    String base64Data, {
    String? prefix,
  }) async {
    final dir = await _getShareTempDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${prefix ?? 'share'}_$timestamp.png';
    final file = File('${dir.path}/$fileName');
    final bytes = base64Decode(base64Data);
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // --- BL-007: Temp file cleanup ---

  static Future<void> cleanupTempShareFiles() async {
    try {
      final dir = await _getShareTempDir(create: false);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // Ignore cleanup errors — OS also periodically cleans temp dir
    }
  }

  static Future<Directory> _getShareTempDir({bool create = true}) async {
    final tempDir = await getTemporaryDirectory();
    final shareDir = Directory('${tempDir.path}/$_shareTempDirName');
    if (create && !await shareDir.exists()) {
      await shareDir.create(recursive: true);
    }
    return shareDir;
  }
}
