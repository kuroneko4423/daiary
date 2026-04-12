import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daiary_offline/services/database_service.dart';
import 'package:daiary_offline/features/album/data/datasources/album_local_datasource.dart';

void main() {
  late Database db;
  late AlbumLocalDataSource dataSource;

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('PRAGMA foreign_keys = ON');
          await db.execute('''
            CREATE TABLE photos (
              id TEXT PRIMARY KEY,
              local_path TEXT NOT NULL,
              thumbnail_path TEXT,
              original_filename TEXT,
              file_size INTEGER,
              width INTEGER,
              height INTEGER,
              exif_data TEXT,
              ai_tags TEXT,
              is_favorite INTEGER DEFAULT 0,
              deleted_at TEXT,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE albums (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              cover_photo_id TEXT REFERENCES photos(id) ON DELETE SET NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE album_photos (
              album_id TEXT NOT NULL REFERENCES albums(id) ON DELETE CASCADE,
              photo_id TEXT NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
              sort_order INTEGER DEFAULT 0,
              added_at TEXT NOT NULL,
              PRIMARY KEY (album_id, photo_id)
            )
          ''');
          await db.execute('''
            CREATE TABLE ai_generations (
              id TEXT PRIMARY KEY,
              photo_id TEXT NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
              generation_type TEXT NOT NULL,
              model TEXT NOT NULL,
              prompt TEXT,
              result TEXT,
              style TEXT,
              language TEXT,
              latency_ms INTEGER,
              created_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    DatabaseService.testDatabase = db;
    dataSource = AlbumLocalDataSource();
  });

  tearDown(() async {
    DatabaseService.testDatabase = null;
    await db.close();
  });

  Map<String, dynamic> makeAlbum(String id, {String name = 'Album'}) {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id,
      'name': name,
      'created_at': now,
      'updated_at': now,
    };
  }

  Map<String, dynamic> makePhoto(String id) {
    return {
      'id': id,
      'local_path': '/photos/$id.jpg',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  group('getAlbums', () {
    test('returns all albums ordered by updated_at DESC', () async {
      final old = DateTime(2024, 1, 1).toIso8601String();
      final recent = DateTime(2024, 6, 1).toIso8601String();
      await db.insert('albums', {
        'id': 'a1',
        'name': 'Old',
        'created_at': old,
        'updated_at': old,
      });
      await db.insert('albums', {
        'id': 'a2',
        'name': 'Recent',
        'created_at': recent,
        'updated_at': recent,
      });

      final results = await dataSource.getAlbums();
      expect(results.length, 2);
      expect(results.first['id'], 'a2');
    });

    test('returns empty list when no albums', () async {
      final results = await dataSource.getAlbums();
      expect(results, isEmpty);
    });
  });

  group('getAlbum', () {
    test('returns album by id', () async {
      await db.insert('albums', makeAlbum('a1', name: 'Test'));

      final result = await dataSource.getAlbum('a1');
      expect(result, isNotNull);
      expect(result!['name'], 'Test');
    });

    test('returns null for non-existent id', () async {
      final result = await dataSource.getAlbum('nonexistent');
      expect(result, isNull);
    });
  });

  group('insertAlbum', () {
    test('inserts an album', () async {
      await dataSource.insertAlbum(makeAlbum('a1', name: 'New Album'));

      final result =
          await db.query('albums', where: 'id = ?', whereArgs: ['a1']);
      expect(result.length, 1);
      expect(result.first['name'], 'New Album');
    });

    test('replaces on conflict', () async {
      await dataSource.insertAlbum(makeAlbum('a1', name: 'V1'));
      await dataSource.insertAlbum(makeAlbum('a1', name: 'V2'));

      final result =
          await db.query('albums', where: 'id = ?', whereArgs: ['a1']);
      expect(result.length, 1);
      expect(result.first['name'], 'V2');
    });
  });

  group('updateAlbum', () {
    test('updates album fields and sets updated_at', () async {
      await db.insert('albums', makeAlbum('a1', name: 'Old Name'));

      await dataSource.updateAlbum('a1', {'name': 'New Name'});

      final result =
          await db.query('albums', where: 'id = ?', whereArgs: ['a1']);
      expect(result.first['name'], 'New Name');
      expect(result.first['updated_at'], isNotNull);
    });
  });

  group('deleteAlbum', () {
    test('removes album from database', () async {
      await db.insert('albums', makeAlbum('a1'));

      await dataSource.deleteAlbum('a1');

      final result =
          await db.query('albums', where: 'id = ?', whereArgs: ['a1']);
      expect(result, isEmpty);
    });
  });

  group('getAlbumPhotos', () {
    test('returns photos in album excluding deleted ones', () async {
      await db.insert('photos', makePhoto('p1'));
      await db.insert('photos', {
        ...makePhoto('p2'),
        'deleted_at': DateTime.now().toIso8601String(),
      });
      await db.insert('albums', makeAlbum('a1'));
      final now = DateTime.now().toIso8601String();
      await db.insert('album_photos', {
        'album_id': 'a1',
        'photo_id': 'p1',
        'sort_order': 0,
        'added_at': now,
      });
      await db.insert('album_photos', {
        'album_id': 'a1',
        'photo_id': 'p2',
        'sort_order': 1,
        'added_at': now,
      });

      final results = await dataSource.getAlbumPhotos('a1');
      expect(results.length, 1);
      expect(results.first['id'], 'p1');
    });

    test('returns empty list for album with no photos', () async {
      await db.insert('albums', makeAlbum('a1'));

      final results = await dataSource.getAlbumPhotos('a1');
      expect(results, isEmpty);
    });
  });

  group('addPhotosToAlbum', () {
    test('adds multiple photos to album', () async {
      await db.insert('photos', makePhoto('p1'));
      await db.insert('photos', makePhoto('p2'));
      await db.insert('albums', makeAlbum('a1'));

      await dataSource.addPhotosToAlbum('a1', ['p1', 'p2']);

      final result = await db
          .query('album_photos', where: 'album_id = ?', whereArgs: ['a1']);
      expect(result.length, 2);
    });

    test('ignores duplicate entries', () async {
      await db.insert('photos', makePhoto('p1'));
      await db.insert('albums', makeAlbum('a1'));

      await dataSource.addPhotosToAlbum('a1', ['p1']);
      await dataSource.addPhotosToAlbum('a1', ['p1']);

      final result = await db
          .query('album_photos', where: 'album_id = ?', whereArgs: ['a1']);
      expect(result.length, 1);
    });
  });

  group('removePhotoFromAlbum', () {
    test('removes photo from album', () async {
      await db.insert('photos', makePhoto('p1'));
      await db.insert('albums', makeAlbum('a1'));
      await db.insert('album_photos', {
        'album_id': 'a1',
        'photo_id': 'p1',
        'sort_order': 0,
        'added_at': DateTime.now().toIso8601String(),
      });

      await dataSource.removePhotoFromAlbum('a1', 'p1');

      final result = await db.query('album_photos');
      expect(result, isEmpty);
    });
  });

  group('getAlbumPhotoCount', () {
    test('returns correct count', () async {
      await db.insert('photos', makePhoto('p1'));
      await db.insert('photos', makePhoto('p2'));
      await db.insert('albums', makeAlbum('a1'));
      final now = DateTime.now().toIso8601String();
      await db.insert('album_photos', {
        'album_id': 'a1',
        'photo_id': 'p1',
        'sort_order': 0,
        'added_at': now,
      });
      await db.insert('album_photos', {
        'album_id': 'a1',
        'photo_id': 'p2',
        'sort_order': 1,
        'added_at': now,
      });

      final count = await dataSource.getAlbumPhotoCount('a1');
      expect(count, 2);
    });

    test('returns 0 for empty album', () async {
      await db.insert('albums', makeAlbum('a1'));

      final count = await dataSource.getAlbumPhotoCount('a1');
      expect(count, 0);
    });
  });
}
