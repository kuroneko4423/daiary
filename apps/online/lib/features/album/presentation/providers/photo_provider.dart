import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daiary_shared/domain/models/photo.dart';
import '../../../../services/api_client.dart';

enum PhotoFilter { all, favorites, trash }

final photoFilterProvider = StateProvider<PhotoFilter>((ref) => PhotoFilter.all);
final photoViewModeProvider = StateProvider<bool>((ref) => true); // true = grid

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
  final ApiClient _apiClient;

  PhotoListNotifier(this._apiClient) : super(const PhotoListState());

  Future<void> loadPhotos({PhotoFilter filter = PhotoFilter.all}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final queryParams = <String, dynamic>{};
      if (filter == PhotoFilter.favorites) {
        queryParams['favorite'] = true;
      } else if (filter == PhotoFilter.trash) {
        queryParams['trash'] = true;
      }
      final response =
          await _apiClient.get('/photos', queryParameters: queryParams);
      final data = response.data as List<dynamic>;
      final photos = data.map((e) {
        final json = e as Map<String, dynamic>;
        return Photo(
          id: json['id'] as String,
          userId: json['user_id'] as String?,
          storagePath: json['storage_path'] as String?,
          thumbnailPath: json['thumbnail_path'] as String?,
          originalFilename: json['original_filename'] as String?,
          fileSize: json['file_size'] as int?,
          width: json['width'] as int?,
          height: json['height'] as int?,
          isFavorite: json['is_favorite'] as bool? ?? false,
          deletedAt: json['deleted_at'] != null
              ? DateTime.parse(json['deleted_at'] as String)
              : null,
          createdAt: DateTime.parse(json['created_at'] as String),
        );
      }).toList();
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
          return Photo(
            id: p.id,
            userId: p.userId,
            storagePath: p.storagePath,
            thumbnailPath: p.thumbnailPath,
            originalFilename: p.originalFilename,
            fileSize: p.fileSize,
            width: p.width,
            height: p.height,
            isFavorite: newFavorite,
            deletedAt: p.deletedAt,
            createdAt: p.createdAt,
          );
        }
        return p;
      }).toList(),
    );
    try {
      await _apiClient.patch('/photos/$photoId', data: {
        'is_favorite': newFavorite,
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
        await _apiClient.delete('/photos/$id');
      }
    } catch (e) {
      state = state.copyWith(photos: previousPhotos, error: e.toString());
    }
  }
}

final photoListNotifierProvider =
    StateNotifierProvider<PhotoListNotifier, PhotoListState>((ref) {
  return PhotoListNotifier(ApiClient());
});
