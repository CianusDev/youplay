import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sika_app/ui/nav_utils.dart';

/// Réplique de la structure du router de l'app : shell à onglets + /player racine.
GoRouter build() {
  final root = GlobalKey<NavigatorState>();
  GoRoute sub() => GoRoute(path: 'c/:kind/:id', builder: (_, s) => Text('c ${s.pathParameters['id']}'));
  return GoRouter(
    navigatorKey: root,
    initialLocation: '/search',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => shell,
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const Text('home'), routes: [sub()])]),
          StatefulShellBranch(routes: [GoRoute(path: '/search', builder: (_, _) => const Text('search'), routes: [sub()])]),
        ],
      ),
      GoRoute(path: '/player', parentNavigatorKey: root, builder: (_, _) => const Text('player')),
    ],
  );
}

void main() {
  testWidgets('deux collections empilées dans le même onglet', (t) async {
    final r = build();
    await t.pumpWidget(MaterialApp.router(routerConfig: r));
    r.push('/search/c/ytalbum/a');
    await t.pumpAndSettle();
    r.push('/search/c/ytquery/b');
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('isPlayerOpen détecte /player malgré une URI inchangée', (t) async {
    final r = build();
    await t.pumpWidget(MaterialApp.router(routerConfig: r));
    expect(isPlayerOpen(r), isFalse);
    r.push('/player');
    await t.pumpAndSettle();
    expect(r.routerDelegate.currentConfiguration.uri.path, '/search');
    expect(isPlayerOpen(r), isTrue);
  });

  testWidgets('pushTabPage ferme le lecteur avant de pousser (pas de clé dupliquée)', (t) async {
    final r = build();
    await t.pumpWidget(MaterialApp.router(routerConfig: r));
    r.push('/search/c/ytalbum/a');
    await t.pumpAndSettle();
    r.push('/player');
    await t.pumpAndSettle();
    await t.runAsync(() async {
      final f = pushTabPage(r, '/search/c/ytquery/b');
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 20));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await f;
    });
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(isPlayerOpen(r), isFalse);
    expect(find.text('c b'), findsOneWidget);
  });
}
