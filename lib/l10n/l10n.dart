import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// Langues de l'interface. Pour en ajouter une : un fichier `app_<code>.arb` dans ce dossier.
const supportedAppLocales = [Locale('en'), Locale('fr')];

/// Choix de langue dans les réglages : `null` = langue du téléphone.
class AppLocaleController extends Notifier<Locale?> {
  static const _key = 'youplay.locale';

  @override
  Locale? build() {
    final code = ref.read(prefsProvider).getString(_key);
    return code == null ? null : Locale(code);
  }

  void set(Locale? locale) {
    final prefs = ref.read(prefsProvider);
    if (locale == null) {
      prefs.remove(_key);
    } else {
      prefs.setString(_key, locale.languageCode);
    }
    state = locale;
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleController, Locale?>(AppLocaleController.new);

/// Langue réellement utilisée : le choix de l'utilisateur, sinon celle du téléphone si elle
/// est traduite (français), sinon l'anglais.
Locale resolveAppLocale(Locale? chosen, [Iterable<Locale>? device]) {
  if (chosen != null) return chosen;
  for (final l in device ?? PlatformDispatcher.instance.locales) {
    final match = supportedAppLocales.where((s) => s.languageCode == l.languageCode).firstOrNull;
    if (match != null) return match;
  }
  return const Locale('en');
}

extension L10nContext on BuildContext {
  /// Textes traduits : `context.l10n.likedSongs`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Textes traduits hors de l'arbre de widgets (contrôleurs, notifications, messages d'erreur).
/// Mis à jour par l'app à chaque changement de langue.
class L10n {
  static AppLocalizations _current = lookupAppLocalizations(resolveAppLocale(null));
  static AppLocalizations get current => _current;
  static void update(Locale locale) => _current = lookupAppLocalizations(locale);
}

/// Les CollectionRef enregistrent leur type en clair (« Album », « Artiste », « Mix »…) : ce sont
/// des codes internes, comparés dans le code et sauvegardés sur le téléphone. On les traduit
/// seulement à l'affichage.
String collectionKindLabel(AppLocalizations l, String code) => switch (code) {
      'Album' || 'ALBUM' => l.kindAlbum,
      'Playlist' || '' => l.kindPlaylist,
      'Mix' => l.kindMix,
      'Artiste' => l.kindArtist,
      _ => code,
    };

/// Prénom affiché : « Utilisateur » est la valeur par défaut enregistrée, traduite à l'affichage.
String displayUserName(AppLocalizations l, String name) => (name.trim().isEmpty || name == 'Utilisateur') ? l.defaultUserName : name;
