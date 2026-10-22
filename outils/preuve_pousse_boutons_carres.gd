# Preuve : boutons « Recommencer » et « Accueil » de Pousse-Pollen = CARRÉS, GROS, ESPACÉS (REQ_pousse_boutons_carres_gros 21-10).
# Retour test Fabrice (Redmi) : deux bandes fines empilées = impossible de viser l'une sans toucher l'autre. Règle Android :
# « boutons carrés, assez gros pour cliquer dessus, assez espacés pour éviter de cliquer sur le mauvais » (modèle 7-diff).
# Monte le VRAI jeu (3 formats × Android/PC) et LIT sur les nœuds et la caméra, sans rien supposer :
#   ① taille RÉELLE de chaque bouton ≥ la cible du 7-diff (62×58), DOUBLÉE au doigt (124×116) ; quasi carrée ; identiques ;
#   ② ÉCART entre les deux (Accueil SOUS Recommencer, colonne gauche) ≥ UNE largeur de bouton, même colonne, sans chevauchement ;
#   ③ les deux boutons sont DANS la zone d'évitement caméra (_rects_boutons()[0]) et cette zone est aussi celle que
#      l'avatar entier évite (_zones_avatar) ;
#   ④ loin des flèches ◄ ► (22-10 : la croix n'est plus en jeu, elle vit à l'accueil) ; entiers dans l'écran visible ;
#   ⑤ l'icône (IconeDessinee) est plein rect et son carré de dessin ≥ 39 px (×2 au doigt) — glyphe du 7-diff à l'échelle ;
#   ⑥ sur les 38 niveaux : AUCUNE case praticable sous un des deux boutons, et l'AVATAR ENTIER (_enveloppe_avatar, posé
#      sur CHAQUE case praticable, projeté par la VRAIE transformée caméra) ne chevauche jamais un des deux boutons.
#      (info, non bloquant : même mesure contre les AUTRES contrôles — D-pad, Agripper, ◄ N ►.)
# Lancement (user:// ISOLÉ) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_pousse_boutons_carres.gd
# Code de sortie 0 = tout vert, 1 = au moins un échec.
extends SceneTree

const SCENE := "res://scenes/pousse_pollen.tscn"
const FORMATS := [Vector2i(1024, 768), Vector2i(1366, 768), Vector2i(2400, 1080)]
const NOMS_FORMAT := ["4:3", "16:9", "20:9"]
const CIBLE_PC := Vector2(62, 58)          # SORTIE_TAILLE du 7-diff
const AUTRES := ["FlechesEcran", "BoutonAgripper", "LabelNiveau", "FlechesNavigation"]   # (22-10) plus de CroixCoccOs en jeu

var _echecs := 0
var _info_autres := 0


func _verifier(libelle: String, vrai: bool, detail: String = "") -> void:
	print("  %s %s%s" % ["ok   " if vrai else "ECHEC", libelle, (" — " + detail) if detail != "" else ""])
	if not vrai:
		_echecs += 1


func _initialize() -> void:
	_derouler.call_deferred()


func _trames(n: int) -> void:
	for i in n:
		await process_frame


func _rects_couches(jeu: Node, couches: Array) -> Dictionary:
	var d := {}
	for nom in couches:
		var couche := jeu.get_node_or_null(nom)
		if couche == null:
			continue
		for c in couche.get_children():
			if c is Control:
				d["%s/%s" % [nom, c.name]] = (c as Control).get_global_rect()
			elif c is TouchScreenButton and (c as TouchScreenButton).shape is RectangleShape2D:
				var tb := c as TouchScreenButton
				var demi: Vector2 = (tb.shape as RectangleShape2D).size * 0.5
				d["%s/%s" % [nom, c.name]] = Rect2(tb.global_position - demi, demi * 2.0)
	return d


func _controler(jeu: Node, etiquette: String, k: float) -> void:
	var vis: Rect2 = root.get_visible_rect()
	var rc: Button = jeu.get_node_or_null("BoutonRecommencer/Recommencer")
	var ac: Button = jeu.get_node_or_null("BoutonAccueil/Accueil")
	_verifier("%s boutons trouvés" % etiquette, rc != null and ac != null)
	if rc == null or ac == null:
		return
	var r1: Rect2 = rc.get_global_rect()
	var r2: Rect2 = ac.get_global_rect()
	var cible := CIBLE_PC * k
	for paire in [["Recommencer", r1], ["Accueil", r2]]:
		var r: Rect2 = paire[1]
		_verifier("① %s %s taille %s ≥ cible %s (7-diff ×%.0f)" % [etiquette, paire[0], r.size, cible, k], r.size.x >= cible.x - 0.5 and r.size.y >= cible.y - 0.5)
		_verifier("① %s %s quasi carré (%.2f)" % [etiquette, paire[0], r.size.x / r.size.y], r.size.x / r.size.y <= 1.15 and r.size.y / r.size.x <= 1.15)
		_verifier("④ %s %s entier dans l'écran visible %s" % [etiquette, paire[0], vis.size], vis.grow(0.5).encloses(r))
	_verifier("① %s mêmes tailles" % etiquette, r1.size.is_equal_approx(r2.size))
	var ecart := r2.position.y - r1.end.y
	_verifier("② %s écart vertical %.0f ≥ une largeur %.0f, même colonne, sans chevauchement" % [etiquette, ecart, r1.size.x],
		ecart >= r1.size.x - 0.5 and is_equal_approx(r1.position.x, r2.position.x) and not r1.intersects(r2))
	var zone: Rect2 = jeu._rects_boutons()[0]
	var zones_av: Array = jeu._zones_avatar()
	_verifier("③ %s zone caméra %s contient les deux boutons (écart compris) et = zone évitée par l'avatar" % [etiquette, zone],
		zone.encloses(r1) and zone.encloses(r2) and zones_av.size() == 1 and (zones_av[0] as Rect2).is_equal_approx(zone))
	var autres := _rects_couches(jeu, AUTRES)
	var trop_pres := []
	for nom in autres:
		var o: Rect2 = autres[nom]
		if o.grow(r1.size.x).intersects(r1) or o.grow(r1.size.x).intersects(r2):
			trop_pres.append(nom)
	_verifier("④ %s à ≥ une largeur des flèches ◄ ►, du D-pad, d'Agripper" % etiquette, trop_pres.is_empty(), ", ".join(trop_pres))
	var Icone: GDScript = jeu.get_script().get_script_constant_map().get("IconeDessinee")
	for paire in [["Recommencer", rc, "rejouer"], ["Accueil", ac, "maison"]]:
		var b: Button = paire[1]
		var ic: Control = null
		for e in b.get_children():
			if e.get_script() == Icone:
				ic = e
		_verifier("⑤ %s %s icône « %s » plein rect" % [etiquette, paire[0], paire[2]], ic != null and ic.forme == paire[2] and ic.get_global_rect().is_equal_approx(b.get_global_rect()))
		if ic != null:
			var carre: float = minf(ic.size.x, ic.size.y) * (1.0 - 2.0 * ic.MARGE)
			_verifier("⑤ %s %s carré de dessin %.1f px ≥ %.0f" % [etiquette, paire[0], carre, 39.0 * k], carre >= 39.0 * k - 0.5)
	# ⑥ tous les niveaux : tunnel et avatar entier jamais sous un des deux boutons
	var cell: float = jeu.CELL
	for n: int in jeu.NIVEAUX.size():
		jeu._aller_a_niveau(n)
		await _trames(3)
		var xf: Transform2D = jeu.get_viewport().get_canvas_transform()
		var z: float = xf.get_scale().x
		var ky: float = jeu._plonge_ky
		var env: Rect2 = jeu._enveloppe_avatar()
		var sous_case := 0
		var sous_avatar := 0
		var autres_avatar := 0
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
				if r1.grow(-1.0).intersects(cas) or r2.grow(-1.0).intersects(cas):
					sous_case += 1
				if r1.intersects(av) or r2.intersects(av):
					sous_avatar += 1
				for nom in autres:
					if (autres[nom] as Rect2).intersects(av):
						autres_avatar += 1
						break
		_verifier("⑥ %s N%d (zoom %.2f) tunnel et avatar entier hors des deux boutons" % [etiquette, n + 1, z], sous_case == 0 and sous_avatar == 0,
			"cases sous bouton=%d, avatar sous bouton=%d" % [sous_case, sous_avatar])
		if autres_avatar > 0:
			_info_autres += 1
			print("  info  %s N%d : avatar chevauchant un AUTRE contrôle sur %d case(s) (non bloquant, hors demande)" % [etiquette, n + 1, autres_avatar])


func _derouler() -> void:
	print("=== PREUVE BOUTONS CARRÉS RECOMMENCER / ACCUEIL POUSSE-POLLEN ===")
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
			await _controler(jeu, etiquette, 2.0 if tactile else 1.0)
			jeu.queue_free()
			await _trames(3)
	print("--- info : %d (niveau × format) où l'avatar chevauche un autre contrôle (hors demande)" % _info_autres)
	print("=== %s (%d échec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
