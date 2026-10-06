class_name DispositionPuzzle
extends RefCounted
# ============================================================================================================
# (#192 · 06-10) LA DISPOSITION DE L'ÉCRAN DE JEU, RÉGLÉE À LA SOURIS PAR FABRICE — la vignette modèle et les
# deux boutons du jeu (la maison, le recadrage), et l'opacité du MODÈLE EN FILIGRANE du cadre de montage.
#
# Fabrice, mot pour mot : « Fais-moi un outil pour que je puisse déplacer, redimensionner, pour chaque jeu, la
# disposition par défaut de la vignette miniature qui va devenir déplaçable ainsi que les boutons. » — et :
# « Pour les tableaux quatre pièces et quinze pièces, dans le cadre dans lequel on doit déposer les pièces que
# l'on construit, on va y faire apparaître l'image de la vignette modèle légèrement grisée. »
#
# ⚠⚠ CE FICHIER EST **CUIT PAR L'OUTIL DEV** (`outils/outil_dev_puzzle.*`, touche ENTRÉE) : le bloc `CAS` est
#   RÉÉCRIT en entier à chaque cuisson (entre les deux marqueurs « CUISSON »). Ne pas y écrire à la main —
#   régler dans l'outil. Tout ce qui est hors des marqueurs est conservé à l'octet.
#   ⚠ C'est un `.gd` et non un `.json`, comme `disposition_accueil.gd` : un script est une RESSOURCE, il voyage
#   donc dans les paquets du bureau (`all_resources`) sans filtre à ajouter.
#
# LA GRANULARITÉ — UN CAS PAR « NOMBRE DE PIÈCES × SOURIS OU DOIGT » (6 cas : 4 · 15 · 30 × bureau · doigt).
#   Pourquoi pas par tableau : à l'intérieur d'une famille la mise en page du jeu est la même, seul le rapport du
#   dessin change — et la vignette est posée DANS une boîte, au plus grand sans déformer, comme le jeu le fait
#   déjà. Pourquoi pas par écran : les positions sont en FRACTIONS du canvas (cf. `rect()`), une seule entrée
#   couvre 4:3, 16:9 et le téléphone couché. Pourquoi bureau ≠ doigt : les deux mises en page diffèrent
#   (réserve à droite au bureau, trois colonnes au doigt, §21.2).
#
# LE FORMAT D'UN RECTANGLE : [centre x / largeur du canvas, centre y / hauteur, largeur / hauteur, hauteur /
#   hauteur]. Le CENTRE suit l'écran, la TAILLE suit la hauteur : un bouton réglé carré reste carré en 16:9.
#
# UN CAS ABSENT (ou un élément absent d'un cas) = LE JEU GARDE SA DISPOSITION CALCULÉE, au millième.
# ============================================================================================================

const FILIGRANE_DEFAUT := 0.30          # l'opacité du modèle grisé dans le cadre de montage (0 = absent, 1 = plein)
const FILIGRANE_PIECES := [4, 15]       # « pour les tableaux quatre pièces et quinze pièces » — pas 30 (hors demande)
const ELEMENTS := ["modele", "maison", "recadrer"]

# --- CUISSON : début (bloc réécrit par l'outil DEV) ---
const CUIT_LE := ""
const CAS := {
}
# --- CUISSON : fin ---


static func cle(pieces: int, tactile: bool) -> String:
	return "%dpieces_%s" % [pieces, "doigt" if tactile else "bureau"]


static func cas(c: String) -> Dictionary:
	return CAS.get(c, {}) as Dictionary


# Le rectangle d'écran d'une entrée [cx/L, cy/H, l/H, h/H] — et son inverse, pour l'outil.
static func rect(e: Array, ecran: Vector2) -> Rect2:
	if e.size() < 4:
		return Rect2()
	var t := Vector2(float(e[2]), float(e[3])) * ecran.y
	var c := Vector2(float(e[0]) * ecran.x, float(e[1]) * ecran.y)
	return Rect2(c - t * 0.5, t)


static func entree(r: Rect2, ecran: Vector2) -> Array:
	var c := r.get_center()
	return [snappedf(c.x / ecran.x, 0.00001), snappedf(c.y / ecran.y, 0.00001),
		snappedf(r.size.x / ecran.y, 0.00001), snappedf(r.size.y / ecran.y, 0.00001)]


# ⚠ UN ÉLÉMENT RÉGLÉ NE SORT JAMAIS DE L'ÉCRAN : réglé en 16:9 puis rejoué en 4:3, un bouton collé au bord droit
#   serait perdu. On le ramène dedans (sa taille, elle, n'est réduite que s'il est plus grand que l'écran).
static func borner(r: Rect2, ecran: Vector2) -> Rect2:
	var t := r.size.min(ecran)
	var p := Vector2(clampf(r.position.x, 0.0, ecran.x - t.x), clampf(r.position.y, 0.0, ecran.y - t.y))
	return Rect2(p, t)


# L'opacité du filigrane pour un nombre de pièces : 0 hors des familles 4 et 15, sinon la valeur réglée du cas,
# sinon le défaut.
static func filigrane(pieces: int, tactile: bool) -> float:
	if not FILIGRANE_PIECES.has(pieces):
		return 0.0
	return clampf(float(cas(cle(pieces, tactile)).get("filigrane", FILIGRANE_DEFAUT)), 0.0, 1.0)
