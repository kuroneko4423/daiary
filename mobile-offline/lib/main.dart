import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'features/album/data/datasources/photo_local_datasource.dart';
import 'services/database_service.dart';
import 'services/share_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.initialize();
  ShareService.cleanupTempShareFiles();
  PhotoLocalDataSource().cleanupExpiredPhotos();
  runApp(
    const ProviderScope(
      child: DAIaryApp(),
    ),
  );
}
