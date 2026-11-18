import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/app_update.dart';
import '../../data/library_backup.dart';
import '../../data/media_storage.dart';
import '../../l10n/l10n.dart';
import '../../state/download_manager.dart';
import '../../state/library_store.dart';
import '../../theme/sika_tokens.dart';
import '../components/common.dart';
import '../components/feedback_sheet.dart';
import '../components/migration_flow.dart';
import '../components/sika_switch.dart';
import '../components/update_dialog.dart';

Future<void> showSettingsSheet(BuildContext context) => showSikaSheet(context, (ctx) => const _SettingsSheet());

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(libraryProvider);
    final dl = ref.watch(downloadsProvider);
    final l = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.settingsTitle, style: SikaText.display(24, ls: -0.6)),
            const SizedBox(height: 16),
            _Row(
              title: l.firstName,
              subtitle: displayUserName(l, lib.userName),
              trailing: TextButton(
                onPressed: () async {
                  final v = await askText(context, l.yourFirstName, l.firstName, initial: lib.userName);
                  if (v != null) ref.read(libraryProvider.notifier).setUserName(v);
                },
                child: Text(l.edit, style: SikaText.ui(13, w: FontWeight.w800, color: SikaColors.yellow)),
              ),
            ),
            if (DownloadManager.supported)
              _Row(
                title: l.offlineMode,
                subtitle: l.offlineModeSubtitle,
                trailing: SikaSwitch(value: dl.offlineMode, label: l.offlineMode, onChanged: ref.read(downloadsProvider.notifier).setOffline),
              ),
            if (DownloadManager.supported)
              _Row(
                title: l.saveMobileData,
                subtitle: l.saveMobileDataSub,
                trailing: SikaSwitch(value: dl.wifiOnly, label: l.saveMobileData, onChanged: ref.read(downloadsProvider.notifier).setWifiOnly),
              ),
            const _LanguageRow(),
            if (DownloadManager.supported) const _BackupRow(),
            if (DownloadManager.supported) const _BackgroundPlaybackRow(),
            _Row(
              title: l.feedbackTitle,
              subtitle: l.feedbackSub,
              trailing: TextButton(
                onPressed: () => showFeedbackSheet(context),
                child: Text(l.feedbackWrite, style: SikaText.ui(13, w: FontWeight.w800, color: SikaColors.yellow)),
              ),
            ),
            if (DownloadManager.supported) const _AutoUpdateRow(),
            if (DownloadManager.supported) const _UpdateRow(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: SikaColors.surface2, borderRadius: BorderRadius.circular(SikaRadius.lg)),
              child: Text(
                l.settingsAbout,
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

/// Langue de l'interface : langue du téléphone (par défaut), français ou anglais.
class _LanguageRow extends ConsumerWidget {
  const _LanguageRow();

  static String _name(Locale locale) => switch (locale.languageCode) {
        'fr' => 'Français',
        _ => 'English',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final chosen = ref.watch(appLocaleProvider);
    return _Row(
      title: l.language,
      subtitle: chosen == null ? '${l.languageSystem} · ${_name(Localizations.localeOf(context))}' : _name(chosen),
      trailing: TextButton(
        onPressed: () => showSikaSheet(context, (ctx) {
          void pick(Locale? v) {
            ref.read(appLocaleProvider.notifier).set(v);
            Navigator.of(ctx).pop();
          }

          Widget option(String label, Locale? v) => SheetAction(
                icon: chosen == v ? 'check' : 'globe',
                label: label,
                color: chosen == v ? SikaColors.yellow : SikaColors.text,
                onTap: () => pick(v),
              );
          return SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(l.language, style: SikaText.h2Small),
              ),
              option(l.languageSystem, null),
              for (final loc in supportedAppLocales) option(_name(loc), loc),
              const SizedBox(height: 8),
            ]),
          );
        }),
        child: Text(l.edit, style: SikaText.ui(13, w: FontWeight.w800, color: SikaColors.yellow)),
      ),
    );
  }
}

/// Version installée + recherche manuelle d'une mise à jour (résultat affiché dans la ligne).
class _UpdateRow extends StatefulWidget {
  const _UpdateRow();
  @override
  State<_UpdateRow> createState() => _UpdateRowState();
}

class _UpdateRowState extends State<_UpdateRow> {
  String? _version;
  bool _checking = false;
  UpdateCheck? _result;

  @override
  void initState() {
    super.initState();
    AppUpdater.currentVersionName().then((v) {
      if (mounted) setState(() => _version = v);
    });
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _result = null;
    });
    final r = await checkForUpdate(context, manual: true);
    if (mounted) {
      setState(() {
        _checking = false;
        _result = r;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = _version == null || _version!.isEmpty ? l.installedVersion : l.versionLabel(_version!);
    return _Row(
      title: l.updatesTitle,
      subtitle: switch (_result) {
        UpdateCheck.upToDate => l.upToDateSuffix(v),
        UpdateCheck.failed => l.updateCheckFailed,
        _ => v,
      },
      trailing: _checking
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: SikaColors.yellow)),
            )
          : TextButton(
              onPressed: _check,
              child: Text(context.l10n.check, style: SikaText.ui(13, w: FontWeight.w800, color: SikaColors.yellow)),
            ),
    );
  }
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
    final l = context.l10n;
    return _Row(
      title: l.backgroundPlayback,
      subtitle: ok ? l.noBatteryRestriction : l.backgroundPlaybackHint,
      trailing: ok
          ? Text(l.enabled, style: SikaText.ui(13, w: FontWeight.w800, color: SikaColors.yellow))
          : TextButton(
              onPressed: () async {
                final r = await Permission.ignoreBatteryOptimizations.request();
                if (mounted) setState(() => _granted = r.isGranted);
              },
              child: Text(l.allow, style: SikaText.ui(13, w: FontWeight.w800, color: SikaColors.yellow)),
            ),
    );
  }
}

/// Sauvegarde dans un fichier, restauration, et transfert entre l'ancienne et la nouvelle YouPlay.
class _BackupRow extends StatefulWidget {
  const _BackupRow();
  @override
  State<_BackupRow> createState() => _BackupRowState();
}

class _BackupRowState extends State<_BackupRow> {
  String? _message;
  MigrationInfo? _info;

  @override
  void initState() {
    super.initState();
    LibraryBackup.info().then((i) {
      if (mounted) setState(() => _info = i);
    }).catchError((_) {});
  }

  void _show(String m) {
    if (mounted) setState(() => _message = m);
  }

  Future<void> _export() async {
    final l = context.l10n;
    try {
      final ok = await LibraryBackup.saveToFile(await SharedPreferences.getInstance());
      if (ok != null) _show(ok ? l.backupSaved : l.backupSaveFailed);
    } catch (_) {
      _show(l.backupSaveFailed);
    }
  }

  Future<void> _restore() async {
    final l = context.l10n;
    final String? raw;
    try {
      raw = await LibraryBackup.pickFile();
    } catch (_) {
      return _show(l.backupInvalid);
    }
    if (raw == null) return; // annulé
    final data = LibraryBackup.parse(raw);
    if (data == null) return _show(l.backupInvalid);
    if (!mounted || !await confirmAction(context, l.restoreTitle, l.restoreBody, l.restoreAction)) return;
    // Sans « Musique et audio », les sons déjà sur le téléphone paraîtraient absents et seraient oubliés.
    await MediaStorage.ensurePermission();
    final prefs = await SharedPreferences.getInstance();
    await LibraryBackup.restore(prefs, data);
    await markRestored(prefs); // au redémarrage : reprise des sons de l'ancienne app
    await LibraryBackup.restart();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final legacy = _info?.legacyInstalled == true;
    return _Row(
      title: l.backupTitle,
      subtitle: _message ?? l.backupSub,
      trailing: TextButton(
        onPressed: () => showSikaSheet(context, (ctx) {
          void run(Future<void> Function() action) {
            Navigator.of(ctx).pop();
            action();
          }

          return SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(l.backupTitle, style: SikaText.h2Small),
              ),
              SheetAction(icon: 'share', label: l.backupExport, onTap: () => run(_export)),
              SheetAction(icon: 'download-circle', label: l.backupRestore, onTap: () => run(_restore)),
              // L'ancienne YouPlay est encore là : y exporter la bibliothèque, puis la restaurer ici.
              if (legacy)
                SheetAction(
                  icon: 'chevron-right',
                  label: l.migrateOpenLegacyAction,
                  color: SikaColors.yellow,
                  onTap: () => run(LibraryBackup.openLegacy),
                ),
              const SizedBox(height: 8),
            ]),
          );
        }),
        child: Text(l.backupManage, style: SikaText.ui(13, w: FontWeight.w800, color: SikaColors.yellow)),
      ),
    );
  }
}

/// Recherche de mise à jour au démarrage (sur GitHub) : activée seulement par l'utilisateur.
class _AutoUpdateRow extends StatefulWidget {
  const _AutoUpdateRow();
  @override
  State<_AutoUpdateRow> createState() => _AutoUpdateRowState();
}

class _AutoUpdateRowState extends State<_AutoUpdateRow> {
  bool _on = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _on = p.getBool(autoUpdateKey) ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Row(
      title: l.updateAuto,
      subtitle: l.updateAutoSub,
      trailing: SikaSwitch(
        value: _on,
        label: l.updateAuto,
        onChanged: (v) async {
          setState(() => _on = v);
          await (await SharedPreferences.getInstance()).setBool(autoUpdateKey, v);
        },
      ),
    );
  }
}
