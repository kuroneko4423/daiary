import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/share_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  ShareService.cleanupTempShareFiles();
  runApp(
    const ProviderScope(
      child: DAIaryApp(),
    ),
  );
}
