import 'package:go_router/go_router.dart';

/// Vrai si le lecteur plein écran (/player, route racine) est au sommet.
/// Attention : `currentConfiguration.uri` ne reflète pas les `push`, d'où `last.matchedLocation`.
bool isPlayerOpen(GoRouter router) => router.routerDelegate.currentConfiguration.last.matchedLocation == '/player';

/// Pousse une page d'onglet. Si le lecteur est ouvert, il est d'abord fermé :
/// pousser une route du shell par-dessus /player dupliquerait la page du shell
/// (assertion '!keyReservation.contains(key)').
Future<void> pushTabPage(GoRouter router, String location, {Object? extra}) async {
  if (isPlayerOpen(router)) {
    router.pop();
    for (var i = 0; i < 30 && isPlayerOpen(router); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    if (isPlayerOpen(router)) return;
  }
  router.push(location, extra: extra);
}
