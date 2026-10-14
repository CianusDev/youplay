# 05 — Bibliothèque (`LibraryScreen`)

Source exacte : `source-html/05-bibliotheque.html` · BottomNav (Bibliothèque actif).

## Structure — scroll, padding `58 0 120`
1. **Header** — padding `0 12 0 20` : avatar 36 yellow "K" · "Bibliothèque" (Bricolage 26 w800 ls −0.8), gap 12 · boutons 44 : rechercher · créer une playlist (+).
2. **Chips** — padding `16 20 0` : Tout · Playlists · Artistes · Albums · Podcasts · Téléchargés. Filtrent la liste.
3. **Carte "Ton mois en musique"** — margin `18 20 0`, surface + bordure 1.5 yellow, r18, padding 14 : carré 52 yellow r14 icône graphique · titre 15 w700 + "Artistes, genres et minutes d'écoute" 12 · chevron yellow.
4. **Barre tri/vue** — padding `14 10 4 20` : bouton "Récents" (icône tri 16 + 13 w700) · bouton 44 qui bascule liste ↔ grille (icône = vue cible).
5. **Contenu** — liste `LibraryRow` ou grille 3 colonnes (components §11).

## Éléments de démo
Titres likés (Playlist · 318 titres, c1, épinglé, téléchargé) · Lomé by Night (c2, épinglé) · Ama Kodjo (Artiste, cercle) · Afro Focus (c3, téléchargé) · Tech en Afrique (Podcast, c4) · Les Lagunes (Artiste) · Harmattan (Album · Sena Waves, c3) · Code & Chill (c6, téléchargé) · Daily Mix 1 (c5).

Filtre "Téléchargés" = éléments téléchargés uniquement. État vide à prévoir.
