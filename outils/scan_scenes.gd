# Balayage headless de migration : compile tous les scripts GDScript du projet,
# puis MONTE chaque scene de res://scenes/ dans l'arbre (ce qui declenche bien
# _ready() et quelques trames de _process) avant de la liberer.
# Sert de preuve de non-regression lors d'un changement de version du moteur.
#
# Lancement :
#   godot --headless --path . --script res://outils/scan_scenes.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const TRAMES_PAR_SCENE := 8

var _scenes: Array[String] = []
var _index := 0
var _trames := 0
var _courante: Node = null
var _echecs := 0

func _lister(racine: String, extension: String) -> Array[String]:
	var trouves: Array[String] = []
	var a_visiter: Array[String] = [racine]
	while not a_visiter.is_empty():
		var courant: String = a_visiter.pop_back()
		var dossier := DirAccess.open(courant)
		if dossier == null:
			continue
		dossier.list_dir_begin()
		var nom := dossier.get_next()
		while nom != "":
			if not nom.begins_with("."):
				var chemin := courant.path_join(nom)
				if dossier.current_is_dir():
					a_visiter.append(chemin)
				elif nom.get_extension() == extension:
					trouves.append(chemin)
			nom = dossier.get_next()
		dossier.list_dir_end()
	trouves.sort()
	return trouves

func _initialize() -> void:
	# On ne balaye PAS res://outils : recharger le script en cours d'execution
	# avec CACHE_MODE_IGNORE invalide sa propre table d'adresses.
	# (LOGITHÈQUE, 01-10) res://jeux_integres est balaye AU MEME TITRE que res://scripts et
	# res://scenes : c'est la ou vivent les sous-projets freres integres au bureau (le jeu des
	# puzzles, et les autres a venir). Sans cette ligne, un jeu integre entrait dans le bureau
	# SANS JAMAIS passer sous la preuve — la verification serait restee muette sur lui.
	var scripts := _lister("res://scripts", "gd")
	scripts.append_array(_lister("res://jeux_integres", "gd"))
	scripts.sort()
	print("=== SCRIPTS (%d) ===" % scripts.size())
	for chemin in scripts:
		if ResourceLoader.load(chemin, "GDScript", ResourceLoader.CACHE_MODE_IGNORE) == null:
			print("  ECHEC compilation : ", chemin)
			_echecs += 1
		else:
			print("  ok ", chemin)

	_scenes = _lister("res://scenes", "tscn")
	_scenes.append_array(_lister("res://jeux_integres", "tscn"))
	_scenes.sort()
	print("=== SCENES MONTEES DANS L'ARBRE (%d) ===" % _scenes.size())

func _process(_delta: float) -> bool:
	if _courante != null:
		_trames += 1
		if _trames < TRAMES_PAR_SCENE:
			return false
		_courante.free()
		_courante = null
		return false

	if _index >= _scenes.size():
		print("=== BILAN : %d echec(s) ===" % _echecs)
		quit(1 if _echecs > 0 else 0)
		return true

	var chemin := _scenes[_index]
	_index += 1
	_trames = 0
	var paquet: PackedScene = ResourceLoader.load(chemin, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)
	if paquet == null:
		print("  ECHEC chargement : ", chemin)
		_echecs += 1
		return false
	var noeud: Node = paquet.instantiate()
	if noeud == null:
		print("  ECHEC instanciation : ", chemin)
		_echecs += 1
		return false
	root.add_child(noeud)
	_courante = noeud
	print("  ok %s (_ready declenche, %d noeuds)" % [chemin, _compter(noeud)])
	return false

func _compter(noeud: Node) -> int:
	var total := 1
	for enfant in noeud.get_children():
		total += _compter(enfant)
	return total
