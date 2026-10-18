import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'router.dart';
import 'state/playlist_folders.dart';
import 'state/providers.dart';
import 'theme/sika_tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lecture en arrière-plan + contrôles écran de verrouillage / notification.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'app.sika.audio',
    androidNotificationChannelName: 'Lecture YouPlay',
    androidNotificationOngoing: true,
    // Icône monochrome dédiée : l'icône d'app adaptative ferait masquer la notification.
    androidNotificationIcon: 'drawable/ic_stat_youplay',
  );
  final prefs = await SharedPreferences.getInstance();
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
}

class SikaApp extends ConsumerWidget {
  const SikaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Démarre la synchronisation playlists ↔ dossiers Music/YouPlay/<playlist>.
    ref.watch(playlistFoldersProvider);
    return MaterialApp.router(
      title: 'YouPlay',
      debugShowCheckedModeBanner: false,
      theme: sikaTheme(),
      routerConfig: router,
    );
  }
}
