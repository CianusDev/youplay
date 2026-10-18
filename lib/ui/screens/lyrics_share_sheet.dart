import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/lyrics_api.dart';
import '../../data/media_storage.dart';
import '../../data/models.dart';
import '../../state/download_manager.dart';
import '../../state/providers.dart';
import '../../theme/sika_tokens.dart';
import '../components/common.dart';
import '../components/cover_art.dart';
import '../components/youplay_logo.dart';

const _maxLines = 6;

bool _selectable(String line) => line.trim().isNotEmpty && line.trim() != '♪';

/// Partage de paroles, en deux étapes (comme Spotify) :
/// 1. choisir les lignes (cette feuille) ; 2. personnaliser la carte et partager (écran suivant).
Future<void> showLyricsShare(BuildContext context, {required Track track, required Lyrics lyrics, int? initialLine}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: SikaColors.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(SikaRadius.xl))),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.92,
      child: _LinePicker(track: track, lyrics: lyrics, initialLine: initialLine),
    ),
  );
}

// ============================================================================
// Étape 1 : choix des lignes
// ============================================================================

class _LinePicker extends StatefulWidget {
  const _LinePicker({required this.track, required this.lyrics, this.initialLine});
  final Track track;
  final Lyrics lyrics;
  final int? initialLine;

  @override
  State<_LinePicker> createState() => _LinePickerState();
}

class _LinePickerState extends State<_LinePicker> {
  late final List<String> _lines = widget.lyrics.lines.map((l) => l.text).toList();
  late final Set<int> _selected = {
    if (widget.initialLine != null && _selectable(_lines[widget.initialLine!])) widget.initialLine!,
  };
  late final _keys = List.generate(_lines.length, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    final start = widget.initialLine;
    if (start != null) {
      // Amène la ligne choisie par appui long au milieu de la liste.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[start].currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.4, duration: const Duration(milliseconds: 300));
      });
    }
  }

  void _toggle(int i) {
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

  void _next() {
    final chosen = (_selected.toList()..sort()).map((i) => _lines[i]).toList();
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => LyricsCardEditor(track: widget.track, lines: chosen),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final n = _selected.length;
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: SikaColors.track, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choisis des paroles', style: SikaText.display(20, ls: -0.4)),
                      Text('Jusqu\'à $_maxLines lignes · ${widget.track.title}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.meta),
                    ],
                  ),
                ),
                if (n > 0)
                  TextButton(
                    onPressed: () => setState(_selected.clear),
                    child: Text('Effacer', style: SikaText.ui(13, w: FontWeight.w700, color: SikaColors.textMuted)),
                  ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: SikaColors.text),
                  tooltip: 'Fermer',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              itemCount: _lines.length,
              itemBuilder: (_, i) {
                if (!_selectable(_lines[i])) return SizedBox(key: _keys[i], height: 10);
                final on = _selected.contains(i);
                return InkWell(
                  key: _keys[i],
                  borderRadius: BorderRadius.circular(SikaRadius.sm),
                  onTap: () => _toggle(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: on ? SikaColors.surface2 : Colors.transparent,
                      borderRadius: BorderRadius.circular(SikaRadius.sm),
                      border: Border(left: BorderSide(color: on ? SikaColors.yellow : Colors.transparent, width: 3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_lines[i],
                              style: SikaText.display(17, w: FontWeight.w700, height: 1.3, color: on ? SikaColors.text : SikaColors.textMuted)),
                        ),
                        const SizedBox(width: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: on
                              ? const Icon(Icons.check_circle_rounded, key: ValueKey(1), size: 22, color: SikaColors.yellow)
                              : const Icon(Icons.radio_button_unchecked_rounded, key: ValueKey(0), size: 22, color: SikaColors.track),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: n == 0 ? null : _next,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  backgroundColor: SikaColors.yellow,
                  foregroundColor: SikaColors.onYellow,
                  disabledBackgroundColor: SikaColors.surface2,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  n == 0 ? 'Touche des lignes pour les choisir' : 'Suivant · $n ligne${n > 1 ? 's' : ''}',
                  style: SikaText.ui(15, w: FontWeight.w800, color: n == 0 ? SikaColors.textMuted : SikaColors.onYellow),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Étape 2 : personnalisation de la carte + partage
// ============================================================================

enum _Bg { color, artwork }

enum _Size { s, m, l }

class LyricsCardEditor extends ConsumerStatefulWidget {
  const LyricsCardEditor({super.key, required this.track, required this.lines});
  final Track track;
  final List<String> lines;

  @override
  ConsumerState<LyricsCardEditor> createState() => _LyricsCardEditorState();
}

class _LyricsCardEditorState extends ConsumerState<LyricsCardEditor> {
  final _cardKey = GlobalKey();
  _Bg _bg = _Bg.color;
  int _palette = 0; // 0 = couleur de la pochette
  _Size _size = _Size.m;
  bool _busy = false;

  static const _swatches = [
    null, // couleur de la pochette
    SikaColors.yellow,
    SikaColors.yellowSoft,
    SikaColors.onYellow,
    SikaColors.orange,
    SikaColors.forest,
    SikaColors.plum,
    SikaColors.wine,
  ];

  Color _swatch(int i, Color? artwork) {
    final c = _swatches[i];
    if (c != null) return c;
    return Color.lerp(artwork ?? SikaColors.orange, Colors.black, 0.25)!;
  }

  double get _fontSize {
    final chars = widget.lines.fold<int>(0, (n, l) => n + l.length);
    final base = chars > 200 ? 17.0 : chars > 130 ? 19.0 : chars > 70 ? 22.0 : 26.0;
    return base * switch (_size) { _Size.s => 0.85, _Size.m => 1.0, _Size.l => 1.15 };
  }

  String get _quote => '« ${widget.lines.join(' / ')} »\n— ${widget.track.title}, ${widget.track.artist.name}';

  Future<List<int>> _png() async {
    final boundary = _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3); // ≈ 1080 px de large
    return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) showSnack(context, 'Opération impossible');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() => _run(() async {
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}/youplay-paroles-${DateTime.now().millisecondsSinceEpoch}.png');
        await f.writeAsBytes(await _png());
        await SharePlus.instance.share(ShareParams(
          files: [XFile(f.path, mimeType: 'image/png')],
          text: '$_quote\n${widget.track.shareUrl}',
        ));
      });

  Future<void> _save() => _run(() async {
        final path = await MediaStorage.savePicture(await _png(), 'YouPlay-${DateTime.now().millisecondsSinceEpoch}.png');
        if (mounted) showSnack(context, path == null ? 'Enregistrement impossible' : 'Image enregistrée dans Pictures/YouPlay');
      });

  @override
  Widget build(BuildContext context) {
    final t = widget.track;
    final artwork = t.artworkUrl == null ? null : ref.watch(artworkColorProvider(t.artworkUrl!)).value;
    final bg = _swatch(_palette, artwork);
    final useArtwork = _bg == _Bg.artwork && t.artworkUrl != null;
    // Texte lisible : blanc sur pochette assombrie, sinon selon la luminance du fond.
    final fg = useArtwork || bg.computeLuminance() <= 0.45 ? Colors.white : SikaColors.onYellow;

    return Scaffold(
      backgroundColor: SikaColors.bg,
      appBar: AppBar(
        backgroundColor: SikaColors.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SikaColors.text),
          tooltip: 'Retour aux lignes',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Personnaliser', style: SikaText.display(20, ls: -0.4)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: SikaColors.text),
            tooltip: 'Fermer',
            // Ferme l'éditeur ET la feuille de choix des lignes.
            onPressed: () => Navigator.of(context)
              ..pop()
              ..pop(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Carte (aperçu = image partagée, rendue à pleine taille puis réduite pour l'écran)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 360,
                          color: useArtwork ? Colors.black : bg,
                          child: Stack(
                            children: [
                              if (useArtwork)
                                Positioned.fill(
                                  child: ImageFiltered(
                                    imageFilter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                                    child: CachedNetworkImage(imageUrl: t.artworkUrl!, fit: BoxFit.cover),
                                  ),
                                ),
                              if (useArtwork) Positioned.fill(child: ColoredBox(color: Colors.black.withValues(alpha: 0.35))),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CoverArt.seeded(t.id, size: 48, radius: SikaRadius.xs, imageUrl: t.artworkUrl),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.ui(15, w: FontWeight.w800, color: fg)),
                                              Text(t.artist.name,
                                                  maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.ui(12, w: FontWeight.w600, color: fg.withValues(alpha: 0.75))),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    for (final line in widget.lines)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text(line, style: SikaText.display(_fontSize, height: 1.28, color: fg)),
                                      ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        YouPlayLogo(size: 18, disc: fg, play: useArtwork ? Colors.black : bg),
                                        const SizedBox(width: 8),
                                        Text('YouPlay', style: SikaText.display(13, color: fg)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Fond : couleur unie / pochette floutée
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Fond', style: SikaText.ui(13, w: FontWeight.w700, color: SikaColors.textSoft)),
                  const Spacer(),
                  SegmentedButton<_Bg>(
                    showSelectedIcon: false,
                    style: _segStyle,
                    segments: [
                      const ButtonSegment(value: _Bg.color, label: Text('Couleur')),
                      ButtonSegment(value: _Bg.artwork, label: const Text('Pochette'), enabled: t.artworkUrl != null),
                    ],
                    selected: {_bg},
                    onSelectionChanged: (v) => setState(() => _bg = v.first),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Couleurs (mode couleur)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _bg == _Bg.color ? 1 : 0.35,
              child: IgnorePointer(
                ignoring: _bg != _Bg.color,
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _swatches.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => Semantics(
                      button: true,
                      selected: i == _palette,
                      label: i == 0 ? 'Couleur de la pochette' : 'Couleur ${i + 1}',
                      child: GestureDetector(
                        onTap: () => setState(() => _palette = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _swatch(i, artwork),
                            border: Border.all(color: i == _palette ? SikaColors.text : SikaColors.surface3, width: i == _palette ? 3 : 1),
                          ),
                          child: i == 0 ? const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white70) : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Taille du texte
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Texte', style: SikaText.ui(13, w: FontWeight.w700, color: SikaColors.textSoft)),
                  const Spacer(),
                  SegmentedButton<_Size>(
                    showSelectedIcon: false,
                    style: _segStyle,
                    segments: const [
                      ButtonSegment(value: _Size.s, label: Text('Petit')),
                      ButtonSegment(value: _Size.m, label: Text('Moyen')),
                      ButtonSegment(value: _Size.l, label: Text('Grand')),
                    ],
                    selected: {_size},
                    onSelectionChanged: (v) => setState(() => _size = v.first),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  _RoundAction(
                    icon: Icons.copy_rounded,
                    label: 'Copier',
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: _quote));
                      if (context.mounted) showSnack(context, 'Paroles copiées');
                    },
                  ),
                  if (DownloadManager.supported) ...[
                    const SizedBox(width: 10),
                    _RoundAction(icon: Icons.download_rounded, label: 'Enregistrer', onTap: _busy ? null : _save),
                  ],
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _share,
                      icon: _busy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: SikaColors.onYellow))
                          : const Icon(Icons.ios_share_rounded, size: 20),
                      label: Text('Partager', style: SikaText.ui(15, w: FontWeight.w800, color: SikaColors.onYellow)),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        backgroundColor: SikaColors.yellow,
                        foregroundColor: SikaColors.onYellow,
                        disabledBackgroundColor: SikaColors.yellow.withValues(alpha: 0.6),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final _segStyle = ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? SikaColors.yellow : SikaColors.surface),
    foregroundColor: WidgetStateProperty.resolveWith((s) {
      if (s.contains(WidgetState.disabled)) return SikaColors.placeholder;
      return s.contains(WidgetState.selected) ? SikaColors.onYellow : SikaColors.text;
    }),
    side: const WidgetStatePropertyAll(BorderSide(color: SikaColors.surface3)),
    textStyle: WidgetStatePropertyAll(SikaText.ui(13, w: FontWeight.w700)),
    visualDensity: VisualDensity.compact,
  );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: Semantics(
          button: true,
          label: label,
          child: Material(
            color: SikaColors.surface,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(width: 52, height: 52, child: Icon(icon, color: SikaColors.text, size: 22)),
            ),
          ),
        ),
      );
}
