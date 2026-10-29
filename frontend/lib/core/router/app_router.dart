import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/favourites/presentation/favourites_page.dart';
import '../../features/more/presentation/more_page.dart';
import '../../features/onboarding/application/onboarding_provider.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/prayers/presentation/blocked_users_page.dart';
import '../../features/prayers/presentation/prayers_page.dart';
import '../../features/share/presentation/share_verse_page.dart';
import '../../features/verses/presentation/explore_page.dart';
import '../../features/verses/presentation/home_page.dart';
import '../../features/verses/presentation/mood_verses_page.dart';
import 'app_routes.dart';
import 'app_shell.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final onboardingAsync = ref.watch(onboardingCompletedProvider);
      if (onboardingAsync.isLoading) return null;

      final hasCompleted = onboardingAsync.value ?? false;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;

      if (!hasCompleted && !isOnboarding) {
        return AppRoutes.onboarding;
      }
      if (hasCompleted && isOnboarding) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      // Outside the shell so it opens full-screen above the bottom nav.
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.share,
        // The verse travels as `extra`, which is lost on a cold deep link.
        redirect: (_, state) =>
            state.extra is ShareVerseArgs ? null : AppRoutes.home,
        builder: (_, state) =>
            ShareVersePage(args: state.extra! as ShareVerseArgs),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.explore,
                builder: (_, _) => const ExplorePage(),
                routes: [
                  GoRoute(
                    path: 'mood/:moodId',
                    builder: (_, state) =>
                        MoodVersesPage(moodId: state.pathParameters['moodId']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.prayers,
                builder: (_, _) => const PrayersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.favourites,
                builder: (_, _) => const FavouritesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (_, _) => const MorePage(),
                routes: [
                  GoRoute(
                    path: 'blocked',
                    builder: (_, _) => const BlockedUsersPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
