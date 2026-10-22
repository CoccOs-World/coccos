# Preuve : CROIX DE FERMETURE À L'ACCUEIL de Pousse-Pollen (REQ_pousse_croix_dans_accueil 22-10).
# Fabrice : « dans le jeu, on revient à l'accueil, et à partir de l'accueil, on sort du jeu — c'est ce qu'on a fait
# sur les autres jeux ». Monte le VRAI jeu (3 formats × Android/PC) et vérifie, par mesure :
#   ① EN JEU, aucune croix nulle part : pas de couche « CroixCoccOs », aucune `_IconeCroixFermerCoccOs` hors de la
#      couche Accueil, plus de zone réservée à la croix dans `_rects_boutons()` (6 zones, non 7) ;
#   ② À L'ACCUEIL, UNE croix : Button 72×72, rond rouge (0.85, 0.35, 0.30) rayon 36, croix blanche dessinée, sans
#      focus — le motif de `_creer_bouton_quitter` des autres jeux ; à 16 px du bord DROIT et 16 px du HAUT de l'écran
#      RÉEL ; entière à l'écran ; son clic est relié à `_quitter_coccos` ;
#   ③ maison en jeu → l'accueil revient, avec sa croix ; « Jouer » la libère (plus aucune croix dans l'arbre) ;
#   ④ Échap et Retour Android EN JEU → accueil (un cran en arrière, pas la sortie) ;
#   ⑤ À L'ACCUEIL, croix / Échap / Retour Android → sortie du jeu : la scène courante devient le BUREAU.
# Lancement (user:// ISOLÉ) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_pousse_croix_accueil.gd
# Code de sortie 0 = tout vert, 1 = au moins un échec.
extends SceneTree

const SCENE := "res://scenes/pousse_pollen.tscn"
const BUREAU := "res://scenes/bureau.tscn"
const FORMATS := [Vector2i(1024, 768), Vector2i(1366, 768), Vector2i(2400, 1080)]
const NOMS_FORMAT := ["4:3", "16:9", "20:9"]
const COULEUR_AUTRES_JEUX := Color(0.85, 0.35, 0.30)   # COULEUR_BOUTON_QUITTER de jeu_ballons / lettres / chasse / mots / tele / souris / classeur

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


func _tous(n: Node) -> Array[Node]:
	var liste: Array[Node] = [n]
	for e in n.get_children():
		liste.append_array(_tous(e))
	return liste


func _icone(jeu: Node) -> GDScript:
	return jeu.get_script().get_script_constant_map().get("_IconeCroixFermerCoccOs")


func _croix_de(jeu: Node) -> Array[Node]:
	var Icone: GDScript = _icone(jeu)
	return _tous(jeu).filter(func(n: Node) -> bool: return n.get_script() == Icone)


func _monter(f: Vector2i) -> Node:
	root.size = f
	await _trames(2)
	root.size = f
	await _trames(2)
	var jeu: Node = load(SCENE).instantiate()
	root.add_child(jeu)
	current_scene = jeu
	await _trames(6)
	return jeu


func _echap() -> void:
	for appui in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = KEY_ESCAPE
		ev.physical_keycode = KEY_ESCAPE
		ev.pressed = appui
		Input.parse_input_event(ev)
	await _trames(3)


func _controler_accueil(jeu: Node, etiquette: String) -> void:
	var vis: Rect2 = root.get_visible_rect()
	var icones := _croix_de(jeu)
	var hors_accueil := icones.filter(func(n: Node) -> bool: return not str(jeu.get_path_to(n)).begins_with("Accueil/"))
	_verifier("① %s aucune croix hors de la couche Accueil, couche CroixCoccOs absente (%d icône(s) au total)" % [etiquette, icones.size()],
		jeu.get_node_or_null("CroixCoccOs") == null and hors_accueil.is_empty() and icones.size() == 1)
	var rects: Array = jeu._rects_boutons()
	var zone_croix := false
	for r in rects:
		if (r as Rect2).size.is_equal_approx(jeu.CROIX_COCCOS_TAILLE):
			zone_croix = true
	_verifier("① %s plus de zone réservée à la croix dans _rects_boutons (%d zones)" % [etiquette, rects.size()], not zone_croix and rects.size() == 6)
	var croix: Button = jeu.get_node_or_null("Accueil/CroixFermer")
	_verifier("② %s une croix dans Accueil : Button 72×72" % etiquette, croix != null and croix.size.is_equal_approx(Vector2(72, 72)), str(croix.size) if croix else "absente")
	if croix == null:
		return
	var sb := croix.get_theme_stylebox("normal") as StyleBoxFlat
	var style_ok := sb != null and sb.bg_color.is_equal_approx(COULEUR_AUTRES_JEUX) and sb.corner_radius_top_left == 36
	_verifier("② %s rond rouge des autres jeux (rayon 36), croix blanche dessinée (1 enfant _IconeCroixFermerCoccOs), sans focus" % etiquette,
		style_ok and croix.get_child_count() == 1 and croix.get_child(0).get_script() == _icone(jeu) and croix.focus_mode == Control.FOCUS_NONE)
	var r: Rect2 = croix.get_global_rect()
	_verifier("② %s au coin haut-droit RÉEL : 16 px du bord droit, 16 px du haut" % etiquette,
		absf(vis.size.x - r.end.x - 16.0) <= 1.0 and absf(r.position.y - 16.0) <= 1.0, "%s dans %s" % [r, vis.size])
	_verifier("② %s entière dans l'écran visible" % etiquette, vis.grow(0.5).encloses(r), str(r))
	_verifier("② %s clic relié à _quitter_coccos (sortie du jeu)" % etiquette, croix.pressed.is_connected(jeu._quitter_coccos))


func _controler_jeu(jeu: Node, etiquette: String) -> void:
	jeu._quitter_accueil()
	await _trames(2)
	_verifier("③ %s après « Jouer » : plus aucune croix dans l'arbre, couche Accueil libérée" % etiquette,
		_croix_de(jeu).is_empty() and jeu.get_node_or_null("Accueil") == null and not jeu._en_accueil)
	var maison: Button = jeu.get_node_or_null("BoutonAccueil/Accueil")
	_verifier("③ %s bouton maison présent en jeu" % etiquette, maison != null)
	if maison != null:
		maison.pressed.emit()
		await _trames(2)
		_verifier("③ %s maison en jeu → accueil, avec sa croix" % etiquette, jeu._en_accueil and jeu.get_node_or_null("Accueil/CroixFermer") != null)
	jeu._quitter_accueil()
	await _trames(2)
	await _echap()
	_verifier("④ %s Échap en jeu → accueil (pas la sortie), avec sa croix" % etiquette,
		jeu._en_accueil and jeu.get_node_or_null("Accueil/CroixFermer") != null and current_scene == jeu)
	jeu._quitter_accueil()
	await _trames(2)
	jeu.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _trames(2)
	_verifier("④ %s Retour Android en jeu → accueil (pas la sortie), avec sa croix" % etiquette,
		jeu._en_accueil and jeu.get_node_or_null("Accueil/CroixFermer") != null and current_scene == jeu)


# À l'accueil, un geste de sortie → la scène courante devient le bureau (le jeu est libéré par change_scene_to_file).
func _controler_sortie(etiquette: String, geste: String) -> void:
	var jeu: Node = await _monter(Vector2i(2400, 1080))
	match geste:
		"croix":
			var croix: Button = jeu.get_node_or_null("Accueil/CroixFermer")
			if croix != null:
				croix.pressed.emit()
		"Échap":
			await _echap()
		"Retour Android":
			jeu.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _trames(6)
	var cs: Node = current_scene
	var sorti := is_instance_valid(cs) and cs.scene_file_path == BUREAU and not is_instance_valid(jeu)
	_verifier("⑤ %s à l'accueil, %s → sortie du jeu vers le bureau" % [etiquette, geste], sorti,
		"scène courante : %s" % (cs.scene_file_path if is_instance_valid(cs) else "aucune"))
	if is_instance_valid(cs):
		cs.queue_free()
	if is_instance_valid(jeu):
		jeu.queue_free()
	await _trames(4)


func _derouler() -> void:
	print("=== PREUVE CROIX DE FERMETURE À L'ACCUEIL — POUSSE-POLLEN ===")
	for tactile in [true, false]:
		var reglages := ConfigFile.new()
		reglages.set_value("interface", "mode_tactile", tactile)
		reglages.save("user://config.cfg")
		var mode := "Android" if tactile else "PC"
		for i in FORMATS.size():
			var jeu: Node = await _monter(FORMATS[i])
			var etiquette := "%s %s %s" % [mode, NOMS_FORMAT[i], root.get_visible_rect().size]
			_controler_accueil(jeu, etiquette)
			await _controler_jeu(jeu, etiquette)
			jeu.queue_free()
			await _trames(3)
		for geste in ["croix", "Échap", "Retour Android"]:
			await _controler_sortie(mode, geste)
	print("=== %s (%d échec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
