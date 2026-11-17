import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

final _ytThumb = RegExp(r'^https?://i\d?\.ytimg\.com/vi(?:_webp)?/([A-Za-z0-9_-]{11})/');
final _sizedArt = RegExp(r'=w\d+-h\d+');

/// URLs de pochette à essayer, de la meilleure à la plus sûre.
///
/// YouTube renvoie souvent `hqdefault.jpg` : 480×360 en 4:3, donc l'image 16:9 encadrée de
/// bandes noires, et floue une fois agrandie dans le lecteur. On lui préfère `maxresdefault`
/// ou `hq720` (1280×720, sans bandes), puis `mqdefault` (320×180, sans bandes), qui suffit aux
/// petites vignettes. `maxresdefault` n'existe pas pour toutes les vidéos (404) : d'où la chaîne.
List<String> artworkCandidates(String url, {required bool large}) {
  final yt = _ytThumb.firstMatch(url);
  if (yt != null) {
    final base = 'https://i.ytimg.com/vi/${yt.group(1)}';
    return [
      if (large) ...['$base/maxresdefault.jpg', '$base/hq720.jpg'],
      '$base/mqdefault.jpg',
      url,
    ];
  }
  // Pochettes carrées YouTube Music (lh3.googleusercontent…=w544-h544) : plus grand si besoin.
  if (large && _sizedArt.hasMatch(url)) return [url.replaceFirst(_sizedArt, '=w1080-h1080'), url];
  return [url];
}

/// Image de pochette : essaie chaque URL de [artworkCandidates] tant que la précédente échoue.
class ArtworkImage extends StatelessWidget {
  const ArtworkImage({super.key, required this.url, required this.large, this.placeholder});
  final String url;
  final bool large;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) => _Chain(urls: artworkCandidates(url, large: large), placeholder: placeholder ?? const SizedBox.expand());
}

class _Chain extends StatelessWidget {
  const _Chain({required this.urls, required this.placeholder, this.index = 0});
  final List<String> urls;
  final Widget placeholder;
  final int index;

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
        imageUrl: urls[index],
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => index + 1 < urls.length ? _Chain(urls: urls, placeholder: placeholder, index: index + 1) : placeholder,
      );
}
