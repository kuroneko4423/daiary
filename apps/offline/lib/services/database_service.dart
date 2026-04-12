import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _database;
  static const _dbName = 'daiary.db';
  static const _dbVersion = 1;

  @visibleForTesting
  static set testDatabase(Database? db) => _database = db;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDir.path, 'daiary', _dbName);

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
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

    // Indexes for common queries
    await db.execute(
        'CREATE INDEX idx_photos_created_at ON photos(created_at DESC)');
    await db.execute(
        'CREATE INDEX idx_photos_is_favorite ON photos(is_favorite)');
    await db.execute(
        'CREATE INDEX idx_photos_deleted_at ON photos(deleted_at)');
    await db.execute(
        'CREATE INDEX idx_album_photos_album_id ON album_photos(album_id)');
    await db.execute(
        'CREATE INDEX idx_ai_generations_photo_id ON ai_generations(photo_id)');
  }

  static Future<void> initialize() async {
    await database;
  }

  static Future<void> clearAllData() async {
    final db = await database;

    // Delete in order respecting foreign key constraints
    await db.delete('ai_generations');
    await db.delete('album_photos');
    await db.delete('albums');
    await db.delete('photos');

    // Delete photo and thumbnail files
    final documentsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(join(documentsDir.path, 'daiary', 'photos'));
    final thumbsDir =
        Directory(join(documentsDir.path, 'daiary', 'thumbnails'));

    if (await photosDir.exists()) {
      await photosDir.delete(recursive: true);
    }
    if (await thumbsDir.exists()) {
      await thumbsDir.delete(recursive: true);
    }
  }

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
