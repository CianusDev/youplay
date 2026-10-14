# Sika — Pack de handoff design → Flutter

App de streaming musical (style Spotify), thème sombre chaud, **jaune #FFD60A** en couleur primaire.
6 écrans mobiles + widgets. Maquette de référence : **390 × 844** (1 px maquette = 1 dp Flutter).

## Contenu

```
sika-handoff/
├── README.md                  ← ce fichier
├── PROMPT_CLAUDE_CODE.md      ← prompt à coller dans Claude Code pour lancer l'implémentation
├── design-system/
│   ├── sika_tokens.dart       ← couleurs, typo, rayons, espacements, ombres, ThemeData (prêt à copier dans lib/)
│   ├── tokens.json            ← mêmes tokens, format neutre
│   └── components.md          ← spec de chaque composant partagé (tailles, états, animations)
├── screens/                   ← spec écran par écran, de haut en bas, avec toutes les mesures
│   ├── 01-accueil.md
│   ├── 02-lecture.md
│   ├── 03-playlist.md
│   ├── 04-recherche.md
│   ├── 05-bibliotheque.md
│   ├── 06-telecharges.md
│   └── 07-widgets.md
├── source-html/               ← code source exact de chaque maquette (référence pixel : CSS inline)
├── assets/icons/              ← 39 icônes SVG (viewBox 24, currentColor) pour flutter_svg
└── screenshots/               ← (vide) dépose ici les PNG exportés du canvas
```

## Navigation

```
BottomNav (4 onglets) : Accueil · Recherche · Bibliothèque · Téléchargés
Accueil ──► Playlist ──► Lecteur (modal plein écran)
MiniPlayer (sur tous les onglets) ──► Lecteur
```

## Lire les fichiers `source-html/`
Ce sont des composants HTML d'un outil de design. Les styles sont **inline** et font foi pour les mesures.
Syntaxe de template à ignorer/interpréter :
- `{{valeur}}` = donnée dynamique calculée dans le `<script>` en bas (`renderVals()`).
- `<sc-for list="{{items}}" as="x">` = boucle (→ `ListView.builder`).
- `<sc-if value="{{cond}}">` = affichage conditionnel.
- `onClick="{{handler}}"` = interaction (voir le `<script>` pour l'état).
- `<a href="Player.dc.html">` = navigation vers l'écran correspondant. Correspondance : `Main` = 01-accueil · `Player` = 02-lecture · `Playlist` = 03-playlist · `Search` = 04-recherche · `Library` = 05-bibliotheque · `Downloads` = 06-telecharges.
- Les classes `.c1`…`.c6` (dans `<style>`) = les 6 pochettes géométriques (voir `components.md` §1).

Ils ne s'ouvrent pas tels quels dans un navigateur (il manque le runtime de l'outil) : ils servent de référence de code.

## Captures d'écran (recommandé)
Pour le pixel perfect, exporte chaque artboard du canvas en PNG (menu Share › Export) et dépose-les dans `screenshots/` avec les mêmes numéros (`01-accueil.png`, …). Claude Code pourra comparer visuellement.

## Stack conseillée
Flutter 3.24+ · `google_fonts` · `flutter_svg` · `just_audio` + `audio_service` (lecture en arrière-plan, contrôles système) · `flutter_riverpod` ou `bloc` · `go_router` (StatefulShellRoute pour la nav à onglets) · `home_widget` (widgets) · `palette_generator` (halo du lecteur).

## À remplacer
Artistes, titres et playlists sont fictifs. Placeholders : `[N]` (auditeurs, épisodes), `[X] Go` / `[Y] Go` (stockage), paroles `[Ligne…]`.
