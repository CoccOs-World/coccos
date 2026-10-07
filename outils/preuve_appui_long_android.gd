# Preuve de l'APPUI LONG au doigt sur le bureau (REQ_261007 android_appui_long_icone_menu).
# Monte le VRAI bureau (scenes/bureau.tscn) en MODE TACTILE (config isolee) et lui injecte
# des evenements de doigt tels qu'Android les livre : clic souris EMULE (DEVICE_ID_EMULATION)
# puis ScreenTouch / ScreenDrag — aucun appel direct aux fonctions du bureau :
#   A0 doigt qui derive SANS appui long = l'icone ne bouge pas (un tap reste un tap) ;
#   A1 appui long SUR une icone = elle se souleve, suit le doigt, se pose, place retenue,
#      sans lancement ni etoiles ;
#   A2 appui long SUR un jeu puis depose sur un dossier = il y entre ;
#   B0 option parent DECOCHEE (defaut) : appui long a cote = etoiles (inchange), pas de bulle ;
#   B1 option COCHEE : appui long a cote = bulle de menu VIDE (sans etoiles) ; tap dedans = elle
#      reste ; tap en dehors = elle disparait ; appui long sur la barre = etoiles ; sur une icone = soulevee ;
#   A3 tap court sur une appli directe = la scene change (lancement intact).
# Lancement (user:// ISOLE — la sauvegarde de Fabrice n'est jamais touchee) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_appui_long_android.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const PinConfig := preload("res://scripts/pin_config.gd")
const Registre := preload("res://scripts/registre_jeux.gd")
const Anneau := preload("res://scripts/effets/anneau.gd")

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


## Un geste de doigt comme sur Android : l'evenement souris emule d'abord, puis le tactile.
func _doigt(type: String, ou: Vector2) -> void:
	var souris: InputEvent
	var tactile: InputEvent
	if type == "glisse":
		souris = InputEventMouseMotion.new()
		souris.button_mask = MOUSE_BUTTON_MASK_LEFT
		tactile = InputEventScreenDrag.new()
	else:
		souris = InputEventMouseButton.new()
		souris.button_index = MOUSE_BUTTON_LEFT
		souris.pressed = type == "pose"
		souris.button_mask = MOUSE_BUTTON_MASK_LEFT if souris.pressed else 0
		tactile = InputEventScreenTouch.new()
		tactile.pressed = type == "pose"
	souris.device = InputEvent.DEVICE_ID_EMULATION
	souris.position = ou
	souris.global_position = ou
	tactile.index = 0
	tactile.position = ou
	root.push_input(souris, true)  # coordonnees du viewport (le headless a une fenetre 64x64)
	root.push_input(tactile, true)
	await _trames(2)


func _tap(ou: Vector2) -> void:
	await _doigt("pose", ou)
	await _doigt("leve", ou)


## Doigt pose et tenu immobile au-dela de la duree d'appui long (0,6 s).
func _appui_long(ou: Vector2) -> void:
	await _doigt("pose", ou)
	await create_timer(0.8).timeout
	await _trames(2)


func _monter_bureau() -> Control:
	var bureau: Control = load("res://scenes/bureau.tscn").instantiate()
	root.add_child(bureau)
	current_scene = bureau
	await _trames(6)
	return bureau


func _demonter(bureau: Control) -> void:
	bureau.queue_free()
	await _trames(3)


func _icones(bureau: Control) -> Array:
	return bureau.get_children().filter(func(n: Node) -> bool: return n.has_signal("deplacee"))


func _icone(bureau: Control, id: String) -> Control:
	for ic in _icones(bureau):
		if ic.id == id:
			return ic
	return null


func _centre_bouton(icone: Control) -> Vector2:
	var btn: Control = icone.get("_btn")
	return btn.get_global_rect().get_center()


func _anneaux(bureau: Control) -> int:
	return bureau.get("_calque_effets").get_children().filter(
		func(n: Node) -> bool: return n.get_script() == Anneau).size()


## Un point du bureau NU : hors de toute icone, au-dessus de la barre, loin des bords.
func _point_libre(bureau: Control) -> Vector2:
	var ecran: Vector2 = bureau.get_viewport().get_visible_rect().size
	var bas: float = ecran.y - bureau.hauteur_barre - 40.0
	var y := 60.0
	while y < bas:
		var x := ecran.x - 80.0
		while x > 60.0:
			var p := Vector2(x, y)
			var libre := true
			for ic in _icones(bureau):
				if ic.get_global_rect().grow(30).has_point(p):
					libre = false
			if libre:
				return p
			x -= 40.0
		y += 40.0
	return Vector2(-1, -1)


func _derouler() -> void:
	print("=== PREUVE APPUI LONG AU DOIGT (bureau, mode tactile) ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	PinConfig.ecrire_option("interface", "mode_tactile", true)
	var bureau := await _monter_bureau()
	var icones := _icones(bureau)
	var dossier: Control = _icone(bureau, "clavier")
	var jeu: Control = null
	for ic in icones:
		if not ic.est_dossier and not Registre.appli(ic.id).is_empty() and Registre.appli(ic.id).has("scene"):
			jeu = ic
			break
	_verifier("bureau monte : dossier « clavier » + un jeu direct", dossier != null and jeu != null,
		str(icones.map(func(i: Control) -> String: return i.id)))
	if dossier == null or jeu == null:
		_fin()
		return
	_verifier("mode tactile : icones deplacables par appui long seulement",
		jeu.deplacable and jeu.par_appui_long)
	var id_jeu: String = jeu.id
	var lancements := []
	jeu.lancee.connect(func(id: String) -> void: lancements.append(id))

	# A0 doigt qui derive sans appui long : un tap reste un tap, l'icone ne bouge pas
	var avant := jeu.position
	var p := _centre_bouton(jeu)
	await _doigt("pose", p)
	for i in range(1, 7):
		await _doigt("glisse", p + Vector2(15 * i, 6 * i))
	await _doigt("leve", p + Vector2(90, 36))
	_verifier("A0 doigt qui derive (sans appui long) : icone immobile", jeu.position == avant,
		"%s → %s" % [avant, jeu.position])
	_verifier("A0 : icone pas soulevee", jeu.scale == Vector2.ONE)

	# A1 appui long SUR l'icone : soulevee, suit le doigt, posee, retenue, sans lancement ni etoiles
	lancements.clear()
	var anneaux_avant := _anneaux(bureau)
	p = _centre_bouton(jeu)
	await _appui_long(p)
	_verifier("A1 appui long sur l'icone : elle se souleve (echelle + opacite)",
		jeu.scale.x > 1.0 and jeu.modulate.a < 1.0,
		"echelle %.2f, opacite %.2f" % [jeu.scale.x, jeu.modulate.a])
	_verifier("A1 : pas d'etoiles sur une icone", _anneaux(bureau) == anneaux_avant)
	var libre := _point_libre(bureau)
	var cible := p + Vector2(0, 0).lerp(libre - p, 0.5)
	for i in range(1, 9):
		await _doigt("glisse", p.lerp(cible, i / 8.0))
	await _doigt("leve", cible)
	var attendu := avant + (cible - p)
	_verifier("A1 posee sous le doigt au releve", jeu.position.distance_to(attendu) < 1.5,
		"avant %s → apres %s (attendu %s)" % [avant, jeu.position, attendu])
	_verifier("A1 : AUCUN lancement", lancements.is_empty(), str(lancements))
	_verifier("A1 : retombee (echelle 1, opaque)", jeu.scale == Vector2.ONE and jeu.modulate.a == 1.0)
	var ranges: Dictionary = PinConfig.lire_option("bureau", "places_icones", {})
	_verifier("A1 : place retenue dans config.cfg [bureau] places_icones",
		ranges.has(id_jeu) and Vector2(ranges[id_jeu]).distance_to(jeu.position) < 0.5, str(ranges))

	# B0 option decochee (defaut) : appui long a cote = etoiles, pas de bulle
	libre = _point_libre(bureau)
	anneaux_avant = _anneaux(bureau)
	await _appui_long(libre)
	_verifier("B0 option decochee : appui long a cote = etoiles (inchange)",
		_anneaux(bureau) > anneaux_avant, "point %s" % libre)
	_verifier("B0 : aucune bulle", bureau.get("_bulle") == null)
	await _doigt("leve", libre)

	# A2 appui long sur le jeu puis depose sur le dossier « clavier » = il y entre
	p = _centre_bouton(jeu)
	await _appui_long(p)
	cible = _centre_bouton(dossier)
	for i in range(1, 9):
		await _doigt("glisse", p.lerp(cible, i / 8.0))
		if i == 8:
			_verifier("A2 en vol au-dessus du dossier : il se signale (grossit)", dossier.scale.x > 1.0)
	await _doigt("leve", cible)
	await _trames(4)
	_verifier("A2 depose sur le dossier : rangee dans « clavier »",
		PinConfig.lire_option("bureau_rangement", id_jeu, null) == "clavier",
		"[bureau_rangement] %s = %s" % [id_jeu, PinConfig.lire_option("bureau_rangement", id_jeu, null)])
	_verifier("A2 : le jeu a quitte le bureau", _icone(bureau, id_jeu) == null)
	await _demonter(bureau)

	# B1 option COCHEE par le parent
	PinConfig.ecrire_option("interface", "menu_contextuel_bureau", true)
	bureau = await _monter_bureau()
	libre = _point_libre(bureau)
	anneaux_avant = _anneaux(bureau)
	await _appui_long(libre)
	var voile: Control = bureau.get("_bulle")
	_verifier("B1 option cochee : appui long a cote = bulle de menu ouverte", voile != null)
	var bulle: Control = voile.get_child(0) if voile != null and voile.get_child_count() > 0 else null
	_verifier("B1 : bulle visible a l'ecran", bulle != null and bulle.is_visible_in_tree()
		and bulle.get_global_rect().size.x > 100.0, "%s" % (bulle.get_global_rect() if bulle else "?"))
	_verifier("B1 : bulle VIDE (aucun element dedans)", bulle != null and bulle.get_child_count() == 0)
	_verifier("B1 : la bulle REMPLACE les etoiles (aucun anneau)", _anneaux(bureau) == anneaux_avant)
	await _doigt("leve", libre)
	await _tap(bulle.get_global_rect().get_center())
	_verifier("B1 tap DANS la bulle : elle reste", bureau.get("_bulle") == voile)
	var dehors := Vector2(30, 30) if not bulle.get_global_rect().has_point(Vector2(30, 30)) \
		else bulle.get_global_rect().end + Vector2(40, 40)
	await _tap(dehors)
	await _trames(2)
	_verifier("B1 tap EN DEHORS de la bulle : elle disparait",
		bureau.get("_bulle") == null and not is_instance_valid(voile))
	# appui long sur la barre des taches : pas de bulle (elle est reservee au bureau nu)
	var ecran: Vector2 = bureau.get_viewport().get_visible_rect().size
	var sur_barre := Vector2(ecran.x * 0.5, ecran.y - bureau.hauteur_barre * 0.5)
	anneaux_avant = _anneaux(bureau)
	await _appui_long(sur_barre)
	_verifier("B1 appui long sur la barre : etoiles, pas de bulle",
		bureau.get("_bulle") == null and _anneaux(bureau) > anneaux_avant)
	await _doigt("leve", sur_barre)
	# appui long sur une icone : elle se souleve (pas de bulle)
	var dossier2: Control = _icone(bureau, "clavier")
	p = _centre_bouton(dossier2)
	await _appui_long(p)
	_verifier("B1 appui long sur une icone : soulevee, pas de bulle",
		dossier2.scale.x > 1.0 and bureau.get("_bulle") == null)
	await _doigt("leve", p)

	# A3 tap court sur une appli directe = lancement (non-regression)
	var directe: Control = null
	for ic in _icones(bureau):
		if not ic.est_dossier and not String(ic.id).begins_with("tel:"):
			directe = ic
			break
	if directe == null:
		_verifier("A3 une appli directe sur le bureau", false)
		_fin()
		return
	var scene_avant := current_scene
	var id_directe: String = directe.id  # l'icone est liberee avec le bureau au lancement
	await _tap(_centre_bouton(directe))
	await _trames(6)
	_verifier("A3 tap court sur « %s » : lancee (scene changee)" % id_directe,
		current_scene != scene_avant and current_scene != null,
		"→ %s" % (current_scene.scene_file_path if current_scene else "?"))
	_fin()


func _fin() -> void:
	print("=== BILAN : %d echec(s) ===" % _echecs)
	quit(1 if _echecs > 0 else 0)
