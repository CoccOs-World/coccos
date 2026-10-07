## Visée À LA POINTE pour les jeux natifs (Android, décision Fabrice 07-10) — même
## mécanisme que le bureau (bureau.gd `_viser_a_la_pointe`) : le doigt du joueur déplace le
## curseur, mais c'est le doigt DU CURSEUR qui vise, clique et tape (touches du clavier
## dessiné comprises). Le moteur livre chaque doigt deux fois, sous le doigt : en clic/
## mouvement souris émulé (`emulate_mouse_from_touch`) et en ScreenTouch/ScreenDrag — en 4.7
## les boutons réagissent AUX DEUX. On déplace les deux à la pointe AVANT que quiconque les
## lise (signal `window_input` de la fenêtre racine, émis avant `_input` et l'interface).
## La vraie souris du PC (déjà la pointe) et le tactile qu'elle émule sont inchangés.
## Usage (après la création du curseur) :
##   var visee := ViseePointe.new()
##   visee.curseur = _curseur
##   add_child(visee)   # se débranche seul à la sortie de la scène
extends Node

var curseur: Node2D


func _enter_tree() -> void:
	get_tree().root.window_input.connect(_viser_a_la_pointe)


func _exit_tree() -> void:
	get_tree().root.window_input.disconnect(_viser_a_la_pointe)


func _viser_a_la_pointe(event: InputEvent) -> void:
	if curseur == null:
		return
	var souris_du_doigt: bool = (event is InputEventMouseButton or event is InputEventMouseMotion) \
			and event.device == InputEvent.DEVICE_ID_EMULATION
	var vrai_doigt: bool = (event is InputEventScreenTouch or event is InputEventScreenDrag) \
			and event.device != InputEvent.DEVICE_ID_EMULATION
	if not (souris_du_doigt or vrai_doigt):
		return
	var pointe: Vector2 = _pointe_fenetre(event.position)
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		event.relative = pointe - _pointe_fenetre(event.position - event.relative)
	event.position = pointe
	if event is InputEventMouse:
		event.global_position = pointe


## Pointe pour un doigt, en coordonnées de la FENÊTRE (l'étirement vers le viewport vient après).
func _pointe_fenetre(doigt: Vector2) -> Vector2:
	var vers_fenetre: Transform2D = get_tree().root.get_final_transform()
	var dans_viewport: Vector2 = vers_fenetre.affine_inverse() * doigt
	return vers_fenetre * curseur.pointe_pour_doigt(dans_viewport, get_viewport().get_visible_rect())
