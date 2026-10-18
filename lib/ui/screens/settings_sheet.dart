import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:permission_handler/permission_handler.dart';

import '../../state/download_manager.dart';
import '../../state/library_store.dart';
import '../../theme/sika_tokens.dart';
import '../components/common.dart';
import '../components/sika_switch.dart';

Future<void> showSettingsSheet(BuildContext context) => showSikaSheet(context, (ctx) => const _SettingsSheet());

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(libraryProvider);
    final dl = ref.watch(downloadsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Réglages', style: SikaText.display(24, ls: -0.6)),
            const SizedBox(height: 16),
            _Row(
              title: 'Prénom',
              subtitle: lib.userName,
              trailing: TextButton(
                onPressed: () async {
                  final v = await askText(context, 'Ton prénom', 'Prénom', initial: lib.userName);
                  if (v != null) ref.read(libraryProvider.notifier).setUserName(v);
                },
                child: Text('Modifier', style: SikaText.ui(13, w: FontWeight.w800, color: SikaColors.yellow)),
              ),
            ),
            if (DownloadManager.supported)
              _Row(
                title: 'Mode hors ligne',
                subtitle: 'Ne lire que les titres téléchargés',
                trailing: SikaSwitch(value: dl.offlineMode, label: 'Mode hors ligne', onChanged: ref.read(downloadsProvider.notifier).setOffline),
              ),
            if (DownloadManager.supported) const _BackgroundPlaybackRow(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: SikaColors.surface2, borderRadius: BorderRadius.circular(SikaRadius.lg)),
              child: Text(
                'YouPlay lit YouTube via NewPipeExtractor (usage personnel). '
                'Paroles fournies par LRCLIB. Tes likes, playlists, historique et téléchargements restent sur cet appareil.',
                style: SikaText.ui(13, color: SikaColors.textSoft, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.subtitle, required this.trailing});
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: SikaText.ui(15, w: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: SikaText.meta),
            ]),
          ),
          trailing,
        ]),
      );
}

/// MIUI / HyperOS coupe les apps en arrière-plan pour économiser la batterie, ce qui arrête la musique.
class _BackgroundPlaybackRow extends StatefulWidget {
  const _BackgroundPlaybackRow();
  @override
  State<_BackgroundPlaybackRow> createState() => _BackgroundPlaybackRowState();
}

class _BackgroundPlaybackRowState extends State<_BackgroundPlaybackRow> {
  bool? _granted;

  @override
  void initState() {
    super.initState();
    Permission.ignoreBatteryOptimizations.isGranted.then((v) {
      if (mounted) setState(() => _granted = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ok = _granted == true;
    return _Row(
      title: 'Lecture en arrière-plan',
      subtitle: ok ? 'Aucune restriction de batterie' : 'Évite que le téléphone coupe la musique',
      trailing: ok
          ? Text('Activé', style: SikaText.ui(13, w: FontWeight.w800, color: SikaColors.yellow))
          : TextButton(
              onPressed: () async {
                final r = await Permission.ignoreBatteryOptimizations.request();
                if (mounted) setState(() => _granted = r.isGranted);
              },
              child: Text('Autoriser', style: SikaText.ui(13, w: FontWeight.w800, color: SikaColors.yellow)),
            ),
    );
  }
}
