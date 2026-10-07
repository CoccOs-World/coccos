# Injecteur de DOIGT par le vrai chemin du moteur (preuves headless du bureau).
# Input.parse_input_event(ScreenTouch/ScreenDrag) en coordonnees FENETRE : c'est le moteur
# lui-meme qui fabrique le clic souris emule (emulate_mouse_from_touch, DEVICE_ID_EMULATION),
# le livre a la fenetre racine (signal window_input, puis _input, puis l'interface) AVANT
# le tactile — exactement comme sur Android. Aucun evenement souris n'est forge a la main.
# Toutes les positions passees ici sont en coordonnees du VIEWPORT (1280x1280 en headless,
# fenetre 64x64) : la conversion vers la fenetre est faite ici.
extends RefCounted


static func _vers_fenetre(racine: Window, p: Vector2) -> Vector2:
	return racine.get_final_transform() * p


static func toucher(racine: Window, doigt: Vector2, appui: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = appui
	ev.position = _vers_fenetre(racine, doigt)
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


static func glisser(racine: Window, de: Vector2, a: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = 0
	ev.position = _vers_fenetre(racine, a)
	ev.relative = _vers_fenetre(racine, a) - _vers_fenetre(racine, de)
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


## Vraie souris de PC (device 0) — le moteur en emule lui-meme le tactile.
static func souris_bouton(racine: Window, ou: Vector2, appui: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = appui
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if appui else 0
	ev.position = _vers_fenetre(racine, ou)
	ev.global_position = ev.position
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


static func souris_mouvement(racine: Window, de: Vector2, a: Vector2, tenu := false) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = _vers_fenetre(racine, a)
	ev.global_position = ev.position
	ev.relative = ev.position - _vers_fenetre(racine, de)
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if tenu else 0
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


## Ou poser le doigt pour que la POINTE du curseur tombe sur `cible` : inverse de
## curseur.pointe_pour_doigt (separable par axe, croissante) par dichotomie.
static func doigt_pour_pointe(curseur: Node2D, cible: Vector2, zone: Rect2) -> Vector2:
	var doigt := cible
	for axe in 2:
		var bas := cible[axe] - 400.0
		var haut := cible[axe] + 400.0
		for i in 50:
			var milieu := (bas + haut) * 0.5
			var essai := cible
			essai[axe] = milieu
			if curseur.pointe_pour_doigt(essai, zone)[axe] < cible[axe]:
				bas = milieu
			else:
				haut = milieu
		doigt[axe] = haut
	return doigt
