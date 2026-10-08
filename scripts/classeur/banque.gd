## Banque du classeur — le modèle « vignettes taguées » (décision Freddy
## 2026-07-07) : une VIGNETTE (pictogramme + mot) est indépendante et porte des
## TAGS de catégories — la même vignette « je veux » sert toutes les plaquettes.
## Une CATÉGORIE = une plaquette au format 6×4 (24 emplacements max), qui
## n'affiche QUE les vignettes attribuées (pas de cases blanches).
##
## Stockage (user://classeur/) :
##   banque.cfg            les données (ConfigFile)
##   pictos/<id>.png       l'image de chaque vignette
## Sections du .cfg :
##   [banque]        prochain_id, categories (ordre d'affichage), sources_importees
##   [vignette_<id>] mot, categories (tags), positions {categorie: index 0-23}
##
## Import TLAb : chaque planche (res:// + user://) dont la catégorie n'existe
## pas encore est convertie — vignettes DÉDUPLIQUÉES par empreinte (image+mot) :
## le « je » commun aux 6 planches devient UNE vignette taguée 6 fois, chacune
## avec sa position d'origine (fidélité école conservée).
extends RefCounted

const PlancheTlab := preload("res://scripts/classeur/planche_tlab.gd")

const CHEMIN_BANQUE := "user://classeur/banque.cfg"
const DOSSIER_PICTOS := "user://classeur/pictos"

## Géométrie de plaquette (repère page A4 paysage 297×210, mesurée sur TLAb)
const COLONNES := 6
const RANGEES := 4
const ORIGINE := Vector2(5.0, 11.0)
const PAS := Vector2(48.67, 48.5)
const CELLULE := Vector2(43.67, 43.5)

var _cfg := ConfigFile.new()
var _textures := {}  # id → ImageTexture (cache)


## Charge la banque (et importe les planches TLAb nouvelles au passage).
static func charger() -> RefCounted:
	var banque = load("res://scripts/classeur/banque.gd").new()
	DirAccess.make_dir_recursive_absolute(DOSSIER_PICTOS)
	banque._cfg.load(CHEMIN_BANQUE)  # absent au premier lancement : banque vide
	# AVANT l'import : une vignette complétée ici dédoublonne ensuite celles
	# d'une planche encore jamais importée (même empreinte image+mot)
	banque.migrer_mots_manquants()
	banque.importer_planches_tlab()
	return banque


func sauver() -> void:
	_cfg.save(CHEMIN_BANQUE)


# --- Catégories (une catégorie = une plaquette) --------------------------------

func categories() -> Array:
	return Array(_cfg.get_value("banque", "categories", PackedStringArray()))


func creer_categorie(nom: String) -> bool:
	nom = nom.strip_edges()
	if nom == "" or nom in categories():
		return false
	var liste := categories()
	liste.append(nom)
	_cfg.set_value("banque", "categories", PackedStringArray(liste))
	sauver()
	return true


## Supprime la plaquette — les vignettes ne sont PAS détruites, juste détaguées.
func supprimer_categorie(nom: String) -> void:
	var liste := categories()
	liste.erase(nom)
	_cfg.set_value("banque", "categories", PackedStringArray(liste))
	for id in ids_vignettes():
		var section := "vignette_%d" % id
		var tags: Array = Array(_cfg.get_value(section, "categories", PackedStringArray()))
		if nom in tags:
			tags.erase(nom)
			_cfg.set_value(section, "categories", PackedStringArray(tags))
			var positions: Dictionary = _cfg.get_value(section, "positions", {})
			positions.erase(nom)
			_cfg.set_value(section, "positions", positions)
	sauver()


# --- Vignettes -------------------------------------------------------------------

func ids_vignettes() -> Array:
	var ids := []
	for section in _cfg.get_sections():
		if section.begins_with("vignette_"):
			ids.append(section.trim_prefix("vignette_").to_int())
	ids.sort()
	return ids


func mot(id: int) -> String:
	return _cfg.get_value("vignette_%d" % id, "mot", "")


func tags(id: int) -> Array:
	return Array(_cfg.get_value("vignette_%d" % id, "categories", PackedStringArray()))


func texture(id: int) -> ImageTexture:
	if not _textures.has(id):
		var image := Image.new()
		if image.load("%s/%d.png" % [DOSSIER_PICTOS, id]) != OK:
			return null
		_textures[id] = ImageTexture.create_from_image(image)
	return _textures[id]


## Crée une vignette : l'image est copiée dans la banque, les tags posés,
## une position libre attribuée dans chaque catégorie. Renvoie l'id.
func creer_vignette(mot_vignette: String, image: Image, categories_vignette: Array) -> int:
	var id: int = _cfg.get_value("banque", "prochain_id", 1)
	_cfg.set_value("banque", "prochain_id", id + 1)
	image.save_png("%s/%d.png" % [DOSSIER_PICTOS, id])
	# Places libres calculées AVANT d'enregistrer les tags — sinon la vignette
	# se verrait elle-même (index 0 par défaut) et se placerait un cran trop loin
	var positions := {}
	for categorie in categories_vignette:
		positions[categorie] = _premiere_place_libre(categorie)
	var section := "vignette_%d" % id
	_cfg.set_value(section, "mot", mot_vignette.strip_edges())
	_cfg.set_value(section, "categories", PackedStringArray(categories_vignette))
	_cfg.set_value(section, "positions", positions)
	sauver()
	return id


func supprimer_vignette(id: int) -> void:
	_cfg.erase_section("vignette_%d" % id)
	DirAccess.remove_absolute("%s/%d.png" % [DOSSIER_PICTOS, id])
	_textures.erase(id)
	sauver()


## Change les tags d'une vignette (positions attribuées/retirées en conséquence).
func retaguer(id: int, nouveaux: Array) -> void:
	var section := "vignette_%d" % id
	var positions: Dictionary = _cfg.get_value(section, "positions", {})
	for categorie in positions.keys().duplicate():
		if not categorie in nouveaux:
			positions.erase(categorie)
	for categorie in nouveaux:
		if not positions.has(categorie):
			positions[categorie] = _premiere_place_libre(categorie)
	_cfg.set_value(section, "categories", PackedStringArray(nouveaux))
	_cfg.set_value(section, "positions", positions)
	sauver()


func renommer(id: int, nouveau_mot: String) -> void:
	_cfg.set_value("vignette_%d" % id, "mot", nouveau_mot.strip_edges())
	sauver()


# --- La plaquette d'une catégorie -------------------------------------------------

## Les vignettes d'une catégorie : [{id, mot, texture, index}] triées par index.
func plaquette(categorie: String) -> Array:
	var liste := []
	for id in ids_vignettes():
		if categorie in tags(id):
			var positions: Dictionary = _cfg.get_value("vignette_%d" % id, "positions", {})
			liste.append({
				"id": id, "mot": mot(id), "texture": texture(id),
				"index": int(positions.get(categorie, 0)),
			})
	liste.sort_custom(func(a, b): return a["index"] < b["index"])
	return liste


## Pose la vignette à cet emplacement ; s'il est occupé, les deux s'échangent.
func placer(id: int, categorie: String, index: int) -> void:
	index = clampi(index, 0, COLONNES * RANGEES - 1)
	var ancien: int = _position(id, categorie)
	for autre in ids_vignettes():
		if autre != id and categorie in tags(autre) and _position(autre, categorie) == index:
			_poser_position(autre, categorie, ancien)
	_poser_position(id, categorie, index)
	sauver()


## Coordonnées (repère page) de l'emplacement n° index.
static func position_emplacement(index: int) -> Vector2:
	return ORIGINE + Vector2(float(index % COLONNES), float(index / COLONNES)) * PAS


## L'emplacement le plus proche d'un point (repère page).
static func emplacement_proche(point: Vector2) -> int:
	var colonne := clampi(int(round((point.x - ORIGINE.x) / PAS.x)), 0, COLONNES - 1)
	var rangee := clampi(int(round((point.y - ORIGINE.y) / PAS.y)), 0, RANGEES - 1)
	return rangee * COLONNES + colonne


func _position(id: int, categorie: String) -> int:
	return int(_cfg.get_value("vignette_%d" % id, "positions", {}).get(categorie, 0))


func _poser_position(id: int, categorie: String, index: int) -> void:
	var section := "vignette_%d" % id
	var positions: Dictionary = _cfg.get_value(section, "positions", {})
	positions[categorie] = index
	_cfg.set_value(section, "positions", positions)


func _premiere_place_libre(categorie: String) -> int:
	var occupees := {}
	for entree in plaquette(categorie):
		occupees[entree["index"]] = true
	for i in COLONNES * RANGEES:
		if not occupees.has(i):
			return i
	return 0


# --- Import des planches TLAb -------------------------------------------------------

## Import EXPLICITE d'un fichier TLAb choisi par l'adulte (bouton des réglages).
## Copie le fichier dans le dépôt user://classeur/ puis le convertit — y compris
## si la planche avait déjà été importée puis sa catégorie supprimée (la demande
## de l'adulte prime). Refuse seulement si la catégorie existe encore.
## Renvoie "" si tout va bien, sinon la clé du message d'erreur.
func importer_fichier(chemin: String) -> String:
	var nom := chemin.get_file().get_basename()
	if nom in categories():
		return "classeur_import_existe"
	if DirAccess.copy_absolute(chemin, "user://classeur/" + chemin.get_file()) != OK:
		return "classeur_import_illisible"
	var sources: Array = Array(_cfg.get_value("banque", "sources_importees", PackedStringArray()))
	sources.erase(nom)  # ré-import explicite autorisé
	_cfg.set_value("banque", "sources_importees", PackedStringArray(sources))
	importer_planches_tlab()
	return "" if nom in categories() else "classeur_import_illisible"

## Convertit toute planche TLAb jamais importée (une planche déjà importée ne
## revient pas, même si l'adulte a supprimé sa catégorie depuis — sa décision
## tient). Déduplication par empreinte (md5 de l'image + mot en minuscules).
func importer_planches_tlab() -> void:
	var sources: Array = Array(_cfg.get_value("banque", "sources_importees", PackedStringArray()))
	# Empreintes calculées SEULEMENT s'il y a du nouveau (les hacher à chaque
	# ouverture du classeur coûterait 70+ chargements d'images pour rien)
	var empreintes := {}
	var empreintes_pretes := false
	var rien_de_neuf := true
	for nom in PlancheTlab.lister_planches():
		if nom in sources or nom in categories():
			continue
		rien_de_neuf = false
		if not empreintes_pretes:
			empreintes = _empreintes_existantes()
			empreintes_pretes = true
		sources.append(nom)
		_cfg.set_value("banque", "sources_importees", PackedStringArray(sources))
		var planche: Dictionary = PlancheTlab.charger(PlancheTlab.lister_planches()[nom])
		if planche.is_empty():
			continue
		creer_categorie(nom)
		for cellule in planche["cellules"]:
			if cellule["texture"] == null:
				continue
			var image: Image = (cellule["texture"] as ImageTexture).get_image()
			var index: int = emplacement_proche(cellule["position"])
			var empreinte := _empreinte(image, cellule["libelle"])
			if empreintes.has(empreinte):
				# La vignette existe déjà : on la tague et on la place
				var id: int = empreintes[empreinte]
				if not nom in tags(id):
					retaguer(id, tags(id) + [nom])
				_poser_position(id, nom, index)
			else:
				var id := creer_vignette(cellule["libelle"], image, [nom])
				_poser_position(id, nom, index)
				empreintes[empreinte] = id
	if not rien_de_neuf:
		sauver()


## Migration des classeurs déjà remplis (2026-10-08) : une planche n'est importée
## qu'UNE fois, donc un libellé corrigé dans les .tlab (« serviette », ARASAAC
## 2566) n'atteignait jamais un appareil qui avait déjà son classeur.
## Remplit le mot des vignettes au mot VIDE, retrouvées par leur IMAGE (md5 des
## pixels) dans les planches de leurs propres catégories. Ne fait que remplir : un mot présent n'est jamais
## touché, ni les tags, ni les positions, ni les images. Si une même image porte
## plusieurs mots selon les planches, rien n'est deviné.
## Passe UNE fois par appareil (repère [banque] migration_mots) : un mot que
## l'adulte viderait ensuite volontairement ne revient pas au démarrage suivant.
const VERSION_MIGRATION_MOTS := 1

func migrer_mots_manquants() -> void:
	if int(_cfg.get_value("banque", "migration_mots", 0)) >= VERSION_MIGRATION_MOTS:
		return
	var vides := []
	for id in ids_vignettes():
		if mot(id) == "":
			vides.append(id)
	if not vides.is_empty():
		# Mots des planches par image, planche par planche : nom → { md5: { mot: true } }
		var mots_par_planche := {}
		var planches := PlancheTlab.lister_planches()
		for nom in planches:
			var mots_par_image := {}
			var planche: Dictionary = PlancheTlab.charger(planches[nom])
			for cellule in planche.get("cellules", []):
				if cellule["texture"] == null or cellule["libelle"] == "":
					continue
				var cle := _md5_pixels((cellule["texture"] as ImageTexture).get_image())
				if not mots_par_image.has(cle):
					mots_par_image[cle] = {}
				mots_par_image[cle][cellule["libelle"]] = true
			mots_par_planche[nom] = mots_par_image
		for id in vides:
			var image := Image.new()
			if image.load("%s/%d.png" % [DOSSIER_PICTOS, id]) != OK:
				continue
			var cle := _md5_pixels(image)
			# Seules les planches d'où vient la vignette (ses tags) font foi : la
			# même image peut porter un autre mot ailleurs (« quelle couleur? » de
			# coloriage n'est pas la vignette sans mot de peinture)
			var mots := {}
			for categorie in tags(id):
				for un_mot in mots_par_planche.get(categorie, {}).get(cle, {}):
					mots[un_mot] = true
			if mots.size() == 1:
				_cfg.set_value("vignette_%d" % id, "mot", mots.keys()[0])
	_cfg.set_value("banque", "migration_mots", VERSION_MIGRATION_MOTS)
	sauver()


static func _md5_pixels(image: Image) -> String:
	var contexte := HashingContext.new()
	contexte.start(HashingContext.HASH_MD5)
	var pixels := image.get_data()
	if not pixels.is_empty():
		contexte.update(pixels)
	return contexte.finish().hex_encode()


func _empreintes_existantes() -> Dictionary:
	var empreintes := {}
	for id in ids_vignettes():
		var image := Image.new()
		if image.load("%s/%d.png" % [DOSSIER_PICTOS, id]) == OK:
			empreintes[_empreinte(image, mot(id))] = id
	return empreintes


static func _empreinte(image: Image, mot_vignette: String) -> String:
	var contexte := HashingContext.new()
	contexte.start(HashingContext.HASH_MD5)
	var pixels := image.get_data()
	if not pixels.is_empty():
		contexte.update(pixels)
	var octets := ("|" + mot_vignette.to_lower()).to_utf8_buffer()  # jamais vide
	contexte.update(octets)
	return contexte.finish().hex_encode()
