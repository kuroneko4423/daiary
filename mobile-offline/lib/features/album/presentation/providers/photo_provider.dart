import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../camera/domain/entities/photo.dart';
import '../../data/datasources/photo_local_datasource.dart';

enum PhotoFilter { all, favorites, trash }

final photoFilterProvider = StateProvider<PhotoFilter>((ref) => PhotoFilter.all);
final photoViewModeProvider = StateProvider<bool>((ref) => true); // true = grid

final photoLocalDataSourceProvider =
    Provider<PhotoLocalDataSource>((ref) => PhotoLocalDataSource());

class PhotoListState {
  final List<Photo> photos;
  final bool isLoading;
  final String? error;
  final Set<String> selectedIds;

  const PhotoListState({
    this.photos = const [],
    this.isLoading = false,
    this.error,
    this.selectedIds = const {},
  });

  bool get isMultiSelectMode => selectedIds.isNotEmpty;

  PhotoListState copyWith({
    List<Photo>? photos,
    bool? isLoading,
    String? error,
    Set<String>? selectedIds,
  }) {
    return PhotoListState(
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class PhotoListNotifier extends StateNotifier<PhotoListState> {
  final PhotoLocalDataSource _dataSource;

  PhotoListNotifier(this._dataSource) : super(const PhotoListState());

  Future<void> loadPhotos({PhotoFilter filter = PhotoFilter.all}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _dataSource.getPhotos(
        favoritesOnly: filter == PhotoFilter.favorites,
        trashOnly: filter == PhotoFilter.trash,
      );
      final photos = data.map((e) => Photo.fromMap(e)).toList();
      state = state.copyWith(photos: photos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void toggleSelection(String photoId) {
    final selected = Set<String>.from(state.selectedIds);
    if (selected.contains(photoId)) {
      selected.remove(photoId);
    } else {
      selected.add(photoId);
    }
    state = state.copyWith(selectedIds: selected);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  Future<void> toggleFavorite(String photoId) async {
    final photo = state.photos.firstWhere((p) => p.id == photoId);
    final newFavorite = !photo.isFavorite;
    // Optimistic update
    state = state.copyWith(
      photos: state.photos.map((p) {
        if (p.id == photoId) {
          return p.copyWith(isFavorite: newFavorite);
        }
        return p;
      }).toList(),
    );
    try {
      await _dataSource.updatePhoto(photoId, {
        'is_favorite': newFavorite ? 1 : 0,
      });
    } catch (e) {
      // Revert on error
      await loadPhotos();
    }
  }

  Future<void> deletePhotos(List<String> photoIds) async {
    final previousPhotos = state.photos;
    state = state.copyWith(
      photos: state.photos.where((p) => !photoIds.contains(p.id)).toList(),
      selectedIds: {},
    );
    try {
      for (final id in photoIds) {
        await _dataSource.softDeletePhoto(id);
      }
    } catch (e) {
      state = state.copyWith(photos: previousPhotos, error: e.toString());
    }
  }

  Future<void> permanentlyDeletePhotos(List<String> photoIds) async {
    final previousPhotos = state.photos;
    state = state.copyWith(
      photos: state.photos.where((p) => !photoIds.contains(p.id)).toList(),
      selectedIds: {},
    );
    try {
      for (final id in photoIds) {
        await _dataSource.permanentlyDeletePhoto(id);
      }
    } catch (e) {
      state = state.copyWith(photos: previousPhotos, error: e.toString());
    }
  }

  Future<void> restorePhotos(List<String> photoIds) async {
    try {
      for (final id in photoIds) {
        await _dataSource.restorePhoto(id);
      }
      await loadPhotos(filter: PhotoFilter.trash);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final photoListNotifierProvider =
    StateNotifierProvider<PhotoListNotifier, PhotoListState>((ref) {
  return PhotoListNotifier(ref.watch(photoLocalDataSourceProvider));
});
