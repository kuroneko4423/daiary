import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/database_service.dart';
import '../../../album/presentation/providers/photo_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/storage_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          // Default AI Settings section
          _buildSectionHeader(context, 'デフォルトAI設定'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('デフォルト言語'),
            subtitle:
                Text(settings.defaultLanguage == 'ja' ? '日本語' : '英語'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showLanguageDialog(context, ref, settings.defaultLanguage),
          ),
          ListTile(
            leading: const Icon(Icons.style),
            title: const Text('デフォルトスタイル'),
            subtitle: Text(_styleLabel(settings.defaultStyle)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showStyleDialog(context, ref, settings.defaultStyle),
          ),
          const Divider(),

          // AI Model section
          _buildSectionHeader(context, 'AIモデル'),
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: const Text('AIモデル管理'),
            subtitle: const Text('Gemma 4 E2B'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/onboarding'),
          ),
          const Divider(),

          // Theme section
          _buildSectionHeader(context, '外観'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('テーマ'),
            subtitle: Text(_themeModeLabel(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showThemeDialog(context, ref, settings.themeMode),
          ),
          const Divider(),

          // Storage section
          _buildSectionHeader(context, 'ストレージ'),
          _buildStorageTile(ref),
          const Divider(),

          // Data management
          _buildSectionHeader(context, 'データ'),
          ListTile(
            leading: Icon(Icons.delete_sweep, color: theme.colorScheme.error),
            title: Text('すべてのデータを削除',
                style: TextStyle(color: theme.colorScheme.error)),
            onTap: () => _confirmClearData(context, ref),
          ),
          const Divider(),

          // Network usage section
          _buildSectionHeader(context, 'ネットワーク使用'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.wifi, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'このアプリがネットワークを使用する場面:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '・AIモデルのダウンロード(初回セットアップ、約1GB)\n'
                          '・広告配信(Google AdMob)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'その他すべての機能(カメラ、アルバム、AI生成)は完全にオフラインで動作します。',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),

          // About section
          _buildSectionHeader(context, 'このアプリについて'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('バージョン'),
            subtitle: const Text('1.0.0 (オフライン)'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Open privacy policy
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Widget _buildStorageTile(WidgetRef ref) {
    final storageAsync = ref.watch(storageUsageProvider);
    return ListTile(
      leading: const Icon(Icons.storage),
      title: const Text('ストレージ使用量'),
      subtitle: storageAsync.when(
        data: (usage) => Text(
          '${_formatBytes(usage.totalBytes)} '
          '(写真: ${_formatBytes(usage.photosBytes)}, '
          'サムネイル: ${_formatBytes(usage.thumbnailsBytes)})',
        ),
        loading: () => const Text('計算中...'),
        error: (_, __) => const Text('計算できません'),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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

  String _styleLabel(String style) {
    switch (style) {
      case 'poem':
        return '\u30DD\u30A8\u30E0\u98A8';
      case 'business':
        return '\u30D3\u30B8\u30CD\u30B9\u98A8';
      case 'casual':
        return '\u30AB\u30B8\u30E5\u30A2\u30EB\u98A8';
      case 'news':
        return '\u30CB\u30E5\u30FC\u30B9\u98A8';
      case 'humor':
        return '\u30E6\u30FC\u30E2\u30A2\u98A8';
      default:
        return '\u30AB\u30B8\u30E5\u30A2\u30EB\u98A8';
    }
  }

  String _themeModeLabel(String mode) {
    switch (mode) {
      case 'light':
        return 'ライト';
      case 'dark':
        return 'ダーク';
      default:
        return 'システム';
    }
  }

  void _showLanguageDialog(
      BuildContext context, WidgetRef ref, String current) {
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
              if (value != null) {
                ref.read(settingsProvider.notifier).setDefaultLanguage(value);
              }
              Navigator.pop(context);
            },
          ),
          RadioListTile<String>(
            title: const Text('英語'),
            value: 'en',
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).setDefaultLanguage(value);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showStyleDialog(BuildContext context, WidgetRef ref, String current) {
    final styles = {
      'poem': '\u30DD\u30A8\u30E0\u98A8',
      'business': '\u30D3\u30B8\u30CD\u30B9\u98A8',
      'casual': '\u30AB\u30B8\u30E5\u30A2\u30EB\u98A8',
      'news': '\u30CB\u30E5\u30FC\u30B9\u98A8',
      'humor': '\u30E6\u30FC\u30E2\u30A2\u98A8',
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
              if (value != null) {
                ref.read(settingsProvider.notifier).setDefaultStyle(value);
              }
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, String current) {
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
              if (value != null) {
                ref.read(settingsProvider.notifier).setThemeMode(value);
              }
              Navigator.pop(context);
            },
          ),
          RadioListTile<String>(
            title: const Text('ダーク'),
            value: 'dark',
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).setThemeMode(value);
              }
              Navigator.pop(context);
            },
          ),
          RadioListTile<String>(
            title: const Text('システム'),
            value: 'system',
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).setThemeMode(value);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('すべてのデータを削除'),
        content: const Text(
          'すべての写真、アルバム、AI生成履歴が完全に削除されます。この操作は元に戻せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await DatabaseService.clearAllData();
                // Refresh photo list and storage usage
                ref.invalidate(photoListNotifierProvider);
                ref.invalidate(storageUsageProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('すべてのデータを削除しました')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('データの削除に失敗しました: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
