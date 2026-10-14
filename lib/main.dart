import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'router.dart';
import 'state/providers.dart';
import 'theme/sika_tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lecture en arrière-plan + contrôles écran de verrouillage / notification.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'app.sika.audio',
    androidNotificationChannelName: 'Lecture YouPlay',
    androidNotificationOngoing: true,
  );
  final prefs = await SharedPreferences.getInstance();
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

class SikaApp extends StatelessWidget {
  const SikaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'YouPlay',
      debugShowCheckedModeBanner: false,
      theme: sikaTheme(),
      routerConfig: router,
    );
  }
}
