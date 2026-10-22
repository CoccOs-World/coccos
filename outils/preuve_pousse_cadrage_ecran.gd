# Preuve : CADRAGE ÉCRAN de Pousse-Pollen sur plusieurs formats (REQ_pousse_cadrage_android 21-10).
# Monte le VRAI jeu à plusieurs tailles de fenêtre (4:3 PC, 16:9 PC, 20:9 téléphone) et vérifie, par mesure :
#   ① chaque contrôle de jeu (D-pad, Agripper, Recommencer, Accueil, ◄ N ►) est ENTIÈREMENT dans l'écran visible ;
#      (22-10 : la croix de fermeture n'est plus EN JEU — elle vit à l'accueil, preuve_pousse_croix_accueil.gd) ;
#   ② il est ancré au BON bord (◄ N ► à droite, D-pad bas-droite, Agripper bas-gauche, Recommencer haut-gauche) ;
#      ► reste à 120 px du bord droit : les 100 px de l'ex-croix sont conservés (disposition = décision Fabrice) ;
#   ③ sur plusieurs niveaux, AUCUNE case praticable du tunnel n'est hors écran ni sous un contrôle (garde-fou b28/b33),
#      projetée par la VRAIE transformée caméra (get_canvas_transform), pas par la formule du jeu (38 niveaux) ;
#   ④ fenêtre redimensionnée EN JEU (1024×768 → 2400×1080) : ► replacé au coin réel, plateau recadré.
# Lancement (user:// ISOLÉ) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_pousse_cadrage_ecran.gd
# Code de sortie 0 = tout vert, 1 = au moins un échec.
extends SceneTree

const SCENE := "res://scenes/pousse_pollen.tscn"
const FORMATS := [Vector2i(1024, 768), Vector2i(1366, 768), Vector2i(2400, 1080)]
const COUCHES := ["FlechesEcran", "BoutonAgripper", "BoutonRecommencer", "BoutonAccueil", "LabelNiveau", "FlechesNavigation"]
const TOL := 1.0

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


func _controles(jeu: Node) -> Dictionary:
	var d := {}
	for nom in COUCHES:
		var couche := jeu.get_node_or_null(nom)
		if couche == null:
			continue
		for c in couche.get_children():
			if c is Control:
				d[str(c.name)] = (c as Control).get_global_rect()
	return d


func _derouler() -> void:
	print("=== PREUVE CADRAGE ÉCRAN POUSSE-POLLEN ===")
	var reglages := ConfigFile.new()
	reglages.set_value("interface", "mode_tactile", true)
	reglages.save("user://config.cfg")
	for f: Vector2i in FORMATS:
		root.size = f
		await _trames(2)
		root.size = f
		await _trames(2)
		var jeu: Node = load(SCENE).instantiate()
		root.add_child(jeu)
		current_scene = jeu
		await _trames(6)
		jeu._quitter_accueil()
		await _trames(3)
		var vis: Rect2 = root.get_visible_rect()
		print("--- fenêtre %s → écran visible %s" % [f, vis.size])
		var ctl := _controles(jeu)
		var dehors := []
		for nom in ctl:
			var r: Rect2 = ctl[nom]
			if not vis.grow(TOL).encloses(r):
				dehors.append("%s %s" % [nom, r])
		_verifier("① contrôles dans l'écran (%d)" % ctl.size(), dehors.is_empty(), ", ".join(dehors))
		var droite := vis.size.x
		var bas := vis.size.y
		var Icone: GDScript = jeu.get_script().get_script_constant_map().get("_IconeCroixFermerCoccOs")
		var croix_en_jeu := _tous(jeu).filter(func(n: Node) -> bool: return n.get_script() == Icone).size()
		_verifier("② aucune croix de fermeture en jeu (22-10 : elle vit à l'accueil)", croix_en_jeu == 0 and jeu.get_node_or_null("CroixCoccOs") == null, "%d icône(s)" % croix_en_jeu)
		var suiv: Rect2 = ctl.get("Nav_suiv", Rect2())
		_verifier("② ► ancré au bord droit (120 px : 20 + les 100 px de l'ex-croix, conservés)", absf(droite - suiv.end.x - 120.0) <= 4.0 and suiv.position.y <= 24.0, str(suiv))
		var vb: Rect2 = ctl.get("Visuel_bas", Rect2())
		var vd: Rect2 = ctl.get("Visuel_droite", Rect2())
		_verifier("② D-pad ancré bas-droite", absf(bas - vb.end.y - 36.0) <= 4.0 and absf(droite - vd.end.x - 20.0) <= 24.0, "%s %s" % [vb, vd])
		var ag: Rect2 = ctl.get("Visuel_agripper", Rect2())
		_verifier("② Agripper ancré bas-gauche", absf(ag.position.x - 80.0) <= 4.0 and absf(bas - ag.end.y - 38.0) <= 4.0, str(ag))
		var rc: Rect2 = ctl.get("Recommencer", Rect2())
		_verifier("② Recommencer haut-gauche", rc.position.is_equal_approx(Vector2(28, 24)), str(rc))
		for n: int in jeu.NIVEAUX.size():
			jeu._aller_a_niveau(n)
			await _trames(3)
			var xf: Transform2D = jeu.get_viewport().get_canvas_transform()
			var ky: float = jeu._plonge_ky
			var hors := 0
			var sous := 0
			var terrain: Array = jeu._terrain
			for y in terrain.size():
				var ligne: String = terrain[y]
				for x in ligne.length():
					if ligne[x] == "#":
						continue
					var a: Vector2 = xf * Vector2(x * 128, y * 128 * ky)
					var b: Vector2 = xf * Vector2((x + 1) * 128, (y + 1) * 128 * ky)
					var cas := Rect2(a, b - a)
					if not vis.grow(TOL).encloses(cas):
						hors += 1
					for nom in ctl:
						if (ctl[nom] as Rect2).grow(-1.0).intersects(cas):
							sous += 1
							break
			_verifier("③ N%d tunnel visible et dégagé (zoom %.2f)" % [n + 1, jeu._cam.zoom.x], hors == 0 and sous == 0, "hors=%d sous=%d" % [hors, sous])
		jeu.queue_free()
		await _trames(3)
	print("--- ④ redimensionnement en jeu 1024×768 → 2400×1080")
	root.size = Vector2i(1024, 768)
	await _trames(2)
	var jeu2: Node = load(SCENE).instantiate()
	root.add_child(jeu2)
	await _trames(6)
	jeu2._quitter_accueil()
	jeu2._aller_a_niveau(14)
	await _trames(3)
	var z_avant: float = jeu2._cam.zoom.x
	root.size = Vector2i(2400, 1080)
	await _trames(4)
	var vis2: Rect2 = root.get_visible_rect()
	var ctl2 := _controles(jeu2)
	var suiv2: Rect2 = ctl2.get("Nav_suiv", Rect2())
	_verifier("④ ► suit le coin réel après redimensionnement", absf(vis2.size.x - suiv2.end.x - 120.0) <= 4.0, "%s dans %s" % [suiv2, vis2.size])
	_verifier("④ plateau recadré (zoom N15 %.2f → %.2f)" % [z_avant, jeu2._cam.zoom.x], not is_equal_approx(z_avant, jeu2._cam.zoom.x))
	jeu2.queue_free()
	await _trames(3)
	print("=== %s (%d échec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
