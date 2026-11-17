/// Modèles de données Sika (indépendants de la source).
library;

import '../l10n/l10n.dart';

class Artist {
  const Artist({
    required this.id,
    required this.name,
    this.handle = '',
    this.imageUrl,
    this.followers = 0,
    this.bio = '',
  });

  final String id;
  final String name;
  final String handle;
  final String? imageUrl;
  final int followers;
  final String bio;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'handle': handle,
        'imageUrl': imageUrl,
        'followers': followers,
      };

  factory Artist.fromJson(Map<String, dynamic> j) => Artist(
        id: j['id'] as String,
        name: j['name'] as String,
        handle: j['handle'] as String? ?? '',
        imageUrl: j['imageUrl'] as String?,
        followers: (j['followers'] as num?)?.toInt() ?? 0,
      );
}

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    this.artworkUrl,
    this.genre = '',
    this.mood = '',
    this.permalink = '',
    this.playCount = 0,
  });

  final String id;
  final String title;
  final Artist artist;
  final Duration duration;
  final String? artworkUrl;
  final String genre;
  final String mood;
  final String permalink;
  final int playCount;

  bool get isPodcast => genre == 'Podcasts' || genre == 'Spoken Word';

  String get shareUrl => permalink.startsWith('http')
      ? permalink
      : 'https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent('${artist.name} $title')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist.toJson(),
        'duration': duration.inSeconds,
        'artworkUrl': artworkUrl,
        'genre': genre,
        'mood': mood,
        'permalink': permalink,
      };

  factory Track.fromJson(Map<String, dynamic> j) => Track(
        id: j['id'] as String,
        title: j['title'] as String,
        artist: Artist.fromJson(j['artist'] as Map<String, dynamic>),
        duration: Duration(seconds: (j['duration'] as num).toInt()),
        artworkUrl: j['artworkUrl'] as String?,
        genre: j['genre'] as String? ?? '',
        mood: j['mood'] as String? ?? '',
        permalink: j['permalink'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.owner,
    this.artworkUrl,
    this.trackCount = 0,
    this.description = '',
    this.isAlbum = false,
  });

  final String id;
  final String name;
  final Artist owner;
  final String? artworkUrl;
  final int trackCount;
  final String description;
  final bool isAlbum;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'owner': owner.toJson(),
        'artworkUrl': artworkUrl,
        'trackCount': trackCount,
        'description': description,
        'isAlbum': isAlbum,
      };

  factory Playlist.fromJson(Map<String, dynamic> j) => Playlist(
        id: j['id'] as String,
        name: j['name'] as String,
        owner: Artist.fromJson(j['owner'] as Map<String, dynamic>),
        artworkUrl: j['artworkUrl'] as String?,
        trackCount: (j['trackCount'] as num?)?.toInt() ?? 0,
        description: j['description'] as String? ?? '',
        isAlbum: j['isAlbum'] as bool? ?? false,
      );
}

/// Type de collection affichable par l'écran Playlist.
enum CollectionKind {
  // Anciens types (source Audius retirée) : conservés pour relire les données
  // enregistrées ; ils sont ouverts comme une recherche YouTube sur leur titre.
  playlist,
  artist,
  genre,
  query,
  trending, // encore utilisé comme source de la Radio
  likes, // titres likés (local)
  mine, // playlist créée par l'utilisateur (locale)
  downloads, // tous les titres téléchargés
  ytquery, // recherche de titres YouTube Music (id = requête)
  ytalbum, // album / playlist YouTube (id = URL)
}

/// Référence légère vers une collection (sérialisable, utilisée dans les routes).
class CollectionRef {
  const CollectionRef(this.kind, this.id, {this.title = '', this.subtitle = '', this.artworkUrl});

  final CollectionKind kind;
  final String id;
  final String title;
  final String subtitle;
  final String? artworkUrl;

  String get key => '${kind.name}:$id';

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'artworkUrl': artworkUrl,
      };

  factory CollectionRef.fromJson(Map<String, dynamic> j) => CollectionRef(
        CollectionKind.values.byName(j['kind'] as String),
        j['id'] as String,
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String? ?? '',
        artworkUrl: j['artworkUrl'] as String?,
      );

  @override
  bool operator ==(Object other) => other is CollectionRef && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

String formatDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String formatTotal(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return L10n.current.durationMin(m);
  return L10n.current.durationHourMin(h, m.toString().padLeft(2, '0'));
}

String formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1).replaceAll('.0', '')} M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1).replaceAll('.0', '')} k';
  return '$n';
}
