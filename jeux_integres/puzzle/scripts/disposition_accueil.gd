class_name DispositionAccueil
# =============================================================================================================
# LA DISPOSITION DE L'ACCUEIL POSÉE PAR FABRICE — PHASE 3 (GDD_puzzles §20.2 · §20.3)
# =============================================================================================================
# Ce fichier porte DEUX choses, et rien d'autre :
#   ① LA TABLE `CIBLES` — ce que Fabrice a posé à la main avec l'outil DEV de la phase 2, cuit depuis
#     `outils/disposition_accueil.json` par `outils/cuire_disposition_phase3.py`. **On ne l'écrit pas à la main.**
#   ② LA MATHÉMATIQUE DE LA REPOSE — l'inverse EXACTE de celle qui a servi à écrire le fichier
#     (`outil_dev_accueil.gd:_poser_groupe()` / `_appliquer()`), et une seule voie pour les trois cibles.
#
# ⚠⚠ TOUT PASSE PAR LES **FRACTIONS DU CANVAS**, JAMAIS PAR LE DÉPLACEMENT EN PIXELS (§20.2 bis ⑤) : 240 px ne
#   veulent pas dire la même chose sur 768 et sur 1664 unités. Le fichier porte les deux ; on ne lit que les
#   fractions.
# ⚠⚠ ET L'ÉCHELLE SE DÉDUIT DE LA LARGEUR VOULUE, PAS DU CHAMP `echelle` : l'accueil a déjà redimensionné ses
#   éléments par son propre `k` avant qu'on arrive — reprendre l'échelle brute les redimensionnerait DEUX FOIS.
#   Le champ `echelle` ne sert que de secours, pour un élément sans largeur mesurable (un trait vertical).
# ⚠ CE QUE ÇA DONNE : la POSE FINALE est honorée (le coin haut-gauche et la LARGEUR), la hauteur suit par
#   l'échelle — donc rien n'est jamais déformé, et une image de tableau qui change de rapport garde le sien.
#
# ⚠⚠ (§20.5) ET C'EST PRÉCISÉMENT POURQUOI L'IMAGE DU MODÈLE A SA PROPRE TABLE, `"modeles"` : sa boîte d'origine
#   est calculée AU RAPPORT DU DESSIN (`accueil.gd:_modele_image`), et les cinq tableaux n'ont pas le même (0,854 ·
#   1,164 · 0,854 · 0,854 · 1,833). À largeur imposée, la même entrée rend plus du DOUBLE de hauteur d'un tableau à
#   l'autre : elle déborde ici et laisse un trou là. `"modeles"` porte donc UNE boîte par tableau que Fabrice a
#   RÉGLÉ (clé = l'index du tableau) ; les autres éléments restent une entrée par cible. Un tableau absent de cette
#   table retombe sur l'entrée unique — l'accueil ne devine rien et l'écrit à son journal.
# =============================================================================================================

# LES BORNES DE L'OUTIL, REPRISES TELLES QUELLES (`outil_dev_accueil.gd`) : une échelle hors de ces bornes n'aurait
# pas pu être posée par Fabrice, donc elle ne peut venir que d'un fichier abîmé.
const ECH_MIN := 0.05
const ECH_MAX := 8.0

# 56 éléments, cuits depuis le fichier de l'outil DEV. ⚠ LES CIBLES PORTÉES SONT : linux_4_3 · linux_16_9 · android_paysage. Android DEBOUT et
# iOS n'y sont PAS — Fabrice ne les a pas disposées, et le brief de la phase 3 dit « les cibles non présentes
# restent inchangées » : elles gardent la disposition que l'accueil CALCULE (cf. `entree_pour()`).
const CIBLES := {
# ==========================================================================================
# ⚠⚠ FICHIER **CUIT**, JAMAIS ÉCRIT À LA MAIN — `python3 outils/cuire_disposition_phase3.py`
#   Source : `outils/disposition_accueil.json`, ce que Fabrice a posé avec l'outil DEV (§20.2).
#   Le harnais `outils/preuve_accueil_phase3.sh` recuit la table et la compare À L'OCTET : si
#   quelqu'un retouche ce fichier à la main, la preuve sort ROUGE.
# ==========================================================================================

# --- linux_4_3 — canvas [1024.0, 768.0] · tableau « Les coccos » · curseur « Sans curseur » · enregistré le 2026-09-12 16:39:13 · 20 élément(s) · 5 boîte(s) de modèle par tableau ---
	"linux_4_3": {
		"canvas": Vector2(1024, 768), "enregistre_le": "2026-09-12 16:39:13", "elements": [
			{"cle": "croix_quitter", "present": true, "rel": Rect2(0.91942, 0.02712, 0.06907, 0.09209), "echelle": 1.1051},
			{"cle": "case_curseur_0", "present": true, "rel": Rect2(0.54675, 0.29123, 0.15285, 0.24126), "echelle": 0.9317},
			{"cle": "case_curseur_1", "present": true, "rel": Rect2(0.70313, 0.29465, 0.14557, 0.28619), "echelle": 1.1052},
			{"cle": "case_curseur_2", "present": true, "rel": Rect2(0.85001, 0.28739, 0.15285, 0.3005), "echelle": 1.1604},
			{"cle": "volume", "present": true, "rel": Rect2(0.46944, 0.74262, 0.64461, 0.07218), "echelle": 0.6446},
			{"cle": "modele_image", "present": true, "rel": Rect2(0.01426, 0.16179, 0.52179, 0.81507), "echelle": 6.5151},
			{"cle": "piece_nombre", "present": true, "rel": Rect2(0.11912, 0.00047, 0.08032, 0.10347), "echelle": 1.1025},
			{"cle": "fleche_pieces_plus", "present": true, "rel": Rect2(0.20902, 0.00831, 0.06585, 0.0878), "echelle": 2.0789},
			{"cle": "selecteur_numero", "present": true, "rel": Rect2(0.74529, 0.62071, 0.10425, 0.0695), "echelle": 1.1603},
			{"cle": "fleche_image_droite", "present": true, "rel": Rect2(0.87471, 0.62228, 0.04953, 0.06604), "echelle": 1.1026},
			{"cle": "jouer", "present": true, "rel": Rect2(0.641, 0.88738, 0.30442, 0.08794), "echelle": 0.8659, "parties": [{"cle": "jouer/p2_label", "present": true, "rel": Rect2(0.60036, 0.88906, 0.38853, 0.07914), "echelle": 1.2763}]},
			{"cle": "texte_titre", "present": true, "rel": Rect2(-0.03921, 0.02248, 1.15762, 0.0829), "echelle": 1.1576},
			{"cle": "texte_regle_1", "present": false, "rel": Rect2(0, 0.10292, 1, 0.04557), "echelle": 1},
			{"cle": "texte_regle_2", "present": false, "rel": Rect2(0, 0.14198, 1, 0.04557), "echelle": 1},
			{"cle": "texte_choisis", "present": true, "rel": Rect2(0.09304, 0.16545, 1.3401, 0.0698), "echelle": 1.3401},
			{"cle": "texte_legende_tableau", "present": true, "rel": Rect2(-0.54357, 0.11227, 1.27628, 0.0565), "echelle": 1.2763},
			{"cle": "texte_mot_pieces", "present": true, "rel": Rect2(-0.29724, 0.06023, 0.90703, 0.03897), "echelle": 0.907},
			{"cle": "fond_ecran", "present": true, "rel": Rect2(0, 0, 1, 1), "echelle": 1},
			{"cle": "fleche_image_gauche", "present": true, "rel": Rect2(0.66017, 0.6189, 0.0546, 0.0728), "echelle": 1.2154},
			{"cle": "fleche_pieces_moins", "present": true, "rel": Rect2(0.04121, 0.0069, 0.06585, 0.0878), "echelle": 2.0789},
		],
		"modeles": {
			0: {"present": true, "rel": Rect2(0.01426, 0.16179, 0.52179, 0.81507), "echelle": 6.5151},
			1: {"present": true, "rel": Rect2(0.00762, 0.22235, 0.52179, 0.59754), "echelle": 4.7764},
			2: {"present": true, "rel": Rect2(0.03222, 0.17233, 0.49695, 0.77626), "echelle": 6.2049},
			3: {"present": true, "rel": Rect2(0.00474, 0.16568, 0.52179, 0.81507), "echelle": 6.5151},
			4: {"present": true, "rel": Rect2(0.01204, 0.17053, 0.52179, 0.37948), "echelle": 3.0333},
		}},

# --- linux_16_9 — canvas [1366.0, 768.0] · tableau « La moto » · curseur « Coccinelle » · enregistré le 2026-08-20 11:56:46 · 16 élément(s) · 5 boîte(s) de modèle par tableau ---
	"linux_16_9": {
		"canvas": Vector2(1366, 768), "enregistre_le": "2026-08-20 11:56:46", "elements": [
			{"cle": "croix_quitter", "present": true, "rel": Rect2(0.91942, 0.02712, 0.06907, 0.12285), "echelle": 1.4742},
			{"cle": "case_curseur_0", "present": true, "rel": Rect2(0.54824, 0.22558, 0.11976, 0.31408), "echelle": 1.2129},
			{"cle": "case_curseur_1", "present": true, "rel": Rect2(0.70654, 0.22856, 0.11976, 0.31408), "echelle": 1.2129},
			{"cle": "case_curseur_2", "present": true, "rel": Rect2(0.86577, 0.23164, 0.11406, 0.29913), "echelle": 1.1551},
			{"cle": "volume", "present": true, "rel": Rect2(0.43336, 0.65767, 0.64461, 0.07218), "echelle": 0.6446},
			{"cle": "modele_image", "present": true, "rel": Rect2(0.08466, 0.13037, 0.35317, 0.73592), "echelle": 5.8825},
			{"cle": "selecteur_numero", "present": true, "rel": Rect2(0.71932, 0.5574, 0.10425, 0.09271), "echelle": 1.5479},
			{"cle": "fleche_image_gauche", "present": true, "rel": Rect2(0.61419, 0.55779, 0.05224, 0.09292), "echelle": 1.5513},
			{"cle": "fleche_image_droite", "present": true, "rel": Rect2(0.86881, 0.56, 0.04975, 0.08849), "echelle": 1.4774},
			{"cle": "jouer", "present": true, "rel": Rect2(0.62006, 0.76173, 0.28992, 0.11173), "echelle": 1.1001, "parties": [{"cle": "jouer/p2_label", "present": true, "rel": Rect2(0.58136, 0.76333, 0.37003, 0.10055), "echelle": 1.2763}]},
			{"cle": "texte_titre", "present": true, "rel": Rect2(-0.08786, -0.00762, 1.27628, 0.0914), "echelle": 1.2763},
			{"cle": "texte_regle_1", "present": false, "rel": Rect2(0, 0.10292, 1, 0.04557), "echelle": 1},
			{"cle": "texte_regle_2", "present": false, "rel": Rect2(0, 0.14198, 1, 0.04557), "echelle": 1},
			{"cle": "texte_choisis", "present": true, "rel": Rect2(0.07958, 0.13502, 1.3401, 0.0698), "echelle": 1.3401},
			{"cle": "texte_legende_tableau", "present": true, "rel": Rect2(-0.51662, 0.05851, 1.27628, 0.0565), "echelle": 1.2763},
			{"cle": "fond_ecran", "present": true, "rel": Rect2(0, 0, 1, 1), "echelle": 1},
		],
		"modeles": {
			0: {"present": true, "rel": Rect2(0.08683, 0.11397, 0.37083, 0.77272), "echelle": 6.1766},
			1: {"present": true, "rel": Rect2(0.0286, 0.14935, 0.47328, 0.72301), "echelle": 5.7793},
			2: {"present": true, "rel": Rect2(0.08566, 0.13037, 0.35317, 0.73592), "echelle": 5.8825},
			3: {"present": true, "rel": Rect2(0.08466, 0.13037, 0.35317, 0.73592), "echelle": 5.8825},
			4: {"present": true, "rel": Rect2(0.01235, 0.23896, 0.52179, 0.50623), "echelle": 4.0465},
		}},

# --- android_paysage — canvas [1664, 768] · tableau « L'hélicoccos » · curseur « Sans curseur » · enregistré le 2026-09-12 16:57:04 · 20 élément(s) · 7 boîte(s) de modèle par tableau ---
	"android_paysage": {
		"canvas": Vector2(1664, 768), "enregistre_le": "2026-09-12 16:57:04", "elements": [
			{"cle": "croix_quitter", "present": true, "rel": Rect2(0.91942, 0.02712, 0.06907, 0.14965), "echelle": 1.7958},
			{"cle": "case_curseur_0", "present": true, "rel": Rect2(0.52684, 0.22808, 0.10863, 0.27863), "echelle": 1.076},
			{"cle": "case_curseur_1", "present": true, "rel": Rect2(0.68469, 0.23458, 0.10863, 0.34704), "echelle": 1.3402},
			{"cle": "case_curseur_2", "present": true, "rel": Rect2(0.83953, 0.23457, 0.10863, 0.34704), "echelle": 1.3402},
			{"cle": "volume", "present": true, "rel": Rect2(0.30049, 0.72154, 0.90703, 0.10157), "echelle": 0.907},
			{"cle": "modele_image", "present": true, "rel": Rect2(0.05275, 0.16233, 0.37551, 0.95581), "echelle": 7.6401},
			{"cle": "piece_nombre", "present": true, "rel": Rect2(0.24613, 0.01172, 0.06955, 0.1456), "echelle": 1.5513},
			{"cle": "fleche_pieces_moins", "present": true, "rel": Rect2(0.18102, 0.02275, 0.05702, 0.12354), "echelle": 2.9252},
			{"cle": "selecteur_numero", "present": true, "rel": Rect2(0.68587, 0.59089, 0.10425, 0.11294), "echelle": 1.8856},
			{"cle": "fleche_image_gauche", "present": true, "rel": Rect2(0.55835, 0.58157, 0.05474, 0.1186), "echelle": 1.9802},
			{"cle": "fleche_image_droite", "present": true, "rel": Rect2(0.84546, 0.59358, 0.04965, 0.10757), "echelle": 1.796},
			{"cle": "jouer", "present": true, "rel": Rect2(0.64994, 0.85995, 0.27612, 0.12962), "echelle": 1.2763, "parties": [{"cle": "jouer/p2_label", "present": true, "rel": Rect2(0.63707, 0.86636, 0.30442, 0.10077), "echelle": 1.1025}]},
			{"cle": "texte_titre", "present": true, "rel": Rect2(-0.14955, -0.01492, 1.4071, 0.10077), "echelle": 1.4071},
			{"cle": "texte_regle_1", "present": false, "rel": Rect2(0, 0.10292, 1, 0.04557), "echelle": 1},
			{"cle": "texte_regle_2", "present": false, "rel": Rect2(0, 0.14198, 1, 0.04557), "echelle": 1},
			{"cle": "texte_choisis", "present": true, "rel": Rect2(-0.06273, 0.12003, 1.47746, 0.07695), "echelle": 1.4775},
			{"cle": "texte_legende_tableau", "present": true, "rel": Rect2(-0.74045, 0.01446, 1.62889, 0.07211), "echelle": 1.6289},
			{"cle": "texte_mot_pieces", "present": true, "rel": Rect2(-0.3598, 0.09581, 1.27621, 0.05484), "echelle": 1.27621},
			{"cle": "fond_ecran", "present": true, "rel": Rect2(0, 0, 1, 1), "echelle": 1},
			{"cle": "fleche_pieces_plus", "present": true, "rel": Rect2(0.32061, 0.02569, 0.05431, 0.11767), "echelle": 2.7862},
		],
		"modeles": {
			0: {"present": true, "rel": Rect2(0.05275, 0.16233, 0.37551, 0.95318), "echelle": 7.6191},
			1: {"present": true, "rel": Rect2(0.01353, 0.17091, 0.49694, 0.92477), "echelle": 7.392},
			2: {"present": true, "rel": Rect2(0.06475, 0.15583, 0.37551, 0.95318), "echelle": 7.6191},
			3: {"present": true, "rel": Rect2(0.07469, 0.16336, 0.35763, 0.90779), "echelle": 7.2563},
			4: {"present": true, "rel": Rect2(0.00132, 0.23205, 0.52837, 0.62444), "echelle": 4.9913},
			5: {"present": true, "rel": Rect2(0.0259, 0.1884, 0.39428, 1.00083), "echelle": 8},
			8: {"present": true, "rel": Rect2(0.0489, 0.19273, 0.34635, 1.00083), "echelle": 8},
		}},
}


# ============================================================================================================
# QUELLE CIBLE ? — LA MÊME DÉDUCTION QUE L'OUTIL (`outil_dev_accueil.gd:cible()`), MOT POUR MOT
# ============================================================================================================
# ⚠⚠ ELLE DOIT ÊTRE LA MÊME DES DEUX CÔTÉS, SINON LA CLÉ ÉCRITE N'EST PAS LA CLÉ RELUE : l'outil rangerait sous
#   `android_paysage` ce que le jeu chercherait sous `android_16_9`, et Fabrice verrait l'accueil nu.
# ⚠ LES RAPPORTS 4_3 / 16_9 SONT RÉSERVÉS AU BUREAU (deux cibles distinctes de CLAUDE.md) ; sur un mobile couché,
#   la forme s'appelle « paysage » — une seule cible couvre tous les téléphones et tablettes couchés.
static func cible_pour(canvas: Vector2) -> String:
	var mobile: bool = OS.get_name() in ["Android", "iOS"]
	var forme := "debout"
	var r: float = canvas.x / maxf(canvas.y, 1.0)
	if r >= 1.0:
		forme = "paysage" if mobile else ("4_3" if r < 1.45 else "16_9")
	return "%s_%s" % [OS.get_name().to_lower().replace(" ", "_"), forme]


# L'ENTRÉE À APPLIQUER POUR CE CANVAS — ou un dictionnaire VIDE quand la cible n'a pas de disposition de Fabrice.
# ⚠⚠ UNE CIBLE INCONNUE GARDE LA DISPOSITION PAR DÉFAUT DE L'ACCUEIL, ET C'EST VOULU : le brief dit « les cibles
#   non présentes (android portrait, iOS) restent inchangées ». Transposer d'office la cible voisine revient à LES
#   PORTER — c'est-à-dire à décider à la place de Fabrice. On ne le fait pas ; l'accueil l'ÉCRIT au journal.
static func entree_pour(canvas: Vector2) -> Dictionary:
	var cle := cible_pour(canvas)
	if CIBLES.has(cle):
		return CIBLES[cle]
	return {}


# ============================================================================================================
# LA BOÎTE D'UN NŒUD — la MÊME lecture que l'outil (`outil_dev_accueil.gd:_rect_noeud()`)
# ============================================================================================================
# ⚠ UN `Line2D` ET UN `Polygon2D` NE SONT PAS LEUR POSITION : leurs points sont écrits en coordonnées de canvas
#   (les cadres de `accueil.gd`), le nœud restant à l'origine. Lire `position` seule rendrait une boîte plate en
#   haut à gauche, et l'échelle déduite serait absurde.
static func rect_noeud(n: Node) -> Rect2:
	if n is Control:
		var c := n as Control
		return Rect2(c.position, c.size)
	if n is Line2D:
		var l := n as Line2D
		var b := Rect2()
		var premier := true
		for p in l.points:
			b = Rect2(p, Vector2.ZERO) if premier else b.expand(p)
			premier = false
		return Rect2(b.position + l.position, b.size)
	if n is Polygon2D:
		var g := n as Polygon2D
		var b2 := Rect2()
		var pr := true
		for p in g.polygon:
			b2 = Rect2(p, Vector2.ZERO) if pr else b2.expand(p)
			pr = false
		return Rect2(b2.position + g.position, b2.size)
	if n is Node2D:
		return Rect2((n as Node2D).position, Vector2.ZERO)
	return Rect2()


# LA CLÉ D'UNE PARTIE — le RANG dans l'élément et la CLASSE, jamais le nom du nœud (Godot le renumérote à chaque
# lancement) et jamais son texte (la cuisson ⓑ : le numéro du tableau est justement ce qui change). Elle doit
# rendre exactement ce que la cuisson a écrit.
static func cle_partie(cle: String, rang: int, n: Node) -> String:
	return "%s/p%d_%s" % [cle, rang, n.get_class().to_lower()]


# LA PART DE `r` QUI TOMBE DANS `dans` — la MÊME mesure que l'outil (`_part_dans()`), parce que c'est elle qui a
# rangé chaque nœud dans son élément. Un rectangle plat (un liseré tracé) n'a pas d'aire : on le juge alors sur
# son CENTRE, sinon il ne serait rangé nulle part.
static func part_dans(r: Rect2, dans: Rect2) -> float:
	if r.size.x <= 0.5 or r.size.y <= 0.5:
		return 1.0 if dans.has_point(r.get_center()) else 0.0
	var i := r.intersection(dans)
	if i.size.x <= 0.0 or i.size.y <= 0.0:
		return 0.0
	return i.get_area() / r.get_area()


static func grandir(r: Rect2, g: float, h: float, d: float, b: float) -> Rect2:
	return Rect2(r.position - Vector2(g, h), r.size + Vector2(g + d, h + b))


# ============================================================================================================
# RÉSOUDRE — de la POSE VOULUE (fractions) vers le couple (échelle, déplacement) qui la produit
# ============================================================================================================
# C'est l'inverse de `Rect2(c + ech * (origine.position - c) + dep, origine.size * ech)`, avec `c` le centre de la
# boîte d'origine. ⚠ DEUX ÉTAGES, DEUX FONCTIONS, comme dans l'outil : la partie se résout DANS le repère du
# groupe déjà posé — la mélanger au groupe donnerait une partie juste sur la cible d'enregistrement et fausse
# ailleurs.
static func resoudre_groupe(origine: Rect2, rel: Rect2, secours: float, canvas: Vector2) -> Dictionary:
	var vise := Vector2(rel.position.x * canvas.x, rel.position.y * canvas.y)
	var large: float = rel.size.x * canvas.x
	var ech: float = clampf(secours, ECH_MIN, ECH_MAX)
	if origine.size.x > 0.5 and large > 0.0:
		ech = clampf(large / origine.size.x, ECH_MIN, ECH_MAX)
	var cg: Vector2 = origine.get_center()
	return {"ech": ech, "dep": vise - (cg + ech * (origine.position - cg))}


static func resoudre_partie(gr_origine: Rect2, gr_ech: float, gr_dep: Vector2, origine: Rect2, rel: Rect2,
		secours: float, canvas: Vector2) -> Dictionary:
	var vise := Vector2(rel.position.x * canvas.x, rel.position.y * canvas.y)
	var large: float = rel.size.x * canvas.x
	var eg: float = maxf(gr_ech, 0.0001)
	var ech: float = clampf(secours, ECH_MIN, ECH_MAX)
	if origine.size.x > 0.5 and large > 0.0:
		ech = clampf(large / (origine.size.x * eg), ECH_MIN, ECH_MAX)
	var cg: Vector2 = gr_origine.get_center()
	var local: Vector2 = (vise - gr_dep - cg) / eg + cg      # où la partie tombe AVANT l'étage du groupe
	var cp: Vector2 = origine.get_center()
	return {"ech": ech, "dep": local - (cp + ech * (origine.position - cp))}


# ============================================================================================================
# APPLIQUER — la formule unique, composée de l'étage du GROUPE et de celui de la PARTIE
# ============================================================================================================
# ⚠ ELLE EST **IDEMPOTENTE** : elle repart toujours de `pos0` (la place que l'accueil venait de donner au nœud),
#   jamais de sa place courante. La page entière étant rebâtie à chaque changement (`accueil.gd:_batir`), les
#   déplacements ne peuvent donc pas s'empiler.
static func appliquer(gr_origine: Rect2, gr_ech: float, gr_dep: Vector2, noeud: Node, pos0: Vector2,
		p_origine: Rect2, p_ech: float, p_dep: Vector2) -> void:
	var cg: Vector2 = gr_origine.get_center()
	var cp: Vector2 = p_origine.get_center()
	var pos_p: Vector2 = cp + p_ech * (pos0 - cp) + p_dep
	noeud.set("position", cg + gr_ech * (pos_p - cg) + gr_dep)
	noeud.set("scale", Vector2(gr_ech * p_ech, gr_ech * p_ech))


# LE RECTANGLE QUE DEVIENT UNE BOÎTE SOUS LA TRANSFORMATION DU GROUPE — c'est ce qui permet à `accueil.gd` de
# remettre à jour les rectangles qu'il DÉCLARE (`etat_accueil()`), donc au harnais et à la mise en page de lire la
# place RÉELLE des éléments et non celle d'avant la disposition.
static func rect_pose(gr_origine: Rect2, gr_ech: float, gr_dep: Vector2, r: Rect2) -> Rect2:
	var cg: Vector2 = gr_origine.get_center()
	return Rect2(cg + gr_ech * (r.position - cg) + gr_dep, r.size * gr_ech)
