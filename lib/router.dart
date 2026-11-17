import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/models.dart';
import 'theme/sika_tokens.dart';
import 'ui/components/bottom_nav.dart';
import 'ui/components/common.dart';
import 'ui/components/mini_player.dart';
import 'ui/screens/collection_screen.dart';
import 'ui/screens/downloads_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/library_screen.dart';
import 'ui/screens/player_screen.dart';
import 'ui/screens/search_screen.dart';

/// Navigateur racine : sert aussi à afficher la proposition de mise à jour au démarrage.
final rootNavigatorKey = GlobalKey<NavigatorState>();
const _tabs = ['/home', '/search', '/library', '/downloads'];

GoRoute _collectionRoute() => GoRoute(
      path: 'c/:kind/:id',
      builder: (context, state) {
        final extra = state.extra;
        final c = extra is CollectionRef
            ? extra
            : CollectionRef(CollectionKind.values.byName(state.pathParameters['kind']!), state.pathParameters['id']!);
        return CollectionScreen(key: ValueKey(c.key), collection: c);
      },
    );

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _Shell(shell: shell),
      branches: [
        for (final (i, path) in _tabs.indexed)
          StatefulShellBranch(routes: [
            GoRoute(
              path: path,
              builder: (_, _) => switch (i) {
                0 => const HomeScreen(),
                1 => const SearchScreen(),
                2 => const LibraryScreen(),
                _ => const DownloadsScreen(),
              },
              routes: [_collectionRoute()],
            ),
          ]),
      ],
    ),
    GoRoute(
      path: '/player',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (_, state) => CustomTransitionPage(
        key: state.pageKey,
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        child: const PlayerScreen(),
        transitionsBuilder: (_, a, _, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ),
  ],
);

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    TabTracker.base = _tabs[shell.currentIndex];
    final navH = BottomNav.heightOf(context);
    return Scaffold(
      backgroundColor: SikaColors.bg,
      body: Stack(
        children: [
          Positioned.fill(child: shell),
          Positioned(left: SikaSpace.miniPlayerInset, right: SikaSpace.miniPlayerInset, bottom: navH + 4, child: const MiniPlayer()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNav(
              index: shell.currentIndex,
              onTap: (i) {
                TabTracker.base = _tabs[i];
                shell.goBranch(i, initialLocation: i == shell.currentIndex);
              },
            ),
          ),
        ],
      ),
    );
  }
}
