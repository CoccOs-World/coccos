#!/usr/bin/env bash
# ============================================================================
#  CoccOs — publication du dépôt APT (mises à jour automatiques Linux)
#  Méthode IA&TIC — à lancer À CHAQUE MAJ, après build_deb.sh.
#
#  Produit un DÉPÔT PLAT signé dans <site>/apt/ (le rsync habituel du site
#  le met en ligne sur https://coccos.fr/apt) :
#    coccos_<version>_amd64.deb   le paquet courant (les anciens sont retirés)
#    Packages / Packages.gz       l'index (dpkg-scanpackages)
#    Release / InRelease / Release.gpg   les sommes + la signature GPG
#    coccos-archive-keyring.gpg   le trousseau public (ajout manuel possible)
#
#  Signature : clé « CoccOs (cle de signature du depot APT) » du trousseau
#  local (créée le 2026-07-08, ed25519 sans protection, empreinte 1B42 1F08 EA2B AB7C 5F5F 8A60 6615 D7A0 0759 5E5D).
#  ⚠️ Cette clé N'A PAS de phrase de passe : elle ne doit jamais quitter
#  cette machine (une fuite permettrait de signer de faux paquets).
#
#  Côté famille : le .deb installe /etc/apt/sources.list.d/coccos.list —
#  les mises à jour arrivent ensuite par le mécanisme normal d'Ubuntu.
#
#  Usage :  bash release/publier_apt.sh     (après build_deb.sh)
#
#  Réglages facultatifs par variable d'environnement :
#    COCCOS_SORTIE  où lire le .deb (défaut : ../installeur/)
#    COCCOS_SITE    la racine du site à publier (défaut : ../site/)
#    COCCOS_CLES    les identités de signature, séparées par « ; ».
#                   Plusieurs clés = InRelease signé par toutes :
#                   apt accepte dès qu'UNE est dans le trousseau de
#                   la machine (rotation de clé d'archive Debian).
# ============================================================================
set -euo pipefail

ICI="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PROJET_SRC="$(dirname "$ICI")"       # la racine du dépôt
SORTIE_DIR="${COCCOS_SORTIE:-$PROJET_SRC/../installeur}"
DEPOT="${COCCOS_SITE:-$PROJET_SRC/../site}/apt"
CLE_HISTORIQUE="CoccOs (cle de signature du depot APT)"

command -v dpkg-scanpackages >/dev/null || { echo "ERREUR : dpkg-scanpackages absent (paquet dpkg-dev)"; exit 1; }

# --- Les identités qui signeront (une ou plusieurs) --------------------------
ARGS_CLES=()
IFS=';' read -r -a CLES <<< "${COCCOS_CLES:-$CLE_HISTORIQUE}"
for cle in "${CLES[@]}"; do
	cle="${cle#"${cle%%[![:space:]]*}"}"; cle="${cle%"${cle##*[![:space:]]}"}"
	[ -n "$cle" ] || continue
	gpg --list-secret-keys "$cle" >/dev/null 2>&1 \
		|| { echo "ERREUR : clé de signature absente du trousseau : $cle"; exit 1; }
	ARGS_CLES+=(--local-user "$cle")
done
[ ${#ARGS_CLES[@]} -gt 0 ] || { echo "ERREUR : aucune clé de signature"; exit 1; }

# --- Le paquet courant (le plus récent construit par build_deb.sh) -----------
DEB="$(ls -t "$SORTIE_DIR"/coccos_*_amd64.deb 2>/dev/null | head -1)"
[ -n "$DEB" ] || { echo "ERREUR : aucun coccos_*.deb — lancer build_deb.sh d'abord"; exit 1; }
echo "▶ Publication APT de $(basename "$DEB")"

mkdir -p "$DEPOT"
rm -f "$DEPOT"/coccos_*_amd64.deb   # un seul paquet servi : le courant
cp "$DEB" "$DEPOT/"
cp "$ICI/coccos-archive-keyring.gpg" "$DEPOT/"

# --- Index Packages (dépôt plat : chemins relatifs « ./ ») -------------------
cd "$DEPOT"
dpkg-scanpackages --multiversion . /dev/null > Packages 2>/dev/null
gzip -9 -kf Packages

# --- Release : les sommes de contrôle attendues par apt ----------------------
{
	echo "Origin: CoccOs"
	echo "Label: CoccOs"
	echo "Suite: stable"
	echo "Codename: coccos"
	echo "Architectures: amd64"
	echo "Date: $(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S UTC')"
	echo "Description: Depot officiel de CoccOs - le bureau d'ordinateur des enfants"
	echo "MD5Sum:"
	for f in Packages Packages.gz; do
		printf ' %s %16d %s\n' "$(md5sum "$f" | cut -d' ' -f1)" "$(stat -c%s "$f")" "$f"
	done
	echo "SHA256:"
	for f in Packages Packages.gz; do
		printf ' %s %16d %s\n' "$(sha256sum "$f" | cut -d' ' -f1)" "$(stat -c%s "$f")" "$f"
	done
} > Release

# --- Signatures (les deux formes que les apt modernes et anciens attendent) --
rm -f InRelease Release.gpg
# Pas de --passphrase "" codé en dur : l'agent gpg sert les deux cas, une clé
# sans phrase de passe comme une clé protégée (dont l'agent doit être amorcé).
SIGNER=(gpg --batch --yes "${ARGS_CLES[@]}")
"${SIGNER[@]}" --clearsign -o InRelease Release
"${SIGNER[@]}" -abs -o Release.gpg Release

echo "✔ Dépôt prêt : $DEPOT"
ls -la "$DEPOT"
echo
echo "Mise en ligne : le rsync habituel du site publie aussi /apt."
echo "Vérif humaine après re-sync :"
echo "  sudo apt update   # sur une machine où CoccOs (>= 0.1.26.32) est installé"