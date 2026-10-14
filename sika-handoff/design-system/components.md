# Sika — Composants partagés

Toutes les mesures sont en px logiques. Couleurs : voir `sika_tokens.dart` (`SikaColors.*`).
Créer un widget Flutter réutilisable par composant (dossier suggéré `lib/ui/components/`).

---

## 1. `CoverArt` — pochette géométrique (placeholder d'image)

Carré (ou cercle pour les artistes) `ClipRRect` + `Stack`. Paramètres : `variant (c1..c6)`, `size`, `radius`.
Les formes sont en **pourcentage de la taille** → utiliser `LayoutBuilder` ou un `CustomPainter`.

| Variante | Fond | Forme (position relative au carré) |
|---|---|---|
| `c1` | yellow `#FFD60A` | Disque `#141208`, Ø 62 %, left 19 %, top 19 % (centré) |
| `c2` | orange `#FF7A1A` | Disque yellow, Ø 90 %, left −25 %, bottom −45 % (déborde en bas-gauche) |
| `c3` | forest `#1F3B2D` | Rayures diagonales 135° : bande yellow 8 %, vide 12 % (période 20 % de la diagonale), sur toute la surface |
| `c4` | cream `#F1E6C8` | Carré `#141208`, côté 46 %, right 12 %, top 12 % |
| `c5` | plum `#3A2A55` | Anneau yellow, Ø 56 %, centré (left/top 22 %), épaisseur 6 px (grand ≥ 148), 5 px (60), 4 px (≤ 56) |
| `c6` | `#141208` (+ contour 1 px `#2A271E` en liste) | Triangle yellow pointe en haut ; base ≈ 43 % de la largeur, hauteur ≈ 35 %, left ≈ 18–22 %, bottom ≈ 14–16 % |

Le moment venu, remplacer par `Image.network` avec ce composant comme `placeholder`/`errorBuilder`.

Tailles utilisées : 44 (mini-lecteur, r8) · 46 (ligne playlist, r8) · 56 (accès rapide, r0 côté gauche / ligne téléchargés r10) · 60 (biblio r10) · 92 (artiste, cercle) · 148 (mix r14, playlist header r18) · 342 (lecteur r22).

---

## 2. `SikaChip` — filtre
- Hauteur 36, padding horizontal 16, radius 18, texte Manrope 13 / w600.
- **Actif** : fond yellow, texte `#141208`. **Inactif** : fond `surface2 #24221C`, texte `text`.
- Rangée horizontale scrollable, gap 8, padding latéral 20, sans scrollbar.
- Sélection unique (state local). `Semantics(selected:)`.

## 3. `IconButtonSika`
- 44×44 (48×48 dans le lecteur), radius plein, fond transparent, hover/press `rgba(255,255,255,0.06)`.
- Icône 22–24, couleur `text`. État "actif" (shuffle, repeat, like, save) → couleur yellow ; like actif = cœur **rempli** yellow.

## 4. `PlayButton`
| Contexte | Taille | Fond | Icône |
|---|---|---|---|
| Mini-lecteur | 44 | yellow | pause/play 18, `#141208` |
| Carte Radio (accueil) | 56 | `#141208` | play 22 yellow |
| Header playlist | 60 | yellow | play 24 |
| Lecteur | 76 | yellow + ombre `playButton` | 30 |
Bascule play ↔ pause avec `AnimatedSwitcher` (150 ms, scale + fade).

## 5. `MiniPlayer`
- Position : `left 8, right 8, bottom 92` (au-dessus de la nav). Fond `surface3 #2A271E`, radius 14, ombre `miniPlayer`.
- Ligne : padding 8, gap 10 → pochette 44 r8 · bloc texte (titre Manrope 13 w700 ellipsis ; sous-titre 12 `textSoft`, avec icône appareil 12 yellow + "Artiste · Enceinte salon") · bouton like 44 · PlayButton 44.
- Barre de progression collée en bas : hauteur 3, marge horizontale 10, piste `rgba(255,255,255,0.12)`, remplissage yellow.
- Tap sur la zone pochette+texte → ouvre le Lecteur (transition slide-up plein écran, Hero sur la pochette).

## 6. `BottomNav` — 4 onglets
- Hauteur 88 (dont 22 de safe area bas), padding `8 12 22`, fond `navBg` (0.96), bordure haute 1 px `navBorder`. Optionnel : `BackdropFilter` blur 20.
- `justify: space-around`. Item : colonne icône 24 + label Manrope 11 w600, gap 4, min-width 64, padding vertical 6.
- Inactif `textMuted #A39E8F` ; actif **yellow** (icône pleine ou trait plus épais).
- Onglets : **Accueil** (home) · **Recherche** (search) · **Bibliothèque** (library) · **Téléchargés** (download-circle).
- Le Lecteur n'a pas de nav (plein écran modal).

## 7. `QuickPickTile` (grille accueil)
- Grille 2 colonnes, gap 8. Tuile hauteur 56, fond `surface`, radius 10, `clip`.
- Pochette 56×56 collée à gauche (pas de radius propre), gap 10, titre Manrope 13 w700, line-height 1.2, max 2 lignes.

## 8. `MixCard` (carrousel horizontal)
- Largeur 148, pochette 148×148 r14, titre 14 w700 (mt 10), sous-titre 12 `textMuted` lh 1.35 (mt 2). Gap entre cartes 14.

## 9. `ArtistBubble`
- Largeur 92, pochette cercle 92, nom 12 w600 centré (mt 8). Gap 16.

## 10. `TrackRow` (playlist)
- Padding `8 20`, gap 12. Colonne index largeur 22 (numéro 13 w600 `textMuted` OU égaliseur animé si en cours) · pochette 46 r8 · titre 15 w700 (yellow si en cours) + méta 12 (badge **E** : fond `textMuted`, texte `bg`, 9 px w800, padding `1 4`, r3) · durée 12 w600 `textMuted`.
- Égaliseur : 4 barres 3 px de large, gap 2, hauteurs de base 8/14/5/11 sur 14 de haut, yellow, animer en boucle (hauteurs aléatoires, 300–500 ms).

## 11. `LibraryRow`
- Padding `8 20`, gap 14, pochette 60 (r10 ; cercle pour artistes), titre 15 w700, méta 12 `textMuted` mt 4, précédée d'icônes 12 yellow : épingle (épinglé) et/ou rond téléchargé.
- Mode grille : 3 colonnes, gap 14, pochette carrée 100 % (aspect 1), titre 12 w700, type 11.

## 12. `DownloadRow`
- Comme LibraryRow (pochette 56 ; r14 pour podcasts).
- Statut à droite : **Téléchargé** = rond 24 yellow + flèche bas `#141208` ; **En cours** = pourcentage 12 w800 yellow + barre 3 px sous la méta (piste `surface2`) ; **En attente** = texte 11 w700 `textMuted`.

## 13. `SikaSwitch`
- 52×32, radius 16. Off : piste `track #3A372D`, pouce 24 `text` à left 4. On : piste yellow, pouce `#141208` à left 24. Animation 150 ms.

## 14. `WaveformSeekBar` (lecteur)
- Hauteur 56, largeur pleine (342). 56 barres `Expanded`, gap 2, radius 2, centrées verticalement.
- Hauteur de la barre i : `10 + v*40` avec `v = 0.35 + 0.35*|sin(i*0.9)| + 0.3*|sin(i*0.37+1)|` (forme figée ; en prod, utiliser l'amplitude réelle).
- Barres jouées (`(i+0.5)/56 <= position/durée`) en yellow, le reste `track`.
- Curseur : trait vertical 3 px `text`, top/bottom 2, entouré d'un halo `0 0 0 3 rgba(15,14,11,0.6)`.
- Geste : tap et drag horizontal → seek. Sous la barre (mt 10) : temps écoulé (13 w800 yellow, chiffres tabulaires) · badge central "Haute qualité" (fond `#1F1D17`, r10, padding `4 10`, 11 w700 `textSoft`, icône ondes 12 yellow) · temps restant "-m:ss" (13 w600 `textSoft`).
- Accessibilité : `Semantics(slider, value: "1:24 sur 3:41")`, incréments clavier.

## 15. Cartes
- **Carte jaune "hero"** (Radio, Paroles) : fond yellow, texte `#141208`, radius 24 (Radio) / 22 (Paroles), padding 20. Décor Radio : anneau `#141208` 22 px d'épaisseur Ø 160 à `right −40 top −40`, opacité 0.08.
- **Carte surface** : fond `surface`, radius 18–22, padding 14–18.
- **Carte accent bordée** ("Ton mois en musique") : fond `surface`, bordure 1.5 yellow, radius 18.

## 16. Icônes
Toutes en trait (stroke 1.8–2.2, `round` caps/joins), viewBox 24. Fichiers dans `assets/icons/*.svg` (`flutter_svg`, couleur via `colorFilter`). Les icônes pleines (play, pause, prev, next, home-filled, heart-filled) sont en `fill`.
