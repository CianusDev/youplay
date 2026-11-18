import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/l10n.dart';
import 'router.dart';
import 'state/playlist_folders.dart';
import 'state/providers.dart';
import 'theme/sika_tokens.dart';
import 'ui/components/migration_flow.dart';
import 'ui/components/splash_overlay.dart';
import 'ui/components/update_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Langue de l'interface dès le démarrage (nom du canal de notification compris).
  final savedLocale = prefs.getString('youplay.locale');
  L10n.update(resolveAppLocale(savedLocale == null ? null : Locale(savedLocale)));
  // Lecture en arrière-plan + contrôles écran de verrouillage / notification.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'app.sika.audio',
    androidNotificationChannelName: L10n.current.notificationChannelName,
    // Le service reste au premier plan même en pause : sinon Android 12+ refuse de le relancer
    // quand la lecture reprend en arrière-plan (fin d'appel, fin de vidéo…), la musique tourne
    // sans protection et MIUI tue l'app au premier manque de mémoire.
    androidStopForegroundOnPause: false,
    // Icône monochrome dédiée : l'icône d'app adaptative ferait masquer la notification.
    androidNotificationIcon: 'drawable/ic_stat_youplay',
  );
  // Android 13+ : sans cette permission, la notification de lecture (contrôles en arrière-plan) est masquée.
  if (!kIsWeb && Platform.isAndroid) {
    Permission.notification.status.then((s) {
      if (!s.isGranted && !s.isPermanentlyDenied) Permission.notification.request();
    });
  }
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: SikaColors.bg,
  ));
  runApp(ProviderScope(
    overrides: [prefsProvider.overrideWithValue(prefs)],
    child: const SikaApp(),
  ));
  if (!kIsWeb && Platform.isAndroid) _scheduleStartupChecks();
}

/// Passage depuis l'ancienne YouPlay, sinon mise à jour publiée sur GitHub :
/// proposés une fois l'écran d'accueil affiché.
void _scheduleStartupChecks() {
  BuildContext? overlay() => rootNavigatorKey.currentState?.overlay?.context;

  Future.delayed(const Duration(seconds: 4), () async {
    final ctx = overlay();
    if (ctx == null || !ctx.mounted || await runMigration(ctx)) return;
    // Recherche sur GitHub seulement si l'utilisateur l'a acceptée (demandé une fois).
    final again = overlay();
    if (again == null || !again.mounted || !await autoUpdateAllowed(again)) return;
    final last = overlay();
    if (last != null && last.mounted) checkForUpdate(last);
  });
}

class SikaApp extends ConsumerWidget {
  const SikaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Démarre la synchronisation playlists ↔ dossiers Music/YouPlay/<playlist>.
    ref.watch(playlistFoldersProvider);
    final chosen = ref.watch(appLocaleProvider);
    return MaterialApp.router(
      title: 'YouPlay',
      debugShowCheckedModeBanner: false,
      theme: sikaTheme(),
      routerConfig: router,
      // Langue : choix des réglages, sinon celle du téléphone (français), sinon anglais.
      locale: chosen,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeListResolutionCallback: (device, _) => resolveAppLocale(chosen, device),
      builder: (context, child) {
        L10n.update(Localizations.localeOf(context));
        return SplashOverlay(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
