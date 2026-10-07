# Preuve : au DOIGT, un TAP pose la coccinelle du bureau (REQ_261007 android curseur tap).
# Monte le VRAI bureau (scenes/bureau.tscn) dans root et rejoue, par Viewport.push_input,
# la suite d'evenements EXACTE que Godot 4.7.2 livre pour un doigt (core/input/input.cpp :
# le clic souris emule — device DEVICE_ID_EMULATION — part AVANT le ScreenTouch reel) :
#   ① tap sur la verdure     = la coccinelle saute au doigt, pointe decalee comme aux
#                              7 differences (ancre sous le doigt), fleurs a la pointe ;
#   ② glisse au doigt        = elle suit, toujours decalee ;
#   ③ tap au ras du bord haut / droit = decalage fondu : la pointe reste DANS l'ecran et
#                              atteint le bord (sans rattrapage elle sortirait de 31 px) ;
#   ④ souris de bureau       = INCHANGEE : pointe = pointeur, fleurs au pointeur, et le
#                              ScreenTouch emule depuis la souris est ignore.
# Les valeurs attendues sont recalculees ICI depuis les constantes des 7 differences
# (pas lues dans le code teste) : sur main, ① et ② sortent ROUGES.
# Lancement (user:// ISOLE) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_curseur_tap.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

# Coccinelle (taille « moyen ») : image 401x470 affichee a 72 px de haut.
const HOTSPOT := Vector2(0.127, 0.081)   # scripts/effets/curseur.gd HOTSPOTS
const ANCRE := Vector2(0.533, 0.594)     # sept_differences.gd CURSEURS « Coccinelle » ancre
const TAILLE := Vector2(72.0 * 401.0 / 470.0, 72.0)
const TOL := 0.6

var _echecs := 0


func _verifier(libelle: String, vrai: bool, detail: String = "") -> void:
	print("  %s %s%s" % ["ok   " if vrai else "ECHEC", libelle, (" — " + detail) if detail != "" else ""])
	if not vrai:
		_echecs += 1


func _initialize() -> void:
	_derouler.call_deferred()


func _trames(n: int) -> void:
	for i in n:
		await process_frame


func _pousser(ev: InputEvent) -> void:
	root.push_input(ev, true)  # coordonnees du viewport (le headless a une fenetre 64x64)


func _clic(ou: Vector2, appui: bool, device: int) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.device = device
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = appui
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if appui else 0
	ev.position = ou
	ev.global_position = ou
	return ev


func _toucher(ou: Vector2, appui: bool, device := 0) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.device = device
	ev.index = 0
	ev.pressed = appui
	ev.position = ou
	return ev


## Un tap au doigt tel que le moteur le livre : clic emule puis ScreenTouch, a l'appui et au relache.
func _tap(ou: Vector2) -> void:
	_pousser(_clic(ou, true, InputEvent.DEVICE_ID_EMULATION))
	_pousser(_toucher(ou, true))
	await _trames(2)
	_pousser(_clic(ou, false, InputEvent.DEVICE_ID_EMULATION))
	_pousser(_toucher(ou, false))
	await _trames(2)


func _attendu(doigt: Vector2, zone: Rect2) -> Vector2:
	var plein := (HOTSPOT - ANCRE) * TAILLE
	var dy := -clampf(doigt.y - zone.position.y, 0.0, -plein.y)
	var dx := -clampf(zone.end.x - doigt.x, 0.0, -plein.x)
	return doigt + Vector2(dx, dy)


func _fleurs(bureau: Node) -> Array:
	var calque: Node2D = bureau.get("_calque_effets")
	return calque.get_children().filter(func(n: Node) -> bool: return n.get_script() != null and str(n.get_script().resource_path).ends_with("fleur.gd"))


func _centre(noeuds: Array) -> Vector2:
	var somme := Vector2.ZERO
	for n in noeuds:
		somme += (n as Node2D).position
	return somme / maxf(1.0, float(noeuds.size()))


func _derouler() -> void:
	print("=== PREUVE CURSEUR AU TAP (bureau, doigt) ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	var bureau: Control = load("res://scenes/bureau.tscn").instantiate()
	root.add_child(bureau)
	current_scene = bureau
	await _trames(6)
	var curseur: Node2D = bureau.get("_curseur")
	var zone: Rect2 = root.get_visible_rect()
	print("  zone = %s ; decalage plein attendu = %s" % [zone, (HOTSPOT - ANCRE) * TAILLE])

	# ① TAP sur la verdure, loin de tout bord, loin de la position de depart du curseur
	var p := Vector2(zone.size.x * 0.5, zone.size.y * 0.55)
	curseur.position = Vector2(20, 20)
	var avant := _fleurs(bureau).size()
	await _tap(p)
	var vise := _attendu(p, zone)
	_verifier("① tap : la coccinelle saute au doigt (pointe decalee)", curseur.position.distance_to(vise) < TOL,
		"doigt %s → pointe %s (attendu %s, ecart doigt→pointe %s)" % [p, curseur.position, vise, curseur.position - p])
	var nouvelles := _fleurs(bureau).slice(avant)
	_verifier("① tap : fleurs autour de la pointe", nouvelles.size() > 0 and _centre(nouvelles).distance_to(vise) < 30.0,
		"%d fleurs, centre %s" % [nouvelles.size(), _centre(nouvelles)])

	# ② GLISSE au doigt : ScreenDrag reel + mouvement souris emule (ignore pour le curseur)
	_pousser(_clic(p, true, InputEvent.DEVICE_ID_EMULATION))
	_pousser(_toucher(p, true))
	var q := p
	for i in 6:
		q += Vector2(-30, 12)
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = q
		drag.relative = Vector2(-30, 12)
		_pousser(drag)
		var mm := InputEventMouseMotion.new()
		mm.device = InputEvent.DEVICE_ID_EMULATION
		mm.position = q
		mm.global_position = q
		mm.relative = Vector2(-30, 12)
		mm.button_mask = MOUSE_BUTTON_MASK_LEFT
		_pousser(mm)
		await _trames(1)
	_verifier("② glisse : la coccinelle suit, decalee", curseur.position.distance_to(_attendu(q, zone)) < TOL,
		"doigt %s → pointe %s (attendu %s)" % [q, curseur.position, _attendu(q, zone)])
	_pousser(_clic(q, false, InputEvent.DEVICE_ID_EMULATION))
	_pousser(_toucher(q, false))
	await _trames(2)

	# ③ TAP au ras du bord haut, puis du bord droit : le decalage fond, la pointe reste dans l'ecran
	var h := Vector2(zone.size.x * 0.3, zone.position.y + 6.0)
	await _tap(h)
	_verifier("③ bord haut : la pointe touche le haut, sans en sortir", curseur.position.distance_to(_attendu(h, zone)) < TOL and curseur.position.y >= zone.position.y,
		"doigt %s → pointe %s (sans rattrapage : y = %.1f)" % [h, curseur.position, h.y + (HOTSPOT.y - ANCRE.y) * TAILLE.y])
	var d := Vector2(zone.end.x - 4.0, zone.size.y * 0.5)
	await _tap(d)
	_verifier("③ bord droit : decalage horizontal fondu", curseur.position.distance_to(_attendu(d, zone)) < TOL and curseur.position.x <= zone.end.x,
		"doigt %s → pointe %s" % [d, curseur.position])

	# ④ SOURIS DE BUREAU : inchangee
	var r := Vector2(zone.size.x * 0.7, zone.size.y * 0.4)
	var mv := InputEventMouseMotion.new()
	mv.position = r
	mv.global_position = r
	mv.relative = Vector2(5, 5)
	_pousser(mv)
	await _trames(2)
	_verifier("④ souris : le curseur est SUR le pointeur (aucun decalage)", curseur.position.distance_to(r) < 0.01, "%s" % curseur.position)
	avant = _fleurs(bureau).size()
	_pousser(_clic(r, true, 0))
	_pousser(_toucher(r, true, InputEvent.DEVICE_ID_EMULATION))  # ce que le moteur emule depuis la souris
	await _trames(2)
	_pousser(_clic(r, false, 0))
	_pousser(_toucher(r, false, InputEvent.DEVICE_ID_EMULATION))
	await _trames(2)
	nouvelles = _fleurs(bureau).slice(avant)
	_verifier("④ souris : clic = curseur immobile, fleurs au pointeur", curseur.position.distance_to(r) < 0.01 and nouvelles.size() > 0 and _centre(nouvelles).distance_to(r) < 30.0,
		"curseur %s, %d fleurs centre %s" % [curseur.position, nouvelles.size(), _centre(nouvelles)])

	print("=== %s (%d echec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(0 if _echecs == 0 else 1)
