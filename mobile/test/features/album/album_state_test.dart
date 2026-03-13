import 'package:flutter_test/flutter_test.dart';
import 'package:daiary/features/album/presentation/providers/album_provider.dart';
import 'package:daiary/features/album/domain/entities/album.dart';
import 'package:daiary/features/camera/domain/entities/photo.dart';

void main() {
  group('AlbumListState', () {
    test('initial values are correct', () {
      const state = AlbumListState();

      expect(state.albums, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('albums defaults to empty list', () {
      const state = AlbumListState();
      expect(state.albums, isA<List<Album>>());
      expect(state.albums.length, 0);
    });

    test('copyWith updates albums', () {
      const state = AlbumListState();
      final now = DateTime.now();
      final albums = [
        Album(
          id: '1',
          userId: 'user1',
          name: 'Test Album',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final updated = state.copyWith(albums: albums);

      expect(updated.albums.length, 1);
      expect(updated.albums.first.name, 'Test Album');
      expect(updated.isLoading, isFalse);
      expect(updated.error, isNull);
    });

    test('copyWith updates isLoading', () {
      const state = AlbumListState();
      final updated = state.copyWith(isLoading: true);

      expect(updated.isLoading, isTrue);
      expect(updated.albums, isEmpty);
      expect(updated.error, isNull);
    });

    test('copyWith updates error', () {
      const state = AlbumListState();
      final updated = state.copyWith(error: 'Failed to load');

      expect(updated.error, 'Failed to load');
      expect(updated.albums, isEmpty);
      expect(updated.isLoading, isFalse);
    });

    test('copyWith clears error when not provided', () {
      final state = const AlbumListState().copyWith(error: 'an error');
      expect(state.error, 'an error');

      final cleared = state.copyWith();
      expect(cleared.error, isNull);
    });

    test('copyWith preserves existing values when not specified', () {
      final now = DateTime.now();
      final albums = [
        Album(
          id: '1',
          userId: 'user1',
          name: 'Album 1',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      final state = const AlbumListState().copyWith(
        albums: albums,
        isLoading: true,
      );

      final updated = state.copyWith(isLoading: false);

      expect(updated.albums.length, 1);
      expect(updated.isLoading, isFalse);
    });
  });

  group('AlbumDetailState', () {
    test('initial values are correct', () {
      const state = AlbumDetailState();

      expect(state.album, isNull);
      expect(state.photos, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('photos defaults to empty list', () {
      const state = AlbumDetailState();
      expect(state.photos, isA<List<Photo>>());
      expect(state.photos.length, 0);
    });

    test('copyWith updates album', () {
      const state = AlbumDetailState();
      final now = DateTime.now();
      final album = Album(
        id: '1',
        userId: 'user1',
        name: 'Test Album',
        createdAt: now,
        updatedAt: now,
      );

      final updated = state.copyWith(album: album);

      expect(updated.album, isNotNull);
      expect(updated.album!.name, 'Test Album');
      expect(updated.photos, isEmpty);
      expect(updated.isLoading, isFalse);
      expect(updated.error, isNull);
    });

    test('copyWith updates photos', () {
      const state = AlbumDetailState();
      final now = DateTime.now();
      final photos = [
        Photo(
          id: 'p1',
          userId: 'user1',
          storagePath: '/path/to/photo.jpg',
          createdAt: now,
        ),
      ];

      final updated = state.copyWith(photos: photos);

      expect(updated.photos.length, 1);
      expect(updated.photos.first.id, 'p1');
    });

    test('copyWith updates isLoading', () {
      const state = AlbumDetailState();
      final updated = state.copyWith(isLoading: true);

      expect(updated.isLoading, isTrue);
      expect(updated.album, isNull);
      expect(updated.photos, isEmpty);
    });

    test('copyWith updates error', () {
      const state = AlbumDetailState();
      final updated = state.copyWith(error: 'Not found');

      expect(updated.error, 'Not found');
    });

    test('copyWith clears error when not provided', () {
      final state = const AlbumDetailState().copyWith(error: 'an error');
      expect(state.error, 'an error');

      final cleared = state.copyWith();
      expect(cleared.error, isNull);
    });

    test('copyWith preserves existing values when not specified', () {
      final now = DateTime.now();
      final album = Album(
        id: '1',
        userId: 'user1',
        name: 'Test Album',
        createdAt: now,
        updatedAt: now,
      );
      final photos = [
        Photo(
          id: 'p1',
          userId: 'user1',
          storagePath: '/path/to/photo.jpg',
          createdAt: now,
        ),
      ];

      final state = const AlbumDetailState().copyWith(
        album: album,
        photos: photos,
        isLoading: true,
      );

      final updated = state.copyWith(isLoading: false);

      expect(updated.album, isNotNull);
      expect(updated.album!.id, '1');
      expect(updated.photos.length, 1);
      expect(updated.isLoading, isFalse);
    });
  });

  group('Album entity', () {
    test('can be created with required fields', () {
      final now = DateTime.now();
      final album = Album(
        id: 'album-1',
        userId: 'user-1',
        name: 'My Album',
        createdAt: now,
        updatedAt: now,
      );

      expect(album.id, 'album-1');
      expect(album.userId, 'user-1');
      expect(album.name, 'My Album');
      expect(album.coverPhotoId, isNull);
      expect(album.isPublic, isFalse);
      expect(album.shareToken, isNull);
    });

    test('isPublic defaults to false', () {
      final now = DateTime.now();
      final album = Album(
        id: 'album-1',
        userId: 'user-1',
        name: 'My Album',
        createdAt: now,
        updatedAt: now,
      );

      expect(album.isPublic, isFalse);
    });

    test('can be created with all fields', () {
      final now = DateTime.now();
      final album = Album(
        id: 'album-1',
        userId: 'user-1',
        name: 'Public Album',
        coverPhotoId: 'photo-1',
        isPublic: true,
        shareToken: 'token-abc',
        createdAt: now,
        updatedAt: now,
      );

      expect(album.coverPhotoId, 'photo-1');
      expect(album.isPublic, isTrue);
      expect(album.shareToken, 'token-abc');
    });
  });
}
