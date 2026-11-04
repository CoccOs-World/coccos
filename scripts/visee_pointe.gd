## Visée À LA POINTE pour les jeux natifs (Android, décision Fabrice 07-10) — même
## mécanisme que le bureau (bureau.gd `_viser_a_la_pointe`) : le doigt du joueur déplace le
## curseur, mais c'est le doigt DU CURSEUR qui vise, clique et tape. Le moteur livre chaque
## doigt deux fois, sous le doigt : en clic/mouvement souris émulé (`emulate_mouse_from_touch`)
## et en ScreenTouch/ScreenDrag — en 4.7 les boutons réagissent AUX DEUX. On déplace les deux
## à la pointe AVANT que quiconque les lise (signal `window_input` de la fenêtre racine, émis
## avant `_input` et l'interface).
## La vraie souris du PC (déjà la pointe) et le tactile qu'elle émule sont inchangés.
## EXCEPTION AU DOIGT (Fabrice 04-11, A2) : les CLAVIERS VIRTUELS et les CROIX DE FERMETURE
## (nœuds du groupe `AU_DOIGT`) se prennent au doigt BRUT du joueur, plus à la pointe. Même
## règle que la roue/éteindre du bureau (#224, validée Redmi 22-10) : décidée à l'appui,
## tenue jusqu'au relâché du vrai doigt. Et la pointe ne les prend plus : un appui dont la
## pointe tombe sur une touche ou une croix (doigt ailleurs) ne l'active pas.
## Usage (après la création du curseur) :
##   var visee := ViseePointe.new()
##   visee.curseur = _curseur
##   add_child(visee)   # se débranche seul à la sortie de la scène
## et pour un élément pris au doigt : `noeud.add_to_group(ViseePointe.AU_DOIGT)`.
extends Node

## Groupe des éléments pris au doigt brut (clavier dessiné, croix de fermeture).
const AU_DOIGT := &"au_doigt"

var curseur: Node2D

var _au_doigt := false     # l'appui en cours a été décidé au doigt brut (jusqu'au relâché)
var _neutralises: Array = []  # [bouton, filtre d'origine] écartés de la pointe pendant l'appui


func _enter_tree() -> void:
	get_tree().root.window_input.connect(_viser_a_la_pointe)


func _exit_tree() -> void:
	get_tree().root.window_input.disconnect(_viser_a_la_pointe)
	rendre(_neutralises)


func _viser_a_la_pointe(event: InputEvent) -> void:
	if curseur == null:
		return
	var souris_du_doigt: bool = (event is InputEventMouseButton or event is InputEventMouseMotion) \
			and event.device == InputEvent.DEVICE_ID_EMULATION
	var vrai_doigt: bool = (event is InputEventScreenTouch or event is InputEventScreenDrag) \
			and event.device != InputEvent.DEVICE_ID_EMULATION
	if not (souris_du_doigt or vrai_doigt):
		return
	var appui: bool = event is InputEventMouseButton or event is InputEventScreenTouch
	if appui and event.pressed:
		_au_doigt = sous_le_doigt(get_tree(), event.position)
	var relache_du_doigt: bool = event is InputEventScreenTouch and not event.pressed
	if _au_doigt:
		# Position BRUTE conservée : la touche / la croix sous le doigt reçoit le tap. Le
		# vrai doigt se relâche en dernier (le moteur livre d'abord le clic émulé).
		if relache_du_doigt:
			_au_doigt = false
		return
	var pointe: Vector2 = _pointe_fenetre(event.position)
	if appui and event.pressed:
		neutraliser(get_tree(), pointe, _neutralises)
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		event.relative = pointe - _pointe_fenetre(event.position - event.relative)
	event.position = pointe
	if event is InputEventMouse:
		event.global_position = pointe
	if relache_du_doigt:
		rendre(_neutralises)


## Pointe pour un doigt, en coordonnées de la FENÊTRE (l'étirement vers le viewport vient après).
func _pointe_fenetre(doigt: Vector2) -> Vector2:
	var vers_fenetre: Transform2D = get_tree().root.get_final_transform()
	var dans_viewport: Vector2 = vers_fenetre.affine_inverse() * doigt
	return vers_fenetre * curseur.pointe_pour_doigt(dans_viewport, get_viewport().get_visible_rect())


## Le doigt BRUT (coordonnées de la fenêtre) tombe-t-il sur un élément du groupe AU_DOIGT ?
## (partagé avec le bureau)
static func sous_le_doigt(arbre: SceneTree, doigt_fenetre: Vector2) -> bool:
	var point: Vector2 = arbre.root.get_final_transform().affine_inverse() * doigt_fenetre
	for noeud in arbre.get_nodes_in_group(AU_DOIGT):
		if noeud is Control and noeud.is_visible_in_tree() and noeud.get_global_rect().has_point(point):
			return true
	return false


## La pointe (coordonnées de la fenêtre) tombe sur un élément AU_DOIGT : ses boutons sous la
## pointe deviennent transparents à la souris le temps de l'appui → le tap passe au parent
## (le panneau du clavier l'avale, la barre de la fenêtre l'ignore) sans rien activer.
static func neutraliser(arbre: SceneTree, pointe_fenetre: Vector2, liste: Array) -> void:
	var point: Vector2 = arbre.root.get_final_transform().affine_inverse() * pointe_fenetre
	for noeud in arbre.get_nodes_in_group(AU_DOIGT):
		if noeud is Control and noeud.is_visible_in_tree() and noeud.get_global_rect().has_point(point):
			_neutraliser_boutons(noeud, point, liste)


static func _neutraliser_boutons(noeud: Control, point: Vector2, liste: Array) -> void:
	if noeud is BaseButton and noeud.mouse_filter != Control.MOUSE_FILTER_IGNORE \
			and noeud.get_global_rect().has_point(point):
		liste.append([noeud, noeud.mouse_filter])
		noeud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for enfant in noeud.get_children():
		if enfant is Control:
			_neutraliser_boutons(enfant, point, liste)


## Rend aux boutons neutralisés leur filtre d'origine (au relâché du vrai doigt).
static func rendre(liste: Array) -> void:
	for paire in liste:
		if is_instance_valid(paire[0]):
			paire[0].mouse_filter = paire[1]
	liste.clear()
