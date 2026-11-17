#!/usr/bin/env bash
# Téléchargements de YouPlay par version (fichiers APK seulement).
#
# GitHub compte des fichiers, pas des personnes. version.json est exclu : l'app le lit à chaque
# lancement pour chercher les mises à jour. Chaque utilisateur qui accepte une mise à jour
# télécharge l'APK de cette version : quelques jours après une sortie, les téléchargements de la
# dernière version donnent donc à peu près le nombre d'utilisateurs actifs.
#
# Usage : ./tools/downloads.sh        (GITHUB_TOKEN facultatif, évite la limite de 60 requêtes/h)
set -euo pipefail

REPO="CianusDev/youplay"
command -v jq >/dev/null || { echo "jq est requis (sudo apt install jq)" >&2; exit 1; }

auth=()
[[ -n "${GITHUB_TOKEN:-}" ]] && auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
json="$(curl -fsSL "${auth[@]}" -H "Accept: application/vnd.github+json" "https://api.github.com/repos/$REPO/releases?per_page=100")" \
  || { echo "Impossible de joindre l'API GitHub (limite de requêtes ?)." >&2; exit 1; }

echo "$json" | jq -r '
  def apk: [.assets[] | select(.name | endswith(".apk"))];
  def sum(f): [.[] | f] | add // 0;
  (["Version", "Date", "APK", "via le site"] | @tsv),
  (.[] | [ (.name // .tag_name | sub("^YouPlay "; "")),
           (.published_at[0:10]),
           (apk | sum(.download_count)),
           ([.assets[] | select(.name == "YouPlay.apk")] | sum(.download_count)) ] | @tsv)
' | column -t -s $'\t'

echo
echo "$json" | jq -r '
  def apk: [.assets[] | select(.name | endswith(".apk"))];
  "Total APK, toutes versions : \([.[] | apk[] | .download_count] | add // 0)",
  "Utilisateurs actifs (≈ APK de la dernière version, \(.[0].name // .[0].tag_name)) : \(.[0] | apk | [.[].download_count] | add // 0)",
  "Nouvelles installations via le site (YouPlay.apk) : \([.[] | .assets[] | select(.name == "YouPlay.apk") | .download_count] | add // 0)"
'
echo "Ces chiffres incluent tes propres installations et quelques robots qui parcourent GitHub."
