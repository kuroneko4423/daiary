import 'dart:io';
import 'package:daiary_shared/core/constants/share_constants.dart';
import 'package:daiary_shared/domain/models/generation_result.dart';
import 'package:daiary_shared/features/ai_generate/presentation/widgets/result_card.dart';
import 'package:daiary_shared/features/ai_generate/presentation/widgets/style_selector.dart';
import 'package:daiary_shared/services/share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../settings/presentation/providers/ad_provider.dart';
import '../../../settings/presentation/widgets/banner_ad_widget.dart';
import '../providers/ai_generate_provider.dart';

class AIGenerateScreen extends ConsumerStatefulWidget {
  final String? photoPath;

  const AIGenerateScreen({super.key, this.photoPath});

  @override
  ConsumerState<AIGenerateScreen> createState() => _AIGenerateScreenState();
}

class _AIGenerateScreenState extends ConsumerState<AIGenerateScreen> {
  final _customPromptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiGenerateNotifierProvider.notifier).checkModelReady();
    });
  }

  @override
  void dispose() {
    _customPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiGenerateNotifierProvider);
    final selectedStyle = ref.watch(selectedStyleProvider);
    final selectedLanguage = ref.watch(selectedLanguageProvider);
    final selectedLength = ref.watch(selectedLengthProvider);
    final theme = Theme.of(context);

    return Scaffold(
      bottomNavigationBar: const BannerAdWidget(),
      appBar: AppBar(
        title: const Text('AI生成'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                aiState.isModelReady ? '準備完了' : 'モデル未ダウンロード',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: aiState.isModelReady ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo preview
            if (widget.photoPath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.photoPath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Model not downloaded banner
            if (!aiState.isModelReady) ...[
              Card(
                color: theme.colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: theme.colorScheme.onSecondaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AIモデルがダウンロードされていません。設定 > AIモデル管理からダウンロードしてください。',
                          style: TextStyle(
                              color: theme.colorScheme.onSecondaryContainer),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => context.go('/settings'),
                        child: const Text('設定'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Style selector
            Text('スタイル', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            StyleSelector(
              selected: selectedStyle,
              onSelected: (style) =>
                  ref.read(selectedStyleProvider.notifier).state = style,
            ),
            const SizedBox(height: 16),

            // Custom prompt (visible when custom style selected)
            if (selectedStyle == GenerationStyle.custom) ...[
              TextField(
                controller: _customPromptController,
                decoration: const InputDecoration(
                  labelText: 'カスタムプロンプト',
                  hintText: '希望のスタイルを説明してください...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],

            // Language selector
            Text('言語', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ja', label: Text('日本語')),
                ButtonSegment(value: 'en', label: Text('英語')),
              ],
              selected: {selectedLanguage},
              onSelectionChanged: (values) =>
                  ref.read(selectedLanguageProvider.notifier).state =
                      values.first,
            ),
            const SizedBox(height: 16),

            // Length selector
            Text('キャプション長', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<GenerationLength>(
              segments: GenerationLength.values
                  .map((l) => ButtonSegment(value: l, label: Text(l.label)))
                  .toList(),
              selected: {selectedLength},
              onSelectionChanged: (values) =>
                  ref.read(selectedLengthProvider.notifier).state =
                      values.first,
            ),
            const SizedBox(height: 24),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: aiState.isLoadingHashtags ||
                        aiState.isLoadingCaption ||
                        !aiState.isModelReady
                    ? null
                    : () => _generateAll(),
                icon: aiState.isLoadingHashtags || aiState.isLoadingCaption
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  aiState.isLoadingHashtags
                      ? 'ハッシュタグを生成中...'
                      : aiState.isLoadingCaption
                          ? 'キャプションを生成中...'
                          : '生成',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error display
            if (aiState.error != null) ...[
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: theme.colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          aiState.error!,
                          style: TextStyle(
                              color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Hashtag results
            if (aiState.hashtags != null) ...[
              ResultCard(
                title: 'ハッシュタグ',
                content: aiState.hashtags!.join(' '),
                onCopy: () {
                  ShareService.copyToClipboard(aiState.hashtags!.join(' '));
                  _showSnackBar('ハッシュタグをコピーしました');
                },
                onShare: () =>
                    ShareService.shareText(aiState.hashtags!.join(' ')),
                onRegenerate: () => _generateHashtags(),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: aiState.hashtags!
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Caption result
            if (aiState.caption != null) ...[
              ResultCard(
                title: 'キャプション',
                content: aiState.caption!,
                onCopy: () {
                  ShareService.copyToClipboard(aiState.caption!);
                  _showSnackBar('キャプションをコピーしました');
                },
                onShare: () => ShareService.shareText(aiState.caption!),
                onRegenerate: () => _generateCaption(),
              ),
            ],

            // Share with photo button
            if (aiState.hashtags != null || aiState.caption != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.photoPath != null
                      ? () {
                          final text = ShareTemplates.buildShareText(
                            hashtags: aiState.hashtags?.join(' '),
                            caption: aiState.caption,
                          );
                          ShareService.shareImageWithText(
                            widget.photoPath!,
                            text: text,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.share),
                  label: const Text('写真と一緒にシェア'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generateAll() async {
    final photoPath = widget.photoPath ?? '';
    final language = ref.read(selectedLanguageProvider);
    final style = ref.read(selectedStyleProvider);
    final length = ref.read(selectedLengthProvider);
    final customPrompt = style == GenerationStyle.custom
        ? _customPromptController.text
        : null;

    await ref.read(aiGenerateNotifierProvider.notifier).generateAll(
          photoLocalPath: photoPath,
          language: language,
          style: style,
          length: length,
          customPrompt: customPrompt,
        );
    ref.read(adServiceProvider).showInterstitialIfNeeded();
  }

  Future<void> _generateHashtags() async {
    final photoPath = widget.photoPath ?? '';
    final language = ref.read(selectedLanguageProvider);
    await ref.read(aiGenerateNotifierProvider.notifier).generateHashtags(
          photoLocalPath: photoPath,
          language: language,
        );
    ref.read(adServiceProvider).showInterstitialIfNeeded();
  }

  Future<void> _generateCaption() async {
    final photoPath = widget.photoPath ?? '';
    final language = ref.read(selectedLanguageProvider);
    final style = ref.read(selectedStyleProvider);
    final length = ref.read(selectedLengthProvider);
    final customPrompt = style == GenerationStyle.custom
        ? _customPromptController.text
        : null;

    await ref.read(aiGenerateNotifierProvider.notifier).generateCaption(
          photoLocalPath: photoPath,
          language: language,
          style: style,
          length: length,
          customPrompt: customPrompt,
        );
    ref.read(adServiceProvider).showInterstitialIfNeeded();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
