import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/favourites/presentation/favourites_page.dart';
import '../../features/more/presentation/more_page.dart';
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
    routes: [
      // Outside the shell so it opens full-screen above the bottom nav.
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
