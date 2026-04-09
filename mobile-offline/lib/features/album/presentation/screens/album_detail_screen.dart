import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/album_provider.dart';

class AlbumDetailScreen extends ConsumerStatefulWidget {
  final String albumId;

  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(albumDetailNotifierProvider(widget.albumId).notifier)
          .loadAlbum();
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailState =
        ref.watch(albumDetailNotifierProvider(widget.albumId));

    return Scaffold(
      appBar: AppBar(
        title: Text(detailState.album?.name ?? 'Album'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: detailState.album != null
                ? () => _showEditDialog(detailState.album!.name)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: detailState.album != null
                ? () => _shareAlbum()
                : null,
          ),
        ],
      ),
      body: _buildBody(detailState),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPhotosDialog(),
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }

  Widget _buildBody(AlbumDetailState detailState) {
    if (detailState.isLoading && detailState.album == null) {
      return const LoadingWidget(message: 'Loading album...');
    }

    if (detailState.error != null && detailState.album == null) {
      return AppErrorWidget(
        message: detailState.error!,
        onRetry: () => ref
            .read(albumDetailNotifierProvider(widget.albumId).notifier)
            .loadAlbum(),
      );
    }

    if (detailState.photos.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: detailState.photos.length,
      itemBuilder: (context, index) {
        final photo = detailState.photos[index];
        return GestureDetector(
          onTap: () => context.push('/photos/${photo.id}'),
          onLongPress: () => _showRemovePhotoConfirmation(photo.id),
          child: Image.file(
            File(photo.thumbnailPath ?? photo.localPath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.photo),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No photos in this album',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add photos from your library',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Album'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Album Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref
                    .read(albumDetailNotifierProvider(widget.albumId).notifier)
                    .updateAlbum(name: name);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _shareAlbum() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Album sharing coming soon')),
    );
  }

  void _showAddPhotosDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Select photos to add from your library')),
    );
  }

  void _showRemovePhotoConfirmation(String photoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content:
            const Text('Remove this photo from the album?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(albumDetailNotifierProvider(widget.albumId).notifier)
                  .removePhoto(photoId);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
