import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/api_client.dart';
import '../../../../services/share_service.dart';
import '../../../camera/domain/entities/photo.dart';

final photoDetailProvider =
    FutureProvider.family<Photo, String>((ref, photoId) async {
  final apiClient = ApiClient();
  final response = await apiClient.get('/photos/$photoId');
  final json = response.data as Map<String, dynamic>;
  return Photo(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    storagePath: json['storage_path'] as String,
    thumbnailPath: json['thumbnail_path'] as String?,
    originalFilename: json['original_filename'] as String?,
    fileSize: json['file_size'] as int?,
    width: json['width'] as int?,
    height: json['height'] as int?,
    exifData: json['exif_data'] as Map<String, dynamic>?,
    isFavorite: json['is_favorite'] as bool? ?? false,
    deletedAt: json['deleted_at'] != null
        ? DateTime.parse(json['deleted_at'] as String)
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
});

class PhotoDetailScreen extends ConsumerWidget {
  final String photoId;

  const PhotoDetailScreen({super.key, required this.photoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoAsync = ref.watch(photoDetailProvider(photoId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Photo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              photoAsync.whenData((photo) {
                ShareService.shareText(
                    'Check out this photo: ${photo.storagePath}');
              });
            },
          ),
        ],
      ),
      body: photoAsync.when(
        data: (photo) => _buildPhotoView(context, ref, photo),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (error, _) => Center(
          child: Text(
            'Failed to load photo: $error',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
      bottomNavigationBar: photoAsync.whenOrNull(
        data: (photo) => _buildBottomBar(context, ref, photo, theme),
      ),
    );
  }

  Widget _buildPhotoView(BuildContext context, WidgetRef ref, Photo photo) {
    return GestureDetector(
      onTap: () {
        // Toggle UI visibility could be added here
      },
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Container(
            color: Colors.black,
            child: const Icon(Icons.photo, size: 200, color: Colors.white38),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, WidgetRef ref, Photo photo, ThemeData theme) {
    return SafeArea(
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: photo.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: 'Favorite',
                  color: photo.isFavorite ? Colors.red : Colors.white,
                  onTap: () {
                    // Toggle favorite
                  },
                ),
                _buildActionButton(
                  icon: Icons.auto_awesome,
                  label: 'AI Generate',
                  color: Colors.amber,
                  onTap: () =>
                      context.push('/ai-generate', extra: photo.storagePath),
                ),
                _buildActionButton(
                  icon: Icons.info_outline,
                  label: 'Details',
                  color: Colors.white,
                  onTap: () => _showExifBottomSheet(context, photo),
                ),
                _buildActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: Colors.white,
                  onTap: () => _confirmDelete(context, ref, photo.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showExifBottomSheet(BuildContext context, Photo photo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Photo Details',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('Filename', photo.originalFilename ?? 'Unknown'),
            if (photo.width != null && photo.height != null)
              _buildInfoRow('Dimensions', '${photo.width} x ${photo.height}'),
            if (photo.fileSize != null)
              _buildInfoRow('File size', _formatFileSize(photo.fileSize!)),
            _buildInfoRow(
              'Created',
              '${photo.createdAt.year}/${photo.createdAt.month.toString().padLeft(2, '0')}/${photo.createdAt.day.toString().padLeft(2, '0')}',
            ),
            if (photo.exifData != null)
              ...photo.exifData!.entries.map(
                (e) => _buildInfoRow(e.key, e.value.toString()),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String photoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiClient().delete('/photos/$photoId');
                if (context.mounted) {
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
