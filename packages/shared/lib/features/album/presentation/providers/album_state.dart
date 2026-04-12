import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/album.dart';
import '../../../../domain/models/photo.dart';
import '../../../../domain/interfaces/album_repository.dart';

enum PhotoFilter { all, favorites, trash }

// Photo list state
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

// Album list state
class AlbumListState {
  final List<Album> albums;
  final bool isLoading;
  final String? error;

  const AlbumListState({
    this.albums = const [],
    this.isLoading = false,
    this.error,
  });

  AlbumListState copyWith({
    List<Album>? albums,
    bool? isLoading,
    String? error,
  }) {
    return AlbumListState(
      albums: albums ?? this.albums,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AlbumListNotifier extends StateNotifier<AlbumListState> {
  final AlbumRepository _repository;

  AlbumListNotifier(this._repository) : super(const AlbumListState());

  Future<void> loadAlbums() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final albums = await _repository.getAlbums();
      state = state.copyWith(albums: albums, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createAlbum(String name) async {
    try {
      final album = await _repository.createAlbum(name: name);
      state = state.copyWith(albums: [...state.albums, album]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteAlbum(String id) async {
    final previousAlbums = state.albums;
    state = state.copyWith(
      albums: state.albums.where((a) => a.id != id).toList(),
    );
    try {
      await _repository.deleteAlbum(id);
    } catch (e) {
      state = state.copyWith(albums: previousAlbums, error: e.toString());
    }
  }
}

// Album detail state
class AlbumDetailState {
  final Album? album;
  final List<Photo> photos;
  final bool isLoading;
  final String? error;

  const AlbumDetailState({
    this.album,
    this.photos = const [],
    this.isLoading = false,
    this.error,
  });

  AlbumDetailState copyWith({
    Album? album,
    List<Photo>? photos,
    bool? isLoading,
    String? error,
  }) {
    return AlbumDetailState(
      album: album ?? this.album,
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AlbumDetailNotifier extends StateNotifier<AlbumDetailState> {
  final AlbumRepository _repository;
  final String albumId;

  AlbumDetailNotifier(this._repository, this.albumId)
      : super(const AlbumDetailState());

  Future<void> loadAlbum() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final album = await _repository.getAlbum(albumId);
      final photos = await _repository.getAlbumPhotos(albumId);
      state = state.copyWith(album: album, photos: photos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addPhotos(List<String> photoIds) async {
    try {
      await _repository.addPhotosToAlbum(albumId, photoIds);
      await loadAlbum();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removePhoto(String photoId) async {
    final previousPhotos = state.photos;
    state = state.copyWith(
      photos: state.photos.where((p) => p.id != photoId).toList(),
    );
    try {
      await _repository.removePhotoFromAlbum(albumId, photoId);
    } catch (e) {
      state = state.copyWith(photos: previousPhotos, error: e.toString());
    }
  }

  Future<void> updateAlbum({String? name}) async {
    try {
      final updated = await _repository.updateAlbum(albumId, name: name);
      state = state.copyWith(album: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
