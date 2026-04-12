import 'package:daiary_shared/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/router.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

class DAIaryApp extends ConsumerWidget {
  const DAIaryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'dAIary',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(settingsProvider.notifier).themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
