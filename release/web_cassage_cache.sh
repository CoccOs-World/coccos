#!/usr/bin/env bash
# Casse le cache navigateur du jeu web : nomme le .pck, le .wasm et les worklets
# avec la version, et met index.html à jour. Le serveur sert ces fichiers avec
# max-age 30 j ; index.html, lui, est en no-cache : il désigne donc toujours
# la bonne version.
# Usage : bash release/web_cassage_cache.sh [dossier_jeu] [version]
#   défauts : $COCCOS_SITE/jeu (../site/jeu) et config/version de project.godot
# Lancer APRÈS l'export Web, AVANT le rsync. Ne pas lancer deux fois.
set -euo pipefail
cd "$(dirname "$0")/.."
JEU="${1:-${COCCOS_SITE:-../site}/jeu}"
VERSION="${2:-$(grep -E '^config/version=' project.godot | cut -d'"' -f2)}"
EXE="index-$VERSION"
cd "$JEU"
[ -f index.html ] && [ -f index.pck ] && [ -f index.wasm ] \
  || { echo "export Web absent ou déjà traité dans $JEU" >&2; exit 1; }
grep -q '"executable":"index"' index.html \
  || { echo "index.html : \"executable\":\"index\" introuvable" >&2; exit 1; }
for s in pck wasm audio.worklet.js audio.position.worklet.js; do
  [ -f "index.$s" ] && mv "index.$s" "$EXE.$s"
done
sed -i -e "s/\"executable\":\"index\"/\"executable\":\"$EXE\"/" \
       -e "s/\"index\.pck\":/\"$EXE.pck\":/" \
       -e "s/\"index\.wasm\":/\"$EXE.wasm\":/" \
       -e "s|<script src=\"index\.js\"></script>|<script src=\"index.js?v=$VERSION\"></script>|" \
       index.html
grep -q "\"executable\":\"$EXE\"" index.html
grep -q "\"$EXE.pck\":" index.html
grep -q "\"$EXE.wasm\":" index.html
grep -q "index.js?v=$VERSION" index.html
echo "jeu web nommé $EXE.* dans $JEU"
