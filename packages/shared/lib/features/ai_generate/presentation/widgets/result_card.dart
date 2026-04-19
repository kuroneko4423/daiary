import 'package:flutter/material.dart';

class ResultCard extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onRegenerate;

  const ResultCard({
    super.key,
    required this.title,
    required this.content,
    this.onCopy,
    this.onShare,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(content),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onCopy != null)
                  IconButton(onPressed: onCopy, icon: const Icon(Icons.copy), tooltip: 'コピー'),
                if (onShare != null)
                  IconButton(onPressed: onShare, icon: const Icon(Icons.share), tooltip: 'シェア'),
                const Spacer(),
                if (onRegenerate != null)
                  TextButton.icon(
                    onPressed: onRegenerate,
                    icon: const Icon(Icons.refresh),
                    label: const Text('再生成'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
