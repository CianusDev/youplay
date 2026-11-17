#!/usr/bin/env bash
# Compile YouPlay en release et copie l'APK dans le dossier Téléchargements du téléphone branché.
#
# Usage :
#   ./build.sh              build release + copie sur le téléphone
#   ./build.sh --skip-build copie le dernier APK déjà compilé
#   ANDROID_SERIAL=xxx ./build.sh   cible un appareil précis si plusieurs sont branchés
#
# L'APK arrive dans /sdcard/Download/YouPlay.apk : l'installer depuis le gestionnaire de fichiers
# (MIUI bloque souvent `adb install`).
set -euo pipefail

cd "$(dirname "$0")"

DEST="/sdcard/Download/YouPlay.apk"
OUT="build/app/outputs/flutter-apk"
SKIP_BUILD=0
for arg in "$@"; do
  case "$arg" in
    --skip-build) SKIP_BUILD=1 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "Option inconnue : $arg (voir --help)" >&2; exit 2 ;;
  esac
done

# --- adb ---------------------------------------------------------------------
ADB="$(command -v adb || true)"
for sdk in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Android/Sdk"; do
  if [[ -z "$ADB" && -n "$sdk" && -x "$sdk/platform-tools/adb" ]]; then
    ADB="$sdk/platform-tools/adb"
  fi
done
if [[ -z "$ADB" ]]; then
  echo "✗ adb introuvable (installe platform-tools ou définis ANDROID_HOME)." >&2
  exit 1
fi

# --- téléphone (vérifié avant le build pour ne pas compiler pour rien) -------
mapfile -t DEVICES < <("$ADB" devices | awk 'NR>1 && $2=="device" {print $1}')
if [[ -n "${ANDROID_SERIAL:-}" ]]; then
  SERIAL="$ANDROID_SERIAL"
elif [[ ${#DEVICES[@]} -eq 1 ]]; then
  SERIAL="${DEVICES[0]}"
elif [[ ${#DEVICES[@]} -eq 0 ]]; then
  echo "✗ Aucun téléphone détecté. Branche-le en USB et autorise le débogage USB." >&2
  "$ADB" devices | sed 's/^/  /' >&2
  exit 1
else
  echo "✗ Plusieurs appareils branchés : relance avec ANDROID_SERIAL=<id> ./build.sh" >&2
  printf '  %s\n' "${DEVICES[@]}" >&2
  exit 1
fi
adb_dev() { "$ADB" -s "$SERIAL" "$@"; }

ABI="$(adb_dev shell getprop ro.product.cpu.abi | tr -d '\r')"
case "$ABI" in
  arm64-v8a|armeabi-v7a|x86_64) ;;
  *) echo "⚠ ABI « $ABI » non reconnue, on utilise arm64-v8a."; ABI="arm64-v8a" ;;
esac
MODEL="$(adb_dev shell getprop ro.product.model | tr -d '\r')"
echo "▶ Téléphone : $MODEL ($SERIAL, $ABI)"

# --- build -------------------------------------------------------------------
if [[ $SKIP_BUILD -eq 0 ]]; then
  # Même numérotation que la CI (.github/workflows/release.yml) : nombre de commits.
  # Sinon une build locale serait « plus ancienne » qu'une release et Android refuserait l'installation.
  CODE="$(git rev-list --count HEAD)"
  echo "▶ flutter build apk --release --split-per-abi (version 1.0.$CODE, code $CODE)"
  flutter build apk --release --split-per-abi --build-number="$CODE" --build-name="1.0.$CODE"
fi

APK="$OUT/app-$ABI-release.apk"
if [[ ! -f "$APK" ]]; then
  echo "✗ APK introuvable : $APK (lance sans --skip-build)." >&2
  exit 1
fi

# --- copie -------------------------------------------------------------------
SIZE="$(du -h "$APK" | cut -f1)"
echo "▶ Copie de $APK ($SIZE) vers $DEST"
adb_dev push "$APK" "$DEST" >/dev/null
# Rend le fichier visible tout de suite dans le gestionnaire de fichiers.
adb_dev shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file://$DEST" >/dev/null 2>&1 || true

echo "✓ Prêt : ouvre Gestionnaire de fichiers › Téléchargements › YouPlay.apk › Mettre à jour"
