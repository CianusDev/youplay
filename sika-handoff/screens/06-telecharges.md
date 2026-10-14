# 06 — Téléchargés (`DownloadsScreen`)

Source exacte : `source-html/06-telecharges.html` · BottomNav (Téléchargés actif, icône pleine : disque yellow + flèche `bg`) + MiniPlayer (sous-titre "Artiste · Hors ligne" avec point yellow).

## Structure — scroll, padding `58 0 190`
1. **Header** — padding `0 10 0 20` : "Téléchargés" (Bricolage 30 w800 ls −1) · bouton 44 réglages (curseurs).
2. **Carte réglages** — margin `16 20 0`, surface r22 padding 18.
   - Ligne 1 : carré 48 r14 icône wifi barré (off : fond `surface2` icône yellow ; on : fond yellow icône `#141208`) · "Mode hors ligne" 15 w800 + statut 12 `textMuted` ("Désactivé · streaming autorisé" / "Activé · seuls tes téléchargements sont lus") · `SikaSwitch`.
   - Séparateur 1 px `surface2`, marges 16.
   - Ligne 2 : "Téléchargement intelligent" 14 w700 + "Garde tes titres les plus écoutés à jour, en Wi-Fi seulement" 12 · `SikaSwitch` (on par défaut).
3. **Stockage** — margin `12 20 0`, padding 0 2 : "Stockage" 12 w700 / "[X] Go utilisés · [Y] Go libres" 12 `textMuted`. Barre 8 px r4 fond `surface2`, segments gap 2 : Sika yellow · Podcasts orange · Autres apps `#5A5547`. Légende 11 w600 (carrés 8 r2), gap 14. Valeurs réelles via `disk_space`/`path_provider`.
4. **Chips** — padding `22 20 0` : Tout · Playlists · Albums · Podcasts.
5. **Section "En cours · N"** (si téléchargements actifs) — padding `18 20 4` : titre Bricolage 16 w800 · bouton "Tout mettre en pause" 12 w700 `textMuted`.
6. **Liste** — `DownloadRow` (components §12).
7. **État vide** — texte centré 14 `textMuted` : "Rien ici pour l'instant. Appuie sur ↓ sur un titre ou une playlist."

## Démo
Harmattan (Album, en cours 64 %) · Tech en Afrique — Ép. [N] (Podcast, en attente) · Titres likés · Lomé by Night · Afro Focus · Code & Chill · Nuit à Kégué · Tech en Afrique — Ép. [N−1] (téléchargés).
