// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get notificationChannelName => 'YouPlay playback';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get firstName => 'First name';

  @override
  String get yourFirstName => 'Your first name';

  @override
  String get edit => 'Edit';

  @override
  String get offlineMode => 'Offline mode';

  @override
  String get offlineModeSubtitle => 'Only play downloaded songs';

  @override
  String get settingsAbout =>
      'YouPlay plays YouTube through NewPipeExtractor. Lyrics provided by LRCLIB. Your likes, playlists, history and downloads stay on this device.';

  @override
  String get installedVersion => 'Installed version';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get updatesTitle => 'Updates';

  @override
  String upToDateSuffix(String version) {
    return '$version · up to date';
  }

  @override
  String get updateCheckFailed => 'Couldn\'t check: check your connection';

  @override
  String get check => 'Check';

  @override
  String get backgroundPlayback => 'Background playback';

  @override
  String get noBatteryRestriction => 'No battery restrictions';

  @override
  String get backgroundPlaybackHint =>
      'Stops your phone from cutting the music';

  @override
  String get enabled => 'On';

  @override
  String get allow => 'Allow';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Phone language';

  @override
  String get updateDownloadFailed =>
      'The download failed. Check your connection and try again.';

  @override
  String megabytes(String size) {
    return '$size MB';
  }

  @override
  String get updateAvailable => 'Update available';

  @override
  String downloadingPercent(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get later => 'Later';

  @override
  String get retry => 'Retry';

  @override
  String get update => 'Update';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navLibrary => 'Library';

  @override
  String get navDownloads => 'Downloads';

  @override
  String get kindAlbum => 'Album';

  @override
  String get kindPlaylist => 'Playlist';

  @override
  String get kindMix => 'Mix';

  @override
  String get kindArtist => 'Artist';

  @override
  String get connectionError => 'Couldn\'t connect. Check your network.';

  @override
  String get removeFromLiked => 'Remove from liked songs';

  @override
  String get addToLiked => 'Add to liked songs';

  @override
  String get addedToLiked => 'Added to liked songs';

  @override
  String get removedFromLiked => 'Removed from liked songs';

  @override
  String get playNext => 'Play next';

  @override
  String get playingNext => 'Plays next';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String get addedToQueue => 'Added to queue';

  @override
  String get addToPlaylist => 'Add to a playlist';

  @override
  String get removeFromThisPlaylist => 'Remove from this playlist';

  @override
  String get removedFromPlaylist => 'Removed from playlist';

  @override
  String get deleteDownload => 'Delete download';

  @override
  String get cancelDownload => 'Cancel download';

  @override
  String get download => 'Download';

  @override
  String get downloadStarted => 'Download started';

  @override
  String get downloadDeleted => 'Download deleted';

  @override
  String get viewArtist => 'View artist';

  @override
  String get share => 'Share';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String get playlistName => 'Playlist name';

  @override
  String addedToPlaylistPath(String name, String path) {
    return 'Added to “$name” · $path';
  }

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String deletePlaylistTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String deletePlaylistBodyFolder(String path) {
    return 'The playlist and its folder $path will be removed. Downloaded songs are kept in Music/YouPlay.';
  }

  @override
  String get deletePlaylistBody =>
      'The playlist will be removed from your library.';

  @override
  String get delete => 'Delete';

  @override
  String playlistDeletedKeptFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personal files left',
      one: '1 personal file left',
    );
    return 'Playlist deleted · $_temp0 in the folder';
  }

  @override
  String get playlistDeletedSongsKept =>
      'Playlist deleted · songs kept in Music/YouPlay';

  @override
  String get playlistDeleted => 'Playlist deleted';

  @override
  String get renamePlaylist => 'Rename playlist';

  @override
  String renamedToPath(String name, String path) {
    return 'Renamed “$name” · $path';
  }

  @override
  String renamedTo(String name) {
    return 'Renamed “$name”';
  }

  @override
  String get openPlayer => 'Open player';

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Play';

  @override
  String get trackOptions => 'Song options';

  @override
  String get queued => 'Waiting';

  @override
  String get failedRetry => 'Failed · retry';

  @override
  String get offlineBadge => 'Offline';

  @override
  String get playbackPosition => 'Playback position';

  @override
  String positionOf(String position, String duration) {
    return '$position of $duration';
  }

  @override
  String get thisDevice => 'This device';

  @override
  String percent(int value) {
    return '$value%';
  }

  @override
  String get srcNowPlaying => 'NOW PLAYING';

  @override
  String get srcAlbum => 'PLAYING FROM ALBUM';

  @override
  String get srcPlaylist => 'PLAYING FROM PLAYLIST';

  @override
  String get srcArtist => 'PLAYING FROM ARTIST';

  @override
  String get srcRadio => 'PLAYING FROM RADIO';

  @override
  String get srcTrending => 'PLAYING FROM TRENDING';

  @override
  String get srcMix => 'PLAYING FROM MIX';

  @override
  String get srcSearch => 'PLAYING FROM SEARCH';

  @override
  String get srcOffline => 'PLAYING OFFLINE';

  @override
  String get nothingPlaying => 'Nothing playing.';

  @override
  String get close => 'Close';

  @override
  String get closePlayer => 'Close player';

  @override
  String get options => 'Options';

  @override
  String get shuffleOff => 'Turn off shuffle';

  @override
  String get shuffleOn => 'Turn on shuffle';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get repeatOff => 'Repeat: off';

  @override
  String get repeatAll => 'Repeat: all';

  @override
  String get repeatOne => 'Repeat: this song';

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String get sleepTimerOn => 'Sleep timer: on';

  @override
  String get queue => 'Queue';

  @override
  String sleepStopsAt(String time) {
    return 'Playback stops at $time';
  }

  @override
  String get sleepStopsEndOfSong => 'Stops at the end of the current song';

  @override
  String get sleepHint => 'Playback pauses after the chosen time.';

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
  String get oneHour => '1 hour';

  @override
  String stopsIn(String duration) {
    return 'Stops in $duration';
  }

  @override
  String get endOfSong => 'End of song';

  @override
  String get stopsAtEndOfSong => 'Stops at the end of the song';

  @override
  String get turnOffTimer => 'Turn off the timer';

  @override
  String get timerOff => 'Timer turned off';

  @override
  String get searchingLyrics => 'Looking for lyrics…';

  @override
  String get lyricsUnavailable => 'No lyrics available for this song.';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get syncApproxAdjust => 'Approx. sync · adjust';

  @override
  String get expandLyrics => 'Expand lyrics';

  @override
  String maxLines(int count) {
    return '$count lines max';
  }

  @override
  String get chooseLyrics => 'Pick lyrics';

  @override
  String tapUpToLines(int count) {
    return 'Tap up to $count lines';
  }

  @override
  String linesSelected(int n, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'lines',
      one: 'line',
    );
    return '$n / $max $_temp0';
  }

  @override
  String get tapLinesToPick => 'Tap lines to pick them';

  @override
  String nextWithLines(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n lines',
      one: '1 line',
    );
    return 'Next · $_temp0';
  }

  @override
  String get wrongLyrics => 'Wrong lyrics?';

  @override
  String get wrongLyricsHint =>
      'We\'ll drop this text for this song and look for another version.';

  @override
  String get searchingOtherLyrics => 'Looking for other lyrics…';

  @override
  String get findOtherLyrics => 'Find other lyrics';

  @override
  String get shareLyrics => 'Share lyrics';

  @override
  String get reportWrongLyrics => 'Report wrong lyrics';

  @override
  String get sync => 'Sync';

  @override
  String get lyricsEarlier => 'Lyrics earlier';

  @override
  String get lyricsLater => 'Lyrics later';

  @override
  String secondsValue(String value) {
    return '$value s';
  }

  @override
  String clipOffset(String offset) {
    return 'Clip $offset';
  }

  @override
  String get alignToClip => 'Align with the video';

  @override
  String get lyricsHintSynced =>
      'Tap a line to jump to it · long-press to share';

  @override
  String get lyricsHintPlain => 'Long-press a line to share';

  @override
  String get seeTheirSongs => 'See their songs';

  @override
  String get removedFromLibrary => 'Removed from your library';

  @override
  String get addedToLibrary => 'Added to your library';

  @override
  String get inYourLibrary => 'In your library';

  @override
  String get add => 'Add';

  @override
  String get chipAll => 'All';

  @override
  String get chipFrenchRap => 'French rap';

  @override
  String get mixNewFrenchRap => 'New French Rap';

  @override
  String get mixNewFrenchRapSub => 'Today\'s rap releases';

  @override
  String get mixAfroHits => 'Afro Hits';

  @override
  String get mixFrenchDrill => 'French Drill';

  @override
  String get mixWeeklyReleases => 'This week\'s releases';

  @override
  String get mixBelgianRap => 'Belgian Rap';

  @override
  String get mixFrenchRapClassics => 'French Rap Classics';

  @override
  String get mixEssentials => 'The essentials';

  @override
  String get mixIvoryCoast => 'Ivory Coast';

  @override
  String get mixLondon => 'London';

  @override
  String get mixFrenchTrap => 'French Trap';

  @override
  String get mixSoftAfroPop => 'Soft Afro-pop';

  @override
  String get mixForWork => 'For working';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String dailyMix(int n) {
    return 'Daily Mix $n';
  }

  @override
  String artistsAndMore(String a, String b) {
    return '$a, $b and more';
  }

  @override
  String get androidOnly => 'YouPlay plays YouTube: use the Android app.';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No new notifications';

  @override
  String get likedSongs => 'Liked songs';

  @override
  String get yourDailyMixes => 'Your daily mixes';

  @override
  String get seeAll => 'See all';

  @override
  String get newReleases => 'New releases';

  @override
  String get radioUnavailable => 'Radio unavailable. Check your connection.';

  @override
  String get newForYou => 'NEW FOR YOU';

  @override
  String get yourRadio => 'Your YouPlay Radio';

  @override
  String get yourRadioSub => 'An endless stream, tuned to your last 30 days.';

  @override
  String get recentlyPlayed => 'Recently played';

  @override
  String get genrePodcasts => 'Podcasts';

  @override
  String get genreFocus => 'Focus';

  @override
  String get genreTraditional => 'Traditional';

  @override
  String get genreElectro => 'Electro';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Artists, songs, playlists…';

  @override
  String get clear => 'Clear';

  @override
  String get voiceSearch => 'Voice search';

  @override
  String get voiceSearchHint => 'Use your keyboard\'s mic to dictate';

  @override
  String get browseAll => 'Browse all';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get trendingThisWeek => 'Trending this week';

  @override
  String get top50France => 'Top 50 — France';

  @override
  String get updatedContinuously => 'Always up to date';

  @override
  String get searchAndroidOnly => 'YouTube search works in the Android app.';

  @override
  String noResultsFor(String query) {
    return 'No results for “$query”.';
  }

  @override
  String get resultsFor => 'Results for ';

  @override
  String get didYouMean => 'Did you mean ';

  @override
  String get topResult => 'Top result';

  @override
  String artistFollowers(String count) {
    return 'Artist · $count followers';
  }

  @override
  String songBy(String artist) {
    return 'Song · $artist';
  }

  @override
  String get songs => 'Songs';

  @override
  String get artists => 'Artists';

  @override
  String get albumsAndPlaylists => 'Albums and playlists';

  @override
  String get chipPlaylists => 'Playlists';

  @override
  String get chipArtists => 'Artists';

  @override
  String get chipAlbums => 'Albums';

  @override
  String get chipPodcasts => 'Podcasts';

  @override
  String get kindPodcast => 'Podcast';

  @override
  String get kindSong => 'Song';

  @override
  String get libraryTitle => 'Library';

  @override
  String get searchInLibrary => 'Search in library';

  @override
  String get createPlaylist => 'Create playlist';

  @override
  String get searchYourLibrary => 'Search your library';

  @override
  String get sortAlphabetical => 'Alphabetical';

  @override
  String get sortRecent => 'Recent';

  @override
  String get showAsList => 'Show as list';

  @override
  String get showAsGrid => 'Show as grid';

  @override
  String get emptyArtists => 'Follow artists to find them here.';

  @override
  String get emptyAlbums => 'No saved albums.';

  @override
  String get emptyPodcasts => 'No saved podcasts.';

  @override
  String get emptyDownloadsYet => 'Nothing downloaded yet.';

  @override
  String get emptyHere => 'Nothing here yet.';

  @override
  String get unpin => 'Unpin';

  @override
  String get pin => 'Pin';

  @override
  String get removeFromLibrary => 'Remove from library';

  @override
  String get unfollow => 'Unfollow';

  @override
  String get rename => 'Rename';

  @override
  String get deletePlaylist => 'Delete playlist';

  @override
  String get yourMonthInMusic => 'Your month in music';

  @override
  String get statMinutes => 'minutes';

  @override
  String get statPlays => 'plays';

  @override
  String get statArtists => 'artists';

  @override
  String get statsEmpty => 'Listen to some music to see your stats here.';

  @override
  String get topArtists => 'Most played artists';

  @override
  String playsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays',
      one: '1 play',
    );
    return '$_temp0';
  }

  @override
  String get genres => 'Genres';

  @override
  String get monthStatsSub => 'Artists, genres and listening minutes';

  @override
  String gigabytes(String size) {
    return '$size GB';
  }

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get downloadsWebOnly =>
      'Offline downloads are available in the Android app, not in the web version.';

  @override
  String inProgressCount(int count) {
    return 'In progress · $count';
  }

  @override
  String get resumeAll => 'Resume all';

  @override
  String get pauseAll => 'Pause all';

  @override
  String get downloadsEmpty =>
      'Nothing here yet. Tap ↓ on a song or a playlist.';

  @override
  String get removeFromDevice => 'Remove from device';

  @override
  String get offlineOnSub => 'On · only your downloads are played';

  @override
  String get offlineOffSub => 'Off · streaming allowed';

  @override
  String get smartDownload => 'Smart download';

  @override
  String get smartDownloadSub => 'Keep your liked songs available offline';

  @override
  String get storage => 'Storage';

  @override
  String storageUsed(String size, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$size used · $_temp0';
  }

  @override
  String musicSize(String size) {
    return 'Music · $size';
  }

  @override
  String podcastsSize(String size) {
    return 'Podcasts · $size';
  }

  @override
  String get top50 => 'Top 50';

  @override
  String get eyebrowTrending => 'TRENDING';

  @override
  String get eyebrowMix => 'MIX';

  @override
  String get eyebrowPlaylist => 'PLAYLIST';

  @override
  String get eyebrowArtist => 'ARTIST';

  @override
  String get eyebrowAlbum => 'ALBUM';

  @override
  String get eyebrowOffline => 'OFFLINE';

  @override
  String get trendingDescription =>
      'The songs getting the most plays right now.';

  @override
  String playlistFolderOnPhone(String path) {
    return 'Folder on your phone: $path';
  }

  @override
  String get playlistEmptyHint => 'Add songs with “… › Add to a playlist”.';

  @override
  String get downloadedSongs => 'Downloaded songs';

  @override
  String searchIn(String name) {
    return 'Search in $name';
  }

  @override
  String get noSongsYet => 'No songs yet.';

  @override
  String get noResults => 'No results.';

  @override
  String get back => 'Back';

  @override
  String get searchInPlaylist => 'Search in playlist';

  @override
  String get addToLibrary => 'Add to library';

  @override
  String downloadingSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return 'Downloading $_temp0';
  }

  @override
  String get playlistOptions => 'Playlist options';

  @override
  String get actionFailed => 'Couldn\'t do that';

  @override
  String get saveFailed => 'Couldn\'t save';

  @override
  String get imageSaved => 'Image saved to Pictures/YouPlay';

  @override
  String get backToLines => 'Back to lines';

  @override
  String get customize => 'Customize';

  @override
  String get background => 'Background';

  @override
  String get color => 'Color';

  @override
  String get artwork => 'Artwork';

  @override
  String get artworkColor => 'Artwork color';

  @override
  String colorN(int n) {
    return 'Color $n';
  }

  @override
  String get text => 'Text';

  @override
  String get sizeSmall => 'Small';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeLarge => 'Large';

  @override
  String get copy => 'Copy';

  @override
  String get lyricsCopied => 'Lyrics copied';

  @override
  String get save => 'Save';

  @override
  String get defaultUserName => 'Listener';

  @override
  String myPlaylistN(int n) {
    return 'My playlist #$n';
  }

  @override
  String get myPlaylist => 'My playlist';

  @override
  String trackUnplayableNext(String title) {
    return '“$title” can\'t be played, skipping to the next song';
  }

  @override
  String playbackFailedReason(String reason) {
    return 'Playback failed: $reason';
  }

  @override
  String get networkError => 'network error';

  @override
  String get playbackFailed => 'Playback failed';

  @override
  String get nothingToPlay => 'Nothing to play';

  @override
  String get audiusRemoved =>
      'This song came from Audius (source removed): search for it on YouTube';

  @override
  String get offlineNoneDownloaded =>
      'Offline mode: none of these songs are downloaded';

  @override
  String durationMin(int m) {
    return '$m min';
  }

  @override
  String durationHourMin(int h, String m) {
    return '$h hr $m min';
  }

  @override
  String get untitled => 'Untitled';

  @override
  String get saveMobileData => 'Save mobile data';

  @override
  String get saveMobileDataSub => 'Download on Wi-Fi only';

  @override
  String get waitingForWifi => 'Waiting for Wi-Fi';

  @override
  String get waitingForWifiBanner =>
      'Downloads will start automatically as soon as you\'re on Wi-Fi.';

  @override
  String get backupTitle => 'Backup';

  @override
  String get backupSub => 'Likes, playlists and downloads in a file';

  @override
  String get backupManage => 'Manage';

  @override
  String get backupExport => 'Export to a file';

  @override
  String get backupRestore => 'Restore from a file';

  @override
  String get backupSaved => 'Backup saved';

  @override
  String get backupSaveFailed => 'Couldn\'t save the backup';

  @override
  String get backupInvalid => 'This file isn\'t a YouPlay backup';

  @override
  String get restoreTitle => 'Restore this backup?';

  @override
  String get restoreBody =>
      'Your current library will be replaced, then YouPlay will restart.';

  @override
  String get restoreAction => 'Restore';

  @override
  String get migrateUninstall => 'Uninstall';

  @override
  String get migrateNewTitle => 'Welcome to the new YouPlay';

  @override
  String get migrateNewBody =>
      'The old YouPlay is still on this phone. To bring over your library: open it, go to Settings › Backup › Export to a file, then come back here: Settings › Backup › Restore.';

  @override
  String get adoptTitle => 'Your downloaded songs';

  @override
  String get adoptBody =>
      'They were downloaded by another YouPlay install, so Android keeps them read-only. To organise and delete them, YouPlay will copy them, and Android will ask you to allow deleting the original files.';

  @override
  String get adoptAction => 'Continue';

  @override
  String get migrateDoneTitle => 'Library transferred';

  @override
  String get migrateNewDoneBody =>
      'Everything is here. You can now uninstall the old YouPlay.';

  @override
  String get updateNewAppNote =>
      'This version installs next to the old one (new app ID, for free-software app stores). Your library is transferred right after.';

  @override
  String get migrateOpenLegacy => 'Open old app';

  @override
  String get migrateOpenLegacyAction => 'Open the old YouPlay to export';

  @override
  String get updateAutoTitle => 'Updates';

  @override
  String get updateAutoBody =>
      'YouPlay can check GitHub for a new version at startup and offer it to you. You can change your mind in settings.';

  @override
  String get updateAutoEnable => 'Turn on';

  @override
  String get noThanks => 'No thanks';

  @override
  String get updateAuto => 'Check automatically';

  @override
  String get updateAutoSub => 'At startup, on GitHub';
}
