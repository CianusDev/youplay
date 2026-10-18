import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/lyrics_api.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../theme/sika_tokens.dart';
import '../components/common.dart';
import '../components/cover_art.dart';
import '../components/rows.dart';

const _maxLines = 6;

/// Ouvre le partage de paroles (sélection de lignes → carte image → réseaux sociaux).
Future<void> showLyricsShare(BuildContext context, {required Track track, required Lyrics lyrics, int? initialLine}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: SikaColors.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(SikaRadius.xl))),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.95,
      child: _LyricsShare(track: track, lyrics: lyrics, initialLine: initialLine),
    ),
  );
}

class _LyricsShare extends ConsumerStatefulWidget {
  const _LyricsShare({required this.track, required this.lyrics, this.initialLine});
  final Track track;
  final Lyrics lyrics;
  final int? initialLine;

  @override
  ConsumerState<_LyricsShare> createState() => _LyricsShareState();
}

class _LyricsShareState extends ConsumerState<_LyricsShare> {
  final _cardKey = GlobalKey();
  late final Set<int> _selected = {if (widget.initialLine != null) widget.initialLine!};
  int _palette = 0; // 0 = couleur de la pochette
  bool _sharing = false;

  List<String> get _lines => widget.lyrics.lines.map((l) => l.text).toList();
  List<int> get _sorted => _selected.toList()..sort();

  void _toggle(int i) {
    if (_lines[i].trim().isEmpty || _lines[i] == '♪') return;
    setState(() {
      if (!_selected.remove(i)) {
        if (_selected.length >= _maxLines) {
          showSnack(context, '$_maxLines lignes maximum');
          return;
        }
        _selected.add(i);
      }
    });
  }

  /// Couleur de fond + couleur du texte lisible dessus.
  (Color bg, Color fg) _colors(Color? artwork) => _colorsFor(_palette, artwork);

  static (Color bg, Color fg) _colorsFor(int palette, Color? artwork) {
    final options = <Color>[
      artwork ?? SikaColors.orange,
      SikaColors.yellow,
      SikaColors.onYellow,
      SikaColors.orange,
      SikaColors.forest,
      SikaColors.plum,
      SikaColors.wine,
    ];
    // Pochette : on assombrit/sature un peu pour que le texte ressorte.
    var bg = options[palette.clamp(0, options.length - 1)];
    if (palette == 0) bg = Color.lerp(bg, Colors.black, 0.25)!;
    final fg = bg.computeLuminance() > 0.45 ? SikaColors.onYellow : Colors.white;
    return (bg, fg);
  }

  Future<File> _render() async {
    final boundary = _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3); // ≈ 1080 px de large
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/youplay-paroles-${DateTime.now().millisecondsSinceEpoch}.png');
    await f.writeAsBytes(bytes);
    return f;
  }

  String get _quote => '« ${_sorted.map((i) => _lines[i]).join(' / ')} »\n— ${widget.track.title}, ${widget.track.artist.name}';

  Future<void> _share() async {
    if (_selected.isEmpty || _sharing) return;
    setState(() => _sharing = true);
    try {
      final f = await _render();
      await SharePlus.instance.share(ShareParams(
        files: [XFile(f.path, mimeType: 'image/png')],
        text: '$_quote\n${widget.track.shareUrl}',
      ));
    } catch (_) {
      if (mounted) showSnack(context, 'Partage impossible');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.track;
    final artwork = t.artworkUrl == null ? null : ref.watch(artworkColorProvider(t.artworkUrl!)).value;
    final (bg, fg) = _colors(artwork);
    final chosen = _sorted.map((i) => _lines[i]).toList();

    return SafeArea(
      child: Column(
        children: [
          // En-tête
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
            child: Row(
              children: [
                Expanded(child: Text('Partager des paroles', style: SikaText.display(20, ls: -0.4))),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: SikaColors.text),
                  tooltip: 'Fermer',
                ),
              ],
            ),
          ),
          // Aperçu de la carte (c'est exactement l'image partagée)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 8),
            child: RepaintBoundary(
              key: _cardKey,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 360,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CoverArt.seeded(t.id, size: 44, radius: SikaRadius.xs, imageUrl: t.artworkUrl),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.ui(14, w: FontWeight.w800, color: fg)),
                              Text(t.artist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.ui(12, w: FontWeight.w600, color: fg.withValues(alpha: 0.75))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (chosen.isEmpty)
                      Text('Touche les lignes à partager ci-dessous.', style: SikaText.display(20, height: 1.3, color: fg.withValues(alpha: 0.5)))
                    else
                      for (final line in chosen)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(line, style: SikaText.display(chosen.length > 4 ? 20 : 23, height: 1.28, color: fg)),
                        ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Equalizer(animating: false, color: fg, height: 12),
                        const SizedBox(width: 8),
                        Text('YouPlay', style: SikaText.display(13, color: fg)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Couleurs
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              children: [
                for (var i = 0; i < 7; i++)
                  GestureDetector(
                    onTap: () => setState(() => _palette = i),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _colorsFor(i, artwork).$1,
                        border: Border.all(color: i == _palette ? SikaColors.text : SikaColors.surface3, width: i == _palette ? 2.5 : 1),
                      ),
                      child: i == 0 ? const Icon(Icons.image_outlined, size: 16, color: Colors.white70) : null,
                    ),
                  ),
              ],
            ),
          ),
          // Lignes à sélectionner
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                Text('Lignes', style: SikaText.h2Small),
                const Spacer(),
                Text('${_selected.length}/$_maxLines', style: SikaText.meta),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: _lines.length,
              itemBuilder: (_, i) {
                final on = _selected.contains(i);
                return InkWell(
                  borderRadius: BorderRadius.circular(SikaRadius.sm),
                  onTap: () => _toggle(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: on ? SikaColors.yellow : Colors.transparent,
                      borderRadius: BorderRadius.circular(SikaRadius.sm),
                    ),
                    child: Text(
                      _lines[i],
                      style: SikaText.ui(15, w: FontWeight.w700, color: on ? SikaColors.onYellow : SikaColors.textSoft),
                    ),
                  ),
                );
              },
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: _quote));
                          if (context.mounted) showSnack(context, 'Paroles copiées');
                        },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    foregroundColor: SikaColors.text,
                    side: const BorderSide(color: SikaColors.track, width: 1.5),
                    shape: const StadiumBorder(),
                  ),
                  child: Text('Copier', style: SikaText.ui(14, w: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _selected.isEmpty || _sharing ? null : _share,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: SikaColors.yellow,
                      foregroundColor: SikaColors.onYellow,
                      disabledBackgroundColor: SikaColors.surface2,
                      shape: const StadiumBorder(),
                    ),
                    child: _sharing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: SikaColors.onYellow))
                        : Text('Partager', style: SikaText.ui(15, w: FontWeight.w800, color: SikaColors.onYellow)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
