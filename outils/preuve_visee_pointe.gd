# Preuve de la VISEE A LA POINTE au doigt (REQ_261007 android_visee_a_la_pointe).
# Decision Fabrice : « on vise avec le doigt DU CURSEUR, pas avec le doigt de celui qui joue ».
# Monte le VRAI bureau en mode tactile (user:// isole) et pose des doigts par le VRAI chemin
# du moteur (outils/doigt_moteur.gd : ScreenTouch → clic emule fabrique par Godot). Chaque
# cas est DISCRIMINANT : la pointe et le doigt tombent sur deux choses differentes, et l'on
# verifie que c'est la chose sous la POINTE qui agit :
#   V1 lancer une icone      : pointe SUR le bouton, doigt dehors → lancee ;
#                              pointe dehors, doigt SUR le bouton → rien ;
#                              le clic recu par le bouton porte la position de la pointe ;
#   V2 attraper (appui long) : pointe sur l'icone, doigt dehors → soulevee ; l'inverse → non ;
#   V3 deposer dans un dossier : pointe sur le dossier, doigt dehors → rangee ; l'inverse → non ;
#   V4 bouton de la barre    : pointe sur « Menu », doigt dehors → boite a icones ouverte ;
#                              pointe dehors, doigt sur « Menu » → rien ;
#   V5 bulle de menu         : tap pointe DANS la bulle, doigt dehors → elle reste ;
#                              pointe dehors, doigt dedans → elle se ferme ;
#   V6 souris de PC          : INCHANGEE, le clic part au pointeur (aucun decalage).
# Lancement :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_visee_pointe.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const PinConfig := preload("res://scripts/pin_config.gd")
const Registre := preload("res://scripts/registre_jeux.gd")
const Doigt := preload("res://outils/doigt_moteur.gd")

const MARGE := 12.0  # la pointe est a 12 px DANS (ou HORS de) la cible : un dossier vise grossit (~5 px)

var _echecs := 0
var _bureau: Control


func _verifier(libelle: String, vrai: bool, detail: String = "") -> void:
	print("  %s %s%s" % ["ok   " if vrai else "ECHEC", libelle, (" — " + detail) if detail != "" else ""])
	if not vrai:
		_echecs += 1


func _initialize() -> void:
	_derouler.call_deferred()


func _trames(n: int) -> void:
	for i in n:
		await process_frame


func _zone() -> Rect2:
	return root.get_visible_rect()


## Doigt a poser pour que la pointe tombe sur `pointe`.
func _doigt_pour(pointe: Vector2) -> Vector2:
	return Doigt.doigt_pour_pointe(_bureau.get("_curseur"), pointe, _zone())


func _tap_pointe(pointe: Vector2) -> Vector2:
	var d := _doigt_pour(pointe)
	Doigt.toucher(root, d, true)
	await _trames(2)
	Doigt.toucher(root, d, false)
	await _trames(2)
	return d


func _appui_long_pointe(pointe: Vector2) -> Vector2:
	var d := _doigt_pour(pointe)
	Doigt.toucher(root, d, true)
	await create_timer(0.8).timeout
	await _trames(2)
	return d


## Glisse le doigt tenu pour amener la pointe de `de` a `a`, puis le leve.
func _glisser_pointe(de: Vector2, a: Vector2) -> Vector2:
	var precedent := _doigt_pour(de)
	var d := precedent
	for i in range(1, 9):
		d = _doigt_pour(de.lerp(a, i / 8.0))
		Doigt.glisser(root, precedent, d)
		precedent = d
		await _trames(1)
	Doigt.toucher(root, d, false)
	await _trames(4)
	return d


func _monter_bureau() -> void:
	_bureau = load("res://scenes/bureau.tscn").instantiate()
	root.add_child(_bureau)
	current_scene = _bureau
	await _trames(6)


func _demonter() -> void:
	_bureau.queue_free()
	await _trames(3)


func _icones() -> Array:
	return _bureau.get_children().filter(func(n: Node) -> bool: return n.has_signal("deplacee"))


func _icone(id: String) -> Control:
	for ic in _icones():
		if ic.id == id:
			return ic
	return null


func _rect_bouton(icone: Control) -> Rect2:
	return (icone.get("_btn") as Control).get_global_rect()


## Tous les rects cliquables du bureau (boutons d'icones) — pour dire ou tombe un point.
func _sur_une_icone(p: Vector2) -> String:
	for ic in _icones():
		if _rect_bouton(ic).has_point(p):
			return ic.id
	return ""


func _jeu_direct() -> Control:
	for ic in _icones():
		var a: Dictionary = Registre.appli(ic.id)
		if not ic.est_dossier and not a.is_empty() and a.has("scene"):
			return ic
	return null


## Pointe juste DANS le bas du bouton (le doigt, plus bas, tombe dessous = dehors).
func _pointe_dedans_bas(r: Rect2) -> Vector2:
	return Vector2(r.get_center().x, r.end.y - MARGE)


## Pointe juste AU-DESSUS du bouton (le doigt, plus bas, tombe dedans).
func _pointe_dehors_haut(r: Rect2) -> Vector2:
	return Vector2(r.get_center().x, r.position.y - MARGE)


func _derouler() -> void:
	print("=== PREUVE VISEE A LA POINTE (bureau, doigt Android) ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	PinConfig.ecrire_option("interface", "mode_tactile", true)
	await _monter_bureau()
	var curseur: Node2D = _bureau.get("_curseur")
	print("  decalage doigt → pointe (plein) = %s" % curseur.decalage_doigt())
	var jeu := _jeu_direct()
	var dossier := _icone("clavier")
	_verifier("bureau monte : un jeu direct + le dossier « clavier »", jeu != null and dossier != null)
	if jeu == null or dossier == null:
		_fin()
		return
	var id_jeu: String = jeu.id
	var lancements := []
	jeu.lancee.connect(func(id: String) -> void: lancements.append(id))
	var recus := []
	(jeu.get("_btn") as Control).gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			recus.append(e.global_position))

	# V1a pointe DEHORS (au-dessus), doigt SUR le bouton → rien
	var r := _rect_bouton(jeu)
	var pointe := _pointe_dehors_haut(r)
	var d := await _tap_pointe(pointe)
	_verifier("V1a mise en place : doigt SUR le bouton, pointe dehors",
		r.has_point(d) and not r.has_point(pointe), "doigt %s, pointe %s, bouton %s" % [d, pointe, r])
	_verifier("V1a pointe dehors : AUCUN lancement (le doigt ne clique plus)", lancements.is_empty(), str(lancements))
	_verifier("V1a la coccinelle est posee a la pointe", curseur.position.distance_to(pointe) < 0.6,
		"%s / %s" % [curseur.position, pointe])

	# V1b pointe SUR le bouton (bas), doigt dehors (dessous) → lancee
	recus.clear()
	pointe = _pointe_dedans_bas(r)
	d = _doigt_pour(pointe)
	_verifier("V1b mise en place : pointe SUR le bouton, doigt dehors",
		r.has_point(pointe) and not r.has_point(d), "doigt %s (sur icone « %s »), pointe %s" % [d, _sur_une_icone(d), pointe])
	var scene_avant := current_scene
	Doigt.toucher(root, d, true)
	await _trames(2)
	_verifier("V1b le clic recu par le bouton porte la POINTE",
		recus.size() == 1 and (recus[0] as Vector2).distance_to(pointe) < 0.6, "%s" % [recus])
	Doigt.toucher(root, d, false)
	await _trames(6)
	_verifier("V1b pointe sur l'icone : « %s » lancee" % id_jeu,
		lancements == [id_jeu] or current_scene != scene_avant,
		"lancements %s, scene %s" % [lancements, current_scene.scene_file_path if current_scene else "?"])
	if current_scene != scene_avant:
		current_scene.queue_free()
		await _trames(3)
	if is_instance_valid(_bureau):
		await _demonter()
	await _monter_bureau()
	curseur = _bureau.get("_curseur")
	jeu = _icone(id_jeu)
	dossier = _icone("clavier")

	# V2a appui long : pointe dehors, doigt sur l'icone → elle ne se souleve pas
	r = _rect_bouton(jeu)
	pointe = _pointe_dehors_haut(r)
	d = await _appui_long_pointe(pointe)
	_verifier("V2a appui long pointe DEHORS (doigt sur l'icone) : pas soulevee",
		jeu.scale == Vector2.ONE, "doigt %s dans %s : %s" % [d, r, r.has_point(d)])
	Doigt.toucher(root, d, false)
	await _trames(3)

	# V2b appui long : pointe sur l'icone, doigt dehors → soulevee
	pointe = _pointe_dedans_bas(r)
	d = await _appui_long_pointe(pointe)
	_verifier("V2b appui long pointe SUR l'icone (doigt dehors) : soulevee",
		jeu.scale.x > 1.0 and not r.has_point(d), "doigt %s, echelle %.2f" % [d, jeu.scale.x])

	# V3a deposer : pointe finit JUSTE AU-DESSUS du dossier (doigt dedans) → pas rangee
	var rd := _rect_bouton(dossier)
	var arrivee := _pointe_dehors_haut(rd)
	var avant := jeu.position
	d = await _glisser_pointe(pointe, arrivee)
	_verifier("V3a mise en place : doigt leve SUR le dossier, pointe dehors",
		rd.has_point(d) and not rd.has_point(arrivee), "doigt %s, pointe %s, dossier %s" % [d, arrivee, rd])
	_verifier("V3a pointe hors du dossier : PAS rangee",
		PinConfig.lire_option("bureau_rangement", id_jeu, null) == null and _icone(id_jeu) != null)
	jeu = _icone(id_jeu)
	_verifier("V3a l'icone a suivi la POINTE", jeu != null and jeu.position.distance_to(avant + (arrivee - pointe)) < 1.5,
		"%s → %s (attendu %s)" % [avant, jeu.position if jeu else "?", avant + (arrivee - pointe)])

	# V3b deposer : pointe finit DANS le bas du dossier (doigt dessous, dehors) → rangee
	r = _rect_bouton(jeu)
	pointe = r.get_center()
	await _appui_long_pointe(pointe)
	rd = _rect_bouton(dossier)
	arrivee = _pointe_dedans_bas(rd)
	d = await _glisser_pointe(pointe, arrivee)
	_verifier("V3b mise en place : pointe SUR le dossier, doigt dehors",
		rd.has_point(arrivee) and not rd.has_point(d), "doigt %s, pointe %s, dossier %s" % [d, arrivee, rd])
	_verifier("V3b pointe sur le dossier : rangee dans « clavier »",
		PinConfig.lire_option("bureau_rangement", id_jeu, null) == "clavier" and _icone(id_jeu) == null,
		"[bureau_rangement] %s = %s" % [id_jeu, PinConfig.lire_option("bureau_rangement", id_jeu, null)])

	# V4 bouton « Menu » de la barre : le doigt est a DROITE de la pointe
	var btn_menu: Button = null
	for b in _bureau.find_children("*", "Button", true, false):
		if (b as Button).text == _bureau.Lang.t("bureau_menu"):
			btn_menu = b
	_verifier("V4 bouton Menu trouve", btn_menu != null)
	if btn_menu != null:
		var rm := btn_menu.get_global_rect()
		var dx: float = curseur.decalage_doigt().x  # < 0 : la pointe est a gauche du doigt
		# hauteur : pres du HAUT du bouton (le doigt, 37 px plus bas, reste sur le bouton)
		var y := rm.position.y + 6.0
		# pointe juste a GAUCHE du bouton → doigt dedans
		pointe = Vector2(rm.position.x - MARGE, y)
		d = await _tap_pointe(pointe)
		_verifier("V4a pointe a gauche de « Menu », doigt dessus : boite FERMEE",
			_bureau.get("_menu") == null and rm.has_point(d), "doigt %s, pointe %s, bouton %s (dx %.1f)" % [d, pointe, rm, dx])
		# pointe dans le bord droit du bouton → doigt dehors a droite
		pointe = Vector2(rm.end.x - MARGE, y)
		d = await _tap_pointe(pointe)
		_verifier("V4b pointe SUR « Menu », doigt dehors : boite a icones OUVERTE",
			_bureau.get("_menu") != null and not rm.has_point(d), "doigt %s, pointe %s" % [d, pointe])
		if _bureau.get("_menu") != null:
			_bureau.call("_fermer_menu")
			await _trames(2)
	await _demonter()

	# V5 bulle de menu (option parent cochee)
	PinConfig.ecrire_option("interface", "menu_contextuel_bureau", true)
	await _monter_bureau()
	curseur = _bureau.get("_curseur")
	var libre := Vector2(_zone().size.x * 0.75, _zone().size.y * 0.35)
	_verifier("V5 point de bureau nu", _sur_une_icone(libre) == "" and _sur_une_icone(_doigt_pour(libre)) == "")
	d = await _appui_long_pointe(libre)
	Doigt.toucher(root, d, false)
	await _trames(2)
	var voile: Control = _bureau.get("_bulle")
	var bulle: Control = voile.get_child(0) if voile != null else null
	_verifier("V5 bulle ouverte, coin haut-gauche A LA POINTE",
		bulle != null and bulle.get_global_rect().position.distance_to(libre) < 1.0,
		"coin %s, pointe %s, doigt %s" % [bulle.get_global_rect().position if bulle else "?", libre, d])
	if bulle != null:
		var rb := bulle.get_global_rect()
		pointe = _pointe_dedans_bas(rb)
		d = await _tap_pointe(pointe)
		_verifier("V5a pointe DANS la bulle, doigt dehors : elle reste",
			_bureau.get("_bulle") == voile and not rb.has_point(d), "doigt %s, pointe %s, bulle %s" % [d, pointe, rb])
		pointe = _pointe_dehors_haut(rb)
		d = await _tap_pointe(pointe)
		_verifier("V5b pointe HORS de la bulle, doigt dedans : elle se ferme",
			_bureau.get("_bulle") == null and rb.has_point(d), "doigt %s, pointe %s" % [d, pointe])
	await _demonter()

	# V6 souris de PC : inchangee — le clic part AU pointeur
	PinConfig.ecrire_option("interface", "mode_tactile", false)
	PinConfig.ecrire_option("interface", "menu_contextuel_bureau", false)
	await _monter_bureau()
	curseur = _bureau.get("_curseur")
	jeu = _jeu_direct()
	r = _rect_bouton(jeu)
	var p := r.get_center()
	Doigt.souris_mouvement(root, p - Vector2(10, 10), p)
	await _trames(2)
	_verifier("V6 souris : le curseur est SUR le pointeur", curseur.position.distance_to(p) < 0.01, "%s / %s" % [curseur.position, p])
	var lances := []
	jeu.lancee.connect(func(id: String) -> void: lances.append(id))
	recus = []
	(jeu.get("_btn") as Control).gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			recus.append(e.global_position))
	Doigt.souris_bouton(root, p, true)
	await _trames(2)
	_verifier("V6 souris : le clic recu par le bouton porte le POINTEUR (aucun decalage)",
		recus.size() == 1 and (recus[0] as Vector2).distance_to(p) < 0.6, "%s / %s" % [recus, p])
	Doigt.souris_bouton(root, p, false)
	await _trames(4)
	_verifier("V6 souris : clic au pointeur = lancement", lances.size() == 1 or current_scene != _bureau, str(lances))
	_fin()


func _fin() -> void:
	print("=== %s (%d echec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
