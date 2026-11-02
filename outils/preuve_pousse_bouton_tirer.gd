# Preuve : bouton TIRER de Pousse-Pollen = LOGO sans mot, PLUS GRAND, PAS GÊNANT (REQ P1, 02-11).
# Fabrice 08-10 : « logo illustré SANS MOT : petit CoccOs reconnaissable + une flèche VERS LUI + au-dessus de la flèche,
# une boule de pollen ». 02-11 : « Il faut qu'il soit plus grand. Et il ne faut pas non plus qu'il devienne gênant. »
# Monte le VRAI jeu (3 formats × Android/PC) et LIT les nœuds, la caméra et les tableaux, sans rien supposer :
#   ① logo présent (LogoTirer plein rect du visuel), AUCUN texte (aucun Label/Button à texte non vide dans le bouton) ;
#      (P1b, 02-11) DISPOSITION lue dans LogoTirer.geometrie() : de haut en bas boule de pollen > avatar > flèche, sans
#      chevauchement, centrés ; avatar PLUS PETIT (≤ 50 % de la hauteur utile) ; flèche POINTE EN BAS ; tout dans le bouton ;
#   ② plus grand que l'ancien mot (150×72) dans les deux sens ; ×1,25 au doigt ; zone tactile = visuel ;
#   ③ entier dans l'écran visible ; ne touche ni le D-pad, ni Recommencer/Accueil, ni ◄ N ► ;
#   ④ sur les 38 niveaux : AUCUNE case praticable sous le bouton, l'AVATAR ENTIER (posé sur chaque case praticable,
#      projeté par la VRAIE transformée caméra) jamais sous le bouton ;
#   ⑥ (P1c, 02-11) « le bouton est beaucoup plus trop large […] Tous les trois alignés […] centré sur l'espace qu'il y a entre
#      le tableau du jeu et le bord de la fenêtre » · « La hauteur, on ne la change pas » · « que ce bouton soit un carré » :
#      sur CHAQUE niveau × format × doigt/souris, relu sur les NŒUDS : TIRER carré, hauteur P1b (112/140) ; y de Recommencer,
#      d'Accueil et du bas de TIRER = ceux de P1b ; centres x des trois égaux ; axe = milieu entre x 0 et le bord gauche du
#      plateau (colonne 0 de la grille, projetée par la VRAIE transformée caméra) — ou, si le plateau passe sous la colonne,
#      axe minimal (plus large bouton à COLONNE_MARGE_MIN du bord) ; garde-fou du jeu jamais déclenché (compté) ;
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
const HAUTEUR_P1B := 112.0                 # hauteur du TIRER en P1b (souris) — « La hauteur, on ne la change pas »

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


# (P1b) Fabrice 02-11 : « la boule de pollen en haut, l'avatar en dessous, la flèche en dessous de l'avatar […] elle garde
# la même direction que si elle était entre la boule de pollen et l'avatar » → pointe EN BAS.
func _disposition(logo: Control, etiquette: String) -> void:
	var g: Dictionary = logo.geometrie()
	_verifier("① %s géométrie du logo calculée" % etiquette, not g.is_empty())
	if g.is_empty():
		return
	var c: Vector2 = g["boule_c"]
	var rb: float = g["boule_r"]
	var boule := Rect2(c - Vector2.ONE * rb, Vector2.ONE * rb * 2.0)
	var av: Rect2 = g["avatar"]
	var fl: Rect2 = g["fleche"]
	var q: Vector2 = g["queue"]
	var pt: Vector2 = g["pointe"]
	var z: Rect2 = g["zone"]
	_verifier("① %s ordre vertical : boule (bas %.1f) AU-DESSUS de l'avatar (haut %.1f)" % [etiquette, boule.end.y, av.position.y],
		boule.end.y <= av.position.y)
	_verifier("① %s ordre vertical : avatar (bas %.1f) AU-DESSUS de la flèche (haut %.1f)" % [etiquette, av.end.y, fl.position.y],
		av.end.y <= fl.position.y)
	_verifier("① %s flèche POINTE EN BAS (queue y %.1f → pointe y %.1f, pointe = bas de la flèche)" % [etiquette, q.y, pt.y],
		pt.y > q.y + 1.0 and is_equal_approx(pt.y, fl.end.y) and is_equal_approx(q.y, fl.position.y))
	_verifier("① %s boule, avatar, flèche centrés (x %.1f / %.1f / %.1f)" % [etiquette, c.x, av.get_center().x, pt.x],
		absf(c.x - av.get_center().x) < 0.5 and absf(pt.x - av.get_center().x) < 0.5 and absf(q.x - pt.x) < 0.5)
	_verifier("① %s avatar plus petit : %.1f px de haut ≤ 50 %% de %.1f (P1 : 100 %%)" % [etiquette, av.size.y, z.size.y],
		av.size.y <= z.size.y * 0.5 and av.size.y >= z.size.y * 0.3)
	var dedans := Rect2(Vector2.ZERO, logo.size)
	_verifier("① %s boule, avatar et flèche entiers dans le bouton %s" % [etiquette, logo.size],
		dedans.encloses(boule) and dedans.encloses(av) and dedans.encloses(fl))


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
	if logo != null:
		_disposition(logo, etiquette)
	var textes := _textes(visuel)
	_verifier("① %s aucun texte sur le bouton" % etiquette, textes.is_empty(), str(textes))
	_verifier("② %s taille %s plus HAUTE que l'ancien %s (P1c : largeur ramenée au carré)" % [etiquette, r.size, ANCIEN], r.size.y > ANCIEN.y)
	_verifier("② %s taille = TIRER_TAILLE ×%.2f" % [etiquette, k], r.size.is_equal_approx(jeu.TIRER_TAILLE * k))
	_verifier("⑥ %s CARRÉ %s, hauteur P1b inchangée (%.0f)" % [etiquette, r.size, HAUTEUR_P1B * k],
		is_equal_approx(r.size.x, r.size.y) and is_equal_approx(r.size.y, HAUTEUR_P1B * k))
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
	var ko6 := 0
	var nb_centre := 0
	var nb_serre := 0
	var garde_fou := 0
	var rec: Button = jeu.get_node_or_null("BoutonRecommencer/Recommencer")
	var acc: Button = jeu.get_node_or_null("BoutonAccueil/Accueil")
	var ti: Vector2 = jeu._taille_bouton_icone()
	var y_rec := 24.0                                   # P1b : RECOMMENCER_POS.y
	var y_acc := 24.0 + ti.y + ti.x                     # P1b : sous Recommencer, une largeur d'écart
	var bas_tirer := 730.0 + vis.size.y - 768.0         # P1b : bas TIRER_COIN_BG ancré bas
	for n: int in jeu.NIVEAUX.size():
		jeu._aller_a_niveau(n)
		await _trames(3)
		r = visuel.get_global_rect()                    # (P1c) la colonne bouge avec le cadrage → relue à chaque niveau
		var xf: Transform2D = jeu.get_viewport().get_canvas_transform()
		# ⑥ colonne : carré, rien en vertical, centres alignés, axe centré dans l'espace bord ↔ plateau
		var rr: Rect2 = rec.get_global_rect()
		var ra: Rect2 = acc.get_global_rect()
		var L: float = (xf * Vector2.ZERO).x                # bord gauche ÉCRAN du plateau (colonne 0 de la grille)
		var axe: float = r.get_center().x
		var axe_min: float = jeu._axe_colonne_min()
		var detail := []
		if not (is_equal_approx(r.size.x, r.size.y) and is_equal_approx(r.size.y, HAUTEUR_P1B * k)):
			detail.append("TIRER %s pas carré/hauteur" % r.size)
		if absf(rr.position.y - y_rec) > 0.5 or absf(ra.position.y - y_acc) > 0.5 or absf(r.end.y - bas_tirer) > 0.5:
			detail.append("vertical bougé rec %.1f acc %.1f bas TIRER %.1f" % [rr.position.y, ra.position.y, r.end.y])
		if not rr.size.is_equal_approx(ti) or not ra.size.is_equal_approx(ti):
			detail.append("taille icônes %s %s" % [rr.size, ra.size])
		if absf(rr.get_center().x - axe) > 0.5 or absf(ra.get_center().x - axe) > 0.5 or absf(_rect_tsb(tsb).get_center().x - axe) > 0.5:
			detail.append("centres x rec %.1f acc %.1f TIRER %.1f" % [rr.get_center().x, ra.get_center().x, axe])
		if L * 0.5 >= axe_min:
			if absf(axe - L * 0.5) <= 0.5:
				nb_centre += 1
				if r.end.x > L - jeu.COLONNE_MARGE_MIN + 0.5:
					detail.append("TIRER déborde sur le plateau (%.1f > %.1f)" % [r.end.x, L])
			elif axe < L * 0.5 and axe >= axe_min - 0.5:
				garde_fou += 1
			else:
				detail.append("axe %.1f ≠ milieu %.1f (plateau à %.1f)" % [axe, L * 0.5, L])
		else:
			if absf(axe - axe_min) <= 0.5:
				nb_serre += 1
			else:
				detail.append("plateau sous la colonne (L %.1f) mais axe %.1f ≠ minimal %.1f" % [L, axe, axe_min])
		if r.position.x < -0.5:
			detail.append("TIRER sort à gauche (%.1f)" % r.position.x)
		if r.grow(jeu.GARDE_BOUTON).intersects(ra):
			detail.append("TIRER touche Accueil")
		if not detail.is_empty():
			ko6 += 1
			_verifier("⑥ %s N%d (plateau à x %.1f, axe %.1f)" % [etiquette, n + 1, L, axe], false, " ; ".join(detail))
		else:
			print("  info ⑥ %s N%d plateau x %.1f → axe %.1f (%s)" % [etiquette, n + 1, L, axe, "centré" if L * 0.5 >= axe_min else "serré"])
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
				for bt: Rect2 in [r, rr, ra]:             # (P1c) Recommencer et Accueil bougent aussi en x → vérifiés pareil
					if bt.grow(-1.0).intersects(cas):
						sous_case += 1
					if bt.grow(-1.0).intersects(av):
						sous_avatar += 1
		if sous_case + sous_avatar > 0:
			pires += 1
			_verifier("④ %s N%d (zoom %.2f)" % [etiquette, n + 1, z], false, "cases sous la colonne=%d, avatar sous la colonne=%d" % [sous_case, sous_avatar])
	_verifier("④ %s 38 niveaux : tunnel et avatar entier jamais sous TIRER, Recommencer ni Accueil" % etiquette, pires == 0)
	_verifier("⑥ %s 38 niveaux : carré, rien en vertical, 3 centres alignés, axe = milieu bord ↔ plateau (%d centrés, %d serrés : plateau sous la colonne)" % [etiquette, nb_centre, nb_serre],
		ko6 == 0 and nb_centre + nb_serre + garde_fou == jeu.NIVEAUX.size())
	_verifier("⑥ %s garde-fou « rapprocher l'axe » jamais déclenché (%d)" % [etiquette, garde_fou], garde_fou == 0)


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
