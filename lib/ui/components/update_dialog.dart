import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/app_update.dart';
import '../../l10n/l10n.dart';
import '../../theme/sika_tokens.dart';

const _skippedKey = 'youplay.update.skipped';

enum UpdateCheck { upToDate, offered, failed }

/// Cherche une mise à jour et propose de l'installer.
/// Au démarrage ([manual] = false) : silencieux si rien de neuf ou version déjà refusée.
/// Depuis les réglages ([manual] = true) : propose même une version refusée ; le résultat est
/// renvoyé à l'appelant, qui l'affiche (un SnackBar serait caché sous la feuille des réglages).
Future<UpdateCheck> checkForUpdate(BuildContext context, {bool manual = false}) async {
  AppRelease? r;
  try {
    r = await AppUpdater.checkNewer();
  } catch (_) {
    return UpdateCheck.failed;
  }
  if (r == null || !context.mounted) return UpdateCheck.upToDate;
  final prefs = await SharedPreferences.getInstance();
  if (!manual && prefs.getInt(_skippedKey) == r.versionCode) return UpdateCheck.upToDate;
  if (!context.mounted) return UpdateCheck.upToDate;
  final later = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (_) => _UpdateDialog(release: r!),
  );
  // « Plus tard » : on ne redemande pas pour cette version, seulement pour la suivante.
  if (later == true) await prefs.setInt(_skippedKey, r.versionCode);
  return UpdateCheck.offered;
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.release});
  final AppRelease release;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double? _progress; // null = pas commencé
  String? _error;

  Future<void> _update() async {
    setState(() {
      _progress = 0;
      _error = null;
    });
    try {
      final apk = await AppUpdater.download(widget.release, (p) {
        if (mounted) setState(() => _progress = p);
      });
      await AppUpdater.install(apk);
      if (mounted) Navigator.of(context).pop(false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _progress = null;
          _error = context.l10n.updateDownloadFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.release;
    final busy = _progress != null;
    final l = context.l10n;
    final mb = r.apkSize > 0 ? ' · ${l.megabytes((r.apkSize / 1048576).toStringAsFixed(1))}' : '';
    return AlertDialog(
      backgroundColor: SikaColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SikaRadius.xl)),
      title: Text(l.updateAvailable, style: SikaText.display(20, w: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YouPlay ${r.versionName}$mb', style: SikaText.meta),
          if (r.newApp) ...[
            const SizedBox(height: 12),
            Text(l.updateNewAppNote, style: SikaText.ui(14, color: SikaColors.text, height: 1.45)),
          ],
          if (r.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Text(r.notes, style: SikaText.ui(14, color: SikaColors.textSoft, height: 1.45)),
              ),
            ),
          ],
          if (busy) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(SikaRadius.pill),
              child: LinearProgressIndicator(
                value: _progress == 0 ? null : _progress,
                minHeight: 6,
                color: SikaColors.yellow,
                backgroundColor: SikaColors.track,
              ),
            ),
            const SizedBox(height: 8),
            Text(l.downloadingPercent(((_progress ?? 0) * 100).round()), style: SikaText.meta),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: SikaText.ui(13, color: SikaColors.yellow)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(true),
          child: Text(l.later, style: SikaText.ui(14, w: FontWeight.w700, color: SikaColors.textMuted)),
        ),
        TextButton(
          onPressed: busy ? null : _update,
          child: Text(_error != null ? l.retry : l.update,
              style: SikaText.ui(14, w: FontWeight.w800, color: busy ? SikaColors.placeholder : SikaColors.yellow)),
        ),
      ],
    );
  }
}
