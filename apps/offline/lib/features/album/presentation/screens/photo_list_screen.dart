import 'dart:io';
import 'package:daiary_shared/core/widgets/app_error_widget.dart';
import 'package:daiary_shared/core/widgets/loading_widget.dart';
import 'package:daiary_shared/domain/models/photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../settings/presentation/widgets/banner_ad_widget.dart';
import '../providers/photo_provider.dart';

class PhotoListScreen extends ConsumerStatefulWidget {
  const PhotoListScreen({super.key});

  @override
  ConsumerState<PhotoListScreen> createState() => _PhotoListScreenState();
}

class _PhotoListScreenState extends ConsumerState<PhotoListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(photoListNotifierProvider.notifier).loadPhotos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final photoState = ref.watch(photoListNotifierProvider);
    final filter = ref.watch(photoFilterProvider);
    final isGrid = ref.watch(photoViewModeProvider);

    return Scaffold(
      bottomNavigationBar: const BannerAdWidget(),
      appBar: AppBar(
        title: const Text('写真'),
        actions: [
          if (photoState.isMultiSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.favorite),
              onPressed: () {
                for (final id in photoState.selectedIds) {
                  ref
                      .read(photoListNotifierProvider.notifier)
                      .toggleFavorite(id);
                }
                ref.read(photoListNotifierProvider.notifier).clearSelection();
              },
              tooltip: 'お気に入り',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDeleteSelected(photoState.selectedIds),
              tooltip: '削除',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () =>
                  ref.read(photoListNotifierProvider.notifier).clearSelection(),
              tooltip: 'キャンセル',
            ),
          ] else ...[
            IconButton(
              icon: Icon(isGrid ? Icons.view_list : Icons.grid_view),
              onPressed: () =>
                  ref.read(photoViewModeProvider.notifier).state = !isGrid,
              tooltip: isGrid ? 'リスト表示' : 'グリッド表示',
            ),
            PopupMenuButton<PhotoFilter>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) {
                ref.read(photoFilterProvider.notifier).state = value;
                ref
                    .read(photoListNotifierProvider.notifier)
                    .loadPhotos(filter: value);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: PhotoFilter.all,
                  child: Row(
                    children: [
                      Icon(Icons.photo_library,
                          color: filter == PhotoFilter.all
                              ? Theme.of(context).colorScheme.primary
                              : null),
                      const SizedBox(width: 8),
                      const Text('すべての写真'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: PhotoFilter.favorites,
                  child: Row(
                    children: [
                      Icon(Icons.favorite,
                          color: filter == PhotoFilter.favorites
                              ? Theme.of(context).colorScheme.primary
                              : null),
                      const SizedBox(width: 8),
                      const Text('お気に入り'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: PhotoFilter.trash,
                  child: Row(
                    children: [
                      Icon(Icons.delete,
                          color: filter == PhotoFilter.trash
                              ? Theme.of(context).colorScheme.primary
                              : null),
                      const SizedBox(width: 8),
                      const Text('ゴミ箱'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildBody(photoState, isGrid),
    );
  }

  Widget _buildBody(PhotoListState photoState, bool isGrid) {
    if (photoState.isLoading && photoState.photos.isEmpty) {
      return const LoadingWidget(message: '写真を読み込み中...');
    }

    if (photoState.error != null && photoState.photos.isEmpty) {
      return AppErrorWidget(
        message: photoState.error!,
        onRetry: () =>
            ref.read(photoListNotifierProvider.notifier).loadPhotos(),
      );
    }

    if (photoState.photos.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(photoListNotifierProvider.notifier).loadPhotos(),
      child: isGrid ? _buildGridView(photoState) : _buildListView(photoState),
    );
  }

  Widget _buildGridView(PhotoListState photoState) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: photoState.photos.length,
      itemBuilder: (context, index) =>
          _buildPhotoTile(photoState.photos[index], photoState.selectedIds),
    );
  }

  Widget _buildListView(PhotoListState photoState) {
    return ListView.builder(
      itemCount: photoState.photos.length,
      itemBuilder: (context, index) {
        final photo = photoState.photos[index];
        final isSelected = photoState.selectedIds.contains(photo.id);
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Image.file(
                File(photo.thumbnailPath ?? photo.imagePath),
                fit: BoxFit.cover,
                cacheWidth: 112,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.photo),
                ),
              ),
            ),
          ),
          title: Text(photo.originalFilename ?? '写真'),
          subtitle: Text(_formatDate(photo.createdAt)),
          trailing: photo.isFavorite
              ? Icon(Icons.favorite,
                  color: Theme.of(context).colorScheme.error, size: 20)
              : null,
          selected: isSelected,
          onTap: () {
            if (photoState.isMultiSelectMode) {
              ref
                  .read(photoListNotifierProvider.notifier)
                  .toggleSelection(photo.id);
            } else {
              context.push('/photos/${photo.id}');
            }
          },
          onLongPress: () => ref
              .read(photoListNotifierProvider.notifier)
              .toggleSelection(photo.id),
        );
      },
    );
  }

  Widget _buildPhotoTile(Photo photo, Set<String> selectedIds) {
    final isSelected = selectedIds.contains(photo.id);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        if (ref.read(photoListNotifierProvider).isMultiSelectMode) {
          ref
              .read(photoListNotifierProvider.notifier)
              .toggleSelection(photo.id);
        } else {
          context.push('/photos/${photo.id}');
        }
      },
      onLongPress: () => ref
          .read(photoListNotifierProvider.notifier)
          .toggleSelection(photo.id),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(photo.thumbnailPath ?? photo.imagePath),
            fit: BoxFit.cover,
            cacheWidth: 300,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: child,
              );
            },
            errorBuilder: (_, __, ___) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.photo),
            ),
          ),
          if (isSelected)
            Container(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              child: Icon(Icons.check_circle,
                  color: theme.colorScheme.primary),
            ),
          if (photo.isFavorite)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.favorite,
                  color: theme.colorScheme.error, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '写真がまだありません',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '写真を撮るかギャラリーからインポートしてください',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelected(Set<String> selectedIds) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('写真を削除'),
        content: Text('${selectedIds.length}件の写真を削除してもよろしいですか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(photoListNotifierProvider.notifier)
                  .deletePhotos(selectedIds.toList());
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

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
