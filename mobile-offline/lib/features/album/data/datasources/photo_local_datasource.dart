import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../../../../services/database_service.dart';

class PhotoLocalDataSource {
  Future<Database> get _db => DatabaseService.database;

  Future<List<Map<String, dynamic>>> getPhotos({
    bool? favoritesOnly,
    bool? trashOnly,
  }) async {
    final db = await _db;
    String where;
    if (trashOnly == true) {
      where = 'deleted_at IS NOT NULL';
    } else if (favoritesOnly == true) {
      where = 'deleted_at IS NULL AND is_favorite = 1';
    } else {
      where = 'deleted_at IS NULL';
    }
    return await db.query(
      'photos',
      where: where,
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getPhoto(String id) async {
    final db = await _db;
    final results = await db.query('photos', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insertPhoto(Map<String, dynamic> data) async {
    final db = await _db;
    await db.insert('photos', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePhoto(String id, Map<String, dynamic> data) async {
    final db = await _db;
    await db.update('photos', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> softDeletePhoto(String id) async {
    final db = await _db;
    await db.update(
      'photos',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restorePhoto(String id) async {
    final db = await _db;
    await db.update(
      'photos',
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> permanentlyDeletePhoto(String id) async {
    final db = await _db;
    final photo = await getPhoto(id);
    if (photo != null) {
      // Delete files
      final localPath = photo['local_path'] as String?;
      final thumbPath = photo['thumbnail_path'] as String?;
      if (localPath != null) {
        final file = File(localPath);
        if (await file.exists()) await file.delete();
      }
      if (thumbPath != null) {
        final file = File(thumbPath);
        if (await file.exists()) await file.delete();
      }
      await db.delete('photos', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<List<Map<String, dynamic>>> searchByTags(String query) async {
    final db = await _db;
    return await db.query(
      'photos',
      where: 'deleted_at IS NULL AND ai_tags LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> getStorageUsageBytes() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(file_size), 0) as total FROM photos WHERE deleted_at IS NULL',
    );
    return (result.first['total'] as int?) ?? 0;
  }
}
