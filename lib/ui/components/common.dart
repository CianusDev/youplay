import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../state/download_manager.dart';
import '../../state/library_store.dart';
import '../../state/player_controller.dart';
import '../../state/playlist_folders.dart';
import '../../theme/sika_tokens.dart';
import '../nav_utils.dart';
import 'cover_art.dart';
import 'sika_icon.dart';

/// Onglet courant du shell, mis à jour par le router (pour pousser les sous-pages au bon endroit).
class TabTracker {
  static String base = '/home';
}

Future<void> openCollection(BuildContext context, CollectionRef c) =>
    pushTabPage(GoRouter.of(context), '${TabTracker.base}/c/${c.kind.name}/${Uri.encodeComponent(c.id)}', extra: c);

void openArtist(BuildContext context, Artist a) => openCollection(context, artistRef(a));

/// Référence d'un album / playlist YouTube (id = URL). Les anciennes playlists Audius
/// enregistrées sont rouvertes comme une recherche YouTube sur leur nom.
CollectionRef playlistRef(Playlist p) => p.id.startsWith('http')
    ? CollectionRef(CollectionKind.ytalbum, p.id, title: p.name, artworkUrl: p.artworkUrl, subtitle: p.isAlbum ? 'Album' : 'Playlist')
    : CollectionRef(CollectionKind.ytquery, p.name, title: p.name, artworkUrl: p.artworkUrl, subtitle: 'Mix');

/// Référence de la page d'un artiste : ses titres sur YouTube.
CollectionRef artistRef(Artist a) =>
    CollectionRef(CollectionKind.ytquery, a.name, title: a.name, subtitle: 'Artiste', artworkUrl: a.imageUrl);

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, style: SikaText.ui(13, w: FontWeight.w600, color: SikaColors.onYellow)),
      backgroundColor: SikaColors.yellow,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 170),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
}

/// Lance la lecture et affiche l'éventuelle erreur.
Future<void> playTracks(BuildContext context, WidgetRef ref, List<Track> tracks, {int start = 0, CollectionRef? source, bool? shuffle}) async {
  // Titre déjà en cours : on ouvre le lecteur (et on reprend s'il était en pause) au lieu de le relancer à 0.
  final ui = ref.read(playerProvider);
  if (tracks.isNotEmpty && ui.current != null && ui.current!.id == tracks[start.clamp(0, tracks.length - 1)].id) {
    if (!ui.playing) ref.read(playerProvider.notifier).play();
    final router = GoRouter.of(context);
    if (!isPlayerOpen(router)) router.push('/player');
    return;
  }
  final err = await ref.read(playerProvider.notifier).playQueue(tracks, start: start, source: source, shuffle: shuffle);
  if (err != null && context.mounted) showSnack(context, err);
}

/// Affichage générique d'un AsyncValue avec chargement / erreur + réessayer.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.data, this.onRetry, this.loading, this.sliver = false});
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final VoidCallback? onRetry;
  final Widget? loading;
  final bool sliver;

  @override
  Widget build(BuildContext context) {
    Widget wrap(Widget w) => sliver ? SliverToBoxAdapter(child: w) : w;
    return value.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: data,
      loading: () => wrap(loading ??
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4, color: SikaColors.yellow))),
          )),
      error: (e, _) => wrap(ErrorBox(onRetry: onRetry)),
    );
  }
}

class ErrorBox extends StatelessWidget {
  const ErrorBox({super.key, this.onRetry, this.message});
  final VoidCallback? onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Text(message ?? context.l10n.connectionError, textAlign: TextAlign.center, style: SikaText.ui(14, color: SikaColors.textMuted)),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: SikaColors.text,
                side: const BorderSide(color: SikaColors.text, width: 1.5),
                shape: const StadiumBorder(),
              ),
              child: Text(context.l10n.retry, style: SikaText.ui(13, w: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Text(text, textAlign: TextAlign.center, style: SikaText.ui(14, color: SikaColors.textMuted, height: 1.5)),
      );
}

Future<T?> showSikaSheet<T>(BuildContext context, Widget Function(BuildContext) builder) => showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: SikaColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(SikaRadius.xl))),
      builder: builder,
    );

class SheetAction extends StatelessWidget {
  const SheetAction({super.key, required this.icon, required this.label, required this.onTap, this.color = SikaColors.text});
  final String icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(children: [
            SikaIcon(icon, size: 22, color: color),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: SikaText.ui(15, w: FontWeight.w600, color: color))),
          ]),
        ),
      );
}

/// Feuille d'options d'un titre.
Future<void> showTrackOptions(BuildContext context, WidgetRef ref, Track t, {String? removeFromPlaylistId}) {
  return showSikaSheet(context, (ctx) {
    // `sheetRef` ne sert qu'à l'affichage : il meurt avec la feuille. Les actions utilisent le `ref`
    // de l'écran appelant, toujours valide après la fermeture de la feuille (sinon : « Cannot use
    // ref after the widget was disposed » et « Ajouter à une playlist » ne s'ouvrait jamais).
    return Consumer(builder: (ctx, sheetRef, _) {
      final liked = sheetRef.watch(libraryProvider.select((s) => s.isLiked(t.id)));
      final dl = sheetRef.watch(downloadsProvider.select((s) => s.items[t.id]?.status));
      final l = context.l10n;
      void done(String msg) {
        Navigator.of(ctx).pop();
        showSnack(context, msg);
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Row(children: [
                CoverArt.seeded(t.id, size: 52, imageUrl: t.artworkUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.rowTitle),
                    const SizedBox(height: 2),
                    Text(t.artist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.meta),
                  ]),
                ),
              ]),
            ),
            const Divider(color: SikaColors.surface2, height: 1),
            SheetAction(
              icon: liked ? 'heart-filled' : 'heart',
              color: liked ? SikaColors.yellow : SikaColors.text,
              label: liked ? l.removeFromLiked : l.addToLiked,
              onTap: () {
                final now = ref.read(libraryProvider.notifier).toggleLike(t);
                done(now ? l.addedToLiked : l.removedFromLiked);
              },
            ),
            SheetAction(
              icon: 'queue',
              label: l.playNext,
              onTap: () {
                ref.read(playerProvider.notifier).playNext(t);
                done(l.playingNext);
              },
            ),
            SheetAction(
              icon: 'list',
              label: l.addToQueue,
              onTap: () {
                ref.read(playerProvider.notifier).addToQueue(t);
                done(l.addedToQueue);
              },
            ),
            SheetAction(
              icon: 'add-circle',
              label: l.addToPlaylist,
              onTap: () {
                Navigator.of(ctx).pop();
                showAddToPlaylist(context, ref, t);
              },
            ),
            if (removeFromPlaylistId != null)
              SheetAction(
                icon: 'close',
                label: l.removeFromThisPlaylist,
                onTap: () {
                  ref.read(libraryProvider.notifier).removeFromPlaylist(removeFromPlaylistId, t.id);
                  done(l.removedFromPlaylist);
                },
              ),
            if (DownloadManager.supported)
              SheetAction(
                icon: dl == DownloadStatus.done ? 'download-circle-filled' : 'download-circle',
                color: dl == DownloadStatus.done ? SikaColors.yellow : SikaColors.text,
                label: switch (dl) {
                  DownloadStatus.done => l.deleteDownload,
                  DownloadStatus.downloading || DownloadStatus.queued => l.cancelDownload,
                  _ => l.download,
                },
                onTap: () {
                  if (dl == null || dl == DownloadStatus.failed) {
                    ref.read(downloadsProvider.notifier).enqueue([t]);
                    done(l.downloadStarted);
                  } else {
                    ref.read(downloadsProvider.notifier).removeTrack(t.id);
                    done(l.downloadDeleted);
                  }
                },
              ),
            SheetAction(
              icon: 'info',
              label: l.viewArtist,
              onTap: () {
                Navigator.of(ctx).pop();
                openArtist(context, t.artist);
              },
            ),
            SheetAction(
              icon: 'share',
              label: l.share,
              onTap: () {
                Navigator.of(ctx).pop();
                SharePlus.instance.share(ShareParams(text: '${t.title} — ${t.artist.name}\n${t.shareUrl}'));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    });
  });
}

Future<void> showAddToPlaylist(BuildContext context, WidgetRef ref, Track t) {
  return showSikaSheet(context, (ctx) {
    final mine = ref.read(libraryProvider).myPlaylists;
    final l = context.l10n;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(l.addToPlaylist, style: SikaText.h2Small),
          ),
          SheetAction(
            icon: 'plus',
            label: l.newPlaylist,
            color: SikaColors.yellow,
            onTap: () async {
              Navigator.of(ctx).pop();
              final name = await askText(context, l.newPlaylist, l.playlistName);
              if (name == null) return;
              final p = ref.read(libraryProvider.notifier).createPlaylist(name);
              ref.read(libraryProvider.notifier).addToPlaylist(p.id, t);
              if (context.mounted) showSnack(context, l.addedToPlaylistPath(p.name, PlaylistFolders.displayPath(p.name)));
            },
          ),
          for (final p in mine)
            SheetAction(
              icon: 'list',
              label: '${p.name} · ${l.songCount(p.tracks.length)}',
              onTap: () {
                ref.read(libraryProvider.notifier).addToPlaylist(p.id, t);
                Navigator.of(ctx).pop();
                showSnack(context, l.addedToPlaylistPath(p.name, PlaylistFolders.displayPath(p.name)));
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  });
}

Future<String?> askText(BuildContext context, String title, String hint, {String initial = ''}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: SikaColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SikaRadius.xl)),
      title: Text(title, style: SikaText.display(20, w: FontWeight.w800)),
      content: TextField(
        controller: c,
        autofocus: true,
        cursorColor: SikaColors.yellow,
        style: SikaText.ui(15, w: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: SikaText.ui(15, color: SikaColors.placeholder),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: SikaColors.track)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: SikaColors.yellow, width: 2)),
        ),
        onSubmitted: (v) => Navigator.of(ctx).pop(v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(ctx.l10n.cancel, style: SikaText.ui(14, w: FontWeight.w700, color: SikaColors.textMuted))),
        TextButton(onPressed: () => Navigator.of(ctx).pop(c.text), child: Text(ctx.l10n.ok, style: SikaText.ui(14, w: FontWeight.w800, color: SikaColors.yellow))),
      ],
    ),
  );
}

/// Supprime une playlist perso. Ses sons téléchargés ne sont pas perdus : leur fichier unique
/// retourne dans Music/YouPlay (ou dans le dossier d'une autre playlist qui les contient),
/// puis le dossier de la playlist est retiré. Retourne true si la playlist a été supprimée.
Future<bool> confirmDeletePlaylist(BuildContext context, WidgetRef ref, String playlistId) async {
  final p = ref.read(libraryProvider).myPlaylists.where((x) => x.id == playlistId).firstOrNull;
  if (p == null) return false;
  final l = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: SikaColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SikaRadius.xl)),
      title: Text(l.deletePlaylistTitle(p.name), style: SikaText.display(20, w: FontWeight.w800)),
      content: Text(
        DownloadManager.supported
            ? l.deletePlaylistBodyFolder(PlaylistFolders.displayPath(p.name))
            : l.deletePlaylistBody,
        style: SikaText.ui(14, color: SikaColors.textSoft, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.cancel, style: SikaText.ui(14, w: FontWeight.w700, color: SikaColors.textMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.delete, style: SikaText.ui(14, w: FontWeight.w800, color: SikaColors.orange)),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  ref.read(libraryProvider.notifier).deletePlaylist(playlistId);
  if (DownloadManager.supported) {
    final kept = await ref.read(playlistFoldersProvider).deleteFolder(p.name);
    if (context.mounted) {
      showSnack(context, kept > 0 ? l.playlistDeletedKeptFiles(kept) : l.playlistDeletedSongsKept);
    }
  } else if (context.mounted) {
    showSnack(context, l.playlistDeleted);
  }
  return true;
}

/// Renomme une playlist perso (et déplace son dossier sur le téléphone).
Future<void> renamePlaylistDialog(BuildContext context, WidgetRef ref, String playlistId) async {
  final p = ref.read(libraryProvider).myPlaylists.where((x) => x.id == playlistId).firstOrNull;
  if (p == null) return;
  final l = context.l10n;
  final v = await askText(context, l.renamePlaylist, l.playlistName, initial: p.name);
  if (v == null || v.trim().isEmpty || v.trim() == p.name) return;
  final name = await ref.read(playlistFoldersProvider).renamePlaylist(playlistId, v);
  if (context.mounted) {
    showSnack(context, DownloadManager.supported ? l.renamedToPath(name, PlaylistFolders.displayPath(name)) : l.renamedTo(name));
  }
}
