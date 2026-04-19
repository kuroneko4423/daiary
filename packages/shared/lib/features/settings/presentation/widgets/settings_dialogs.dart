import 'package:flutter/material.dart';

void showLanguageDialog(
  BuildContext context, {
  required String current,
  required ValueChanged<String> onChanged,
}) {
  showDialog(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('デフォルト言語'),
      children: [
        RadioListTile<String>(
          title: const Text('日本語'),
          value: 'ja',
          groupValue: current,
          onChanged: (value) {
            if (value != null) onChanged(value);
            Navigator.pop(context);
          },
        ),
        RadioListTile<String>(
          title: const Text('英語'),
          value: 'en',
          groupValue: current,
          onChanged: (value) {
            if (value != null) onChanged(value);
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

void showStyleDialog(
  BuildContext context, {
  required String current,
  required ValueChanged<String> onChanged,
}) {
  final styles = {
    'poem': 'ポエム風',
    'business': 'ビジネス風',
    'casual': 'カジュアル風',
    'news': 'ニュース風',
    'humor': 'ユーモア風',
  };

  showDialog(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('デフォルトスタイル'),
      children: styles.entries.map((entry) {
        return RadioListTile<String>(
          title: Text(entry.value),
          value: entry.key,
          groupValue: current,
          onChanged: (value) {
            if (value != null) onChanged(value);
            Navigator.pop(context);
          },
        );
      }).toList(),
    ),
  );
}

void showThemeDialog(
  BuildContext context, {
  required String current,
  required ValueChanged<String> onChanged,
}) {
  showDialog(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('テーマ'),
      children: [
        RadioListTile<String>(
          title: const Text('ライト'),
          value: 'light',
          groupValue: current,
          onChanged: (value) {
            if (value != null) onChanged(value);
            Navigator.pop(context);
          },
        ),
        RadioListTile<String>(
          title: const Text('ダーク'),
          value: 'dark',
          groupValue: current,
          onChanged: (value) {
            if (value != null) onChanged(value);
            Navigator.pop(context);
          },
        ),
        RadioListTile<String>(
          title: const Text('システム'),
          value: 'system',
          groupValue: current,
          onChanged: (value) {
            if (value != null) onChanged(value);
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

String styleLabel(String style) {
  switch (style) {
    case 'poem':
      return 'ポエム風';
    case 'business':
      return 'ビジネス風';
    case 'casual':
      return 'カジュアル風';
    case 'news':
      return 'ニュース風';
    case 'humor':
      return 'ユーモア風';
    default:
      return 'カジュアル風';
  }
}

String themeModeLabel(String mode) {
  switch (mode) {
    case 'light':
      return 'ライト';
    case 'dark':
      return 'ダーク';
    default:
      return 'システム';
  }
}

Widget buildSectionHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
    ),
  );
}
