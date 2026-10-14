# 04 — Recherche (`SearchScreen`)

Source exacte : `source-html/04-recherche.html` · BottomNav (Recherche actif). Pas de mini-lecteur dans la maquette (l'ajouter s'il y a une lecture en cours, même position que partout).

## Structure — scroll, padding `58 0 120`
1. **Titre** — padding 20 : "Recherche" (Bricolage 32 w800 ls −1) · bouton 44 fond `surface` icône ondes yellow (reconnaissance musicale).
2. **Champ** — padding `16 20 0`. Hauteur 52, fond `text #F6F3EA` (champ clair !), radius 14, padding 16, gap 10 : loupe 22 `#141208` · `TextField` (15 w600, placeholder "Artistes, titres, podcasts…" `#6B6659`) · bouton micro 36 fond yellow.
3. **"Recherches récentes"** — titre `h2Small` margin `24 20 12`. Chips scrollables : hauteur 36, padding 14, radius 18, fond `surface`, 13 w600, icône horloge 14 `textMuted`, gap 8.
4. **"Tendances au Togo"** — margin `26 20 12`. Carte surface r18 padding 12 : carré 64 yellow r12 "50" (Bricolage 26 w800) · "Top 50 — Togo" 15 w700 + "Mis à jour chaque jeudi" 12 · chevron droite.
5. **"Parcourir tout"** — grille 2 colonnes gap 10, padding 20. Tuile hauteur 104, radius 16, padding 14, titre Bricolage 17 w800 ; carré 72 r10 pivoté 22° en bas-droite (right −14, bottom −10) avec ombre `0 8 18 rgba(0,0,0,.3)`.

| Tuile | Fond | Texte | Carré |
|---|---|---|---|
| Afrobeat | `#FFD60A` | `#141208` | `#141208` |
| Amapiano | `#FF7A1A` | `#141208` | `#FFD60A` |
| Highlife | `#1F3B2D` | `#F6F3EA` | `#FFD60A` |
| Gospel | `#3A2A55` | `#F6F3EA` | `#FF7A1A` |
| Podcasts | `#F1E6C8` | `#141208` | `#1F3B2D` |
| Concentration | `#2A271E` | `#FFD60A` | `#F1E6C8` |
| Rap FR | `#8A1C1C` | `#F6F3EA` | `#141208` |
| Traditionnel | `#FFE878` | `#141208` | `#8A1C1C` |

## Comportement
Focus sur le champ → masquer "Parcourir tout", afficher suggestions/résultats en direct (debounce 250 ms).
