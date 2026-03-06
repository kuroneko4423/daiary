import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<void> shareText(String text) async {
    await Share.share(text);
  }

  static Future<void> shareTextWithPhoto(String text, String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: text);
  }
}
