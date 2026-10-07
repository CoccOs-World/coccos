# Preuve du RANGEMENT par glisse (REQ_261007 glisser jeu dans dossier, Linux/Windows — souris).
# Monte le VRAI bureau (scenes/bureau.tscn) dans root et lui injecte des evenements
# souris (Viewport.push_input) — aucun appel direct aux fonctions de rangement :
#   ① defaut : puzzle ABSENT du bureau direct, PRESENT dans la fenetre « souris » ;
#      clic simple sur le dossier = la fenetre s'ouvre ;
#   ② RESSORTIR : jeu glisse hors de la fenetre = icone directe, posee la ou on l'a lache,
#      [bureau_rangement] puzzle = "" ; lache DANS la fenetre = il y reste ;
#   ③ relance : toujours sur le bureau, a sa place ;
#   ④ DANS : jeu du bureau glisse sur un dossier = le dossier se signale pendant le vol,
#      le jeu quitte le bureau, entre dans la fenetre, [bureau_rangement] ecrit ;
#   ⑤ relance : toujours dans le dossier ;
#   ⑥ logitheque : un jeu range mais DESACTIVE n'apparait nulle part ;
#   ⑦ cas limite : ressortir le DERNIER jeu d'un dossier (constat, a trancher par Fabrice) ;
#   ⑧ clic simple sur un jeu de la fenetre = il se lance (scene changee).
# Lancement (user:// ISOLE — la sauvegarde de Fabrice n'est jamais touchee) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_glisser_dans_dossier.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const PinConfig := preload("res://scripts/pin_config.gd")
const Registre := preload("res://scripts/registre_jeux.gd")

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


func _cliquer(ou: Vector2) -> void:
	await _souris("mouvement", ou)
	await _souris("appui", ou)
	await _souris("relache", ou)


## Glisse de `de` a `a` en 8 pas ; `pendant` est appele au pas 6 (vol en cours).
func _glisser(de: Vector2, a: Vector2, pendant := Callable()) -> void:
	await _souris("mouvement", de)
	await _souris("appui", de)
	for i in range(1, 9):
		await _souris("mouvement", de.lerp(a, i / 8.0), true)
		if i == 6 and pendant.is_valid():
			pendant.call()
	await _souris("relache", a)
	await _trames(4)


func _monter_bureau() -> Control:
	var bureau: Control = load("res://scenes/bureau.tscn").instantiate()
	root.add_child(bureau)
	current_scene = bureau
	await _trames(6)
	return bureau


func _demonter(bureau: Control) -> void:
	bureau.queue_free()
	await _trames(3)


func _icone(bureau: Control, id: String) -> Control:
	for n in bureau.get_children():
		if n.has_signal("deplacee") and is_instance_valid(n) and not n.is_queued_for_deletion() and n.id == id:
			return n
	return null


func _dans_fenetre(fenetre: Control, id: String) -> Control:
	for n in fenetre.contenu.get_children():
		if not n.is_queued_for_deletion() and n.id == id:
			return n
	return null


func _centre_bouton(icone: Control) -> Vector2:
	var btn: Control = icone.get("_btn")
	return btn.get_global_rect().get_center()


func _rangement(id: String) -> Variant:
	return PinConfig.lire_option("bureau_rangement", id, null)


func _ouvrir(bureau: Control, categorie: String) -> Control:
	await _cliquer(_centre_bouton(_icone(bureau, categorie)))
	await _trames(4)
	return bureau._fenetres_ouvertes.get(categorie)


func _fermer_fenetres(bureau: Control) -> void:
	for f in bureau._fenetres_ouvertes.values():
		if is_instance_valid(f):
			f.queue_free()
	bureau._fenetres_ouvertes.clear()
	await _trames(3)


## Un point du bureau libre : hors fenetre, hors icones, au-dessus de la barre.
func _point_libre(bureau: Control, fenetre: Control) -> Vector2:
	for p in [Vector2(bureau.size.x - 160, bureau.size.y - 260), Vector2(bureau.size.x - 160, 120),
			Vector2(160, bureau.size.y - 260)]:
		if fenetre == null or not fenetre.get_global_rect().has_point(p):
			return p
	return Vector2(bureau.size.x - 160, 120)


func _derouler() -> void:
	print("=== PREUVE RANGER UN JEU DANS UN DOSSIER (bureau) ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	var bureau := await _monter_bureau()
	print("  bureau %s" % bureau.size)

	# ① defaut du manifeste
	_verifier("① puzzle ABSENT du bureau direct", _icone(bureau, "puzzle") == null)
	_verifier("① dossier « souris » present", _icone(bureau, "souris") != null)
	_verifier("① aucun rangement enfant ecrit", _rangement("puzzle") == null)
	var fenetre := await _ouvrir(bureau, "souris")
	_verifier("① clic simple sur le dossier : fenetre ouverte", fenetre != null)
	var jeu := _dans_fenetre(fenetre, "puzzle")
	_verifier("① puzzle PRESENT dans la fenetre « souris »", jeu != null)
	_verifier("① jeu de fenetre glissable (mode souris)", jeu != null and jeu.rangeable)

	# ② lache DANS la fenetre = reste range, aucun lancement
	var lancements := []
	jeu.lancee.connect(func(id: String) -> void: lancements.append(id))
	var p := _centre_bouton(jeu)
	await _glisser(p, p + Vector2(30, 25))
	jeu = _dans_fenetre(fenetre, "puzzle")
	_verifier("② lache dans la fenetre : toujours dedans", jeu != null and _rangement("puzzle") == null,
		"rangement = %s" % _rangement("puzzle"))
	_verifier("② lache dans la fenetre : rien lance", lancements.is_empty(), str(lancements))
	_verifier("② lache dans la fenetre : reprend sa place (plus top_level)", jeu != null and not jeu.top_level)

	# ② RESSORTIR : glisse hors de la fenetre
	p = _centre_bouton(jeu)
	var cible := _point_libre(bureau, fenetre)
	var en_vol := {}
	await _glisser(p, cible, func() -> void:
		en_vol["souleve"] = jeu.scale.x > 1.0 and jeu.modulate.a < 1.0
		en_vol["suit"] = _centre_bouton(jeu).distance_to(p.lerp(cible, 0.75)) < 30.0)
	_verifier("② en vol : jeu souleve (echelle + opacite)", en_vol.get("souleve", false))
	_verifier("② en vol : il suit la souris hors de la rangee", en_vol.get("suit", false))
	_verifier("② ressorti : [bureau_rangement] puzzle = \"\"", _rangement("puzzle") == "",
		"rangement = %s" % _rangement("puzzle"))
	var direct := _icone(bureau, "puzzle")
	_verifier("② ressorti : icone directe sur le bureau", direct != null)
	_verifier("② ressorti : posee la ou on l'a lache",
		direct != null and _centre_bouton(direct).distance_to(cible) < 40.0,
		"centre %s, lache %s" % [_centre_bouton(direct) if direct else "?", cible])
	_verifier("② ressorti : plus dans la fenetre", is_instance_valid(fenetre) and _dans_fenetre(fenetre, "puzzle") == null)
	_verifier("② ressorti : rien lance", lancements.is_empty(), str(lancements))
	var place_sortie: Vector2 = direct.position if direct else Vector2.ZERO
	await _fermer_fenetres(bureau)

	# ③ relance
	await _demonter(bureau)
	bureau = await _monter_bureau()
	direct = _icone(bureau, "puzzle")
	_verifier("③ apres relance : puzzle toujours sur le bureau", direct != null)
	_verifier("③ apres relance : a sa place", direct != null and direct.position.distance_to(place_sortie) < 0.5,
		"%s vs %s" % [direct.position if direct else "?", place_sortie])

	# ④ DANS : glisse sur le dossier « clavier »
	var dossier := _icone(bureau, "clavier")
	p = _centre_bouton(direct)
	cible = _centre_bouton(dossier)
	await _glisser(p, cible)  # (le signalement en vol est mesure en ④bis, juste au-dessus du dossier)
	_verifier("④ range : [bureau_rangement] puzzle = \"clavier\"", _rangement("puzzle") == "clavier",
		"rangement = %s" % _rangement("puzzle"))
	_verifier("④ range : puzzle a quitte le bureau", _icone(bureau, "puzzle") == null)
	_verifier("④ range : sa place n'a pas ete ecrasee par le lache",
		Vector2(PinConfig.lire_option("bureau", "places_icones", {}).get("puzzle", Vector2.ZERO)).distance_to(place_sortie) < 0.5)
	_verifier("④ range : le dossier visé est revenu a la normale",
		_icone(bureau, "clavier") != null and _icone(bureau, "clavier").scale == Vector2.ONE)
	fenetre = await _ouvrir(bureau, "clavier")
	_verifier("④ range : puzzle dans la fenetre « clavier »", fenetre != null and _dans_fenetre(fenetre, "puzzle") != null)
	await _fermer_fenetres(bureau)

	# ④bis retour visuel pendant le vol : on ressort, puis on survole le dossier sans lacher
	fenetre = await _ouvrir(bureau, "clavier")
	jeu = _dans_fenetre(fenetre, "puzzle")
	await _glisser(_centre_bouton(jeu), _point_libre(bureau, fenetre))
	await _fermer_fenetres(bureau)
	direct = _icone(bureau, "puzzle")
	dossier = _icone(bureau, "souris")
	p = _centre_bouton(direct)
	cible = _centre_bouton(dossier)
	await _souris("mouvement", p)
	await _souris("appui", p)
	for i in range(1, 9):
		await _souris("mouvement", p.lerp(cible, i / 8.0), true)
	var d_coul: Color = dossier.get("_dossier").couleur
	_verifier("④ en vol au-dessus du dossier : il grossit (pas la couleur seule)", dossier.scale.x > 1.0,
		"echelle %.2f" % dossier.scale.x)
	_verifier("④ en vol au-dessus du dossier : il s'eclaircit",
		d_coul.get_luminance() > dossier.couleur.get_luminance(), "%.2f > %.2f" % [d_coul.get_luminance(), dossier.couleur.get_luminance()])
	var autre := _icone(bureau, "clavier")
	_verifier("④ l'AUTRE dossier ne se signale pas", autre != null and autre.scale == Vector2.ONE)
	await _souris("relache", cible)
	await _trames(4)
	_verifier("④ range dans « souris »", _rangement("puzzle") == "souris" and _icone(bureau, "puzzle") == null)

	# ⑤ relance
	await _demonter(bureau)
	bureau = await _monter_bureau()
	_verifier("⑤ apres relance : puzzle toujours range (absent du bureau)", _icone(bureau, "puzzle") == null)
	fenetre = await _ouvrir(bureau, "souris")
	_verifier("⑤ apres relance : puzzle dans la fenetre « souris »", fenetre != null and _dans_fenetre(fenetre, "puzzle") != null)
	await _fermer_fenetres(bureau)

	# ⑥ logitheque : range + desactive = nulle part ; reactive = de retour dans son dossier
	Registre.activer("puzzle", false)
	await _demonter(bureau)
	bureau = await _monter_bureau()
	fenetre = await _ouvrir(bureau, "souris")
	_verifier("⑥ desactive : ni sur le bureau ni dans la fenetre",
		_icone(bureau, "puzzle") == null and fenetre != null and _dans_fenetre(fenetre, "puzzle") == null)
	await _fermer_fenetres(bureau)
	Registre.activer("puzzle", true)
	await _demonter(bureau)
	bureau = await _monter_bureau()

	# ⑦ cas limite : vider le dossier « souris » (on ressort tous ses jeux)
	var ids := Registre.jeux_de("souris").map(func(a: Dictionary) -> String: return a["id"])
	for k in ids.size():
		fenetre = await _ouvrir(bureau, "souris")
		if fenetre == null:
			break
		jeu = fenetre.contenu.get_child(0)
		var ou := Vector2(bureau.size.x - 160, 100 + 180 * k)
		await _glisser(_centre_bouton(jeu), ou)
		if is_instance_valid(fenetre):
			await _fermer_fenetres(bureau)
	_verifier("⑦ constat : dossier « souris » vide → disparu du bureau", _icone(bureau, "souris") == null,
		"(cas a trancher par Fabrice)")
	_verifier("⑦ constat : ses %d jeux sont sur le bureau" % ids.size(),
		ids.all(func(id: String) -> bool: return _icone(bureau, id) != null), str(ids))
	_verifier("⑦ fenetre du dossier vide refermee", not bureau._fenetres_ouvertes.has("souris"))
	# Le dossier n'existant plus, on ne peut plus y reglisser ses jeux : remise a zero pour la
	# suite en effacant les choix de l'enfant (= defauts du manifeste)
	for id in ids:
		PinConfig.effacer_option("bureau_rangement", id)
	await _demonter(bureau)
	bureau = await _monter_bureau()
	_verifier("⑦ choix effaces = defauts du manifeste revenus", _icone(bureau, "souris") != null and _icone(bureau, "puzzle") == null)

	# ⑧ clic simple sur un jeu de la fenetre = lance
	fenetre = await _ouvrir(bureau, "souris")
	jeu = _dans_fenetre(fenetre, "puzzle")
	var scene_avant := current_scene
	await _cliquer(_centre_bouton(jeu))
	await _trames(6)
	_verifier("⑧ clic simple sur le puzzle de la fenetre : scene changee",
		current_scene != scene_avant and current_scene != null,
		current_scene.scene_file_path if current_scene else "?")
	_fin()


func _fin() -> void:
	print("=== BILAN : %d echec(s) ===" % _echecs)
	quit(1 if _echecs > 0 else 0)
