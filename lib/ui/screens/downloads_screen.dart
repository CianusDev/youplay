import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../state/download_manager.dart';
import '../../state/library_store.dart';
import '../../theme/sika_tokens.dart';
import '../components/common.dart';
import '../components/rows.dart';
import '../components/sika_chip.dart';
import '../components/sika_icon.dart';
import '../components/sika_switch.dart';
import 'settings_sheet.dart';

List<String> _chips(AppLocalizations l) => [l.chipAll, l.chipPlaylists, l.chipAlbums, l.chipPodcasts];

String _size(int bytes) {
  final l = L10n.current;
  if (bytes >= 1 << 30) return l.gigabytes((bytes / (1 << 30)).toStringAsFixed(1));
  return l.megabytes((bytes / (1 << 20)).toStringAsFixed(bytes < 10 << 20 ? 1 : 0));
}

DownloadRowStatus _rowStatus(DownloadStatus s) => switch (s) {
      DownloadStatus.done => DownloadRowStatus.done,
      DownloadStatus.downloading => DownloadRowStatus.downloading,
      DownloadStatus.queued => DownloadRowStatus.queued,
      DownloadStatus.failed => DownloadRowStatus.failed,
    };

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});
  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  int _chip = 0;

  @override
  Widget build(BuildContext context) {
    final dl = ref.watch(downloadsProvider);
    final mgr = ref.read(downloadsProvider.notifier);
    final inCollections = dl.collections.expand((c) => c.trackIds).toSet();
    // Titres téléchargés seuls (hors collection)
    final singles = dl.items.values.where((i) => !inCollections.contains(i.track.id)).toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

    final rows = <Widget>[];
    final activeCount = dl.active.length;

    bool keepCollection(DownloadedCollection c) => switch (_chip) {
          1 => c.ref.subtitle != 'Album' && c.ref.subtitle != 'Podcast',
          2 => c.ref.subtitle == 'Album',
          3 => c.ref.subtitle == 'Podcast',
          _ => true,
        };
    bool keepSingle(DownloadItem i) => switch (_chip) {
          0 => true,
          3 => i.track.isPodcast,
          _ => false,
        };

    for (final c in dl.collections.where(keepCollection)) {
      final st = dl.collectionStatus(c);
      rows.add(DownloadRow(
        title: c.ref.title,
        meta: '${collectionKindLabel(context.l10n, c.ref.subtitle)} · ${context.l10n.songCount(c.trackIds.length)}',
        seed: c.ref.key,
        imageUrl: c.ref.artworkUrl,
        variant: c.ref.kind == CollectionKind.likes ? 1 : null,
        status: _rowStatus(st.status),
        waitingForWifi: dl.waitingForWifi,
        progress: st.progress,
        podcast: c.ref.subtitle == 'Podcast',
        onTap: () {
          if (st.status == DownloadStatus.failed) return mgr.retryFailed();
          if (!dl.offlineMode) {
            openCollection(context, c.ref);
            return;
          }
          // Hors ligne : lecture directe des fichiers locaux de la collection.
          final local = [for (final id in c.trackIds) if (dl.isDownloaded(id)) dl.items[id]!.track];
          playTracks(context, ref, local, source: c.ref);
        },
        onLongPress: () => _confirmDelete(context, c.ref.title, () => mgr.removeCollection(c.ref.key)),
      ));
    }
    final playable = dl.done.map((i) => i.track).toList();
    for (final i in singles.where(keepSingle)) {
      rows.add(DownloadRow(
        title: i.track.title,
        meta: '${i.track.isPodcast ? context.l10n.kindPodcast : context.l10n.kindSong} · ${i.track.artist.name}',
        seed: i.track.id,
        imageUrl: i.track.artworkUrl,
        status: _rowStatus(i.status),
        waitingForWifi: dl.waitingForWifi,
        progress: i.progress,
        podcast: i.track.isPodcast,
        onTap: () {
          if (i.status == DownloadStatus.failed) return mgr.retryFailed();
          if (i.status != DownloadStatus.done) return;
          playTracks(
            context,
            ref,
            playable,
            start: playable.indexOf(i.track),
            source: CollectionRef(CollectionKind.downloads, 'me', title: context.l10n.downloadsTitle),
          );
        },
        onLongPress: () => _confirmDelete(context, i.track.title, () => mgr.removeTrack(i.track.id)),
      ));
    }

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 14, bottom: 190),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
            child: Row(
              children: [
                Expanded(child: Text(context.l10n.downloadsTitle, style: SikaText.h1Page)),
                IconButtonSika(
                  icon: 'sliders',
                  label: context.l10n.settingsTitle,
                  onTap: () => showSettingsSheet(context),
                ),
              ],
            ),
          ),
          if (!DownloadManager.supported)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: EmptyState(context.l10n.downloadsWebOnly),
            )
          else ...[
            _SettingsCard(dl: dl),
            _Storage(dl: dl),
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: ChipRow(labels: _chips(context.l10n), selected: _chip, onSelect: (i) => setState(() => _chip = i)),
            ),
            if (activeCount > 0 || dl.paused)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Row(
                  children: [
                    Expanded(child: Text(context.l10n.inProgressCount(activeCount), style: SikaText.display(16))),
                    TextButton(
                      onPressed: mgr.togglePause,
                      child: Text(
                        dl.paused ? context.l10n.resumeAll : context.l10n.pauseAll,
                        style: SikaText.ui(12, w: FontWeight.w700, color: SikaColors.textMuted),
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 10),
            // « Économiser les données mobiles » sans Wi-Fi : on explique pourquoi rien n'avance.
            if (dl.waitingForWifi)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Row(children: [
                  const SikaIcon('wifi-off', size: 18, color: SikaColors.yellow),
                  const SizedBox(width: 10),
                  Expanded(child: Text(context.l10n.waitingForWifiBanner, style: SikaText.meta)),
                ]),
              ),
            if (rows.isEmpty) EmptyState(context.l10n.downloadsEmpty) else ...rows,
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String title, VoidCallback onDelete) {
    showSikaSheet(context, (ctx) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.h2Small),
            ),
            SheetAction(
              icon: 'close',
              label: context.l10n.removeFromDevice,
              color: SikaColors.orange,
              onTap: () {
                onDelete();
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: 8),
          ]),
        ));
  }
}

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard({required this.dl});
  final DownloadsState dl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mgr = ref.read(downloadsProvider.notifier);
    final on = dl.offlineMode;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: SikaColors.surface, borderRadius: BorderRadius.circular(SikaRadius.xl)),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: on ? SikaColors.yellow : SikaColors.surface2, borderRadius: BorderRadius.circular(SikaRadius.md)),
                alignment: Alignment.center,
                child: SikaIcon('wifi-off', size: 22, color: on ? SikaColors.onYellow : SikaColors.yellow),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.offlineMode, style: SikaText.ui(15, w: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      on ? context.l10n.offlineOnSub : context.l10n.offlineOffSub,
                      style: SikaText.meta,
                    ),
                  ],
                ),
              ),
              SikaSwitch(value: on, label: context.l10n.offlineMode, onChanged: mgr.setOffline),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: SikaColors.surface2)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.smartDownload, style: SikaText.ui(14, w: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(context.l10n.smartDownloadSub, style: SikaText.meta),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SikaSwitch(
                value: dl.smartDownload,
                label: context.l10n.smartDownload,
                onChanged: (v) => mgr.setSmart(v, liked: ref.read(libraryProvider).likedTracks),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Storage extends StatelessWidget {
  const _Storage({required this.dl});
  final DownloadsState dl;

  @override
  Widget build(BuildContext context) {
    final total = dl.totalBytes;
    final pod = dl.podcastBytes;
    final music = total - pod;
    final count = dl.done.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
      child: Column(
        children: [
          Row(
            children: [
              Text(context.l10n.storage, style: SikaText.ui(12, w: FontWeight.w700)),
              const Spacer(),
              Text(context.l10n.storageUsed(_size(total), count), style: SikaText.meta),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: total == 0
                  ? Container(color: SikaColors.surface2)
                  : Row(
                      children: [
                        if (music > 0) Expanded(flex: music, child: Container(color: SikaColors.yellow)),
                        if (music > 0 && pod > 0) const SizedBox(width: 2),
                        if (pod > 0) Expanded(flex: pod, child: Container(color: SikaColors.orange)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Legend(color: SikaColors.yellow, label: context.l10n.musicSize(_size(music))),
              const SizedBox(width: 14),
              _Legend(color: SikaColors.orange, label: context.l10n.podcastsSize(_size(pod))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: SikaText.ui(11, w: FontWeight.w600, color: SikaColors.textMuted)),
      ]);
}

