import 'package:sqflite/sqflite.dart';
import '../../../../services/database_service.dart';

class AlbumLocalDataSource {
  Future<Database> get _db => DatabaseService.database;

  Future<List<Map<String, dynamic>>> getAlbums() async {
    final db = await _db;
    return await db.query('albums', orderBy: 'updated_at DESC');
  }

  Future<Map<String, dynamic>?> getAlbum(String id) async {
    final db = await _db;
    final results = await db.query('albums', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insertAlbum(Map<String, dynamic> data) async {
    final db = await _db;
    await db.insert('albums', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAlbum(String id, Map<String, dynamic> data) async {
    final db = await _db;
    data['updated_at'] = DateTime.now().toIso8601String();
    await db.update('albums', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAlbum(String id) async {
    final db = await _db;
    await db.delete('albums', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAlbumPhotos(String albumId) async {
    final db = await _db;
    return await db.rawQuery('''
      SELECT p.* FROM photos p
      INNER JOIN album_photos ap ON p.id = ap.photo_id
      WHERE ap.album_id = ? AND p.deleted_at IS NULL
      ORDER BY ap.sort_order ASC, ap.added_at DESC
    ''', [albumId]);
  }

  Future<void> addPhotosToAlbum(
      String albumId, List<String> photoIds) async {
    final db = await _db;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (var i = 0; i < photoIds.length; i++) {
      batch.insert(
        'album_photos',
        {
          'album_id': albumId,
          'photo_id': photoIds[i],
          'sort_order': i,
          'added_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> removePhotoFromAlbum(String albumId, String photoId) async {
    final db = await _db;
    await db.delete(
      'album_photos',
      where: 'album_id = ? AND photo_id = ?',
      whereArgs: [albumId, photoId],
    );
  }

  Future<int> getAlbumPhotoCount(String albumId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM album_photos WHERE album_id = ?',
      [albumId],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
