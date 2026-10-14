# 01 — Accueil (`HomeScreen`)

Source exacte : `source-html/01-accueil.html` · Frame 390×844 · Fond `bg`.

## Structure (de haut en bas)
`Stack` : contenu scrollable (padding top 58, bottom 190 pour laisser passer mini-lecteur + nav) · `MiniPlayer` (bottom 92) · `BottomNav` (onglet Accueil actif).

1. **Header** — padding horizontal 20, `Row spaceBetween`.
   - Gauche : avatar cercle 40 yellow, initiale "K" Bricolage 16 w800 `#141208` · gap 12 · colonne : "Bonsoir" (Manrope 12 w500 `textMuted`, dépend de l'heure : Bonjour / Bon après-midi / Bonsoir) + prénom (Bricolage 20 w700 ls −0.3).
   - Droite : 2 `IconButton` 44 (gap 4) : cloche (pastille 8×8 yellow à top 11 right 12 = notification non lue) · réglages.
2. **Chips** — padding `18 20 4`, gap 8 : Tout (actif par défaut) · Musique · Podcasts · Afro · Concentration. Filtre le contenu en dessous.
3. **Accès rapides** — padding `16 20 0`, grille 2×3 de `QuickPickTile` : Titres likés (c1) · Lomé by Night (c2) · Afro Focus (c3) · Highlife Gold (c4) · Daily Mix 1 (c5) · Code & Chill (c6). Tap → Playlist.
4. **Carte "Ta Radio Sika"** — margin `24 20 0`, carte jaune radius 24, padding 20, `Row` gap 16, `clip`.
   - Texte : eyebrow "NOUVEAU POUR TOI" (11 w700 ls 1.4) · titre "Ta Radio Sika" (Bricolage 26 w800 lh 1.05 ls −0.6, mt 6) · "Un flux infini, calé sur tes 30 derniers jours." (13 w500, mt 6).
   - Bouton play 56 fond `#141208` icône yellow → lance la radio + ouvre le lecteur.
   - Décor anneau (voir components §15).
5. **"Tes mix du jour"** — en-tête padding `28 20 12`, titre `h2Section` + lien "Tout voir" (12 w700 `textMuted`) → Bibliothèque. Carrousel `MixCard` : Daily Mix 1 (c5, "Afrobeat, Azonto, Highlife") · Daily Mix 2 (c2, "Amapiano, Gqom") · Daily Mix 3 (c3, "Lo-fi, Jazz, Soul").
6. **"Écoutés récemment"** — padding `28 20 12`, carrousel `ArtistBubble` : Ama Kodjo (c1) · Les Lagunes (c4) · DJ Kpalimé (c6) · Sena Waves (c2).

## Interactions
- Chips : sélection unique.
- Mini-lecteur : like (toggle cœur yellow plein), play/pause, tap zone gauche → Lecteur.
- Pull-to-refresh (indicateur yellow) recommandé.

## Données factices
Artistes et titres inventés (à remplacer par l'API).
