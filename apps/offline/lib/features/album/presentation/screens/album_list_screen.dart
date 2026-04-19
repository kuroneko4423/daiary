import 'dart:io';
import 'package:daiary_shared/core/widgets/app_error_widget.dart';
import 'package:daiary_shared/core/widgets/loading_widget.dart';
import 'package:daiary_shared/features/album/presentation/widgets/album_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/album_provider.dart';
import '../providers/photo_provider.dart';

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
      appBar: AppBar(title: const Text('アルバム')),
      body: _buildBody(albumState),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAlbumDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(AlbumListState albumState) {
    if (albumState.isLoading && albumState.albums.isEmpty) {
      return const LoadingWidget(message: 'アルバムを読み込み中...');
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
          final coverPath = _coverPhotoPaths[album.id];
          return AlbumCard(
            album: album,
            coverImage: coverPath != null
                ? Image.file(
                    File(coverPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.photo_album),
                  )
                : null,
            onTap: () => context.go('/albums/${album.id}'),
            onLongPress: () =>
                _showDeleteConfirmation(album.id, album.name),
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
            'アルバムがまだありません',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '最初のアルバムを作成して写真を整理しましょう',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showCreateAlbumDialog(),
            icon: const Icon(Icons.add),
            label: const Text('アルバムを作成'),
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
        title: const Text('アルバムを作成'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'アルバム名',
            hintText: 'アルバム名を入力',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
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
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String albumId, String albumName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アルバムを削除'),
        content: Text('"$albumName"を削除してもよろしいですか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
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
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
