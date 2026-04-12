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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Default AI Settings section
          _buildSectionHeader(context, 'Default AI Settings'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Default Language'),
            subtitle:
                Text(settings.defaultLanguage == 'ja' ? '\u65E5\u672C\u8A9E' : 'English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showLanguageDialog(context, ref, settings.defaultLanguage),
          ),
          ListTile(
            leading: const Icon(Icons.style),
            title: const Text('Default Style'),
            subtitle: Text(_styleLabel(settings.defaultStyle)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showStyleDialog(context, ref, settings.defaultStyle),
          ),
          const Divider(),

          // AI Model section
          _buildSectionHeader(context, 'AI Model'),
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: const Text('AI Model Management'),
            subtitle: const Text('Gemma 4 E2B'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/onboarding'),
          ),
          const Divider(),

          // Theme section
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(_themeModeLabel(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showThemeDialog(context, ref, settings.themeMode),
          ),
          const Divider(),

          // Storage section
          _buildSectionHeader(context, 'Storage'),
          _buildStorageTile(ref),
          const Divider(),

          // Data management
          _buildSectionHeader(context, 'Data'),
          ListTile(
            leading: Icon(Icons.delete_sweep, color: theme.colorScheme.error),
            title: Text('Clear All Data',
                style: TextStyle(color: theme.colorScheme.error)),
            onTap: () => _confirmClearData(context, ref),
          ),
          const Divider(),

          // About section
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: const Text('1.0.0 (Offline)'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
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
      title: const Text('Storage Usage'),
      subtitle: storageAsync.when(
        data: (usage) => Text(
          '${_formatBytes(usage.totalBytes)} '
          '(Photos: ${_formatBytes(usage.photosBytes)}, '
          'Thumbnails: ${_formatBytes(usage.thumbnailsBytes)})',
        ),
        loading: () => const Text('Calculating...'),
        error: (_, __) => const Text('Unable to calculate'),
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
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System';
    }
  }

  void _showLanguageDialog(
      BuildContext context, WidgetRef ref, String current) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Default Language'),
        children: [
          RadioListTile<String>(
            title: const Text('\u65E5\u672C\u8A9E'),
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
            title: const Text('English'),
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
        title: const Text('Default Style'),
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
        title: const Text('Theme'),
        children: [
          RadioListTile<String>(
            title: const Text('Light'),
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
            title: const Text('Dark'),
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
            title: const Text('System'),
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
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all photos, albums, and AI generation history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
                    const SnackBar(content: Text('All data cleared')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to clear data: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
