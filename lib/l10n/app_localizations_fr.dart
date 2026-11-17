// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get notificationChannelName => 'Lecture YouPlay';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get firstName => 'Prénom';

  @override
  String get yourFirstName => 'Ton prénom';

  @override
  String get edit => 'Modifier';

  @override
  String get offlineMode => 'Mode hors ligne';

  @override
  String get offlineModeSubtitle => 'Ne lire que les titres téléchargés';

  @override
  String get settingsAbout =>
      'YouPlay lit YouTube via NewPipeExtractor. Paroles fournies par LRCLIB. Tes likes, playlists, historique et téléchargements restent sur cet appareil.';

  @override
  String get installedVersion => 'Version installée';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get updatesTitle => 'Mises à jour';

  @override
  String upToDateSuffix(String version) {
    return '$version · à jour';
  }

  @override
  String get updateCheckFailed =>
      'Vérification impossible : vérifie ta connexion';

  @override
  String get check => 'Vérifier';

  @override
  String get backgroundPlayback => 'Lecture en arrière-plan';

  @override
  String get noBatteryRestriction => 'Aucune restriction de batterie';

  @override
  String get backgroundPlaybackHint =>
      'Évite que le téléphone coupe la musique';

  @override
  String get enabled => 'Activé';

  @override
  String get allow => 'Autoriser';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Langue du téléphone';

  @override
  String get updateDownloadFailed =>
      'Le téléchargement a échoué. Vérifie ta connexion et réessaie.';

  @override
  String megabytes(String size) {
    return '$size Mo';
  }

  @override
  String get updateAvailable => 'Mise à jour disponible';

  @override
  String downloadingPercent(int percent) {
    return 'Téléchargement… $percent %';
  }

  @override
  String get later => 'Plus tard';

  @override
  String get retry => 'Réessayer';

  @override
  String get update => 'Mettre à jour';

  @override
  String get navHome => 'Accueil';

  @override
  String get navSearch => 'Recherche';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get navDownloads => 'Téléchargés';

  @override
  String get kindAlbum => 'Album';

  @override
  String get kindPlaylist => 'Playlist';

  @override
  String get kindMix => 'Mix';

  @override
  String get kindArtist => 'Artiste';

  @override
  String get connectionError => 'Connexion impossible. Vérifie ton réseau.';

  @override
  String get removeFromLiked => 'Retirer des titres likés';

  @override
  String get addToLiked => 'Ajouter aux titres likés';

  @override
  String get addedToLiked => 'Ajouté aux titres likés';

  @override
  String get removedFromLiked => 'Retiré des titres likés';

  @override
  String get playNext => 'Lire ensuite';

  @override
  String get playingNext => 'Lu juste après';

  @override
  String get addToQueue => 'Ajouter à la file d\'attente';

  @override
  String get addedToQueue => 'Ajouté à la file d\'attente';

  @override
  String get addToPlaylist => 'Ajouter à une playlist';

  @override
  String get removeFromThisPlaylist => 'Retirer de cette playlist';

  @override
  String get removedFromPlaylist => 'Retiré de la playlist';

  @override
  String get deleteDownload => 'Supprimer le téléchargement';

  @override
  String get cancelDownload => 'Annuler le téléchargement';

  @override
  String get download => 'Télécharger';

  @override
  String get downloadStarted => 'Téléchargement lancé';

  @override
  String get downloadDeleted => 'Téléchargement supprimé';

  @override
  String get viewArtist => 'Voir l\'artiste';

  @override
  String get share => 'Partager';

  @override
  String get newPlaylist => 'Nouvelle playlist';

  @override
  String get playlistName => 'Nom de la playlist';

  @override
  String addedToPlaylistPath(String name, String path) {
    return 'Ajouté à « $name » · $path';
  }

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '1 titre',
      zero: '0 titre',
    );
    return '$_temp0';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'OK';

  @override
  String deletePlaylistTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String deletePlaylistBodyFolder(String path) {
    return 'La playlist et son dossier $path seront retirés. Les sons téléchargés sont conservés dans Music/YouPlay.';
  }

  @override
  String get deletePlaylistBody =>
      'La playlist sera retirée de ta bibliothèque.';

  @override
  String get delete => 'Supprimer';

  @override
  String playlistDeletedKeptFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers perso laissés',
      one: '1 fichier perso laissé',
    );
    return 'Playlist supprimée · $_temp0 dans le dossier';
  }

  @override
  String get playlistDeletedSongsKept =>
      'Playlist supprimée · sons conservés dans Music/YouPlay';

  @override
  String get playlistDeleted => 'Playlist supprimée';

  @override
  String get renamePlaylist => 'Renommer la playlist';

  @override
  String renamedToPath(String name, String path) {
    return 'Renommée « $name » · $path';
  }

  @override
  String renamedTo(String name) {
    return 'Renommée « $name »';
  }

  @override
  String get openPlayer => 'Ouvrir le lecteur';

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Lecture';

  @override
  String get trackOptions => 'Options du titre';

  @override
  String get queued => 'En attente';

  @override
  String get failedRetry => 'Échec · réessayer';

  @override
  String get offlineBadge => 'Hors ligne';

  @override
  String get playbackPosition => 'Position de lecture';

  @override
  String positionOf(String position, String duration) {
    return '$position sur $duration';
  }

  @override
  String get thisDevice => 'Cet appareil';

  @override
  String percent(int value) {
    return '$value %';
  }

  @override
  String get srcNowPlaying => 'LECTURE EN COURS';

  @override
  String get srcAlbum => 'LECTURE DEPUIS L\'ALBUM';

  @override
  String get srcPlaylist => 'LECTURE DEPUIS LA PLAYLIST';

  @override
  String get srcArtist => 'LECTURE DEPUIS L\'ARTISTE';

  @override
  String get srcRadio => 'LECTURE DEPUIS LA RADIO';

  @override
  String get srcTrending => 'LECTURE DEPUIS LES TENDANCES';

  @override
  String get srcMix => 'LECTURE DEPUIS LE MIX';

  @override
  String get srcSearch => 'LECTURE DEPUIS LA RECHERCHE';

  @override
  String get srcOffline => 'LECTURE HORS LIGNE';

  @override
  String get nothingPlaying => 'Rien en lecture.';

  @override
  String get close => 'Fermer';

  @override
  String get closePlayer => 'Fermer le lecteur';

  @override
  String get options => 'Options';

  @override
  String get shuffleOff => 'Désactiver l\'aléatoire';

  @override
  String get shuffleOn => 'Activer l\'aléatoire';

  @override
  String get previous => 'Précédent';

  @override
  String get next => 'Suivant';

  @override
  String get repeatOff => 'Répéter : désactivé';

  @override
  String get repeatAll => 'Répéter : tout';

  @override
  String get repeatOne => 'Répéter : ce titre';

  @override
  String get sleepTimer => 'Minuteur de sommeil';

  @override
  String get sleepTimerOn => 'Minuteur de sommeil : activé';

  @override
  String get queue => 'File d\'attente';

  @override
  String sleepStopsAt(String time) {
    return 'Arrêt de la lecture à $time';
  }

  @override
  String get sleepStopsEndOfSong => 'Arrêt à la fin du titre en cours';

  @override
  String get sleepHint => 'La lecture se met en pause au bout du délai choisi.';

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get oneHour => '1 heure';

  @override
  String stopsIn(String duration) {
    return 'Arrêt dans $duration';
  }

  @override
  String get endOfSong => 'Fin du titre';

  @override
  String get stopsAtEndOfSong => 'Arrêt à la fin du titre';

  @override
  String get turnOffTimer => 'Désactiver le minuteur';

  @override
  String get timerOff => 'Minuteur désactivé';

  @override
  String get searchingLyrics => 'Recherche des paroles…';

  @override
  String get lyricsUnavailable => 'Paroles indisponibles pour ce titre.';

  @override
  String get lyrics => 'Paroles';

  @override
  String get syncApproxAdjust => 'Synchro approx. · régler';

  @override
  String get expandLyrics => 'Agrandir les paroles';

  @override
  String maxLines(int count) {
    return '$count lignes maximum';
  }

  @override
  String get chooseLyrics => 'Choisis des paroles';

  @override
  String tapUpToLines(int count) {
    return 'Touche jusqu\'à $count lignes';
  }

  @override
  String linesSelected(int n, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'lignes',
      one: 'ligne',
      zero: 'ligne',
    );
    return '$n / $max $_temp0';
  }

  @override
  String get tapLinesToPick => 'Touche des lignes pour les choisir';

  @override
  String nextWithLines(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n lignes',
      one: '1 ligne',
    );
    return 'Suivant · $_temp0';
  }

  @override
  String get wrongLyrics => 'Mauvaises paroles ?';

  @override
  String get wrongLyricsHint =>
      'On écarte ce texte pour ce titre et on cherche une autre version.';

  @override
  String get searchingOtherLyrics => 'Recherche d\'autres paroles…';

  @override
  String get findOtherLyrics => 'Chercher d\'autres paroles';

  @override
  String get shareLyrics => 'Partager des paroles';

  @override
  String get reportWrongLyrics => 'Signaler de mauvaises paroles';

  @override
  String get sync => 'Synchro';

  @override
  String get lyricsEarlier => 'Paroles plus tôt';

  @override
  String get lyricsLater => 'Paroles plus tard';

  @override
  String secondsValue(String value) {
    return '$value s';
  }

  @override
  String clipOffset(String offset) {
    return 'Clip $offset';
  }

  @override
  String get alignToClip => 'Aligner sur le clip';

  @override
  String get lyricsHintSynced =>
      'Touche une ligne pour y sauter · appui long pour partager';

  @override
  String get lyricsHintPlain => 'Appui long sur une ligne pour partager';

  @override
  String get seeTheirSongs => 'Voir ses titres';

  @override
  String get removedFromLibrary => 'Retiré de ta bibliothèque';

  @override
  String get addedToLibrary => 'Ajouté à ta bibliothèque';

  @override
  String get inYourLibrary => 'Dans ta biblio';

  @override
  String get add => 'Ajouter';

  @override
  String get chipAll => 'Tout';

  @override
  String get chipFrenchRap => 'Rap FR';

  @override
  String get mixNewFrenchRap => 'Nouveautés Rap FR';

  @override
  String get mixNewFrenchRapSub => 'Les sorties rap du moment';

  @override
  String get mixAfroHits => 'Hits Afro';

  @override
  String get mixFrenchDrill => 'Drill FR';

  @override
  String get mixWeeklyReleases => 'Les sorties de la semaine';

  @override
  String get mixBelgianRap => 'Rap Belge';

  @override
  String get mixFrenchRapClassics => 'Classiques Rap FR';

  @override
  String get mixEssentials => 'Les incontournables';

  @override
  String get mixIvoryCoast => 'Côte d\'Ivoire';

  @override
  String get mixLondon => 'Londres';

  @override
  String get mixFrenchTrap => 'Trap FR';

  @override
  String get mixSoftAfroPop => 'Afro-pop douce';

  @override
  String get mixForWork => 'Pour bosser';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get goodAfternoon => 'Bon après-midi';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String dailyMix(int n) {
    return 'Daily Mix $n';
  }

  @override
  String artistsAndMore(String a, String b) {
    return '$a, $b et plus';
  }

  @override
  String get androidOnly => 'YouPlay lit YouTube : utilise l\'app Android.';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'Aucune nouvelle notification';

  @override
  String get likedSongs => 'Titres likés';

  @override
  String get yourDailyMixes => 'Tes mix du jour';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get newReleases => 'Nouveautés';

  @override
  String get radioUnavailable => 'Radio indisponible. Vérifie ta connexion.';

  @override
  String get newForYou => 'NOUVEAU POUR TOI';

  @override
  String get yourRadio => 'Ta Radio YouPlay';

  @override
  String get yourRadioSub => 'Un flux infini, calé sur tes 30 derniers jours.';

  @override
  String get recentlyPlayed => 'Écoutés récemment';

  @override
  String get genrePodcasts => 'Podcasts';

  @override
  String get genreFocus => 'Concentration';

  @override
  String get genreTraditional => 'Traditionnel';

  @override
  String get genreElectro => 'Électro';

  @override
  String get searchTitle => 'Recherche';

  @override
  String get searchHint => 'Artistes, titres, playlists…';

  @override
  String get clear => 'Effacer';

  @override
  String get voiceSearch => 'Recherche vocale';

  @override
  String get voiceSearchHint => 'Utilise le micro de ton clavier pour dicter';

  @override
  String get browseAll => 'Parcourir tout';

  @override
  String get recentSearches => 'Recherches récentes';

  @override
  String get trendingThisWeek => 'Tendances de la semaine';

  @override
  String get top50France => 'Top 50 — France';

  @override
  String get updatedContinuously => 'Mis à jour en continu';

  @override
  String get searchAndroidOnly =>
      'La recherche YouTube fonctionne dans l\'app Android.';

  @override
  String noResultsFor(String query) {
    return 'Aucun résultat pour « $query ».';
  }

  @override
  String get resultsFor => 'Résultats pour ';

  @override
  String get didYouMean => 'Vouliez-vous dire ';

  @override
  String get topResult => 'Meilleur résultat';

  @override
  String artistFollowers(String count) {
    return 'Artiste · $count abonnés';
  }

  @override
  String songBy(String artist) {
    return 'Titre · $artist';
  }

  @override
  String get songs => 'Titres';

  @override
  String get artists => 'Artistes';

  @override
  String get albumsAndPlaylists => 'Albums et playlists';

  @override
  String get chipPlaylists => 'Playlists';

  @override
  String get chipArtists => 'Artistes';

  @override
  String get chipAlbums => 'Albums';

  @override
  String get chipPodcasts => 'Podcasts';

  @override
  String get kindPodcast => 'Podcast';

  @override
  String get kindSong => 'Titre';

  @override
  String get libraryTitle => 'Bibliothèque';

  @override
  String get searchInLibrary => 'Rechercher dans la bibliothèque';

  @override
  String get createPlaylist => 'Créer une playlist';

  @override
  String get searchYourLibrary => 'Rechercher dans ta bibliothèque';

  @override
  String get sortAlphabetical => 'Alphabétique';

  @override
  String get sortRecent => 'Récents';

  @override
  String get showAsList => 'Afficher en liste';

  @override
  String get showAsGrid => 'Afficher en grille';

  @override
  String get emptyArtists => 'Suis des artistes pour les retrouver ici.';

  @override
  String get emptyAlbums => 'Aucun album enregistré.';

  @override
  String get emptyPodcasts => 'Aucun podcast enregistré.';

  @override
  String get emptyDownloadsYet => 'Rien de téléchargé pour l\'instant.';

  @override
  String get emptyHere => 'Rien ici pour l\'instant.';

  @override
  String get unpin => 'Désépingler';

  @override
  String get pin => 'Épingler';

  @override
  String get removeFromLibrary => 'Retirer de la bibliothèque';

  @override
  String get unfollow => 'Ne plus suivre';

  @override
  String get rename => 'Renommer';

  @override
  String get deletePlaylist => 'Supprimer la playlist';

  @override
  String get yourMonthInMusic => 'Ton mois en musique';

  @override
  String get statMinutes => 'minutes';

  @override
  String get statPlays => 'écoutes';

  @override
  String get statArtists => 'artistes';

  @override
  String get statsEmpty => 'Écoute de la musique pour voir tes stats ici.';

  @override
  String get topArtists => 'Artistes les plus écoutés';

  @override
  String playsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count écoutes',
      one: '1 écoute',
    );
    return '$_temp0';
  }

  @override
  String get genres => 'Genres';

  @override
  String get monthStatsSub => 'Artistes, genres et minutes d\'écoute';

  @override
  String gigabytes(String size) {
    return '$size Go';
  }

  @override
  String get downloadsTitle => 'Téléchargés';

  @override
  String get downloadsWebOnly =>
      'Les téléchargements hors ligne sont disponibles dans l\'app Android, pas dans la version web.';

  @override
  String inProgressCount(int count) {
    return 'En cours · $count';
  }

  @override
  String get resumeAll => 'Tout reprendre';

  @override
  String get pauseAll => 'Tout mettre en pause';

  @override
  String get downloadsEmpty =>
      'Rien ici pour l\'instant. Appuie sur ↓ sur un titre ou une playlist.';

  @override
  String get removeFromDevice => 'Supprimer de l\'appareil';

  @override
  String get offlineOnSub => 'Activé · seuls tes téléchargements sont lus';

  @override
  String get offlineOffSub => 'Désactivé · streaming autorisé';

  @override
  String get smartDownload => 'Téléchargement intelligent';

  @override
  String get smartDownloadSub =>
      'Garde tes titres likés disponibles hors ligne';

  @override
  String get storage => 'Stockage';

  @override
  String storageUsed(String size, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '1 titre',
      zero: '0 titre',
    );
    return '$size utilisés · $_temp0';
  }

  @override
  String musicSize(String size) {
    return 'Musique · $size';
  }

  @override
  String podcastsSize(String size) {
    return 'Podcasts · $size';
  }

  @override
  String get top50 => 'Top 50';

  @override
  String get eyebrowTrending => 'TENDANCES';

  @override
  String get eyebrowMix => 'MIX';

  @override
  String get eyebrowPlaylist => 'PLAYLIST';

  @override
  String get eyebrowArtist => 'ARTISTE';

  @override
  String get eyebrowAlbum => 'ALBUM';

  @override
  String get eyebrowOffline => 'HORS LIGNE';

  @override
  String get trendingDescription =>
      'Les titres qui tournent le plus en ce moment.';

  @override
  String playlistFolderOnPhone(String path) {
    return 'Dossier sur le téléphone : $path';
  }

  @override
  String get playlistEmptyHint =>
      'Ajoute des titres avec « … › Ajouter à une playlist ».';

  @override
  String get downloadedSongs => 'Titres téléchargés';

  @override
  String searchIn(String name) {
    return 'Rechercher dans $name';
  }

  @override
  String get noSongsYet => 'Aucun titre pour l\'instant.';

  @override
  String get noResults => 'Aucun résultat.';

  @override
  String get back => 'Retour';

  @override
  String get searchInPlaylist => 'Rechercher dans la playlist';

  @override
  String get addToLibrary => 'Ajouter à la bibliothèque';

  @override
  String downloadingSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '1 titre',
    );
    return 'Téléchargement de $_temp0 lancé';
  }

  @override
  String get playlistOptions => 'Options de la playlist';

  @override
  String get actionFailed => 'Opération impossible';

  @override
  String get saveFailed => 'Enregistrement impossible';

  @override
  String get imageSaved => 'Image enregistrée dans Pictures/YouPlay';

  @override
  String get backToLines => 'Retour aux lignes';

  @override
  String get customize => 'Personnaliser';

  @override
  String get background => 'Fond';

  @override
  String get color => 'Couleur';

  @override
  String get artwork => 'Pochette';

  @override
  String get artworkColor => 'Couleur de la pochette';

  @override
  String colorN(int n) {
    return 'Couleur $n';
  }

  @override
  String get text => 'Texte';

  @override
  String get sizeSmall => 'Petit';

  @override
  String get sizeMedium => 'Moyen';

  @override
  String get sizeLarge => 'Grand';

  @override
  String get copy => 'Copier';

  @override
  String get lyricsCopied => 'Paroles copiées';

  @override
  String get save => 'Enregistrer';

  @override
  String get defaultUserName => 'Utilisateur';

  @override
  String myPlaylistN(int n) {
    return 'Ma playlist n°$n';
  }

  @override
  String get myPlaylist => 'Ma playlist';

  @override
  String trackUnplayableNext(String title) {
    return '« $title » est illisible, titre suivant';
  }

  @override
  String playbackFailedReason(String reason) {
    return 'Lecture impossible : $reason';
  }

  @override
  String get networkError => 'erreur réseau';

  @override
  String get playbackFailed => 'Lecture impossible';

  @override
  String get nothingToPlay => 'Aucun titre à lire';

  @override
  String get audiusRemoved =>
      'Ce titre venait d\'Audius (source retirée) : cherche-le sur YouTube';

  @override
  String get offlineNoneDownloaded =>
      'Mode hors ligne : aucun de ces titres n\'est téléchargé';

  @override
  String durationMin(int m) {
    return '$m min';
  }

  @override
  String durationHourMin(int h, String m) {
    return '$h h $m';
  }

  @override
  String get untitled => 'Sans titre';

  @override
  String get saveMobileData => 'Économiser les données mobiles';

  @override
  String get saveMobileDataSub => 'Télécharger uniquement en Wi-Fi';

  @override
  String get waitingForWifi => 'En attente du Wi-Fi';

  @override
  String get waitingForWifiBanner =>
      'Les téléchargements démarreront tout seuls dès que tu seras en Wi-Fi.';

  @override
  String get backupTitle => 'Sauvegarde';

  @override
  String get backupSub => 'Likes, playlists et téléchargements dans un fichier';

  @override
  String get backupManage => 'Gérer';

  @override
  String get backupExport => 'Exporter vers un fichier';

  @override
  String get backupRestore => 'Restaurer depuis un fichier';

  @override
  String get backupSaved => 'Sauvegarde enregistrée';

  @override
  String get backupSaveFailed => 'Impossible d\'enregistrer la sauvegarde';

  @override
  String get backupInvalid => 'Ce fichier n\'est pas une sauvegarde YouPlay';

  @override
  String get restoreTitle => 'Restaurer cette sauvegarde ?';

  @override
  String get restoreBody =>
      'Ta bibliothèque actuelle sera remplacée, puis YouPlay redémarrera.';

  @override
  String get restoreAction => 'Restaurer';

  @override
  String get migrateSendAction => 'Transférer vers la nouvelle YouPlay';

  @override
  String get migrateFetchAction => 'Récupérer depuis l\'ancienne YouPlay';

  @override
  String get migrateTitle => 'YouPlay a déménagé';

  @override
  String get migrateLegacyBody =>
      'La nouvelle YouPlay est installée. Transfère-lui ta bibliothèque : likes, playlists, historique et sons téléchargés.';

  @override
  String get migrateTransfer => 'Transférer';

  @override
  String get migrateLegacyDoneBody =>
      'Ta bibliothèque est dans la nouvelle YouPlay. Cette ancienne version ne recevra plus de mises à jour : tu peux la désinstaller.';

  @override
  String get migrateUninstall => 'Désinstaller';

  @override
  String get migrateNewTitle => 'Bienvenue dans la nouvelle YouPlay';

  @override
  String get migrateNewBody =>
      'L\'ancienne YouPlay est sur ce téléphone. Récupérer sa bibliothèque : likes, playlists, historique et sons téléchargés ?';

  @override
  String get migrateFetch => 'Récupérer';

  @override
  String get adoptTitle => 'Tes sons téléchargés';

  @override
  String get adoptBody =>
      'Android les considère encore comme ceux de l\'ancienne YouPlay. Pour pouvoir les ranger et les supprimer, la nouvelle va les recopier : Android te demandera d\'autoriser la suppression des fichiers originaux.';

  @override
  String get adoptAction => 'Continuer';

  @override
  String get migrateDoneTitle => 'Bibliothèque transférée';

  @override
  String get migrateNewDoneBody =>
      'Tout est là. Tu peux maintenant désinstaller l\'ancienne YouPlay.';

  @override
  String get updateNewAppNote =>
      'Cette version s\'installe à côté de l\'ancienne (nouvel identifiant, pour les catalogues d\'apps libres). Ta bibliothèque sera transférée juste après.';
}
