import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daiary_shared/domain/models/album.dart';
import 'package:daiary_shared/domain/models/photo.dart';
import 'package:daiary_shared/domain/interfaces/album_repository.dart';
import '../../../../services/api_client.dart';
import '../../data/datasources/album_remote_datasource.dart';
import '../../data/repositories/album_repository_impl.dart';

final albumApiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final albumRemoteDataSourceProvider = Provider<AlbumRemoteDataSource>((ref) {
  return AlbumRemoteDataSource(ref.watch(albumApiClientProvider));
});

final albumRepositoryProvider = Provider<AlbumRepository>((ref) {
  return AlbumRepositoryImpl(ref.watch(albumRemoteDataSourceProvider));
});

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
    // Optimistic update
    state = state.copyWith(
      albums: state.albums.where((a) => a.id != id).toList(),
    );
    try {
      await _repository.deleteAlbum(id);
    } catch (e) {
      // Revert on error
      state = state.copyWith(albums: previousAlbums, error: e.toString());
    }
  }
}

final albumListNotifierProvider =
    StateNotifierProvider<AlbumListNotifier, AlbumListState>((ref) {
  return AlbumListNotifier(ref.watch(albumRepositoryProvider));
});

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
      state = state.copyWith(album: album, isLoading: false);
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
    // Optimistic update
    state = state.copyWith(
      photos: state.photos.where((p) => p.id != photoId).toList(),
    );
    try {
      await _repository.removePhotoFromAlbum(albumId, photoId);
    } catch (e) {
      state = state.copyWith(photos: previousPhotos, error: e.toString());
    }
  }

  Future<void> updateAlbum({String? name, bool? isPublic}) async {
    try {
      final updated = await _repository.updateAlbum(
        albumId,
        name: name,
      );
      state = state.copyWith(album: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final albumDetailNotifierProvider = StateNotifierProvider.family<
    AlbumDetailNotifier, AlbumDetailState, String>((ref, albumId) {
  return AlbumDetailNotifier(ref.watch(albumRepositoryProvider), albumId);
});
