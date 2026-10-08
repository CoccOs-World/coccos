# Preuve : CHOIX DE CURSEUR RÉTABLI SUR PC (REQ_261008 pousse accueil curseur desktop).
# Monte le VRAI jeu (scenes/pousse_pollen.tscn), mode tactile DÉCOCHÉ (= Linux/Windows), et vérifie par mesure :
#   ① section « Choisis ton curseur » PRÉSENTE : titre, 3 cases Main/Coccinelle/Abeille, 3 aperçus, liseré ;
#   ② choix MÉMORISÉ (choix/curseur écrit, relu au relancement, liseré sur la bonne case), progression + avatar intacts ;
#   ③ en jeu, le curseur CHOISI est posé (curseur_pose = "jeu:<type>") avec le confinement fenêtre ;
#   ④ accueil conservé (ab66be9) : prairie, curseur coccinelle d'accueil, fleurs au clic dans une zone vide,
#      et un clic sur un aperçu CHOISIT (les fleurs, décoratives, ne mangent pas le clic) ;
#   ⑤ non-régression : ← résout N1 en jeu, bouton « Accueil » rouvre l'accueil avec la section curseur.
# ⚠ En --headless, Input.mouse_mode reste VISIBLE (pas de vrai pointeur) : le confinement est prouvé par le chemin
# de code (_appliquer_curseur → MOUSE_MODE_CONFINED, tracé par curseur_pose), pas par le pointeur réel.
# Lancement (user:// ISOLÉ — la sauvegarde de Fabrice n'est jamais touchée) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_pousse_curseur_pc.gd
# Code de sortie 0 = tout vert, 1 = au moins un échec.
extends SceneTree

const Doigt := preload("res://outils/doigt_moteur.gd")
const SCENE := "res://scenes/pousse_pollen.tscn"
const CFG := "user://pousse_pollen_progression.cfg"

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


func _monter() -> Node:
	var jeu: Node = load(SCENE).instantiate()
	root.add_child(jeu)
	current_scene = jeu
	await _trames(6)
	return jeu


# Les cases (Button plats) de l'accueil, dans l'ordre : 2 avatars puis 3 curseurs.
func _cases(accueil: Node) -> Array[Button]:
	var liste: Array[Button] = []
	for n in _tous(accueil):
		if n is Button and (n as Button).flat:
			liste.append(n)
	return liste


func _cliquer(ou: Vector2) -> void:
	Doigt.souris_bouton(root, ou, true)
	await _trames(2)
	Doigt.souris_bouton(root, ou, false)
	await _trames(2)


func _touche(code: Key) -> void:
	for appui in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = appui
		Input.parse_input_event(ev)
		Input.flush_buffered_events()
		await _trames(2)


func _derouler() -> void:
	print("=== PREUVE CURSEUR PC POUSSE-POLLEN (08-10) ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	var reglages := ConfigFile.new()                 # mode tactile décoché = PC (Linux/Windows)
	reglages.set_value("interface", "mode_tactile", false)
	reglages.save("user://config.cfg")
	var vieux := ConfigFile.new()                    # progression N5 + avatar coccinelle, aucun curseur encore choisi
	vieux.set_value("progression", "niveau_max_atteint", 4)
	vieux.set_value("choix", "avatar", 0)
	vieux.save(CFG)

	var jeu := await _monter()
	var accueil: CanvasLayer = jeu.get_node_or_null("Accueil")
	_verifier("① accueil monté, mode PC détecté", accueil != null and jeu.get("_curseur_pc") == true)
	var textes: Array[String] = []
	for n in _tous(accueil):
		if n is Label:
			textes.append((n as Label).text)
	print("     libellés de l'accueil : %s" % [textes])
	var cases := _cases(accueil)
	var noms: Array[String] = []
	for b in cases:
		noms.append(b.tooltip_text)
	_verifier("① titre « Choisis ton curseur » présent", textes.has("Choisis ton curseur"))
	_verifier("① titre « Choisis ton personnage » présent", textes.has("Choisis ton personnage"))
	_verifier("① cases = 2 avatars + Main/Coccinelle/Abeille", noms == ["Coccinelle", "Abeille", "Main", "Coccinelle", "Abeille"], str(noms))
	var apercus := 0
	for n in accueil.get_children():
		if n.get_signal_connection_list("draw").any(func(c: Dictionary) -> bool: return c["callable"].get_method() == "_apercu_curseur"):
			apercus += 1
	_verifier("① 3 aperçus de curseur dessinés", apercus == 3, "%d" % apercus)
	var lis: Array = jeu.get("_surbrillance_curseur")
	_verifier("① liseré : 3 cases, sur Main par défaut", lis.size() == 3 and lis[0].visible and not lis[1].visible and not lis[2].visible)
	_verifier("④ accueil : curseur coccinelle posé, souris libre", jeu.get("curseur_pose") == "accueil" and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	var prairie: Node = accueil.get_node_or_null("Prairie")
	var tex_prairie := ""
	if prairie != null:
		for n in _tous(prairie):
			if n is TextureRect and (n as TextureRect).texture != null:
				tex_prairie = (n as TextureRect).texture.resource_path
	_verifier("④ prairie en fond de l'accueil", tex_prairie == "res://assets/backgrounds/fond_prairie.png", tex_prairie)

	# ④ clic RÉEL (souris injectée) sur l'aperçu « Abeille » du curseur = choisit ; les fleurs ne gênent pas
	var case_abeille := cases[4]
	var centre := case_abeille.get_global_rect().get_center()
	var f0: int = jeu.get("fleurs_accueil_posees")
	await _cliquer(centre)
	var lu := ConfigFile.new()
	lu.load(CFG)
	_verifier("④ clic sur l'aperçu Abeille = curseur choisi", jeu.get("_curseur_type") == 2, str(jeu.get("_curseur_type")))
	_verifier("② choix/curseur = 2 écrit sur disque", int(lu.get_value("choix", "curseur", -1)) == 2)
	_verifier("② avatar + progression préservés", int(lu.get_value("choix", "avatar", -1)) == 0 and int(lu.get_value("progression", "niveau_max_atteint", -1)) == 4)
	_verifier("① liseré déplacé sur Abeille", not lis[0].visible and lis[2].visible)
	print("     (clic sur l'aperçu : %d ronde(s) de fleurs, comme sur une case avatar)" % (int(jeu.get("fleurs_accueil_posees")) - f0))
	await create_timer(0.2).timeout
	# ④ clic dans une zone VIDE = fleurs, aucun choix ne bouge
	var f1: int = jeu.get("fleurs_accueil_posees")
	await _cliquer(Vector2(60, 520))
	_verifier("④ clic dans le vide = 1 ronde de fleurs, choix inchangés",
		int(jeu.get("fleurs_accueil_posees")) - f1 == 1 and jeu.get("_curseur_type") == 2 and jeu.get("_avatar_type") == 0)
	await create_timer(0.2).timeout
	# ④ clic réel sur l'avatar Abeille → avatar, sans toucher au curseur
	await _cliquer(cases[1].get_global_rect().get_center())
	_verifier("④ clic avatar Abeille = avatar choisi, curseur intact", jeu.get("_avatar_type") == 1 and jeu.get("_curseur_type") == 2)

	# ③ « Jouer » → curseur choisi posé en jeu + confinement
	(accueil.get_node("Jouer") as Button).pressed.emit()
	await _trames(4)
	_verifier("③ en jeu, curseur choisi posé (abeille)", jeu.get("curseur_pose") == "jeu:2", str(jeu.get("curseur_pose")))
	_verifier("③ en jeu, aucune fleur ni couche d'accueil", jeu.get_node_or_null("Accueil") == null and jeu.get("_en_accueil") == false)
	var av1: Vector2i = jeu.get("_avatar")
	await _touche(KEY_LEFT)
	_verifier("⑤ en jeu, ← déplace l'avatar", jeu.get("_avatar") != av1)
	_verifier("⑤ N1 gagné", jeu.get("_a_gagne") == true)
	lu = ConfigFile.new()
	lu.load(CFG)
	_verifier("⑤ sauvegarde intacte après victoire (N5, avatar 1, curseur 2)",
		int(lu.get_value("progression", "niveau_max_atteint", -1)) == 4 and int(lu.get_value("choix", "avatar", -1)) == 1 and int(lu.get_value("choix", "curseur", -1)) == 2)

	# ② relancement : curseur relu du disque
	jeu.queue_free()
	await _trames(4)
	var jeu2 := await _monter()
	var lis2: Array = jeu2.get("_surbrillance_curseur")
	_verifier("② relancé : curseur abeille relu, liseré sur Abeille",
		jeu2.get("_curseur_type") == 2 and lis2.size() == 3 and lis2[2].visible and not lis2[0].visible)
	(jeu2.get_node("Accueil/Jouer") as Button).pressed.emit()
	await _trames(3)
	_verifier("③ relancé : curseur abeille en jeu", jeu2.get("curseur_pose") == "jeu:2")
	(jeu2.get_node("BoutonAccueil/Accueil") as Button).pressed.emit()
	await _trames(3)
	_verifier("⑤ « Accueil » rouvre l'accueil, section curseur là, curseur d'accueil reposé",
		jeu2.get_node_or_null("Accueil") != null and (jeu2.get("_surbrillance_curseur") as Array).size() == 3 and jeu2.get("curseur_pose") == "accueil")
	await _cliquer(_cases(jeu2.get_node("Accueil"))[2].get_global_rect().get_center())
	(jeu2.get_node("Accueil/Jouer") as Button).pressed.emit()
	await _trames(3)
	_verifier("③ changé pour Main → main posée en jeu", jeu2.get("curseur_pose") == "jeu:0", str(jeu2.get("curseur_pose")))

	print("=== %s (%d échec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(0 if _echecs == 0 else 1)
