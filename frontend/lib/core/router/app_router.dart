import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/favourites/presentation/favourites_page.dart';
import '../../features/more/presentation/more_page.dart';
import '../../features/verses/presentation/explore_page.dart';
import '../../features/verses/presentation/home_page.dart';
import 'app_shell.dart';

part 'app_router.g.dart';

abstract final class AppRoutes {
  static const home = '/home';
  static const explore = '/explore';
  static const favourites = '/favourites';
  static const more = '/more';
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
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
