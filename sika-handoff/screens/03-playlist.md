# 03 — Playlist (`PlaylistScreen`)

Source exacte : `source-html/03-playlist.html` · BottomNav (Bibliothèque actif) + MiniPlayer.

## Structure — scroll, padding bottom 180
1. **En-tête jaune** — fond yellow, texte `#141208`, padding `54 20 24`, radius bas 32 (haut 0).
   - Rangée boutons (marges −10) : retour (chevron gauche 24, stroke 2.2) · rechercher dans la playlist.
   - `Row` crossAxis end, gap 18, mt 8 : pochette 148 r18 ombre `playlistCover` · colonne : eyebrow "PLAYLIST" (11 w700 ls 1.4) · titre "Lomé by Night" (Bricolage 32 w800 lh 0.98 ls −1, mt 6) · "Sika · 42 titres · 2 h 36" (12 w600, mt 10).
   - Description (13 w500 lh 1.5, mt 16).
   - Recommandé : `SliverAppBar` qui se réduit en barre jaune avec titre compact au scroll.
2. **Actions** — padding `18 12 8 10`, `Row spaceBetween` : à gauche ajouter (cercle +, yellow si enregistré) · télécharger · partager ; à droite shuffle (yellow) + **Play 60** yellow.
3. **Liste** — `TrackRow` × N (components §10). Titre en cours : égaliseur animé à la place du numéro + titre yellow. Tap = lire ce titre.

## Pistes de démo
1 Marée haute – Sena Waves 3:12 (c3) · 2 Soleil de Bè – Ama Kodjo 3:41 (c2, en cours) · 3 Maquis 228 – DJ Kpalimé 4:05 (c6, E) · 4 Akodessewa – Les Lagunes 3:28 (c4) · 5 Zémidjan Groove – Kossi & The Moto 2:57 (c1) · 6 Nuit à Kégué – Ama Kodjo 3:50 (c5) · 7 Harmattan – Sena Waves 4:22 (c3, E) · 8 Port Autonome – DJ Kpalimé 3:09 (c6).

Le mini-lecteur reflète le titre sélectionné.
