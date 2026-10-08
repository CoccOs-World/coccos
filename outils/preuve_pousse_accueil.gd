# Preuve : ACCUEIL de Pousse-Pollen nettoyé (REQ_261008 pousse accueil nettoyage).
# Monte le VRAI jeu (scenes/pousse_pollen.tscn) dans root et vérifie, par mesure :
#   ① plus de choix de CURSEUR (titre, cases, aperçus absents) ; choix d'AVATAR présent (2 cases) ;
#   ② avatar coccinelle/abeille MÉMORISÉ (fichier + relecture au relancement), progression PRÉSERVÉE,
#      ancienne clé choix/curseur EFFACÉE ;
#   ③ PRAIRIE en fond de l'accueil (TextureRect = assets/backgrounds/fond_prairie.png) ;
#   ④ clic souris et touche au doigt dans l'accueil = UNE ronde de 4 fleurs chacun (l'émulé est écarté) ;
#   ⑤ après « Jouer » : plus de couche d'accueil, AUCUNE fleur dans l'arbre, un clic n'en fait plus, souris visible ;
#   ⑥ non-régression : en accueil les flèches ne bougent rien ; en jeu ← résout N1 (victoire, progression sauvée).
# Lancement (user:// ISOLÉ — la sauvegarde de Fabrice n'est jamais touchée) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_pousse_accueil.gd
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


func _fleurs_dans_arbre() -> int:
	return _tous(root).filter(func(n: Node) -> bool: return n.get_script() != null and str(n.get_script().resource_path).ends_with("effets/fleur.gd")).size()


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
	print("=== PREUVE ACCUEIL POUSSE-POLLEN (nettoyage 08-10) ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	# Sauvegarde « ancienne » : progression N5 + ancien choix de curseur (abeille) à effacer.
	var vieux := ConfigFile.new()
	vieux.set_value("progression", "niveau_max_atteint", 4)
	vieux.set_value("choix", "avatar", 0)
	vieux.set_value("choix", "curseur", 2)
	vieux.save(CFG)

	var jeu := await _monter()
	var accueil: CanvasLayer = jeu.get_node_or_null("Accueil")
	_verifier("① accueil monté au lancement", accueil != null and jeu.get("_en_accueil") == true)
	var textes: Array[String] = []
	var cases: Array[String] = []
	for n in _tous(accueil):
		if n is Label:
			textes.append((n as Label).text)
		if n is Button and (n as Button).flat:
			cases.append((n as Button).tooltip_text)
	print("     libellés de l'accueil : %s" % [textes])
	_verifier("① titre « Choisis ton curseur » absent", not textes.has("Choisis ton curseur"))
	_verifier("① libellé « Main » absent", not textes.has("Main"))
	_verifier("① cases de choix = Coccinelle + Abeille seulement", cases == ["Coccinelle", "Abeille"], str(cases))
	_verifier("① plus aucune méthode du choix de curseur",
		not jeu.has_method("_choisir_curseur") and not jeu.has_method("_apercu_curseur") and jeu.get("_curseur_type") == null)
	_verifier("① titre « Choisis ton personnage » présent", textes.has("Choisis ton personnage"))

	# ③ prairie
	var prairie: Node = accueil.get_node_or_null("Prairie")
	var tex_prairie := ""
	if prairie != null:
		for n in _tous(prairie):
			if n is TextureRect and (n as TextureRect).texture != null:
				tex_prairie = (n as TextureRect).texture.resource_path
	_verifier("③ prairie en fond de l'accueil", tex_prairie == "res://assets/backgrounds/fond_prairie.png", tex_prairie)
	var fond_brun: Node = accueil.get_child(0)
	_verifier("③ le bouchon à clics (voile) reste DESSOUS la prairie",
		fond_brun is ColorRect and (fond_brun as Control).mouse_filter == Control.MOUSE_FILTER_STOP and prairie != null and prairie.get_index() > fond_brun.get_index())
	var fleurs_calque: Node = accueil.get_node_or_null("FleursAccueil")
	_verifier("③ calque des fleurs peint par-dessus tout l'accueil", fleurs_calque != null and fleurs_calque.get_index() >= accueil.get_child_count() - 2)

	# ② avatar mémorisé
	var abeille: Button = null
	var jouer: Button = accueil.get_node_or_null("Jouer")
	for n in _tous(accueil):
		if n is Button and (n as Button).tooltip_text == "Abeille":
			abeille = n
	abeille.pressed.emit()
	await _trames(2)
	var lu := ConfigFile.new()
	lu.load(CFG)
	_verifier("② choix abeille appliqué", jeu.get("_avatar_type") == 1)
	_verifier("② choix abeille écrit sur disque", int(lu.get_value("choix", "avatar", -1)) == 1)
	_verifier("② ancienne clé choix/curseur effacée", not lu.has_section_key("choix", "curseur"))
	_verifier("② progression préservée (N5)", int(lu.get_value("progression", "niveau_max_atteint", -1)) == 4)
	_verifier("① souris visible en accueil", Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)

	# ⑥a en accueil, une flèche ne bouge rien
	var av0: Vector2i = jeu.get("_avatar")
	await _touche(KEY_LEFT)
	_verifier("⑥ en accueil, ← ne bouge pas l'avatar", jeu.get("_avatar") == av0)

	# ④ fleurs au clic et au doigt (zone vide de l'accueil)
	var vide := Vector2(120, 520)
	var avant: int = jeu.get("fleurs_accueil_posees")
	Doigt.souris_bouton(root, vide, true)
	await _trames(2)
	Doigt.souris_bouton(root, vide, false)
	await _trames(2)
	var apres_souris: int = jeu.get("fleurs_accueil_posees")
	var nb_souris := fleurs_calque.get_child_count()
	_verifier("④ clic souris = 1 ronde (le doigt émulé n'en ajoute pas)", apres_souris - avant == 1, "%d ronde(s)" % (apres_souris - avant))
	_verifier("④ ronde = 4 fleurs dans le calque d'accueil", nb_souris == 4, "%d" % nb_souris)
	await create_timer(0.2).timeout
	Doigt.toucher(root, vide + Vector2(200, 0), true)
	await _trames(2)
	Doigt.toucher(root, vide + Vector2(200, 0), false)
	await _trames(2)
	var apres_doigt: int = jeu.get("fleurs_accueil_posees")
	_verifier("④ touche au doigt = 1 ronde (le clic émulé n'en ajoute pas)", apres_doigt - apres_souris == 1, "%d ronde(s)" % (apres_doigt - apres_souris))

	# ⑤ « Jouer » → plus rien de l'accueil
	jouer.pressed.emit()
	await _trames(4)
	_verifier("⑤ après Jouer, couche d'accueil retirée", jeu.get_node_or_null("Accueil") == null and jeu.get("_en_accueil") == false)
	_verifier("⑤ après Jouer, aucune fleur dans l'arbre", _fleurs_dans_arbre() == 0, "%d" % _fleurs_dans_arbre())
	var compte_jeu: int = jeu.get("fleurs_accueil_posees")
	Doigt.souris_bouton(root, vide, true)
	await _trames(2)
	Doigt.souris_bouton(root, vide, false)
	await create_timer(0.2).timeout
	Doigt.toucher(root, vide, true)
	await _trames(2)
	Doigt.toucher(root, vide, false)
	await _trames(2)
	_verifier("⑤ en jeu, clic + doigt = aucune fleur", jeu.get("fleurs_accueil_posees") == compte_jeu and _fleurs_dans_arbre() == 0)
	_verifier("⑤ en jeu, souris libre et visible (plus de confinement)", Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)

	# ⑥b le jeu se joue : N1 = ← pousse la boule sur la loge
	var av1: Vector2i = jeu.get("_avatar")
	await _touche(KEY_LEFT)
	_verifier("⑥ en jeu, ← déplace l'avatar", jeu.get("_avatar") != av1, "%s → %s" % [av1, jeu.get("_avatar")])
	_verifier("⑥ N1 gagné (boule sur la loge)", jeu.get("_a_gagne") == true)
	lu = ConfigFile.new()
	lu.load(CFG)
	_verifier("⑥ progression intacte après victoire", int(lu.get_value("progression", "niveau_max_atteint", -1)) == 4 and int(lu.get_value("choix", "avatar", -1)) == 1)

	# ② relancement : l'abeille est relue
	jeu.queue_free()
	await _trames(4)
	var jeu2 := await _monter()
	var lis: Array = jeu2.get("_surbrillance_avatar")
	_verifier("② relancé : abeille relue du disque, liseré sur Abeille",
		jeu2.get("_avatar_type") == 1 and lis.size() == 2 and not lis[0].visible and lis[1].visible)
	jeu2.get_node("Accueil/Jouer").pressed.emit()
	await _trames(3)
	(jeu2.get_node("BoutonAccueil/Accueil") as Button).pressed.emit()
	await _trames(3)
	_verifier("② bouton « Accueil » en jeu rouvre l'accueil", jeu2.get_node_or_null("Accueil") != null and jeu2.get("_en_accueil") == true)
	_verifier("② accueil ré-ouvert : prairie + fleurs de nouveau là", jeu2.get_node_or_null("Accueil/Prairie") != null and jeu2.get_node_or_null("Accueil/FleursAccueil") != null)

	print("=== %s (%d échec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(0 if _echecs == 0 else 1)
