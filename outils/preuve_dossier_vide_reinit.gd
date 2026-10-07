# Preuve DOSSIER VIDE + REMISE AU RANGEMENT PAR DEFAUT (REQ_261007 dossier vide, Linux/Windows — souris).
# Monte le VRAI bureau / la VRAIE logitheque dans root et leur injecte des evenements souris :
#   A1 l'enfant sort TOUS les jeux de « souris » → le dossier RESTE sur le bureau ;
#      la fenetre ouverte au moment ou il se vide reste ouverte et dit « vide » ;
#   A2 clic sur le dossier vide : fenetre ouverte, propre (la phrase « vide », aucune icone) ;
#   A3 reglisser un jeu du bureau sur le dossier vide : il y entre ;
#   A4 regle « pas d'icone fantome » : un dossier sans jeu actif (ni range, ni par defaut) reste cache ;
#   B1 logitheque : 1er clic sur « Remettre le rangement par defaut » = demande de confirmation, rien efface ;
#   B2 2e clic : [bureau_rangement] effacee, les AUTRES sections de config.cfg intactes ;
#   B3 relance du bureau : chaque jeu a son dossier du manifeste (puzzle dans « souris »).
# Lancement (user:// ISOLE — la sauvegarde de Fabrice n'est jamais touchee) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_dossier_vide_reinit.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const PinConfig := preload("res://scripts/pin_config.gd")
const Registre := preload("res://scripts/registre_jeux.gd")
const Lang := preload("res://scripts/lang.gd")

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


func _bouton_texte(racine: Node, debut: String) -> Button:
	for n in racine.find_children("*", "Button", true, false):
		if (n as Button).text.begins_with(debut):
			return n
	return null


func _sections_hors_rangement() -> Dictionary:
	var cfg := ConfigFile.new()
	cfg.load(PinConfig.CHEMIN)
	var instantane := {}
	for section in cfg.get_sections():
		if section == "bureau_rangement":
			continue
		for cle in cfg.get_section_keys(section):
			instantane[section + "/" + cle] = cfg.get_value(section, cle)
	return instantane


func _derouler() -> void:
	print("=== PREUVE DOSSIER VIDE + RANGEMENT PAR DEFAUT ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	var bureau := await _monter_bureau()

	# A1 vider « souris » en glissant ses jeux hors de la fenetre
	var ids := Registre.jeux_de("souris").map(func(a: Dictionary) -> String: return a["id"])
	print("  jeux de « souris » : %s" % str(ids))
	var fenetre: Control = null
	for k in ids.size():
		fenetre = await _ouvrir(bureau, "souris")
		var jeu: Control = fenetre.contenu.get_child(0)
		await _glisser(_centre_bouton(jeu), Vector2(bureau.size.x - 160, 100 + 180 * k))
		if k < ids.size() - 1:
			await _fermer_fenetres(bureau)
	_verifier("A1 tous les jeux ressortis ([bureau_rangement] = \"\")",
		ids.all(func(id: String) -> bool: return _rangement(id) == ""))
	_verifier("A1 dossier « souris » vide → RESTE sur le bureau", _icone(bureau, "souris") != null)
	_verifier("A1 fenetre videe : reste ouverte", is_instance_valid(fenetre) and bureau._fenetres_ouvertes.has("souris"))
	await _trames(2)
	var etiquettes: Array = fenetre.contenu.get_children().filter(func(n: Node) -> bool: return n is Label)
	_verifier("A1 fenetre videe : dit « vide »",
		etiquettes.size() == 1 and etiquettes[0].text == Lang.t("bureau_dossier_vide"),
		etiquettes[0].text if etiquettes.size() > 0 else "aucun Label")
	await _fermer_fenetres(bureau)

	# A2 relance + clic sur le dossier vide
	await _demonter(bureau)
	bureau = await _monter_bureau()
	_verifier("A2 apres relance : dossier « souris » toujours la", _icone(bureau, "souris") != null)
	fenetre = await _ouvrir(bureau, "souris")
	_verifier("A2 clic sur le dossier vide : fenetre ouverte", fenetre != null)
	var enfants: Array = fenetre.contenu.get_children() if fenetre else []
	_verifier("A2 fenetre propre : une phrase « vide », aucune icone",
		enfants.size() == 1 and enfants[0] is Label and enfants[0].text == "Ce dossier est vide.",
		str(enfants.map(func(n: Node) -> String: return n.get_class())))
	await _fermer_fenetres(bureau)

	# A3 reglisser le puzzle du bureau sur le dossier vide
	await _glisser(_centre_bouton(_icone(bureau, "puzzle")), _centre_bouton(_icone(bureau, "souris")))
	_verifier("A3 reglisse : [bureau_rangement] puzzle = \"souris\"", _rangement("puzzle") == "souris",
		"rangement = %s" % _rangement("puzzle"))
	_verifier("A3 reglisse : puzzle a quitte le bureau", _icone(bureau, "puzzle") == null)
	fenetre = await _ouvrir(bureau, "souris")
	_verifier("A3 reglisse : puzzle dans la fenetre, plus de phrase « vide »",
		fenetre != null and _dans_fenetre(fenetre, "puzzle") != null
		and fenetre.contenu.get_children().all(func(n: Node) -> bool: return not n is Label))
	await _fermer_fenetres(bureau)
	await _demonter(bureau)

	# A4 regle fantome : « clavier » sans aucun jeu actif (tous desactives, aucun range dedans)
	var clavier := Registre.APPLIS.filter(func(a: Dictionary) -> bool: return a["categorie"] == "clavier") \
		.map(func(a: Dictionary) -> String: return a["id"])
	for id in clavier:
		Registre.activer(id, false)
	bureau = await _monter_bureau()
	_verifier("A4 dossier sans jeu actif (%s desactives) : cache" % str(clavier), _icone(bureau, "clavier") == null)
	_verifier("A4 … et « souris » (jeux par defaut actifs) toujours la", _icone(bureau, "souris") != null)
	await _demonter(bureau)
	Registre.ranger("puzzle", "clavier")
	bureau = await _monter_bureau()
	_verifier("A4 un jeu range dedans par l'enfant le rend visible", _icone(bureau, "clavier") != null)
	await _demonter(bureau)
	for id in clavier:
		Registre.activer(id, true)

	# B — rangements varies de l'enfant + autres sections a proteger
	Registre.ranger("puzzle", "")
	Registre.ranger("ballons", "clavier")
	Registre.ranger("lettres", "souris")
	PinConfig.ecrire_option("bureau", "places_icones", {"puzzle": Vector2(700, 300)})
	PinConfig.ecrire_option("logitheque", "chasse", false)
	Registre.ajouter_etiquette("mots", "preuve")
	PinConfig.lire_pin()
	var avant := _sections_hors_rangement()
	print("  autres cles avant : %s" % str(avant.keys()))

	var logi: Control = load("res://scenes/reglages_applis.tscn").instantiate()
	root.add_child(logi)
	current_scene = logi
	await _trames(8)
	var btn := _bouton_texte(logi, Lang.t("logitheque_reinit_rangement"))
	_verifier("B1 bouton « %s » present" % Lang.t("logitheque_reinit_rangement"), btn != null)
	_verifier("B1 bouton visible a l'ecran", btn != null and btn.is_visible_in_tree()
		and logi.get_global_rect().encloses(btn.get_global_rect()), str(btn.get_global_rect()) if btn else "")
	var retour := _bouton_texte(logi, Lang.t("reglages_retour"))
	_verifier("B1 en-tete tient dans l'ecran (bouton retour non pousse dehors)", retour != null
		and logi.get_global_rect().encloses(retour.get_global_rect()), str(retour.get_global_rect()) if retour else "")
	await _cliquer(btn.get_global_rect().get_center())
	_verifier("B1 1er clic : demande confirmation", btn.text.ends_with(Lang.t("classeur_btn_confirmer")), btn.text)
	_verifier("B1 1er clic : rien efface", _rangement("ballons") == "clavier")
	await _cliquer(btn.get_global_rect().get_center())
	var cfg := ConfigFile.new()
	cfg.load(PinConfig.CHEMIN)
	_verifier("B2 2e clic : section [bureau_rangement] effacee", not cfg.has_section("bureau_rangement"))
	_verifier("B2 2e clic : le bouton le dit", btn.text == Lang.t("logitheque_reinit_fait"), btn.text)
	var apres := _sections_hors_rangement()
	_verifier("B2 autres sections intactes ([bureau] [logitheque] etiquettes [adulte])", avant == apres,
		"%d cles avant / %d apres" % [avant.size(), apres.size()])
	logi.queue_free()
	await _trames(3)

	# B3 relance du bureau = defauts du manifeste
	Registre.activer("chasse", true)
	bureau = await _monter_bureau()
	_verifier("B3 tous les jeux a leur dossier du manifeste",
		Registre.APPLIS.all(func(a: Dictionary) -> bool: return Registre.categorie_de(a) == a["categorie"]))
	_verifier("B3 puzzle ABSENT du bureau direct", _icone(bureau, "puzzle") == null)
	fenetre = await _ouvrir(bureau, "souris")
	_verifier("B3 puzzle et ballons de retour dans « souris », lettres sortie",
		fenetre != null and _dans_fenetre(fenetre, "puzzle") != null and _dans_fenetre(fenetre, "ballons") != null
		and _dans_fenetre(fenetre, "lettres") == null)
	await _fermer_fenetres(bureau)
	fenetre = await _ouvrir(bureau, "clavier")
	_verifier("B3 lettres de retour dans « clavier »", fenetre != null and _dans_fenetre(fenetre, "lettres") != null)
	_fin()


func _fin() -> void:
	print("=== BILAN : %d echec(s) ===" % _echecs)
	quit(1 if _echecs > 0 else 0)
