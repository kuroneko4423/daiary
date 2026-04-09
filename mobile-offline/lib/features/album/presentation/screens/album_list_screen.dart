import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/album_provider.dart';
import '../providers/photo_provider.dart';
import '../widgets/album_card.dart';

class AlbumListScreen extends ConsumerStatefulWidget {
  const AlbumListScreen({super.key});

  @override
  ConsumerState<AlbumListScreen> createState() => _AlbumListScreenState();
}

class _AlbumListScreenState extends ConsumerState<AlbumListScreen> {
  final Map<String, String> _coverPhotoPaths = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(albumListNotifierProvider.notifier).loadAlbums();
      _resolveCoverPhotoPaths();
    });
  }

  Future<void> _resolveCoverPhotoPaths() async {
    final albums = ref.read(albumListNotifierProvider).albums;
    final dataSource = ref.read(photoLocalDataSourceProvider);
    final paths = <String, String>{};
    for (final album in albums) {
      if (album.coverPhotoId != null) {
        final photo = await dataSource.getPhoto(album.coverPhotoId!);
        if (photo != null) {
          final path = (photo['thumbnail_path'] as String?) ??
              (photo['local_path'] as String);
          paths[album.id] = path;
        }
      }
    }
    if (mounted) {
      setState(() {
        _coverPhotoPaths
          ..clear()
          ..addAll(paths);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final albumState = ref.watch(albumListNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Albums')),
      body: _buildBody(albumState),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAlbumDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(AlbumListState albumState) {
    if (albumState.isLoading && albumState.albums.isEmpty) {
      return const LoadingWidget(message: 'Loading albums...');
    }

    if (albumState.error != null && albumState.albums.isEmpty) {
      return AppErrorWidget(
        message: albumState.error!,
        onRetry: () =>
            ref.read(albumListNotifierProvider.notifier).loadAlbums(),
      );
    }

    if (albumState.albums.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(albumListNotifierProvider.notifier).loadAlbums();
        await _resolveCoverPhotoPaths();
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: albumState.albums.length,
        itemBuilder: (context, index) {
          final album = albumState.albums[index];
          return AlbumCard(
            album: album,
            coverPhotoPath: _coverPhotoPaths[album.id],
            onTap: () => context.go('/albums/${album.id}'),
            onLongPress: () => _showDeleteConfirmation(album.id, album.name),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_album_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No albums yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first album to organize photos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showCreateAlbumDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create Album'),
          ),
        ],
      ),
    );
  }

  void _showCreateAlbumDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Album'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Album Name',
            hintText: 'Enter album name',
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
                    .read(albumListNotifierProvider.notifier)
                    .createAlbum(name);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String albumId, String albumName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Album'),
        content: Text('Are you sure you want to delete "$albumName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(albumListNotifierProvider.notifier)
                  .deleteAlbum(albumId);
              Navigator.pop(context);
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
