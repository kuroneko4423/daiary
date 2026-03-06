import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/share_service.dart';
import '../../domain/entities/generation_result.dart';
import '../providers/ai_generate_provider.dart';
import '../widgets/result_card.dart';
import '../widgets/style_selector.dart';

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
      ref.read(aiGenerateNotifierProvider.notifier).fetchUsage();
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
      appBar: AppBar(
        title: const Text('AI Generate'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${aiState.remainingGenerations} left',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
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
              const SizedBox(height: 24),
            ],

            // Style selector
            Text('Style', style: theme.textTheme.titleMedium),
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
                  labelText: 'Custom Prompt',
                  hintText: 'Describe the style you want...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],

            // Language selector
            Text('Language', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ja', label: Text('日本語')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {selectedLanguage},
              onSelectionChanged: (values) =>
                  ref.read(selectedLanguageProvider.notifier).state =
                      values.first,
            ),
            const SizedBox(height: 16),

            // Length selector
            Text('Caption Length', style: theme.textTheme.titleMedium),
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

            // Generate buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: aiState.isLoadingHashtags
                        ? null
                        : () => _generateHashtags(),
                    icon: aiState.isLoadingHashtags
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.tag),
                    label: const Text('Hashtags'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: aiState.isLoadingCaption
                        ? null
                        : () => _generateCaption(),
                    icon: aiState.isLoadingCaption
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.edit_note),
                    label: const Text('Caption'),
                  ),
                ),
              ],
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
                title: 'Hashtags',
                content: aiState.hashtags!.join(' '),
                onCopy: () {
                  ShareService.copyToClipboard(aiState.hashtags!.join(' '));
                  _showSnackBar('Hashtags copied to clipboard');
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
                title: 'Caption',
                content: aiState.caption!,
                onCopy: () {
                  ShareService.copyToClipboard(aiState.caption!);
                  _showSnackBar('Caption copied to clipboard');
                },
                onShare: () => ShareService.shareText(aiState.caption!),
                onRegenerate: () => _generateCaption(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _generateHashtags() {
    final photoPath = widget.photoPath ?? '';
    final language = ref.read(selectedLanguageProvider);
    ref.read(aiGenerateNotifierProvider.notifier).generateHashtags(
          photoId: photoPath,
          language: language,
        );
  }

  void _generateCaption() {
    final photoPath = widget.photoPath ?? '';
    final language = ref.read(selectedLanguageProvider);
    final style = ref.read(selectedStyleProvider);
    final length = ref.read(selectedLengthProvider);
    final customPrompt = style == GenerationStyle.custom
        ? _customPromptController.text
        : null;

    ref.read(aiGenerateNotifierProvider.notifier).generateCaption(
          photoId: photoPath,
          language: language,
          style: style,
          length: length,
          customPrompt: customPrompt,
        );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
