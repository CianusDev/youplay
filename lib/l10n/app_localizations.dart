import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'YouPlay playback'**
  String get notificationChannelName;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @yourFirstName.
  ///
  /// In en, this message translates to:
  /// **'Your first name'**
  String get yourFirstName;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get offlineMode;

  /// No description provided for @offlineModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only play downloaded songs'**
  String get offlineModeSubtitle;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'YouPlay plays YouTube through NewPipeExtractor. Lyrics provided by LRCLIB. Your likes, playlists, history and downloads stay on this device.'**
  String get settingsAbout;

  /// No description provided for @installedVersion.
  ///
  /// In en, this message translates to:
  /// **'Installed version'**
  String get installedVersion;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @updatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updatesTitle;

  /// No description provided for @upToDateSuffix.
  ///
  /// In en, this message translates to:
  /// **'{version} · up to date'**
  String upToDateSuffix(String version);

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check: check your connection'**
  String get updateCheckFailed;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @backgroundPlayback.
  ///
  /// In en, this message translates to:
  /// **'Background playback'**
  String get backgroundPlayback;

  /// No description provided for @noBatteryRestriction.
  ///
  /// In en, this message translates to:
  /// **'No battery restrictions'**
  String get noBatteryRestriction;

  /// No description provided for @backgroundPlaybackHint.
  ///
  /// In en, this message translates to:
  /// **'Stops your phone from cutting the music'**
  String get backgroundPlaybackHint;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get enabled;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get languageSystem;

  /// No description provided for @updateDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'The download failed. Check your connection and try again.'**
  String get updateDownloadFailed;

  /// No description provided for @megabytes.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String megabytes(String size);

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @downloadingPercent.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String downloadingPercent(int percent);

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get navDownloads;

  /// No description provided for @kindAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get kindAlbum;

  /// No description provided for @kindPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get kindPlaylist;

  /// No description provided for @kindMix.
  ///
  /// In en, this message translates to:
  /// **'Mix'**
  String get kindMix;

  /// No description provided for @kindArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get kindArtist;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect. Check your network.'**
  String get connectionError;

  /// No description provided for @removeFromLiked.
  ///
  /// In en, this message translates to:
  /// **'Remove from liked songs'**
  String get removeFromLiked;

  /// No description provided for @addToLiked.
  ///
  /// In en, this message translates to:
  /// **'Add to liked songs'**
  String get addToLiked;

  /// No description provided for @addedToLiked.
  ///
  /// In en, this message translates to:
  /// **'Added to liked songs'**
  String get addedToLiked;

  /// No description provided for @removedFromLiked.
  ///
  /// In en, this message translates to:
  /// **'Removed from liked songs'**
  String get removedFromLiked;

  /// No description provided for @playNext.
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get playNext;

  /// No description provided for @playingNext.
  ///
  /// In en, this message translates to:
  /// **'Plays next'**
  String get playingNext;

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get addToQueue;

  /// No description provided for @addedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added to queue'**
  String get addedToQueue;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to a playlist'**
  String get addToPlaylist;

  /// No description provided for @removeFromThisPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Remove from this playlist'**
  String get removeFromThisPlaylist;

  /// No description provided for @removedFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Removed from playlist'**
  String get removedFromPlaylist;

  /// No description provided for @deleteDownload.
  ///
  /// In en, this message translates to:
  /// **'Delete download'**
  String get deleteDownload;

  /// No description provided for @cancelDownload.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get cancelDownload;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started'**
  String get downloadStarted;

  /// No description provided for @downloadDeleted.
  ///
  /// In en, this message translates to:
  /// **'Download deleted'**
  String get downloadDeleted;

  /// No description provided for @viewArtist.
  ///
  /// In en, this message translates to:
  /// **'View artist'**
  String get viewArtist;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get newPlaylist;

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistName;

  /// No description provided for @addedToPlaylistPath.
  ///
  /// In en, this message translates to:
  /// **'Added to “{name}” · {path}'**
  String addedToPlaylistPath(String name, String path);

  /// No description provided for @songCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}}'**
  String songCount(int count);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @deletePlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String deletePlaylistTitle(String name);

  /// No description provided for @deletePlaylistBodyFolder.
  ///
  /// In en, this message translates to:
  /// **'The playlist and its folder {path} will be removed. Downloaded songs are kept in Music/YouPlay.'**
  String deletePlaylistBodyFolder(String path);

  /// No description provided for @deletePlaylistBody.
  ///
  /// In en, this message translates to:
  /// **'The playlist will be removed from your library.'**
  String get deletePlaylistBody;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @playlistDeletedKeptFiles.
  ///
  /// In en, this message translates to:
  /// **'Playlist deleted · {count, plural, =1{1 personal file left} other{{count} personal files left}} in the folder'**
  String playlistDeletedKeptFiles(int count);

  /// No description provided for @playlistDeletedSongsKept.
  ///
  /// In en, this message translates to:
  /// **'Playlist deleted · songs kept in Music/YouPlay'**
  String get playlistDeletedSongsKept;

  /// No description provided for @playlistDeleted.
  ///
  /// In en, this message translates to:
  /// **'Playlist deleted'**
  String get playlistDeleted;

  /// No description provided for @renamePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Rename playlist'**
  String get renamePlaylist;

  /// No description provided for @renamedToPath.
  ///
  /// In en, this message translates to:
  /// **'Renamed “{name}” · {path}'**
  String renamedToPath(String name, String path);

  /// No description provided for @renamedTo.
  ///
  /// In en, this message translates to:
  /// **'Renamed “{name}”'**
  String renamedTo(String name);

  /// No description provided for @openPlayer.
  ///
  /// In en, this message translates to:
  /// **'Open player'**
  String get openPlayer;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @trackOptions.
  ///
  /// In en, this message translates to:
  /// **'Song options'**
  String get trackOptions;

  /// No description provided for @queued.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get queued;

  /// No description provided for @failedRetry.
  ///
  /// In en, this message translates to:
  /// **'Failed · retry'**
  String get failedRetry;

  /// No description provided for @offlineBadge.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineBadge;

  /// No description provided for @playbackPosition.
  ///
  /// In en, this message translates to:
  /// **'Playback position'**
  String get playbackPosition;

  /// No description provided for @positionOf.
  ///
  /// In en, this message translates to:
  /// **'{position} of {duration}'**
  String positionOf(String position, String duration);

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDevice;

  /// No description provided for @percent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String percent(int value);

  /// No description provided for @srcNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get srcNowPlaying;

  /// No description provided for @srcAlbum.
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM ALBUM'**
  String get srcAlbum;

  /// No description provided for @srcPlaylist.
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM PLAYLIST'**
  String get srcPlaylist;

  /// No description provided for @srcArtist.
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM ARTIST'**
  String get srcArtist;

  /// No description provided for @srcRadio.
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM RADIO'**
  String get srcRadio;

  /// No description provided for @srcTrending.
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM TRENDING'**
  String get srcTrending;

  /// No description provided for @srcMix.
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM MIX'**
  String get srcMix;

  /// No description provided for @srcSearch.
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM SEARCH'**
  String get srcSearch;

  /// No description provided for @srcOffline.
  ///
  /// In en, this message translates to:
  /// **'PLAYING OFFLINE'**
  String get srcOffline;

  /// No description provided for @nothingPlaying.
  ///
  /// In en, this message translates to:
  /// **'Nothing playing.'**
  String get nothingPlaying;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @closePlayer.
  ///
  /// In en, this message translates to:
  /// **'Close player'**
  String get closePlayer;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @shuffleOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off shuffle'**
  String get shuffleOff;

  /// No description provided for @shuffleOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on shuffle'**
  String get shuffleOn;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @repeatOff.
  ///
  /// In en, this message translates to:
  /// **'Repeat: off'**
  String get repeatOff;

  /// No description provided for @repeatAll.
  ///
  /// In en, this message translates to:
  /// **'Repeat: all'**
  String get repeatAll;

  /// No description provided for @repeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeat: this song'**
  String get repeatOne;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// No description provided for @sleepTimerOn.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer: on'**
  String get sleepTimerOn;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @sleepStopsAt.
  ///
  /// In en, this message translates to:
  /// **'Playback stops at {time}'**
  String sleepStopsAt(String time);

  /// No description provided for @sleepStopsEndOfSong.
  ///
  /// In en, this message translates to:
  /// **'Stops at the end of the current song'**
  String get sleepStopsEndOfSong;

  /// No description provided for @sleepHint.
  ///
  /// In en, this message translates to:
  /// **'Playback pauses after the chosen time.'**
  String get sleepHint;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String durationMinutes(int count);

  /// No description provided for @oneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get oneHour;

  /// No description provided for @stopsIn.
  ///
  /// In en, this message translates to:
  /// **'Stops in {duration}'**
  String stopsIn(String duration);

  /// No description provided for @endOfSong.
  ///
  /// In en, this message translates to:
  /// **'End of song'**
  String get endOfSong;

  /// No description provided for @stopsAtEndOfSong.
  ///
  /// In en, this message translates to:
  /// **'Stops at the end of the song'**
  String get stopsAtEndOfSong;

  /// No description provided for @turnOffTimer.
  ///
  /// In en, this message translates to:
  /// **'Turn off the timer'**
  String get turnOffTimer;

  /// No description provided for @timerOff.
  ///
  /// In en, this message translates to:
  /// **'Timer turned off'**
  String get timerOff;

  /// No description provided for @searchingLyrics.
  ///
  /// In en, this message translates to:
  /// **'Looking for lyrics…'**
  String get searchingLyrics;

  /// No description provided for @lyricsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No lyrics available for this song.'**
  String get lyricsUnavailable;

  /// No description provided for @lyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyrics;

  /// No description provided for @syncApproxAdjust.
  ///
  /// In en, this message translates to:
  /// **'Approx. sync · adjust'**
  String get syncApproxAdjust;

  /// No description provided for @expandLyrics.
  ///
  /// In en, this message translates to:
  /// **'Expand lyrics'**
  String get expandLyrics;

  /// No description provided for @maxLines.
  ///
  /// In en, this message translates to:
  /// **'{count} lines max'**
  String maxLines(int count);

  /// No description provided for @chooseLyrics.
  ///
  /// In en, this message translates to:
  /// **'Pick lyrics'**
  String get chooseLyrics;

  /// No description provided for @tapUpToLines.
  ///
  /// In en, this message translates to:
  /// **'Tap up to {count} lines'**
  String tapUpToLines(int count);

  /// No description provided for @linesSelected.
  ///
  /// In en, this message translates to:
  /// **'{n} / {max} {n, plural, =1{line} other{lines}}'**
  String linesSelected(int n, int max);

  /// No description provided for @tapLinesToPick.
  ///
  /// In en, this message translates to:
  /// **'Tap lines to pick them'**
  String get tapLinesToPick;

  /// No description provided for @nextWithLines.
  ///
  /// In en, this message translates to:
  /// **'Next · {n, plural, =1{1 line} other{{n} lines}}'**
  String nextWithLines(int n);

  /// No description provided for @wrongLyrics.
  ///
  /// In en, this message translates to:
  /// **'Wrong lyrics?'**
  String get wrongLyrics;

  /// No description provided for @wrongLyricsHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll drop this text for this song and look for another version.'**
  String get wrongLyricsHint;

  /// No description provided for @searchingOtherLyrics.
  ///
  /// In en, this message translates to:
  /// **'Looking for other lyrics…'**
  String get searchingOtherLyrics;

  /// No description provided for @findOtherLyrics.
  ///
  /// In en, this message translates to:
  /// **'Find other lyrics'**
  String get findOtherLyrics;

  /// No description provided for @shareLyrics.
  ///
  /// In en, this message translates to:
  /// **'Share lyrics'**
  String get shareLyrics;

  /// No description provided for @reportWrongLyrics.
  ///
  /// In en, this message translates to:
  /// **'Report wrong lyrics'**
  String get reportWrongLyrics;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @lyricsEarlier.
  ///
  /// In en, this message translates to:
  /// **'Lyrics earlier'**
  String get lyricsEarlier;

  /// No description provided for @lyricsLater.
  ///
  /// In en, this message translates to:
  /// **'Lyrics later'**
  String get lyricsLater;

  /// No description provided for @secondsValue.
  ///
  /// In en, this message translates to:
  /// **'{value} s'**
  String secondsValue(String value);

  /// No description provided for @clipOffset.
  ///
  /// In en, this message translates to:
  /// **'Clip {offset}'**
  String clipOffset(String offset);

  /// No description provided for @alignToClip.
  ///
  /// In en, this message translates to:
  /// **'Align with the video'**
  String get alignToClip;

  /// No description provided for @lyricsHintSynced.
  ///
  /// In en, this message translates to:
  /// **'Tap a line to jump to it · long-press to share'**
  String get lyricsHintSynced;

  /// No description provided for @lyricsHintPlain.
  ///
  /// In en, this message translates to:
  /// **'Long-press a line to share'**
  String get lyricsHintPlain;

  /// No description provided for @seeTheirSongs.
  ///
  /// In en, this message translates to:
  /// **'See their songs'**
  String get seeTheirSongs;

  /// No description provided for @removedFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Removed from your library'**
  String get removedFromLibrary;

  /// No description provided for @addedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Added to your library'**
  String get addedToLibrary;

  /// No description provided for @inYourLibrary.
  ///
  /// In en, this message translates to:
  /// **'In your library'**
  String get inYourLibrary;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @chipAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get chipAll;

  /// No description provided for @chipFrenchRap.
  ///
  /// In en, this message translates to:
  /// **'French rap'**
  String get chipFrenchRap;

  /// No description provided for @mixNewFrenchRap.
  ///
  /// In en, this message translates to:
  /// **'New French Rap'**
  String get mixNewFrenchRap;

  /// No description provided for @mixNewFrenchRapSub.
  ///
  /// In en, this message translates to:
  /// **'Today\'s rap releases'**
  String get mixNewFrenchRapSub;

  /// No description provided for @mixAfroHits.
  ///
  /// In en, this message translates to:
  /// **'Afro Hits'**
  String get mixAfroHits;

  /// No description provided for @mixFrenchDrill.
  ///
  /// In en, this message translates to:
  /// **'French Drill'**
  String get mixFrenchDrill;

  /// No description provided for @mixWeeklyReleases.
  ///
  /// In en, this message translates to:
  /// **'This week\'s releases'**
  String get mixWeeklyReleases;

  /// No description provided for @mixBelgianRap.
  ///
  /// In en, this message translates to:
  /// **'Belgian Rap'**
  String get mixBelgianRap;

  /// No description provided for @mixFrenchRapClassics.
  ///
  /// In en, this message translates to:
  /// **'French Rap Classics'**
  String get mixFrenchRapClassics;

  /// No description provided for @mixEssentials.
  ///
  /// In en, this message translates to:
  /// **'The essentials'**
  String get mixEssentials;

  /// No description provided for @mixIvoryCoast.
  ///
  /// In en, this message translates to:
  /// **'Ivory Coast'**
  String get mixIvoryCoast;

  /// No description provided for @mixLondon.
  ///
  /// In en, this message translates to:
  /// **'London'**
  String get mixLondon;

  /// No description provided for @mixFrenchTrap.
  ///
  /// In en, this message translates to:
  /// **'French Trap'**
  String get mixFrenchTrap;

  /// No description provided for @mixSoftAfroPop.
  ///
  /// In en, this message translates to:
  /// **'Soft Afro-pop'**
  String get mixSoftAfroPop;

  /// No description provided for @mixForWork.
  ///
  /// In en, this message translates to:
  /// **'For working'**
  String get mixForWork;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @dailyMix.
  ///
  /// In en, this message translates to:
  /// **'Daily Mix {n}'**
  String dailyMix(int n);

  /// No description provided for @artistsAndMore.
  ///
  /// In en, this message translates to:
  /// **'{a}, {b} and more'**
  String artistsAndMore(String a, String b);

  /// No description provided for @androidOnly.
  ///
  /// In en, this message translates to:
  /// **'YouPlay plays YouTube: use the Android app.'**
  String get androidOnly;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get noNotifications;

  /// No description provided for @likedSongs.
  ///
  /// In en, this message translates to:
  /// **'Liked songs'**
  String get likedSongs;

  /// No description provided for @yourDailyMixes.
  ///
  /// In en, this message translates to:
  /// **'Your daily mixes'**
  String get yourDailyMixes;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @newReleases.
  ///
  /// In en, this message translates to:
  /// **'New releases'**
  String get newReleases;

  /// No description provided for @radioUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Radio unavailable. Check your connection.'**
  String get radioUnavailable;

  /// No description provided for @newForYou.
  ///
  /// In en, this message translates to:
  /// **'NEW FOR YOU'**
  String get newForYou;

  /// No description provided for @yourRadio.
  ///
  /// In en, this message translates to:
  /// **'Your YouPlay Radio'**
  String get yourRadio;

  /// No description provided for @yourRadioSub.
  ///
  /// In en, this message translates to:
  /// **'An endless stream, tuned to your last 30 days.'**
  String get yourRadioSub;

  /// No description provided for @recentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently played'**
  String get recentlyPlayed;

  /// No description provided for @genrePodcasts.
  ///
  /// In en, this message translates to:
  /// **'Podcasts'**
  String get genrePodcasts;

  /// No description provided for @genreFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get genreFocus;

  /// No description provided for @genreTraditional.
  ///
  /// In en, this message translates to:
  /// **'Traditional'**
  String get genreTraditional;

  /// No description provided for @genreElectro.
  ///
  /// In en, this message translates to:
  /// **'Electro'**
  String get genreElectro;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Artists, songs, playlists…'**
  String get searchHint;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @voiceSearch.
  ///
  /// In en, this message translates to:
  /// **'Voice search'**
  String get voiceSearch;

  /// No description provided for @voiceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Use your keyboard\'s mic to dictate'**
  String get voiceSearchHint;

  /// No description provided for @browseAll.
  ///
  /// In en, this message translates to:
  /// **'Browse all'**
  String get browseAll;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get recentSearches;

  /// No description provided for @trendingThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Trending this week'**
  String get trendingThisWeek;

  /// No description provided for @top50France.
  ///
  /// In en, this message translates to:
  /// **'Top 50 — France'**
  String get top50France;

  /// No description provided for @updatedContinuously.
  ///
  /// In en, this message translates to:
  /// **'Always up to date'**
  String get updatedContinuously;

  /// No description provided for @searchAndroidOnly.
  ///
  /// In en, this message translates to:
  /// **'YouTube search works in the Android app.'**
  String get searchAndroidOnly;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for “{query}”.'**
  String noResultsFor(String query);

  /// No description provided for @resultsFor.
  ///
  /// In en, this message translates to:
  /// **'Results for '**
  String get resultsFor;

  /// No description provided for @didYouMean.
  ///
  /// In en, this message translates to:
  /// **'Did you mean '**
  String get didYouMean;

  /// No description provided for @topResult.
  ///
  /// In en, this message translates to:
  /// **'Top result'**
  String get topResult;

  /// No description provided for @artistFollowers.
  ///
  /// In en, this message translates to:
  /// **'Artist · {count} followers'**
  String artistFollowers(String count);

  /// No description provided for @songBy.
  ///
  /// In en, this message translates to:
  /// **'Song · {artist}'**
  String songBy(String artist);

  /// No description provided for @songs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get songs;

  /// No description provided for @artists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get artists;

  /// No description provided for @albumsAndPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Albums and playlists'**
  String get albumsAndPlaylists;

  /// No description provided for @chipPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get chipPlaylists;

  /// No description provided for @chipArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get chipArtists;

  /// No description provided for @chipAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get chipAlbums;

  /// No description provided for @chipPodcasts.
  ///
  /// In en, this message translates to:
  /// **'Podcasts'**
  String get chipPodcasts;

  /// No description provided for @kindPodcast.
  ///
  /// In en, this message translates to:
  /// **'Podcast'**
  String get kindPodcast;

  /// No description provided for @kindSong.
  ///
  /// In en, this message translates to:
  /// **'Song'**
  String get kindSong;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @searchInLibrary.
  ///
  /// In en, this message translates to:
  /// **'Search in library'**
  String get searchInLibrary;

  /// No description provided for @createPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create playlist'**
  String get createPlaylist;

  /// No description provided for @searchYourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Search your library'**
  String get searchYourLibrary;

  /// No description provided for @sortAlphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get sortAlphabetical;

  /// No description provided for @sortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get sortRecent;

  /// No description provided for @showAsList.
  ///
  /// In en, this message translates to:
  /// **'Show as list'**
  String get showAsList;

  /// No description provided for @showAsGrid.
  ///
  /// In en, this message translates to:
  /// **'Show as grid'**
  String get showAsGrid;

  /// No description provided for @emptyArtists.
  ///
  /// In en, this message translates to:
  /// **'Follow artists to find them here.'**
  String get emptyArtists;

  /// No description provided for @emptyAlbums.
  ///
  /// In en, this message translates to:
  /// **'No saved albums.'**
  String get emptyAlbums;

  /// No description provided for @emptyPodcasts.
  ///
  /// In en, this message translates to:
  /// **'No saved podcasts.'**
  String get emptyPodcasts;

  /// No description provided for @emptyDownloadsYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing downloaded yet.'**
  String get emptyDownloadsYet;

  /// No description provided for @emptyHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get emptyHere;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @removeFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Remove from library'**
  String get removeFromLibrary;

  /// No description provided for @unfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollow;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get deletePlaylist;

  /// No description provided for @yourMonthInMusic.
  ///
  /// In en, this message translates to:
  /// **'Your month in music'**
  String get yourMonthInMusic;

  /// No description provided for @statMinutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get statMinutes;

  /// No description provided for @statPlays.
  ///
  /// In en, this message translates to:
  /// **'plays'**
  String get statPlays;

  /// No description provided for @statArtists.
  ///
  /// In en, this message translates to:
  /// **'artists'**
  String get statArtists;

  /// No description provided for @statsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Listen to some music to see your stats here.'**
  String get statsEmpty;

  /// No description provided for @topArtists.
  ///
  /// In en, this message translates to:
  /// **'Most played artists'**
  String get topArtists;

  /// No description provided for @playsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 play} other{{count} plays}}'**
  String playsCount(int count);

  /// No description provided for @genres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get genres;

  /// No description provided for @monthStatsSub.
  ///
  /// In en, this message translates to:
  /// **'Artists, genres and listening minutes'**
  String get monthStatsSub;

  /// No description provided for @gigabytes.
  ///
  /// In en, this message translates to:
  /// **'{size} GB'**
  String gigabytes(String size);

  /// No description provided for @downloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsTitle;

  /// No description provided for @downloadsWebOnly.
  ///
  /// In en, this message translates to:
  /// **'Offline downloads are available in the Android app, not in the web version.'**
  String get downloadsWebOnly;

  /// No description provided for @inProgressCount.
  ///
  /// In en, this message translates to:
  /// **'In progress · {count}'**
  String inProgressCount(int count);

  /// No description provided for @resumeAll.
  ///
  /// In en, this message translates to:
  /// **'Resume all'**
  String get resumeAll;

  /// No description provided for @pauseAll.
  ///
  /// In en, this message translates to:
  /// **'Pause all'**
  String get pauseAll;

  /// No description provided for @downloadsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet. Tap ↓ on a song or a playlist.'**
  String get downloadsEmpty;

  /// No description provided for @removeFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove from device'**
  String get removeFromDevice;

  /// No description provided for @offlineOnSub.
  ///
  /// In en, this message translates to:
  /// **'On · only your downloads are played'**
  String get offlineOnSub;

  /// No description provided for @offlineOffSub.
  ///
  /// In en, this message translates to:
  /// **'Off · streaming allowed'**
  String get offlineOffSub;

  /// No description provided for @smartDownload.
  ///
  /// In en, this message translates to:
  /// **'Smart download'**
  String get smartDownload;

  /// No description provided for @smartDownloadSub.
  ///
  /// In en, this message translates to:
  /// **'Keep your liked songs available offline'**
  String get smartDownloadSub;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @storageUsed.
  ///
  /// In en, this message translates to:
  /// **'{size} used · {count, plural, =1{1 song} other{{count} songs}}'**
  String storageUsed(String size, int count);

  /// No description provided for @musicSize.
  ///
  /// In en, this message translates to:
  /// **'Music · {size}'**
  String musicSize(String size);

  /// No description provided for @podcastsSize.
  ///
  /// In en, this message translates to:
  /// **'Podcasts · {size}'**
  String podcastsSize(String size);

  /// No description provided for @top50.
  ///
  /// In en, this message translates to:
  /// **'Top 50'**
  String get top50;

  /// No description provided for @eyebrowTrending.
  ///
  /// In en, this message translates to:
  /// **'TRENDING'**
  String get eyebrowTrending;

  /// No description provided for @eyebrowMix.
  ///
  /// In en, this message translates to:
  /// **'MIX'**
  String get eyebrowMix;

  /// No description provided for @eyebrowPlaylist.
  ///
  /// In en, this message translates to:
  /// **'PLAYLIST'**
  String get eyebrowPlaylist;

  /// No description provided for @eyebrowArtist.
  ///
  /// In en, this message translates to:
  /// **'ARTIST'**
  String get eyebrowArtist;

  /// No description provided for @eyebrowAlbum.
  ///
  /// In en, this message translates to:
  /// **'ALBUM'**
  String get eyebrowAlbum;

  /// No description provided for @eyebrowOffline.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get eyebrowOffline;

  /// No description provided for @trendingDescription.
  ///
  /// In en, this message translates to:
  /// **'The songs getting the most plays right now.'**
  String get trendingDescription;

  /// No description provided for @playlistFolderOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Folder on your phone: {path}'**
  String playlistFolderOnPhone(String path);

  /// No description provided for @playlistEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add songs with “… › Add to a playlist”.'**
  String get playlistEmptyHint;

  /// No description provided for @downloadedSongs.
  ///
  /// In en, this message translates to:
  /// **'Downloaded songs'**
  String get downloadedSongs;

  /// No description provided for @searchIn.
  ///
  /// In en, this message translates to:
  /// **'Search in {name}'**
  String searchIn(String name);

  /// No description provided for @noSongsYet.
  ///
  /// In en, this message translates to:
  /// **'No songs yet.'**
  String get noSongsYet;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results.'**
  String get noResults;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @searchInPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Search in playlist'**
  String get searchInPlaylist;

  /// No description provided for @addToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add to library'**
  String get addToLibrary;

  /// No description provided for @downloadingSongs.
  ///
  /// In en, this message translates to:
  /// **'Downloading {count, plural, =1{1 song} other{{count} songs}}'**
  String downloadingSongs(int count);

  /// No description provided for @playlistOptions.
  ///
  /// In en, this message translates to:
  /// **'Playlist options'**
  String get playlistOptions;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t do that'**
  String get actionFailed;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save'**
  String get saveFailed;

  /// No description provided for @imageSaved.
  ///
  /// In en, this message translates to:
  /// **'Image saved to Pictures/YouPlay'**
  String get imageSaved;

  /// No description provided for @backToLines.
  ///
  /// In en, this message translates to:
  /// **'Back to lines'**
  String get backToLines;

  /// No description provided for @customize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get customize;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @artwork.
  ///
  /// In en, this message translates to:
  /// **'Artwork'**
  String get artwork;

  /// No description provided for @artworkColor.
  ///
  /// In en, this message translates to:
  /// **'Artwork color'**
  String get artworkColor;

  /// No description provided for @colorN.
  ///
  /// In en, this message translates to:
  /// **'Color {n}'**
  String colorN(int n);

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @sizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get sizeSmall;

  /// No description provided for @sizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get sizeMedium;

  /// No description provided for @sizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get sizeLarge;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @lyricsCopied.
  ///
  /// In en, this message translates to:
  /// **'Lyrics copied'**
  String get lyricsCopied;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @defaultUserName.
  ///
  /// In en, this message translates to:
  /// **'Listener'**
  String get defaultUserName;

  /// No description provided for @myPlaylistN.
  ///
  /// In en, this message translates to:
  /// **'My playlist #{n}'**
  String myPlaylistN(int n);

  /// No description provided for @myPlaylist.
  ///
  /// In en, this message translates to:
  /// **'My playlist'**
  String get myPlaylist;

  /// No description provided for @trackUnplayableNext.
  ///
  /// In en, this message translates to:
  /// **'“{title}” can\'t be played, skipping to the next song'**
  String trackUnplayableNext(String title);

  /// No description provided for @playbackFailedReason.
  ///
  /// In en, this message translates to:
  /// **'Playback failed: {reason}'**
  String playbackFailedReason(String reason);

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'network error'**
  String get networkError;

  /// No description provided for @playbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Playback failed'**
  String get playbackFailed;

  /// No description provided for @nothingToPlay.
  ///
  /// In en, this message translates to:
  /// **'Nothing to play'**
  String get nothingToPlay;

  /// No description provided for @audiusRemoved.
  ///
  /// In en, this message translates to:
  /// **'This song came from Audius (source removed): search for it on YouTube'**
  String get audiusRemoved;

  /// No description provided for @offlineNoneDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Offline mode: none of these songs are downloaded'**
  String get offlineNoneDownloaded;

  /// No description provided for @durationMin.
  ///
  /// In en, this message translates to:
  /// **'{m} min'**
  String durationMin(int m);

  /// No description provided for @durationHourMin.
  ///
  /// In en, this message translates to:
  /// **'{h} hr {m} min'**
  String durationHourMin(int h, String m);

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @saveMobileData.
  ///
  /// In en, this message translates to:
  /// **'Save mobile data'**
  String get saveMobileData;

  /// No description provided for @saveMobileDataSub.
  ///
  /// In en, this message translates to:
  /// **'Download on Wi-Fi only'**
  String get saveMobileDataSub;

  /// No description provided for @waitingForWifi.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Wi-Fi'**
  String get waitingForWifi;

  /// No description provided for @waitingForWifiBanner.
  ///
  /// In en, this message translates to:
  /// **'Downloads will start automatically as soon as you\'re on Wi-Fi.'**
  String get waitingForWifiBanner;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupTitle;

  /// No description provided for @backupSub.
  ///
  /// In en, this message translates to:
  /// **'Likes, playlists and downloads in a file'**
  String get backupSub;

  /// No description provided for @backupManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get backupManage;

  /// No description provided for @backupExport.
  ///
  /// In en, this message translates to:
  /// **'Export to a file'**
  String get backupExport;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from a file'**
  String get backupRestore;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupSaved;

  /// No description provided for @backupSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the backup'**
  String get backupSaveFailed;

  /// No description provided for @backupInvalid.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t a YouPlay backup'**
  String get backupInvalid;

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get restoreTitle;

  /// No description provided for @restoreBody.
  ///
  /// In en, this message translates to:
  /// **'Your current library will be replaced, then YouPlay will restart.'**
  String get restoreBody;

  /// No description provided for @restoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreAction;

  /// No description provided for @migrateSendAction.
  ///
  /// In en, this message translates to:
  /// **'Transfer to the new YouPlay'**
  String get migrateSendAction;

  /// No description provided for @migrateFetchAction.
  ///
  /// In en, this message translates to:
  /// **'Get library from the old YouPlay'**
  String get migrateFetchAction;

  /// No description provided for @migrateTitle.
  ///
  /// In en, this message translates to:
  /// **'YouPlay has moved'**
  String get migrateTitle;

  /// No description provided for @migrateLegacyBody.
  ///
  /// In en, this message translates to:
  /// **'The new YouPlay is installed. Transfer your library to it: likes, playlists, history and downloaded songs.'**
  String get migrateLegacyBody;

  /// No description provided for @migrateTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get migrateTransfer;

  /// No description provided for @migrateLegacyDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Your library is in the new YouPlay. This old version won\'t get updates anymore: you can uninstall it.'**
  String get migrateLegacyDoneBody;

  /// No description provided for @migrateUninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get migrateUninstall;

  /// No description provided for @migrateNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the new YouPlay'**
  String get migrateNewTitle;

  /// No description provided for @migrateNewBody.
  ///
  /// In en, this message translates to:
  /// **'The old YouPlay is on this phone. Bring over its library: likes, playlists, history and downloaded songs?'**
  String get migrateNewBody;

  /// No description provided for @migrateFetch.
  ///
  /// In en, this message translates to:
  /// **'Bring it over'**
  String get migrateFetch;

  /// No description provided for @adoptTitle.
  ///
  /// In en, this message translates to:
  /// **'Your downloaded songs'**
  String get adoptTitle;

  /// No description provided for @adoptBody.
  ///
  /// In en, this message translates to:
  /// **'Android still treats them as the old YouPlay\'s. To organise and delete them, the new one will copy them: Android will ask you to allow deleting the original files.'**
  String get adoptBody;

  /// No description provided for @adoptAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get adoptAction;

  /// No description provided for @migrateDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Library transferred'**
  String get migrateDoneTitle;

  /// No description provided for @migrateNewDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Everything is here. You can now uninstall the old YouPlay.'**
  String get migrateNewDoneBody;

  /// No description provided for @updateNewAppNote.
  ///
  /// In en, this message translates to:
  /// **'This version installs next to the old one (new app ID, for free-software app stores). Your library is transferred right after.'**
  String get updateNewAppNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
