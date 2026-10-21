# Preuve PIXEL : les icônes « rejouer » et « maison » sont DESSINÉES et entières dans leur bouton, en 16:9 et 20:9.
# `--headless` ne rend AUCUN pixel → cette preuve tourne sur un vrai affichage, mais SANS prendre l'écran : le jeu est
# monté dans un SubViewport à la taille de l'écran visible (1280×720, 1600×720) et la fenêtre reste minuscule (64×64).
# L'accueil est retiré (`_quitter_accueil`, ce que fait « Jouer ») pour voir le HUD du jeu.
# Le GLYPHE est isolé par DIFFÉRENCE : même rendu avec les icônes cachées → les pixels qui changent sont le glyphe
# (la bordure sombre du bouton, de la même teinte, ne pollue pas la mesure). Pour chaque bouton :
#   • masque non vide = glyphe présent ;
#   • enveloppe du masque DANS le bouton hors bordure de 3 px = « non mangée », et ne touche pas la bordure ;
#   • pixels CLAIRS (COL_SORTIE) majoritaires dans le bouton = fond du 7-diff bien peint.
# Captures : /tmp/preuve_pousse_icones_<format>.png (plein HUD) et …_hud_x3.png (coin haut-gauche agrandi ×3).
# Lancement :
#   DISPLAY=:0 XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --path . --windowed --resolution 64x64 --position 0,0 \
#       --script res://outils/preuve_pousse_icones_pixel.gd
extends SceneTree

const SCENE := "res://scenes/pousse_pollen.tscn"
const FORMATS := {"16-9": Vector2i(1280, 720), "20-9": Vector2i(1600, 720)}
const BOUTONS := {"Recommencer": "BoutonRecommencer/Recommencer", "Accueil": "BoutonAccueil/Accueil"}

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


func _proche(c: Color, ref: Color, tol: float) -> bool:
	return absf(c.r - ref.r) <= tol and absf(c.g - ref.g) <= tol and absf(c.b - ref.b) <= tol


func _mesurer(img: Image, sans: Image, jeu: Node, nom: String, etiquette: String) -> void:
	var b: Button = jeu.get_node(BOUTONS[nom])
	var r: Rect2i = Rect2i(b.get_global_rect())
	var interieur := Rect2i(r.position + Vector2i(3, 3), r.size - Vector2i(6, 6))   # hors bordure de 3 px
	var glyphe := 0
	var clairs := 0
	var env := Rect2i()
	var premier := true
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := img.get_pixel(x, y)
			if not c.is_equal_approx(sans.get_pixel(x, y)):
				glyphe += 1
				var p := Rect2i(x, y, 1, 1)
				env = p if premier else env.merge(p)
				premier = false
			elif _proche(c, jeu.COL_SORTIE, 0.08):
				clairs += 1
	_verifier("%s %s : glyphe dessiné (%d px, enveloppe %s)" % [etiquette, nom, glyphe, env], glyphe >= 60)
	_verifier("%s %s : glyphe entier dans le bouton, hors bordure (non mangé)" % [etiquette, nom],
		not premier and interieur.encloses(env), "%s dans %s" % [env, interieur])
	_verifier("%s %s : fond clair du 7-diff peint (%d px clairs)" % [etiquette, nom, clairs], clairs > glyphe * 4)
	_verifier("%s %s : bouton entier dans l'image %s" % [etiquette, nom, img.get_size()],
		Rect2i(Vector2i.ZERO, img.get_size()).encloses(r))


func _derouler() -> void:
	print("=== PREUVE PIXEL ICÔNES POUSSE-POLLEN (SubViewport, fenêtre 64×64) ===")
	var reglages := ConfigFile.new()
	reglages.set_value("interface", "mode_tactile", true)
	reglages.save("user://config.cfg")
	for nom_f in FORMATS:
		var sub := SubViewport.new()
		sub.size = FORMATS[nom_f]
		sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(sub)
		var jeu: Node = load(SCENE).instantiate()
		sub.add_child(jeu)
		await _trames(6)
		jeu._quitter_accueil()
		await _trames(6)
		await RenderingServer.frame_post_draw
		var img: Image = sub.get_texture().get_image()
		var etiquette := "%s %s" % [nom_f, sub.get_visible_rect().size]
		img.save_png("/tmp/preuve_pousse_icones_%s.png" % nom_f)
		var coin := img.get_region(Rect2i(0, 0, 300, 120))
		coin.resize(900, 360, Image.INTERPOLATE_NEAREST)
		coin.save_png("/tmp/preuve_pousse_icones_%s_hud_x3.png" % nom_f)
		var icones := []
		for nom in BOUTONS:
			for e in jeu.get_node(BOUTONS[nom]).get_children():
				if e is Control:
					e.visible = false
					icones.append(e)
		await _trames(4)
		await RenderingServer.frame_post_draw
		var sans: Image = sub.get_texture().get_image()
		for e in icones:
			e.visible = true
		for nom in BOUTONS:
			_mesurer(img, sans, jeu, nom, etiquette)
		sub.queue_free()
		await _trames(3)
	print("=== %s (%d échec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
