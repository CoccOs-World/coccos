# Preuve des icones DEPLACABLES du bureau (REQ_261007, Linux/Windows — souris).
# Monte le VRAI bureau (scenes/bureau.tscn) dans root et lui injecte des evenements
# souris (Viewport.push_input) — aucun appel direct aux fonctions du bureau :
#   ① clic simple sur une icone-dossier  = la fenetre s'ouvre (lancement intact) ;
#   ② clic maintenu + deplacement       = l'icone suit, se pose au relache, NE lance PAS ;
#   ③ petit tremblement sous le seuil   = reste un clic (lance) ;
#   ④ la place est ecrite dans user://config.cfg ;
#   ⑤ un bureau REMONTE (= relance) repose l'icone a la place choisie ;
#   ⑥ un clic simple sur une appli directe change bien de scene (lancement intact).
# Lancement (user:// ISOLE — la sauvegarde de Fabrice n'est jamais touchee) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_icones_deplacables.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const PinConfig := preload("res://scripts/pin_config.gd")

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


func _souris(type: String, ou: Vector2, bouton_tenu := false) -> void:
	var ev: InputEvent
	if type == "mouvement":
		ev = InputEventMouseMotion.new()
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT if bouton_tenu else 0
	else:
		ev = InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = type == "appui"
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT if ev.pressed else 0
	ev.position = ou
	ev.global_position = ou
	root.push_input(ev, true)  # coordonnees du viewport (le headless a une fenetre 64x64)
	await _trames(2)


## Glisse du point `de` au point `a` en plusieurs pas (bouton tenu).
func _glisser(de: Vector2, a: Vector2, pas := 8) -> void:
	await _souris("mouvement", de)
	await _souris("appui", de)
	for i in range(1, pas + 1):
		await _souris("mouvement", de.lerp(a, float(i) / pas), true)
	await _souris("relache", a)


func _monter_bureau() -> Control:
	var bureau: Control = load("res://scenes/bureau.tscn").instantiate()
	root.add_child(bureau)
	current_scene = bureau
	await _trames(6)
	return bureau


func _icones(bureau: Control) -> Array:
	return bureau.get_children().filter(func(n: Node) -> bool: return n.has_signal("deplacee"))


func _centre_bouton(icone: Control) -> Vector2:
	var btn: Control = icone.get("_btn")
	return btn.get_global_rect().get_center()


func _derouler() -> void:
	print("=== PREUVE ICONES DEPLACABLES (bureau) ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	var bureau := await _monter_bureau()
	var icones := _icones(bureau)
	_verifier("bureau monte avec des icones", icones.size() >= 2, "%d icone(s)" % icones.size())
	if icones.size() < 2:
		_fin()
		return
	var dossier: Control = null
	var directe: Control = null
	for ic in icones:
		if ic.est_dossier and dossier == null:
			dossier = ic
		elif not ic.est_dossier and directe == null and not String(ic.id).begins_with("tel:"):
			directe = ic
	_verifier("une icone-dossier trouvee", dossier != null, String(dossier.id) if dossier else "")
	_verifier("une appli directe trouvee", directe != null, String(directe.id) if directe else "")
	_verifier("icones deplacables (mode souris)", dossier.deplacable)

	var lancements := []
	dossier.lancee.connect(func(id: String) -> void: lancements.append(id))

	# ① clic simple = lance (ouvre la fenetre de la categorie)
	var p := _centre_bouton(dossier)
	await _souris("mouvement", p)
	await _souris("appui", p)
	await _souris("relache", p)
	_verifier("① clic simple : lancee emis", lancements.size() == 1, str(lancements))
	_verifier("① clic simple : fenetre ouverte", bureau._fenetres_ouvertes.has(dossier.id))
	for f in bureau._fenetres_ouvertes.values():
		if is_instance_valid(f):
			f.queue_free()
	bureau._fenetres_ouvertes.clear()
	await _trames(3)

	# ② clic maintenu + deplacement = deplace, ne lance pas
	lancements.clear()
	var avant := dossier.position
	p = _centre_bouton(dossier)
	var cible := p + Vector2(420, 160)
	await _souris("mouvement", p)
	await _souris("appui", p)
	for i in range(1, 9):
		await _souris("mouvement", p.lerp(cible, i / 8.0), true)
		if i == 4:
			_verifier("② en vol : icone soulevee (echelle + opacite)",
				dossier.scale.x > 1.0 and dossier.modulate.a < 1.0,
				"echelle %.2f, opacite %.2f" % [dossier.scale.x, dossier.modulate.a])
	await _souris("relache", cible)
	var attendu := avant + (cible - p)
	_verifier("② posee au relache", dossier.position.distance_to(attendu) < 1.5,
		"avant %s → apres %s (attendu %s)" % [avant, dossier.position, attendu])
	_verifier("② glisse : AUCUN lancement", lancements.is_empty(), str(lancements))
	_verifier("② glisse : aucune fenetre ouverte", bureau._fenetres_ouvertes.is_empty())
	_verifier("② posee : retombee (echelle 1, opaque)",
		dossier.scale == Vector2.ONE and dossier.modulate.a == 1.0)

	# ③ tremblement sous le seuil = reste un clic
	lancements.clear()
	var pose := dossier.position
	p = _centre_bouton(dossier)
	await _souris("mouvement", p)
	await _souris("appui", p)
	await _souris("mouvement", p + Vector2(4, 3), true)
	await _souris("relache", p + Vector2(4, 3))
	_verifier("③ tremblement (5 px) : lance quand meme", lancements.size() == 1, str(lancements))
	_verifier("③ tremblement : icone pas bougee", dossier.position == pose)
	for f in bureau._fenetres_ouvertes.values():
		if is_instance_valid(f):
			f.queue_free()
	bureau._fenetres_ouvertes.clear()

	# ④ persistance
	var ranges: Dictionary = PinConfig.lire_option("bureau", "places_icones", {})
	_verifier("④ place ecrite dans config.cfg", ranges.has(dossier.id)
		and Vector2(ranges[dossier.id]).distance_to(pose) < 0.5, str(ranges))

	# ⑤ relance : un nouveau bureau repose l'icone a sa place
	var id_dossier: String = dossier.id
	var id_directe: String = directe.id
	var pos_directe_defaut := directe.position
	bureau.queue_free()
	await _trames(3)
	bureau = await _monter_bureau()
	var rouvert: Control = null
	var directe2: Control = null
	for ic in _icones(bureau):
		if ic.id == id_dossier:
			rouvert = ic
		elif ic.id == id_directe:
			directe2 = ic
	_verifier("⑤ apres relance : icone a la place choisie",
		rouvert != null and rouvert.position.distance_to(pose) < 0.5,
		"%s" % (rouvert.position if rouvert else "absente"))
	_verifier("⑤ apres relance : icone non rangee = place par defaut",
		directe2 != null and directe2.position == pos_directe_defaut)

	# ⑥ clic simple sur l'appli directe = la scene change (lancement reel)
	var scene_avant := current_scene
	p = _centre_bouton(directe2)
	await _souris("mouvement", p)
	await _souris("appui", p)
	await _souris("relache", p)
	await _trames(6)
	_verifier("⑥ appli directe lancee (scene changee)",
		current_scene != scene_avant and current_scene != null,
		"%s → %s" % [id_directe, current_scene.scene_file_path if current_scene else "?"])
	_fin()


func _fin() -> void:
	print("=== BILAN : %d echec(s) ===" % _echecs)
	quit(1 if _echecs > 0 else 0)
