import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/library_backup.dart';
import '../../data/media_storage.dart';
import '../../l10n/l10n.dart';
import '../../theme/sika_tokens.dart';

const _askedKey = 'youplay.migrate.asked'; // guide « ancienne YouPlay » déjà montré
const _adoptKey = 'youplay.migrate.adopt'; // sons à reprendre après une restauration
const autoUpdateKey = 'youplay.update.auto'; // recherche de mise à jour au démarrage (null = pas encore demandé)

/// Après une restauration : au prochain lancement, on reprend les sons d'une autre app.
Future<void> markRestored(SharedPreferences prefs) => prefs.setBool(_adoptKey, true);

/// Étapes du passage à la nouvelle app, au démarrage. Retourne true si une étape a été montrée.
///
/// L'ancienne YouPlay (`com.example.sika_app`) est signée avec une autre clé : la bibliothèque
/// passe par un fichier (Exporter là-bas, Restaurer ici), puis les sons téléchargés sont repris.
Future<bool> runMigration(BuildContext context) async {
  if (!Platform.isAndroid) return false;
  final MigrationInfo info;
  try {
    info = await LibraryBackup.info();
  } catch (_) {
    return false;
  }
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return false;
  final l = context.l10n;

  if (prefs.getBool(_adoptKey) == true) {
    await prefs.remove(_adoptKey);
    var shown = false;
    final paths = LibraryBackup.downloadedPaths(prefs);
    if (paths.isNotEmpty) {
      // Sans « Musique et audio », les sons d'une autre app sont invisibles (ni lus, ni repris).
      await MediaStorage.ensurePermission();
      final foreign = await LibraryBackup.foreignCount(paths).catchError((_) => 0);
      if (foreign > 0 && context.mounted) {
        shown = true;
        if (await _ask(context, l.adoptTitle, l.adoptBody, l.adoptAction)) {
          await LibraryBackup.adopt(paths).catchError((_) => 0);
        }
      }
    }
    if (info.legacyInstalled && context.mounted) {
      shown = true;
      if (await _ask(context, l.migrateDoneTitle, l.migrateNewDoneBody, l.migrateUninstall)) {
        await LibraryBackup.uninstallLegacy();
      }
    }
    return shown;
  }

  if (info.legacyInstalled && prefs.getBool(_askedKey) != true) {
    await prefs.setBool(_askedKey, true); // une seule fois ; Réglages › Sauvegarde reste disponible
    if (context.mounted && await _ask(context, l.migrateNewTitle, l.migrateNewBody, l.migrateOpenLegacy)) {
      await LibraryBackup.openLegacy();
    }
    return true;
  }
  return false;
}

/// Recherche de mise à jour au démarrage : seulement si l'utilisateur l'a activée (demandé une fois).
Future<bool> autoUpdateAllowed(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final v = prefs.getBool(autoUpdateKey);
  if (v != null || !context.mounted) return v ?? false;
  final l = context.l10n;
  final yes = await _ask(context, l.updateAutoTitle, l.updateAutoBody, l.updateAutoEnable, dismiss: l.noThanks);
  await prefs.setBool(autoUpdateKey, yes);
  return yes;
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
