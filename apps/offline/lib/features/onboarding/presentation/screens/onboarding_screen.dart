import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/router.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(onboardingNotifierProvider.notifier).checkModelStatus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AIモデルセットアップ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Icon(
              Icons.smart_toy_outlined,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Gemma 4 E2B',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ハッシュタグ・キャプション生成用のオンデバイスAI',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.wifi, size: 20,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'このアプリはAIモデルのダウンロードと広告配信にネットワークを使用します。'
                        'その他の機能はオフラインで動作します。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          state.isModelReady
                              ? Icons.check_circle
                              : Icons.download,
                          color: state.isModelReady
                              ? Colors.green
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.isModelReady
                                ? 'モデルの準備が完了しました'
                                : 'モデルがダウンロードされていません',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    if (state.isDownloading) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: state.downloadProgress),
                      const SizedBox(height: 8),
                      Text(
                        '${(state.downloadProgress * 100).toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Action buttons
            if (!state.isModelReady && !state.isDownloading)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _startDownload(),
                  icon: const Icon(Icons.download),
                  label: const Text('モデルをダウンロード(約1GB)'),
                ),
              ),

            if (state.isDownloading)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ref
                        .read(onboardingNotifierProvider.notifier)
                        .cancelDownload();
                  },
                  child: const Text('キャンセル'),
                ),
              ),

            if (state.isModelReady) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _completeOnboarding(),
                  child: const Text('完了'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(onboardingNotifierProvider.notifier)
                        .deleteModel();
                  },
                  icon: Icon(Icons.delete, color: theme.colorScheme.error),
                  label: Text('モデルを削除',
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _startDownload() async {
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final onWifi = await notifier.isOnWifi();

    if (!onWifi && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Wi-Fiに接続されていません'),
          content: const Text(
            'Wi-Fiに接続されていません。'
            'モデルのダウンロードは約1GBです。'
            'モバイルデータを使用して続行しますか?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('続行'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
      notifier.downloadModel(skipWifiCheck: true);
    } else {
      notifier.downloadModel(skipWifiCheck: true);
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    ref.invalidate(hasCompletedOnboardingProvider);
    if (mounted) {
      context.go('/camera');
    }
  }
}
