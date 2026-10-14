# Prompt à coller dans Claude Code

Place le dossier `sika-handoff/` à la racine de ton projet Flutter, puis colle ceci :

---

Implémente l'UI de l'app Flutter **Sika** en **pixel perfect** à partir du dossier `sika-handoff/`.

**Lis d'abord, dans cet ordre :**
1. `sika-handoff/README.md` (structure, navigation, syntaxe des sources)
2. `sika-handoff/design-system/sika_tokens.dart` et `components.md`
3. `sika-handoff/screens/*.md` (une spec par écran)
4. `sika-handoff/source-html/*.html` quand une mesure manque : le CSS inline fait foi
5. `sika-handoff/screenshots/*.png` s'ils existent : compare visuellement ton rendu

**Règles :**
- 1 px de maquette = 1 dp. Frame de référence 390×844 ; garder les marges latérales fixes (20, ou 24 pour le Lecteur) et laisser les largeurs s'adapter aux autres tailles d'écran.
- Utiliser **uniquement** les tokens de `sika_tokens.dart` (copie-le dans `lib/theme/`). Aucune couleur ni taille de police en dur ailleurs.
- Polices via `google_fonts` : Bricolage Grotesque (titres) et Manrope (UI). Respecter graisses, letterSpacing et line-height (`height`).
- Icônes : `assets/icons/*.svg` avec `flutter_svg` et `colorFilter`. Pas d'icônes Material à la place.
- Pochettes : composant `CoverArt` (6 variantes géométriques, `components.md` §1) utilisé comme placeholder d'image.
- Cibles tactiles ≥ 44. `Semantics` sur les boutons-icônes, les sliders et les interrupteurs.
- Pas de barre de statut dessinée : utiliser `SafeArea` / les paddings de la spec.

**Architecture :**
```
lib/
  main.dart
  theme/sika_tokens.dart
  router.dart                 (go_router, StatefulShellRoute : 4 onglets + route modale /player)
  ui/components/              (CoverArt, SikaChip, MiniPlayer, BottomNav, PlayButton, TrackRow,
                               LibraryRow, DownloadRow, SikaSwitch, WaveformSeekBar, QuickPickTile,
                               MixCard, ArtistBubble, IconButtonSika)
  ui/screens/                 (home, player, playlist, search, library, downloads)
  data/mock_data.dart         (données de démo des specs)
  state/                      (player state : titre courant, lecture, position, like, shuffle, repeat)
```

**Étapes :**
1. Thème et tokens, puis les composants un par un, chacun avec une page de démo (`/dev/components`).
2. Le shell : BottomNav, MiniPlayer persistant au-dessus de la nav, routes.
3. Les écrans dans l'ordre 01 → 06, avec les interactions décrites (chips, toggles, liste ↔ grille, seek sur la waveform, sélection de piste qui met à jour le mini-lecteur).
4. Animations : Hero de la pochette entre mini-lecteur et Lecteur, `AnimatedSwitcher` play/pause, égaliseur animé, switch 150 ms.
5. Ne branche l'audio réel (`just_audio` + `audio_service`) qu'une fois l'UI validée. Les widgets natifs (07) viennent en dernier, via `home_widget`.

Après chaque écran, lance l'app sur un simulateur 390×844 (iPhone 14/15), compare avec la spec ou le screenshot et corrige les écarts avant de passer à l'écran suivant.
