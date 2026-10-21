#!/usr/bin/env bash
# ============================================================================
#  CoccOs — construction de l'installeur .deb (Linux / Debian・Ubuntu)
#  Méthode IA&TIC — reconstruit à chaque MAJ (recette reproductible).
#
#  Ce que produit le paquet (structure apprise de l'artefact d'origine) :
#    /opt/<pkg>/godot          le moteur Godot embarqué (binaire éditeur)
#    /opt/<pkg>/projet/        la SOURCE du projet, lancée en --path (pas un
#                              export binaire) — le moteur exécute le projet
#    /usr/bin/<pkg>            lanceur : exec .../godot --path .../projet "$@"
#    /usr/share/applications/<pkg>.desktop     entrée de menu (Name=CoccOs)
#    /usr/share/icons/hicolor/256x256/apps/<pkg>.png   icône coccinelle
#  postinst : (ré)génère le cache d'import sur la machine cible.
#
#  Le paquet est AUTONOME (rien d'autre à installer). Dépendance pkexec pour
#  l'installation graphique d'applis externes ; speech-dispatcher recommandé
#  pour la voix de synthèse (le repli reste silencieux si absent).
#
#  BUILD : aucun sudo requis (dpkg-deb --root-owner-group pose root:root).
#  INSTALL : « sudo apt install ./<fichier>.deb » — à faire par l'humain.
#
#  Usage :  bash release/build_deb.sh      (depuis n'importe où)
#
#  Le script vit DANS le dépôt : un clone nu suffit à fabriquer le paquet.
#  Trois réglages par variable d'environnement, tous facultatifs :
#    COCCOS_GODOT   le binaire de l'éditeur Godot 4.7.2 (hors dépôt, 120 Mo).
#                   À défaut, cherché dans ../outils/ à côté du dépôt.
#    COCCOS_SORTIE  où déposer le .deb (défaut : ../installeur/ à côté du dépôt)
# ============================================================================
set -euo pipefail

# --- Repères (le script se situe dans dev/installeur/) ----------------------
ICI="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PROJET_SRC="$(dirname "$ICI")"       # la racine du dépôt EST le projet Godot
ICONE="$ICI/coccos.png"
SORTIE_DIR="${COCCOS_SORTIE:-$PROJET_SRC/../installeur}"

# Le moteur Godot ne peut pas vivre dans le dépôt (binaire de 120 Mo) : on le
# désigne par COCCOS_GODOT, sinon on le cherche à côté du dépôt (disposition
# historique dev/outils/), sinon dans le PATH.
GODOT="${COCCOS_GODOT:-}"
if [ -z "$GODOT" ]; then
	for candidat in "$PROJET_SRC"/../outils/Godot_v4.7*-stable_linux.x86_64; do
		[ -x "$candidat" ] && { GODOT="$candidat"; break; }
	done
fi
[ -n "$GODOT" ] || GODOT="$(command -v godot || true)"

PKG="coccos"             # nom définitif (décision Freddy 2026-07-07) — le paquet
                         # remplace proprement l'ancien « kidosaure » (Conflicts/Replaces)
ARCH="amd64"

# --- Contrôles préalables (ne jamais supposer) ------------------------------
[ -f "$PROJET_SRC/project.godot" ] || { echo "ERREUR : projet introuvable ($PROJET_SRC)"; exit 1; }
[ -n "$GODOT" ] && [ -x "$GODOT" ] || {
	echo "ERREUR : moteur Godot introuvable. Indiquer son chemin :"
	echo "  COCCOS_GODOT=/chemin/Godot_v4.7.2-stable_linux.x86_64 bash release/build_deb.sh"
	exit 1; }
[ -f "$ICONE" ] || { echo "ERREUR : icône introuvable ($ICONE)"; exit 1; }
command -v dpkg-deb >/dev/null || { echo "ERREUR : dpkg-deb absent"; exit 1; }

# --- Version lue dans project.godot (source unique de vérité) ---------------
VERSION="$(grep -E '^config/version=' "$PROJET_SRC/project.godot" | head -1 | cut -d'"' -f2)"
[ -n "$VERSION" ] || { echo "ERREUR : version illisible dans project.godot"; exit 1; }
echo "▶ Construction de $PKG $VERSION ($ARCH)"

# --- Aire de montage temporaire ---------------------------------------------
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT
RACINE="$BUILD/${PKG}_${VERSION}_${ARCH}"
OPT="$RACINE/opt/$PKG"
mkdir -p "$RACINE/DEBIAN" "$OPT/projet" \
         "$RACINE/usr/bin" \
         "$RACINE/usr/share/applications" \
         "$RACINE/usr/share/icons/hicolor/256x256/apps"

# --- 1) Moteur Godot embarqué -----------------------------------------------
cp "$GODOT" "$OPT/godot"
chmod 755 "$OPT/godot"

# --- 2) Source du projet (sans le cache dev ni le bac _staging) -------------
#     Le cache .godot est REGÉNÉRÉ proprement plus bas ; export_presets.cfg
#     (web/Windows) est inutile à l'exécution.
cp -a "$PROJET_SRC/." "$OPT/projet/"
# Le dépôt git, le gabarit de build Android (1 Go d'outillage gradle) et la
# chaîne de release elle-même n'ont rien à faire dans le paquet — purge
# après copie.
rm -rf "$OPT/projet/.git" "$OPT/projet/android" "$OPT/projet/release"
rm -rf "$OPT/projet/.godot" "$OPT/projet/_staging" "$OPT/projet/export_presets.cfg"

# --- 3) Cache d'import frais (textes, voix, textures) -----------------------
echo "▶ Génération du cache d'import…"
"$GODOT" --headless --path "$OPT/projet" --import >/dev/null 2>&1 || true
# On ne garde pas les caches spécifiques à la machine de build
rm -rf "$OPT/projet/.godot/shader_cache" "$OPT/projet/.godot/editor"

# --- 4) Lanceur --------------------------------------------------------------
#     Les arguments (ex. --app classeur, icônes directes) passent après « -- »
#     pour arriver dans les user args de Godot sans heurter le parseur du moteur.
cat > "$RACINE/usr/bin/$PKG" <<EOF
#!/bin/sh
exec /opt/$PKG/godot --path /opt/$PKG/projet -- "\$@"
EOF
chmod 755 "$RACINE/usr/bin/$PKG"

# --- 5) Entrée de menu + icône ----------------------------------------------
cat > "$RACINE/usr/share/applications/$PKG.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=CoccOs
GenericName=Bureau enfant
Comment=Le bureau d'ordinateur des enfants — souris, clavier, jeux et applications éducatives
Exec=$PKG
Icon=$PKG
Terminal=false
Categories=Education;Game;KidsGame;
Keywords=enfant;éducatif;souris;clavier;lettres;mots;chasse;coccinelle;
EOF
cp "$ICONE" "$RACINE/usr/share/icons/hicolor/256x256/apps/$PKG.png"

# --- 5 ter) Icône directe « Mon classeur » (spec logithèque, 2026-07-10) -----
#     Le classeur de communication a sa propre entrée de menu : on le lance
#     sans passer par le bureau CoccOs (la croix quitte alors l'application).
cat > "$RACINE/usr/share/applications/$PKG-classeur.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Mon classeur
GenericName=Classeur de communication
Comment=Le classeur de communication CoccOs — les vignettes qui parlent
Exec=$PKG --app classeur
Icon=$PKG-classeur
Terminal=false
Categories=Education;
Keywords=communication;CAA;pictogramme;classeur;coccos;
EOF
cp "$PROJET_SRC/assets/icones/classeur.png" \
   "$RACINE/usr/share/icons/hicolor/256x256/apps/$PKG-classeur.png"

# --- 5 bis) Mises à jour automatiques : le paquet installe SA source APT -----
#     (modèle Chrome/VSCode : installer une fois, les MAJ arrivent ensuite
#     par le mécanisme normal du système). Dépôt plat signé : coccos.fr/apt.
#     Le trousseau public est généré une fois pour toutes (clé « CoccOs »)
#     et versionné dans release/.
TROUSSEAU="$ICI/coccos-archive-keyring.gpg"
[ -f "$TROUSSEAU" ] || { echo "ERREUR : trousseau APT introuvable ($TROUSSEAU)"; exit 1; }
mkdir -p "$RACINE/usr/share/keyrings" "$RACINE/etc/apt/sources.list.d"
cp "$TROUSSEAU" "$RACINE/usr/share/keyrings/coccos-archive-keyring.gpg"
cat > "$RACINE/etc/apt/sources.list.d/coccos.list" <<EOF
# Mises à jour automatiques de CoccOs (dépôt officiel) — retirer ce fichier
# pour s'en désabonner. https://coccos.fr
deb [signed-by=/usr/share/keyrings/coccos-archive-keyring.gpg] https://coccos.fr/apt ./
EOF

# --- 6) Métadonnées + postinst ----------------------------------------------
INSTALLED_KB="$(du -sk "$RACINE/opt" "$RACINE/usr" | awk '{s+=$1} END {print s}')"
cat > "$RACINE/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: education
Priority: optional
Architecture: $ARCH
Installed-Size: $INSTALLED_KB
Depends: pkexec | policykit-1
Recommends: speech-dispatcher
Conflicts: kidosaure
Replaces: kidosaure
Maintainer: Freddy Maillard - NET&TIC <seedfrid@gmail.com>
Description: CoccOs — bureau educatif pour l'enfant (mini-OS)
 CoccOs est un bureau
 d'ordinateur pense pour les jeunes enfants et les profils atypiques :
 icones-dossiers, fenetres, jeux de decouverte de la souris et du
 clavier (lettres, mots et chasse aux lettres parles), lancement
 d'applications educatives libres, reglages parentaux sous PIN.
 .
 Pas de chrono, pas d'echec, pas de stimuli inutiles.
EOF

cat > "$RACINE/DEBIAN/postinst" <<EOF
#!/bin/sh
set -e
/opt/$PKG/godot --headless --path /opt/$PKG/projet --import > /dev/null 2>&1 || true
exit 0
EOF
chmod 755 "$RACINE/DEBIAN/postinst"

# --- 7) Assemblage (root:root grâce à --root-owner-group) -------------------
mkdir -p "$SORTIE_DIR"
SORTIE="$(cd "$SORTIE_DIR" && pwd)/${PKG}_${VERSION}_${ARCH}.deb"
dpkg-deb --root-owner-group --build "$RACINE" "$SORTIE" >/dev/null

echo "✔ Paquet construit : $SORTIE"
echo "  Taille : $(du -h "$SORTIE" | cut -f1)"
echo
echo "Installation (par l'humain) :  sudo apt install \"$SORTIE\""
