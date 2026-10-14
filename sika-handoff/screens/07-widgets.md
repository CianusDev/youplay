# 07 — Widgets (écran d'accueil, verrouillage, Android, montre)

Source exacte : `source-html/07-widgets.html` (planche 1240×844).

Implémentation : package `home_widget` (^0.7) côté Flutter + code natif :
- iOS : extension WidgetKit (SwiftUI) + Live Activity / lock screen (accessoryCircular, accessoryRectangular) ; contrôles via App Intents.
- Android : AppWidget (Glance/Jetpack Compose) ; contrôles média via `MediaSession` (`audio_service`).
Les données (titre, artiste, pochette, progression, état) sont poussées par l'app via `HomeWidget.saveWidgetData` puis `updateWidget`.

## iOS — écran d'accueil
| Widget | Taille maquette | Contenu |
|---|---|---|
| **Moyen (4×2)** | 356×158, r24, fond `#141208`, padding 14 | Pochette 130 r14 · colonne : "Sika" (Bricolage 12 w800 yellow) + mini-égaliseur 3 barres · titre (Bricolage 18 w800) · artiste 12 `textMuted` · barre 3 px (piste `track`, yellow 38 %) poussée en bas · contrôles prev 32 / pause 40 yellow / next 32 |
| **Petit A (2×2)** | 162×162, r24, fond yellow | "Sika" · "Daily Mix 1" (Bricolage 20 w800 lh 1.05, retour ligne) · "50 titres pour toi" 11 w600 · disque `#141208` Ø110 en bas-droite (right/bottom −30) · bouton play 44 yellow |
| **Petit B (2×2)** | 162×162, r24, fond `#141208`, padding 10 | Grille 2×2 de pochettes (gap 8, r12) = 4 dernières playlists, chaque case est un deep link |
| **Grand (4×4)** | 356 × auto, r24, fond `#141208`, padding 16 | "Reprendre l'écoute" (Bricolage 15 w800) + "Sika" yellow · 3 lignes (pochette 40 r8, titre 13 w700, méta 11) ; la ligne en cours a son titre en yellow |

## Écran de verrouillage
- **Circulaire** 60 : anneau de progression (conic yellow 38 % / `rgba(255,255,255,.18)`), disque intérieur 50 `surface` + pause yellow.
- **Rectangulaire** h60, r18, fond `rgba(26,25,21,.85)`, padding 16 : "À SUIVRE" 10 w700 yellow ls 0.8 + "Maquis 228 · DJ Kpalimé" 13 w700.
- **Lecteur média** (Live Activity / contrôles système) : left/right 14, bottom 120, r28, fond `rgba(36,33,25,.92)`, padding 16 — pochette 52 r10, titre 15 w700, artiste 13 `textSoft`, "Sika" yellow ; progression 4 px avec temps 11 w600 ; contrôles : like yellow · prev · pause 56 yellow · next · appareils.

## Android — barre 4×1
Hauteur 76, r38 (pilule), fond yellow, padding `0 8 0 10`, gap 10 : pochette ronde 56 · titre 14 w800 + artiste 12 w600 (`#141208`) · bouton pause 56 fond `#141208` icône yellow.

## Montre — complication
Cadran 120×140 r36, heure Bricolage 22 w800, anneau 48 (yellow 38 % / `#2A271E`) avec pause yellow au centre.
