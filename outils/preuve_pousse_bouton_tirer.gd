# Preuve : bouton TIRER de Pousse-Pollen = LOGO sans mot, PLUS GRAND, PAS GÊNANT (REQ P1, 02-11).
# Fabrice 08-10 : « logo illustré SANS MOT : petit CoccOs reconnaissable + une flèche VERS LUI + au-dessus de la flèche,
# une boule de pollen ». 02-11 : « Il faut qu'il soit plus grand. Et il ne faut pas non plus qu'il devienne gênant. »
# Monte le VRAI jeu (3 formats × Android/PC) et LIT les nœuds, la caméra et les tableaux, sans rien supposer :
#   ① logo présent (LogoTirer plein rect du visuel), AUCUN texte (aucun Label/Button à texte non vide dans le bouton) ;
#   ② plus grand que l'ancien mot (150×72) dans les deux sens ; ×1,25 au doigt ; zone tactile = visuel ;
#   ③ entier dans l'écran visible ; ne touche ni le D-pad, ni Recommencer/Accueil, ni ◄ N ► ;
#   ④ sur les 38 niveaux : AUCUNE case praticable sous le bouton, l'AVATAR ENTIER (posé sur chaque case praticable,
#      projeté par la VRAIE transformée caméra) jamais sous le bouton ;
#   ⑤ rien d'autre ne change : maintien (pressed → tirer actif + doré, released → relâché), guide N4 qui PULSE le bouton
#      (le logo est enfant du visuel pulsé), espace = maintien PC.
# Lancement (user:// ISOLÉ) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_pousse_bouton_tirer.gd
# Code de sortie 0 = tout vert, 1 = au moins un échec.
extends SceneTree

const SCENE := "res://scenes/pousse_pollen.tscn"
const FORMATS := [Vector2i(1024, 768), Vector2i(1366, 768), Vector2i(2400, 1080)]
const NOMS_FORMAT := ["4:3", "16:9", "20:9"]
const ANCIEN := Vector2(150, 72)           # l'ancien bouton « Agripper » (main 3554d47)

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


func _rect_tsb(tb: TouchScreenButton) -> Rect2:
	var demi: Vector2 = (tb.shape as RectangleShape2D).size * 0.5
	return Rect2(tb.global_position - demi, demi * 2.0)


func _textes(n: Node) -> Array:
	var t := []
	for e in n.get_children():
		if (e is Label or e is Button) and e.text.strip_edges() != "":
			t.append(e.text)
		t.append_array(_textes(e))
	return t


func _controler(jeu: Node, etiquette: String, k: float) -> void:
	var vis: Rect2 = jeu.get_viewport().get_visible_rect()
	var visuel: ColorRect = jeu.get_node_or_null("BoutonAgripper/Visuel_agripper")
	var tsb: TouchScreenButton = jeu.get_node_or_null("BoutonAgripper/Touche_agripper")
	_verifier("%s bouton TIRER trouvé (visuel + zone tactile)" % etiquette, visuel != null and tsb != null)
	if visuel == null or tsb == null:
		return
	var r: Rect2 = visuel.get_global_rect()
	var logo: Control = visuel.get_node_or_null("LogoTirer")
	_verifier("① %s logo TIRER présent, plein rect du bouton" % etiquette, logo != null and logo.get_global_rect().is_equal_approx(r))
	var textes := _textes(visuel)
	_verifier("① %s aucun texte sur le bouton" % etiquette, textes.is_empty(), str(textes))
	_verifier("② %s taille %s plus grande que l'ancien %s" % [etiquette, r.size, ANCIEN], r.size.x > ANCIEN.x and r.size.y > ANCIEN.y)
	_verifier("② %s taille = TIRER_TAILLE ×%.2f" % [etiquette, k], r.size.is_equal_approx(jeu.TIRER_TAILLE * k))
	_verifier("② %s zone tactile = visuel" % etiquette, _rect_tsb(tsb).is_equal_approx(r), "%s / %s" % [_rect_tsb(tsb), r])
	_verifier("③ %s entier dans l'écran visible %s" % [etiquette, vis.size], vis.grow(0.5).encloses(r), str(r))
	var gene := []
	for nom in ["FlechesEcran", "LabelNiveau", "FlechesNavigation", "BoutonRecommencer", "BoutonAccueil"]:
		var couche := jeu.get_node_or_null(nom)
		if couche == null:
			continue
		for c in couche.get_children():
			var o := Rect2()
			if c is Control and (c as Control).visible:
				o = (c as Control).get_global_rect()
			elif c is TouchScreenButton and (c as TouchScreenButton).shape is RectangleShape2D:
				o = _rect_tsb(c)
			if o.has_area() and o.intersects(r.grow(jeu.GARDE_BOUTON)):
				gene.append("%s/%s" % [nom, c.name])
	_verifier("③ %s ne touche aucun autre contrôle (D-pad, Recommencer, Accueil, ◄ N ►), jeu de %.0f px compris" % [etiquette, jeu.GARDE_BOUTON], gene.is_empty(), ", ".join(gene))
	# ④ 38 niveaux
	var cell: float = jeu.CELL
	var pires := 0
	for n: int in jeu.NIVEAUX.size():
		jeu._aller_a_niveau(n)
		await _trames(3)
		var xf: Transform2D = jeu.get_viewport().get_canvas_transform()
		var z: float = xf.get_scale().x
		var ky: float = jeu._plonge_ky
		var env: Rect2 = jeu._enveloppe_avatar()
		var sous_case := 0
		var sous_avatar := 0
		var terrain: Array = jeu._terrain
		for y in terrain.size():
			var ligne: String = terrain[y]
			for x in ligne.length():
				if ligne[x] == "#":
					continue
				var a: Vector2 = xf * Vector2(x * cell, y * cell * ky)
				var b: Vector2 = xf * Vector2((x + 1) * cell, (y + 1) * cell * ky)
				var cas := Rect2(a, b - a)
				var centre: Vector2 = xf * Vector2((x + 0.5) * cell, (y + 0.5) * cell * ky)
				var av := Rect2(centre + env.position * z, env.size * z)
				if r.grow(-1.0).intersects(cas):
					sous_case += 1
				if r.grow(-1.0).intersects(av):
					sous_avatar += 1
		if sous_case + sous_avatar > 0:
			pires += 1
			_verifier("④ %s N%d (zoom %.2f)" % [etiquette, n + 1, z], false, "cases sous TIRER=%d, avatar sous TIRER=%d" % [sous_case, sous_avatar])
	_verifier("④ %s 38 niveaux : tunnel et avatar entier jamais sous le bouton TIRER" % etiquette, pires == 0)


func _mecanique(jeu: Node, etiquette: String) -> void:
	var visuel: ColorRect = jeu.get_node("BoutonAgripper/Visuel_agripper")
	var tsb: TouchScreenButton = jeu.get_node("BoutonAgripper/Touche_agripper")
	tsb.pressed.emit()
	await _trames(1)
	_verifier("⑤ %s appui tenu → tirer actif + fond doré" % etiquette, jeu._agripper_actif() and visuel.color.is_equal_approx(jeu.COL_TOUCHE_ACTIVE))
	tsb.released.emit()
	await _trames(1)
	_verifier("⑤ %s relâché → tirer inactif + fond de repos" % etiquette, not jeu._agripper_actif() and visuel.color.is_equal_approx(jeu.COL_TOUCHE))
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_SPACE
	ev.pressed = true
	Input.parse_input_event(ev)
	await _trames(2)
	var tenu: bool = jeu._agripper_actif()
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)
	await _trames(2)
	_verifier("⑤ %s barre espace = maintien (tenu %s, relâché %s)" % [etiquette, tenu, not jeu._agripper_actif()], tenu and not jeu._agripper_actif())
	# Guide N4 : niveau index 3, avatar SOUS une boule → le bouton pulse (logo compris, enfant du visuel).
	jeu._aller_a_niveau(3)
	await _trames(3)
	var ok_case := false
	for i in jeu._boules.size():
		var dessous: Vector2i = jeu._boules[i] + Vector2i(0, 1)
		var ligne: String = jeu._terrain[dessous.y] if dessous.y < jeu._terrain.size() else "#"
		if dessous.x < ligne.length() and ligne[dessous.x] != "#" and jeu._index_boule(dessous) == -1:
			jeu._avatar = dessous
			ok_case = true
			break
	jeu._deja_deplace = true
	jeu._maj_guide_tirer()
	var mini := 1.0
	for i in 60:
		await process_frame
		mini = minf(mini, visuel.modulate.a)
	_verifier("⑤ %s guide N4 : le bouton TIRER PULSE (alpha min %.2f < 0,9), logo dedans" % [etiquette, mini],
		ok_case and mini < 0.9 and visuel.get_node_or_null("LogoTirer") != null)
	jeu._arreter_guide_tirer()


func _derouler() -> void:
	print("=== PREUVE BOUTON TIRER POUSSE-POLLEN (logo, taille, sans gêne) ===")
	for tactile in [true, false]:
		var reglages := ConfigFile.new()
		reglages.set_value("interface", "mode_tactile", tactile)
		reglages.save("user://config.cfg")
		for i in FORMATS.size():
			var f: Vector2i = FORMATS[i]
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
			var etiquette := "%s %s %s" % ["Android" if tactile else "PC", NOMS_FORMAT[i], root.get_visible_rect().size]
			await _controler(jeu, etiquette, jeu.TIRER_FACTEUR_TACTILE if tactile else 1.0)
			if i == 0:
				await _mecanique(jeu, etiquette)
			jeu.queue_free()
			await _trames(3)
	print("=== %s (%d échec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
