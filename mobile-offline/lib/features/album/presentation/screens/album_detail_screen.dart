import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../camera/domain/entities/photo.dart';
import '../providers/album_provider.dart';
import '../providers/photo_provider.dart';

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
    final detailState =
        ref.read(albumDetailNotifierProvider(widget.albumId));
    final existingPhotoIds =
        detailState.photos.map((p) => p.id).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _AddPhotosSheet(
        albumId: widget.albumId,
        existingPhotoIds: existingPhotoIds,
      ),
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

class _AddPhotosSheet extends ConsumerStatefulWidget {
  final String albumId;
  final Set<String> existingPhotoIds;

  const _AddPhotosSheet({
    required this.albumId,
    required this.existingPhotoIds,
  });

  @override
  ConsumerState<_AddPhotosSheet> createState() => _AddPhotosSheetState();
}

class _AddPhotosSheetState extends ConsumerState<_AddPhotosSheet> {
  final Set<String> _selectedIds = {};
  List<Photo>? _allPhotos;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final dataSource = ref.read(photoLocalDataSourceProvider);
      final data = await dataSource.getPhotos();
      final photos = data.map((e) => Photo.fromMap(e)).toList();
      setState(() {
        _allPhotos = photos
            .where((p) => !widget.existingPhotoIds.contains(p.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add Photos',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (_selectedIds.isNotEmpty)
                  Text(
                    '${_selectedIds.length} selected',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildContent(scrollController)),
          if (_selectedIds.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _addSelectedPhotos,
                    child: Text('Add ${_selectedIds.length} photo${_selectedIds.length == 1 ? '' : 's'}'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    final photos = _allPhotos!;
    if (photos.isEmpty) {
      return Center(
        child: Text(
          'No photos available to add',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
    }

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final isSelected = _selectedIds.contains(photo.id);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(photo.id);
              } else {
                _selectedIds.add(photo.id);
              }
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(photo.thumbnailPath ?? photo.localPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.photo),
                ),
              ),
              if (isSelected) ...[
                Container(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _addSelectedPhotos() {
    if (_selectedIds.isEmpty) return;
    ref
        .read(albumDetailNotifierProvider(widget.albumId).notifier)
        .addPhotos(_selectedIds.toList());
    Navigator.pop(context);
  }
}
