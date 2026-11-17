import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/library_backup.dart';
import '../../data/media_storage.dart';
import '../../l10n/l10n.dart';
import '../../theme/sika_tokens.dart';

// Étapes du déménagement, mémorisées dans chaque app.
const _sentKey = 'youplay.migrate.sent'; // ancienne app : bibliothèque envoyée
const _askedKey = 'youplay.migrate.asked'; // nouvelle app : proposition déjà faite
const _importedKey = 'youplay.migrate.imported'; // nouvelle app : bibliothèque reçue
const _adoptKey = 'youplay.migrate.adopt'; // nouvelle app : sons à reprendre au prochain lancement

bool _busy = false;

/// Déménagement `com.example.sika_app` → `io.github.cianusdev.youplay`.
///
/// Au démarrage ([resumed] = false), propose chaque étape ; au retour dans l'app
/// ([resumed] = true), traite seulement ce que l'autre app vient d'envoyer ou de demander.
/// Retourne true quand le déménagement est en cours (pas de recherche de mise à jour alors).
Future<bool> runMigration(BuildContext context, {bool resumed = false}) async {
  if (!Platform.isAndroid || _busy) return false;
  _busy = true;
  try {
    final MigrationInfo info;
    try {
      info = await LibraryBackup.info();
    } catch (_) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return false;
    if (info.isLegacy) return await _legacy(context, info, prefs, resumed);
    if (info.isNew) return await _newApp(context, info, prefs, resumed);
    return false;
  } finally {
    _busy = false;
  }
}

/// Ancienne app : envoie la bibliothèque, puis invite à se désinstaller.
Future<bool> _legacy(BuildContext context, MigrationInfo info, SharedPreferences prefs, bool resumed) async {
  if (!info.otherReady) return false;
  final l = context.l10n;
  // La nouvelle app vient de la demander : l'utilisateur a déjà accepté là-bas.
  if (await LibraryBackup.takeRequest()) {
    if (await LibraryBackup.send(prefs)) await prefs.setBool(_sentKey, true);
    return true;
  }
  if (resumed || !context.mounted) return true;
  if (prefs.getBool(_sentKey) != true) {
    if (await _ask(context, l.migrateTitle, l.migrateLegacyBody, l.migrateTransfer) && await LibraryBackup.send(prefs)) {
      await prefs.setBool(_sentKey, true);
    }
  } else if (await _ask(context, l.migrateTitle, l.migrateLegacyDoneBody, l.migrateUninstall)) {
    await LibraryBackup.uninstallLegacy();
  }
  return true;
}

/// Nouvelle app : reçoit la bibliothèque, reprend les sons téléchargés, invite à désinstaller l'ancienne.
Future<bool> _newApp(BuildContext context, MigrationInfo info, SharedPreferences prefs, bool resumed) async {
  final data = LibraryBackup.parse(await LibraryBackup.takeImport());
  if (data != null) {
    await LibraryBackup.restore(prefs, data, checkFiles: false);
    await prefs.setBool(_importedKey, true);
    await prefs.setBool(_adoptKey, true);
    await LibraryBackup.restart(); // recharge tout avec la bibliothèque reçue
    return true;
  }
  if (resumed || !context.mounted) return false;
  final l = context.l10n;

  if (prefs.getBool(_adoptKey) == true) {
    await prefs.remove(_adoptKey);
    final paths = LibraryBackup.downloadedPaths(prefs);
    // Android 11+ : les fichiers appartiennent encore à l'ancienne app (lecture seule pour nous).
    if (info.sdk >= 30 && paths.isNotEmpty && context.mounted && await _ask(context, l.adoptTitle, l.adoptBody, l.adoptAction)) {
      await MediaStorage.ensurePermission();
      try {
        await LibraryBackup.adopt(paths);
      } catch (_) {}
    }
    if (info.otherReady && context.mounted && await _ask(context, l.migrateDoneTitle, l.migrateNewDoneBody, l.migrateUninstall)) {
      await LibraryBackup.uninstallLegacy();
    }
    return true;
  }

  if (info.otherReady && prefs.getBool(_importedKey) != true && prefs.getBool(_askedKey) != true) {
    await prefs.setBool(_askedKey, true); // une seule fois ; ensuite via Réglages › Sauvegarde
    if (context.mounted && await _ask(context, l.migrateNewTitle, l.migrateNewBody, l.migrateFetch)) {
      await LibraryBackup.requestFromOther();
    }
    return true;
  }
  return false;
}

Future<bool> _ask(BuildContext context, String title, String body, String action, {String? dismiss}) async {
  final l = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: SikaColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SikaRadius.xl)),
      title: Text(title, style: SikaText.display(20, w: FontWeight.w800)),
      content: Text(body, style: SikaText.ui(14, color: SikaColors.textSoft, height: 1.45)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(dismiss ?? l.later, style: SikaText.ui(14, w: FontWeight.w700, color: SikaColors.textMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(action, style: SikaText.ui(14, w: FontWeight.w800, color: SikaColors.yellow)),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Confirmation simple (restauration d'une sauvegarde).
Future<bool> confirmAction(BuildContext context, String title, String body, String action) =>
    _ask(context, title, body, action, dismiss: context.l10n.cancel);
