import 'package:daiary_shared/services/share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'features/album/data/datasources/photo_local_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.initialize();
  ShareService.cleanupTempShareFiles();
  PhotoLocalDataSource().cleanupExpiredPhotos();
  runApp(const ProviderScope(child: DAIaryApp()));
}
