import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daiary_offline/services/database_service.dart';
import 'package:daiary_offline/features/album/data/datasources/photo_local_datasource.dart';

void main() {
  late Database db;
  late PhotoLocalDataSource dataSource;

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
    dataSource = PhotoLocalDataSource();
  });

  tearDown(() async {
    DatabaseService.testDatabase = null;
    await db.close();
  });

  Map<String, dynamic> makePhoto(String id, {
    String? deletedAt,
    int isFavorite = 0,
    String? aiTags,
    int fileSize = 1024,
  }) {
    return {
      'id': id,
      'local_path': '/photos/$id.jpg',
      'thumbnail_path': '/thumbs/$id.jpg',
      'original_filename': '$id.jpg',
      'file_size': fileSize,
      'width': 100,
      'height': 100,
      'ai_tags': aiTags,
      'is_favorite': isFavorite,
      'deleted_at': deletedAt,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  group('getPhotos', () {
    test('returns all non-deleted photos', () async {
      await db.insert('photos', makePhoto('p1'));
      await db.insert('photos', makePhoto('p2'));
      await db.insert('photos', makePhoto('p3', deletedAt: DateTime.now().toIso8601String()));

      final results = await dataSource.getPhotos();
      expect(results.length, 2);
    });

    test('returns only favorites when favoritesOnly is true', () async {
      await db.insert('photos', makePhoto('p1', isFavorite: 1));
      await db.insert('photos', makePhoto('p2'));

      final results = await dataSource.getPhotos(favoritesOnly: true);
      expect(results.length, 1);
      expect(results.first['id'], 'p1');
    });

    test('returns only trashed photos when trashOnly is true', () async {
      await db.insert('photos', makePhoto('p1'));
      await db.insert('photos', makePhoto('p2', deletedAt: DateTime.now().toIso8601String()));

      final results = await dataSource.getPhotos(trashOnly: true);
      expect(results.length, 1);
      expect(results.first['id'], 'p2');
    });
  });

  group('getPhoto', () {
    test('returns photo by id', () async {
      await db.insert('photos', makePhoto('p1'));

      final result = await dataSource.getPhoto('p1');
      expect(result, isNotNull);
      expect(result!['id'], 'p1');
    });

    test('returns null for non-existent id', () async {
      final result = await dataSource.getPhoto('nonexistent');
      expect(result, isNull);
    });
  });

  group('insertPhoto', () {
    test('inserts a photo', () async {
      await dataSource.insertPhoto(makePhoto('p1'));

      final result = await db.query('photos', where: 'id = ?', whereArgs: ['p1']);
      expect(result.length, 1);
      expect(result.first['id'], 'p1');
    });

    test('replaces on conflict', () async {
      await dataSource.insertPhoto(makePhoto('p1', fileSize: 100));
      await dataSource.insertPhoto(makePhoto('p1', fileSize: 200));

      final result = await db.query('photos', where: 'id = ?', whereArgs: ['p1']);
      expect(result.length, 1);
      expect(result.first['file_size'], 200);
    });
  });

  group('updatePhoto', () {
    test('updates photo fields', () async {
      await db.insert('photos', makePhoto('p1'));

      await dataSource.updatePhoto('p1', {'is_favorite': 1});

      final result = await db.query('photos', where: 'id = ?', whereArgs: ['p1']);
      expect(result.first['is_favorite'], 1);
    });
  });

  group('softDeletePhoto', () {
    test('sets deleted_at timestamp', () async {
      await db.insert('photos', makePhoto('p1'));

      await dataSource.softDeletePhoto('p1');

      final result = await db.query('photos', where: 'id = ?', whereArgs: ['p1']);
      expect(result.first['deleted_at'], isNotNull);
    });
  });

  group('restorePhoto', () {
    test('clears deleted_at', () async {
      await db.insert('photos', makePhoto('p1', deletedAt: DateTime.now().toIso8601String()));

      await dataSource.restorePhoto('p1');

      final result = await db.query('photos', where: 'id = ?', whereArgs: ['p1']);
      expect(result.first['deleted_at'], isNull);
    });
  });

  group('permanentlyDeletePhoto', () {
    test('removes photo record from database', () async {
      await db.insert('photos', makePhoto('p1'));

      await dataSource.permanentlyDeletePhoto('p1');

      final result = await db.query('photos', where: 'id = ?', whereArgs: ['p1']);
      expect(result, isEmpty);
    });

    test('does nothing for non-existent id', () async {
      await dataSource.permanentlyDeletePhoto('nonexistent');
      // Should not throw
    });
  });

  group('searchByTags', () {
    test('finds photos by tag substring', () async {
      await db.insert('photos', makePhoto('p1', aiTags: 'sunset,beach,ocean'));
      await db.insert('photos', makePhoto('p2', aiTags: 'mountain,forest'));
      await db.insert('photos', makePhoto('p3', aiTags: 'beach,palm'));

      final results = await dataSource.searchByTags('beach');
      expect(results.length, 2);
    });

    test('excludes deleted photos', () async {
      await db.insert('photos', makePhoto('p1', aiTags: 'beach', deletedAt: DateTime.now().toIso8601String()));

      final results = await dataSource.searchByTags('beach');
      expect(results, isEmpty);
    });
  });

  group('getStorageUsageBytes', () {
    test('sums file sizes of non-deleted photos', () async {
      await db.insert('photos', makePhoto('p1', fileSize: 1000));
      await db.insert('photos', makePhoto('p2', fileSize: 2000));
      await db.insert('photos', makePhoto('p3', fileSize: 500, deletedAt: DateTime.now().toIso8601String()));

      final total = await dataSource.getStorageUsageBytes();
      expect(total, 3000);
    });

    test('returns 0 when no photos exist', () async {
      final total = await dataSource.getStorageUsageBytes();
      expect(total, 0);
    });
  });

  group('cleanupExpiredPhotos', () {
    test('deletes photos older than threshold', () async {
      final oldDate = DateTime.now().subtract(const Duration(days: 31)).toIso8601String();
      final recentDate = DateTime.now().subtract(const Duration(days: 5)).toIso8601String();

      await db.insert('photos', makePhoto('p1', deletedAt: oldDate));
      await db.insert('photos', makePhoto('p2', deletedAt: recentDate));
      await db.insert('photos', makePhoto('p3'));

      final count = await dataSource.cleanupExpiredPhotos();
      expect(count, 1);

      final remaining = await db.query('photos');
      expect(remaining.length, 2);
      expect(remaining.map((r) => r['id']).toList()..sort(), ['p2', 'p3']);
    });

    test('respects custom threshold', () async {
      final date = DateTime.now().subtract(const Duration(days: 10)).toIso8601String();
      await db.insert('photos', makePhoto('p1', deletedAt: date));

      final count = await dataSource.cleanupExpiredPhotos(daysThreshold: 5);
      expect(count, 1);
    });

    test('returns 0 when nothing to clean', () async {
      await db.insert('photos', makePhoto('p1'));

      final count = await dataSource.cleanupExpiredPhotos();
      expect(count, 0);
    });
  });
}
