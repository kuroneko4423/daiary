import 'package:daiary_shared/features/navigation/main_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/ai_generate/presentation/screens/ai_generate_screen.dart';
import '../features/album/presentation/screens/album_detail_screen.dart';
import '../features/album/presentation/screens/album_list_screen.dart';
import '../features/album/presentation/screens/photo_detail_screen.dart';
import '../features/album/presentation/screens/photo_list_screen.dart';
import '../features/camera/presentation/screens/camera_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';

final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('has_completed_onboarding') ?? false;
});

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingAsync = ref.watch(hasCompletedOnboardingProvider);

  return GoRouter(
    initialLocation: '/camera',
    redirect: (context, state) {
      final hasCompleted = onboardingAsync.valueOrNull ?? false;
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!hasCompleted && !isOnboarding) {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/camera',
            builder: (context, state) => const CameraScreen(),
          ),
          GoRoute(
            path: '/photos',
            builder: (context, state) => const PhotoListScreen(),
          ),
          GoRoute(
            path: '/albums',
            builder: (context, state) => const AlbumListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => AlbumDetailScreen(
                  albumId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/ai-generate',
        builder: (context, state) {
          final photoPath = state.extra as String?;
          return AIGenerateScreen(photoPath: photoPath);
        },
      ),
      GoRoute(
        path: '/photos/:id',
        builder: (context, state) => PhotoDetailScreen(
          photoId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
});
