import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/youtube_source.dart';
import '../../l10n/l10n.dart';
import '../../state/library_store.dart';
import '../../state/providers.dart';
import '../../theme/sika_tokens.dart';
import 'common.dart';
import 'migration_flow.dart' show confirmAction;

/// Importe une playlist YouTube (lien collé) comme playlist perso. Comme toute playlist perso,
/// ses titres sont ensuite téléchargés dans `Music/YouPlay/<nom>`.
Future<void> importYoutubePlaylist(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  // Lien déjà copié (depuis l'app YouTube, par exemple) : proposé d'office.
  var initial = '';
  try {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (text != null && youtubePlaylistUrl(text) != null) initial = text.trim();
  } catch (_) {}
  if (!context.mounted) return;
  final input = await askText(context, l.importPlaylistTitle, l.importPlaylistHint, initial: initial);
  if (input == null || !context.mounted) return;
  final url = youtubePlaylistUrl(input);
  if (url == null) return showSnack(context, l.importPlaylistInvalid);

  final nav = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: SikaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SikaRadius.xl)),
        content: Row(children: [
          const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: SikaColors.yellow)),
          const SizedBox(width: 18),
          Expanded(child: Text(l.importPlaylistLoading, style: SikaText.ui(15, w: FontWeight.w600))),
        ]),
      ),
    ),
  );
  ImportedPlaylist? result;
  try {
    result = await ref.read(youtubeProvider).importPlaylist(url);
  } catch (_) {}
  nav.pop();
  if (!context.mounted) return;
  if (result == null) return showSnack(context, l.importPlaylistFailed);
  if (result.tracks.isEmpty) return showSnack(context, l.importPlaylistEmpty);

  final name = result.name.isEmpty ? l.myPlaylist : result.name;
  var body = l.importPlaylistBody(result.tracks.length);
  if (result.truncated) body += '\n\n${l.importPlaylistTruncated(YoutubeSource.importMax)}';
  if (!await confirmAction(context, name, body, l.importAction) || !context.mounted) return;
  final p = ref.read(libraryProvider.notifier).createPlaylistWith(name, result.tracks);
  openCollection(context, CollectionRef(CollectionKind.mine, p.id, title: p.name));
}
