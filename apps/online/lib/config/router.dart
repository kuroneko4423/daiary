import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:daiary_shared/features/navigation/main_shell.dart';

import '../features/ai_generate/presentation/screens/ai_generate_screen.dart';
import '../features/album/presentation/screens/album_detail_screen.dart';
import '../features/album/presentation/screens/album_list_screen.dart';
import '../features/album/presentation/screens/photo_detail_screen.dart';
import '../features/album/presentation/screens/photo_list_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/camera/presentation/screens/camera_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/subscription_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }
      if (isLoggedIn && isAuthRoute) {
        return '/camera';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
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
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
    ],
  );
});
