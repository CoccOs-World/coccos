extends RefCounted
class_name ProgressionPuzzle

# ============================================================================================================
# LA PROGRESSION — « LE PLUS HAUT TABLEAU ATTEINT », **PAR FAMILLE**, ET ELLE SURVIT À L'EXTINCTION
# (PUZZLE-B4 puis PUZZLE-B15 · GDD §7.11, §23 quater)
#
# « Un tableau se débloque en gagnant le précédent (mécanique du 7 différences). Au départ : seul le tableau 1
# est accessible ; gagner le 1 débloque le 2. » (Fabrice, GDD §7.11)
# « Dans chaque famille, c'est la progression qui débloque les puzzles suivants. » (Fabrice, GDD §23 quater)
#
# ⚠⚠ CE QUE B15 CHANGE, ET POURQUOI CE N'EST PAS COSMÉTIQUE : ce fichier ne retenait QU'UN chiffre, le plus haut
#   tableau atteint dans la table entière. Avec les familles (§23 bis) ce chiffre unique deviendrait FAUX dans
#   les deux sens — un enfant qui a fini les cinq « 15 pièces » trouverait les quatre « 4 pièces » déjà ouverts
#   sans les avoir faits, et un enfant qui débute sur le 4 pièces verrait la progression des 15 se remettre à
#   zéro. On tient donc UN chiffre PAR FAMILLE, et c'est un RANG DANS SA FAMILLE (0 = le premier de la famille),
#   jamais un index de table.
#
# ⚠ POURQUOI UN FICHIER À PART, ET NON UNE CLÉ DE PLUS DANS `reglages_puzzle.cfg` (le choix du curseur) — le
#   brief B4 demande « une sauvegarde de progression propre à ce jeu, ISOLÉE ». Deux choses de nature différente
#   y gagnent : un réglage de confort (le curseur) s'efface sans conséquence, une progression EFFACÉE reprend un
#   tableau gagné à l'enfant. Les séparer, c'est pouvoir remettre l'une à zéro sans toucher l'autre.
#
# ⚠ ET L'ISOLATION ENTRE JEUX EST DÉJÀ TENUE PAR `user://` : ce dossier est celui du projet « Le jeu des
#   puzzles » et de lui seul (son `config/name` le nomme).
#
# ⚠ UN FICHIER ABSENT, ILLISIBLE OU FARFELU NE BLOQUE JAMAIS LE JEU : on rend 0 pour CHAQUE famille (« seul le
#   premier tableau de la famille »), qui est exactement l'état du premier lancement (§23 quater).
#
# ⚠ LA PROGRESSION NE REDESCEND PAS : `noter_victoire` prend le MAXIMUM, famille par famille.
#
# ============================================================================================================
# ⚠⚠ LA MIGRATION — CE QUE FABRICE A DÉBLOQUÉ NE DOIT RIEN PERDRE (§23 quater, exigence explicite)
# ============================================================================================================
# Sur son poste, `progression_puzzle.cfg` porte aujourd'hui `[progression] plus_haut_atteint = k`, où `k` est un
# index de la table d'AVANT B15 — donc forcément l'un des cinq tableaux à 15 pièces (les seuls qui existaient).
# `_lire()` le transforme, la PREMIÈRE fois qu'il le rencontre, en `[familles] 15pieces = k` — et comme la
# famille « 15 pièces » liste ses tableaux dans l'ordre 0, 1, 2, 3, 4, l'index de table k EST son rang : la
# valeur est reportée telle quelle, sans arithmétique à laquelle se tromper. La famille « 4 pièces » démarre à 0.
#
# ⚠ LA MIGRATION EST **IDEMPOTENTE ET NON DESTRUCTIVE**, et les deux comptent :
#   ① elle ne s'applique QUE si la clé de famille est absente — une fois `15pieces` écrit, l'ancienne clé ne
#     peut plus écraser une progression plus récente ;
#   ② l'ancienne clé `plus_haut_atteint` est **GARDÉE** dans le fichier. Elle ne sert plus à rien au jeu, et
#     c'est justement pourquoi on ne la supprime pas : elle ne coûte que quelques octets, et elle laisse à
#     Fabrice (et au harnais) la trace de ce qui a été migré. Effacer la seule preuve de l'état d'avant pour
#     faire propre, c'est le geste qu'on ne rattrape pas.
# ============================================================================================================

const FICHIER := "user://progression_puzzle.cfg"
const SECTION := "familles"             # (B15) une clé par famille : `4pieces`, `15pieces`, …
const SECTION_V1 := "progression"       # (B4) l'ancienne section, relue une fois pour la migration
const CLE_V1 := "plus_haut_atteint"     # …et son unique clé


# ------------------------------------------------------------------------------------------------------------
# LA LECTURE DU FICHIER, MIGRATION COMPRISE — une seule porte, pour que la migration ne puisse pas être oubliée
# ------------------------------------------------------------------------------------------------------------
# Rend { "cfg": ConfigFile, "migre": bool, "v1": int }. `v1` vaut −1 s'il n'y avait rien d'ancien à migrer.
static func _lire() -> Dictionary:
	var cfg := ConfigFile.new()
	cfg.load(FICHIER)                    # un fichier absent laisse simplement un ConfigFile vide : on continue
	var v1 := -1
	var migre := false
	if cfg.has_section_key(SECTION_V1, CLE_V1):
		v1 = int(cfg.get_value(SECTION_V1, CLE_V1, 0))
		# LA FAMILLE D'ACCUEIL DE L'ANCIENNE VALEUR EST **LUE DANS LA TABLE**, jamais nommée en dur : c'est la
		# famille du tableau 0 (la ferme), le seul point de départ que l'ancienne progression pouvait avoir.
		var cle := TableauxPuzzle.cle_famille(TableauxPuzzle.famille_de(0))
		if not cfg.has_section_key(SECTION, cle):
			var f := TableauxPuzzle.famille_de(0)
			cfg.set_value(SECTION, cle, clampi(v1, 0, TableauxPuzzle.nombre_dans_famille(f) - 1))
			migre = true
	return {"cfg": cfg, "migre": migre, "v1": v1}


# ⚠ ON RÉÉCRIT LE FICHIER DÈS QUE LA MIGRATION A EU LIEU, et pas seulement à la prochaine victoire : sinon un
#   enfant qui ouvre le jeu, regarde et referme repartirait de l'ancienne clé au lancement suivant. La migration
#   doit être faite UNE fois, et écrite.
static func _garder(d: Dictionary) -> ConfigFile:
	var cfg: ConfigFile = d["cfg"]
	if bool(d["migre"]):
		cfg.save(FICHIER)
		print("[progression] MIGRATION B15 — l'ancien « %s = %d » devient la famille « %s » (rang %d) ; "
			% [CLE_V1, int(d["v1"]), TableauxPuzzle.cle_famille(TableauxPuzzle.famille_de(0)),
				int(cfg.get_value(SECTION, TableauxPuzzle.cle_famille(TableauxPuzzle.famille_de(0)), 0))]
			+ "l'ancienne clé est GARDÉE comme trace, les autres familles démarrent à 0")
	return cfg


# LE PLUS HAUT RANG ATTEINT DANS UNE FAMILLE (0 = seul son premier tableau est ouvert). Plafonné par la taille
# de la famille : si un jour un tableau disparaît, une sauvegarde plus ambitieuse ne pointera pas dans le vide.
static func plus_haut_famille(f: int) -> int:
	var cfg := _garder(_lire())
	var r := int(cfg.get_value(SECTION, TableauxPuzzle.cle_famille(f), 0))
	return clampi(r, 0, TableauxPuzzle.nombre_dans_famille(f) - 1)


# LE PLUS HAUT **TABLEAU** ATTEINT DANS UNE FAMILLE, en index de table — ce que l'accueil clampe.
static func plus_haut_tableau(f: int) -> int:
	return TableauxPuzzle.tableau_de(f, plus_haut_famille(f))


# ⚠ L'ANCIENNE SIGNATURE EST GARDÉE, ET SON SENS EST EXACTEMENT CELUI QU'ELLE AVAIT : « le plus haut index de
#   table atteint parmi les cinq tableaux d'origine ». Comme la famille « 15 pièces » liste ses tableaux dans
#   l'ordre 0…4, son rang EST cet index. Les harnais B4 → B14 la lisent ; ils continuent de mesurer la même
#   chose. Le code VIVANT, lui, passe par les fonctions à famille — c'est écrit ici pour qu'on ne s'y trompe pas.
static func plus_haut() -> int:
	return plus_haut_famille(TableauxPuzzle.famille_de(0))


# CE TABLEAU EST-IL ACCESSIBLE ? Le premier de sa famille l'est toujours ; les autres, une fois atteints.
static func debloque(t: int) -> bool:
	if t < 0 or t >= TableauxPuzzle.nombre():
		return false
	return TableauxPuzzle.rang_dans_famille(t) <= plus_haut_famille(TableauxPuzzle.famille_de(t))


# EXISTE-T-IL UN TABLEAU APRÈS CELUI-CI **DANS SA FAMILLE**, ET A-T-IL DÉJÀ ÉTÉ ATTEINT ? C'est LA question que
# pose la flèche de droite de l'accueil — elle n'est visible que si la réponse est oui (GDD §7.11, §23 quater).
# ⚠ SIGNATURE INCHANGÉE, RÉPONSE RECADRÉE : au dernier tableau d'une famille la réponse est NON, même si la
#   table porte un index de plus — celui-là appartient à une autre famille, et une autre famille ne se déverrouille
#   pas en finissant celle d'à côté.
static func suivant_ouvert(t: int) -> bool:
	var suivant := TableauxPuzzle.suivant_dans_famille(t)
	if suivant < 0:
		return false
	return TableauxPuzzle.rang_dans_famille(suivant) <= plus_haut_famille(TableauxPuzzle.famille_de(t))


# GAGNER UN TABLEAU OUVRE LE SUIVANT **DE SA FAMILLE**. Rend `true` si quelque chose a VRAIMENT été débloqué (le
# jeu l'écrit alors à son journal, et le harnais le relit) ; `false` si le suivant était déjà ouvert, ou s'il
# n'y a pas de suivant dans cette famille.
static func noter_victoire(t: int) -> bool:
	var f := TableauxPuzzle.famille_de(t)
	var vise: int = clampi(TableauxPuzzle.rang_dans_famille(t) + 1, 0,
		TableauxPuzzle.nombre_dans_famille(f) - 1)
	var d := _lire()
	var cfg: ConfigFile = d["cfg"]
	var cle := TableauxPuzzle.cle_famille(f)
	var actuel: int = clampi(int(cfg.get_value(SECTION, cle, 0)), 0,
		TableauxPuzzle.nombre_dans_famille(f) - 1)
	if vise <= actuel:
		_garder(d)                       # rien de neuf à ouvrir, mais une migration en attente doit être écrite
		return false
	cfg.set_value(SECTION, cle, vise)
	return cfg.save(FICHIER) == OK


# ------------------------------------------------------------------------------------------------------------
# CE QUE LE HARNAIS EMPRUNTE ET REND — la partie de Fabrice ne doit jamais payer une mesure
# ------------------------------------------------------------------------------------------------------------
# ⚠⚠ `instantane()` / `restaurer()` RENDENT LE FICHIER **ENTIER**, familles comprises, et c'est ce que le harnais
#   B15 utilise : `plus_haut()` + `poser()` (les deux d'avant) ne connaissent qu'UNE famille, et un harnais qui
#   emprunterait par eux rendrait à Fabrice une progression amputée des autres familles.
static func instantane() -> Dictionary:
	var cfg := ConfigFile.new()
	cfg.load(FICHIER)
	var d: Dictionary = {}
	for f in TableauxPuzzle.nombre_familles():
		var cle := TableauxPuzzle.cle_famille(f)
		d[cle] = int(cfg.get_value(SECTION, cle, 0))
	d[CLE_V1] = int(cfg.get_value(SECTION_V1, CLE_V1, -1))
	return d


static func restaurer(d: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.load(FICHIER)
	for f in TableauxPuzzle.nombre_familles():
		var cle := TableauxPuzzle.cle_famille(f)
		if d.has(cle):
			cfg.set_value(SECTION, cle, clampi(int(d[cle]), 0, TableauxPuzzle.nombre_dans_famille(f) - 1))
	if d.has(CLE_V1) and int(d[CLE_V1]) >= 0:
		cfg.set_value(SECTION_V1, CLE_V1, int(d[CLE_V1]))
	cfg.save(FICHIER)


# REMISE À ZÉRO — « le premier lancement », celui où seul le premier tableau de CHAQUE famille existe.
static func remettre_a_zero() -> void:
	var cfg := ConfigFile.new()
	cfg.load(FICHIER)
	for f in TableauxPuzzle.nombre_familles():
		cfg.set_value(SECTION, TableauxPuzzle.cle_famille(f), 0)
	cfg.save(FICHIER)


# POSER un rang dans une famille nommée.
static func poser_famille(f: int, rang: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load(FICHIER)
	cfg.set_value(SECTION, TableauxPuzzle.cle_famille(f),
		clampi(rang, 0, TableauxPuzzle.nombre_dans_famille(f) - 1))
	cfg.save(FICHIER)


# ⚠ L'ANCIENNE `poser(t)` GARDE SON SENS : elle pose la famille des cinq tableaux d'origine (cf. `plus_haut()`).
static func poser(t: int) -> void:
	poser_famille(TableauxPuzzle.famille_de(0), t)
