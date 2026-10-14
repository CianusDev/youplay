# 02 — Lecture en cours (`PlayerScreen`)

Source exacte : `source-html/02-lecture.html` · Modal plein écran (slide-up depuis le mini-lecteur, drag-down pour fermer). Pas de BottomNav.

## Fond
`bg` + halo : ellipse 630×520 orange `#FF7A1A`, opacité 0.16, blur 60, positionnée left −120 top −160. En prod, la couleur du halo = couleur dominante de la pochette (`palette_generator`).

## Structure — scroll, padding `54 24 40`
1. **Header** (marges −12 pour aligner les boutons 48) : chevron bas (fermer) · centre : "LECTURE DEPUIS LA PLAYLIST" (11 w600 ls 1.2 `textSoft`) + "Lomé by Night" (14 w700, mt 2) · bouton "…" (options).
2. **Pochette** 342×342, radius 22, ombre `playerCover`, mt 28. Hero tag partagé avec le mini-lecteur. Swipe horizontal = titre suivant/précédent.
3. **Titre + like** — mt 30, `Row spaceBetween` gap 12 : titre (Bricolage 28 w800 lh 1.1 ls −0.6) + artiste (15 w500 `textSoft`, mt 4, lien → page artiste/playlist) · bouton cœur 48 (icône 28, actif = rempli yellow).
4. **WaveformSeekBar** — mt 20 (components §14). Durée de démo 3:41 (221 s), position initiale 1:24.
5. **Contrôles** — mt 12, `Row spaceBetween` : shuffle (48, icône 22, actif yellow) · précédent (56, icône 30) · **Play/Pause 76** yellow · suivant (56) · repeat (48).
6. **Barre secondaire** — mt 10 (marges −12) : bouton appareil (yellow, icône 20 + "Enceinte salon" 12 w700) · partager · file d'attente.
7. **Carte Paroles** — mt 24, carte jaune radius 22 padding `20 20 22` : titre "Paroles" (Bricolage 17 w800) + bouton agrandir 36 (fond `rgba(20,18,8,0.12)`). 3 lignes : précédente (21 w700 lh 1.35, opacité 0.4) · **en cours** (23 w800 lh 1.3) · suivante (opacité 0.4). Défilement synchronisé, animation de la ligne courante.
8. **Carte artiste** — mt 14, surface, radius 22, padding `18 20` : avatar 56 orange initiales "AK" · nom 15 w700 + "[N] auditeurs mensuels" 12 `textMuted` · bouton "Suivre" (hauteur 36, padding 16, bordure 1.5 `text`, radius 18).

## États par défaut (démo)
playing = true · liked = true · shuffle = true · repeat = false.
