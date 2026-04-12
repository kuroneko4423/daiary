import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Profile section
          _buildSectionHeader(context, 'Profile'),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                (user?.username ?? user?.email ?? 'U')
                    .substring(0, 1)
                    .toUpperCase(),
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
            title: Text(user?.username ?? 'User'),
            subtitle: Text(user?.email ?? ''),
          ),
          const Divider(),

          // Default AI Settings section
          _buildSectionHeader(context, 'Default AI Settings'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Default Language'),
            subtitle: Text(
                settings.defaultLanguage == 'ja' ? '\u65E5\u672C\u8A9E' : 'English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context, ref, settings.defaultLanguage),
          ),
          ListTile(
            leading: const Icon(Icons.style),
            title: const Text('Default Style'),
            subtitle: Text(_styleLabel(settings.defaultStyle)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showStyleDialog(context, ref, settings.defaultStyle),
          ),
          const Divider(),

          // Theme section
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(_themeModeLabel(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, ref, settings.themeMode),
          ),
          const Divider(),

          // Storage section
          _buildSectionHeader(context, 'Storage'),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Storage Usage'),
            subtitle: const Text('Calculating...'),
          ),
          const Divider(),

          // Subscription section
          _buildSectionHeader(context, 'Subscription'),
          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('Current Plan'),
            subtitle: Text(user?.isPremium == true ? 'Premium' : 'Free'),
            trailing: user?.isPremium == true
                ? null
                : FilledButton(
                    onPressed: () => context.push('/subscription'),
                    child: const Text('Upgrade'),
                  ),
          ),
          const Divider(),

          // About section
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Open privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Open terms
            },
          ),
          const Divider(),

          // Sign out
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text('Sign Out',
                style: TextStyle(color: theme.colorScheme.error)),
            onTap: () => _confirmSignOut(context, ref),
          ),

          // Delete account
          ListTile(
            leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
            title: Text('Delete Account',
                style: TextStyle(color: theme.colorScheme.error)),
            onTap: () => _confirmDeleteAccount(context, ref),
          ),

          const SizedBox(height: 24),
        ],
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

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action is permanent and cannot be undone. All your data will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Account deletion request sent')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
