# Preuve PIXEL : le LOGO TIRER (REQ P1b 02-11 : empilé boule de pollen · avatar · flèche pointe en bas) est DESSINÉ, entier dans son
# bouton, et lisible sans la couleur (trait sombre sur fond clair), en 4:3, 16:9 et 20:9, au doigt et à la souris.
# `--headless` ne rend aucun pixel → vrai affichage SANS prendre l'écran : jeu monté dans un SubViewport à la taille de
# l'écran visible, fenêtre 64×64 (même recette que preuve_pousse_icones_pixel).
# Le LOGO est isolé par DIFFÉRENCE (même rendu, logo caché) :
#   • logo dessiné (≥ 10 % de la surface du bouton — P1b : avatar plus petit voulu, P1 exigeait 15 %) et entier dans le bouton ;
#   • pixels SOMBRES (luminance < 0,25 : flèche, cernes, cadre) ET pixels CLAIRS (fond, luminance > 0,6) tous deux
#     présents en quantité → contraste de luminance, pas la couleur seule ;
#   • la boule, l'avatar ET la flèche changent des pixels CHACUN dans sa case (geometrie() du logo), de haut en bas ;
#   • la flèche POINTE EN BAS, lu sur les pixels sombres : la rangée la plus large (base de la tête) est AU-DESSUS de la
#     dernière rangée sombre (la pointe), qui est étroite, et le trait du haut est étroit.
# Captures : /tmp/preuve_pousse_tirer_<cas>.png (écran entier) et …_bouton_x2.png (bouton agrandi ×2).
# Lancement :
#   xvfb-run -a -s "-screen 0 1920x1080x24" Godot_v4.7.2 --path . --windowed --resolution 64x64 --position 0,0 \
#       --script res://outils/preuve_pousse_bouton_tirer_pixel.gd
extends SceneTree

const SCENE := "res://scenes/pousse_pollen.tscn"
# [nom du cas, taille de l'écran visible, tactile, avatar (0 coccinelle, 1 abeille)]
const CAS := [
	["4-3_doigt", Vector2i(1280, 960), true, 0],
	["16-9_doigt", Vector2i(1280, 720), true, 0],
	["20-9_doigt", Vector2i(1600, 720), true, 0],
	["16-9_souris", Vector2i(1280, 720), false, 0],
	["20-9_doigt_abeille", Vector2i(1600, 720), true, 1],
]

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


func _derouler() -> void:
	print("=== PREUVE PIXEL BOUTON TIRER POUSSE-POLLEN (SubViewport, fenêtre 64×64) ===")
	for cas in CAS:
		var reglages := ConfigFile.new()
		reglages.set_value("interface", "mode_tactile", cas[2])
		reglages.save("user://config.cfg")
		var sub := SubViewport.new()
		sub.size = cas[1]
		sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(sub)
		var jeu: Node = load(SCENE).instantiate()
		sub.add_child(jeu)
		await _trames(6)
		jeu._choisir_avatar(cas[3])
		jeu._quitter_accueil()
		await _trames(6)
		await RenderingServer.frame_post_draw
		var img: Image = sub.get_texture().get_image()
		var visuel: Control = jeu.get_node("BoutonAgripper/Visuel_agripper")
		var logo: Control = visuel.get_node("LogoTirer")
		var r := Rect2i(visuel.get_global_rect())
		var etiquette := "%s %s bouton %s" % [cas[0], sub.get_visible_rect().size, r]
		img.save_png("/tmp/preuve_pousse_tirer_%s.png" % cas[0])
		var bouton := img.get_region(r)
		bouton.resize(r.size.x * 2, r.size.y * 2, Image.INTERPOLATE_NEAREST)
		bouton.save_png("/tmp/preuve_pousse_tirer_%s_bouton_x2.png" % cas[0])
		logo.visible = false
		await _trames(4)
		await RenderingServer.frame_post_draw
		var sans: Image = sub.get_texture().get_image()
		logo.visible = true
		var change := 0
		var sombres := 0
		var clairs := 0
		var g: Dictionary = logo.geometrie()
		var o := logo.get_global_rect().position
		var cb: Vector2 = g["boule_c"]
		var rb: float = g["boule_r"]
		var cases := {
			"boule": Rect2i(Rect2(o + cb - Vector2.ONE * rb, Vector2.ONE * rb * 2.0)),
			"avatar": Rect2i(Rect2(o + (g["avatar"] as Rect2).position, (g["avatar"] as Rect2).size)),
			"flèche": Rect2i(Rect2(o + (g["fleche"] as Rect2).position, (g["fleche"] as Rect2).size)),
		}
		var dans := {"boule": 0, "avatar": 0, "flèche": 0}
		var env := Rect2i()
		var premier := true
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var c := img.get_pixel(x, y)
				var l := c.get_luminance()
				if l < 0.25:
					sombres += 1
				elif l > 0.6:
					clairs += 1
				if not c.is_equal_approx(sans.get_pixel(x, y)):
					change += 1
					env = Rect2i(x, y, 1, 1) if premier else env.merge(Rect2i(x, y, 1, 1))
					premier = false
					for k in cases:
						if cases[k].has_point(Vector2i(x, y)):
							dans[k] += 1
		var aire := r.get_area()
		_verifier("%s : logo dessiné (%d px changés, %.0f %% du bouton ≥ 10 %%)" % [etiquette, change, 100.0 * change / aire], change >= aire * 0.10)
		_verifier("%s : logo entier dans le bouton (enveloppe %s)" % [etiquette, env], not premier and r.encloses(env))
		_verifier("%s : sombres %d (≥ 8 %%) ET clairs %d (≥ 20 %%) → contraste de luminance" % [etiquette, sombres, clairs],
			sombres >= aire * 0.08 and clairs >= aire * 0.20)
		for k in cases:
			var a: int = cases[k].get_area()
			_verifier("%s : %s dessinée dans sa case %s (%d px, ≥ 25 %%)" % [etiquette, k, cases[k], dans[k]], dans[k] >= a * 0.25)
		_verifier("%s : de haut en bas boule %d < avatar %d < flèche %d (y des cases, sans chevauchement)" % [etiquette,
			cases["boule"].position.y, cases["avatar"].position.y, cases["flèche"].position.y],
			cases["boule"].end.y <= cases["avatar"].position.y + 1 and cases["avatar"].end.y <= cases["flèche"].position.y + 1)
		# Sens de la flèche, lu sur les pixels SOMBRES de sa case, rangée par rangée.
		var fr: Rect2i = cases["flèche"]
		var larg := []
		for y in range(fr.position.y, fr.end.y + 1):
			var n := 0
			for x in range(fr.position.x, fr.end.x):
				if img.get_pixel(x, y).get_luminance() < 0.25:
					n += 1
			larg.append(n)
		var y_max := 0
		var y_bas := -1
		for i in larg.size():
			if larg[i] > larg[y_max]:
				y_max = i
			if larg[i] > 0:
				y_bas = i
		var y_haut := 0
		while y_haut < larg.size() and larg[y_haut] == 0:
			y_haut += 1
		var haut_w: int = larg[mini(y_haut + 1, larg.size() - 1)]
		var bas_w: int = larg[y_bas] if y_bas >= 0 else 0
		_verifier("%s : flèche POINTE EN BAS (largeur sombre : trait du haut %d px, base de tête %d px à la rangée %d, pointe %d px à la rangée %d)"
			% [etiquette, haut_w, larg[y_max], y_max, bas_w, y_bas],
			y_bas > y_max + 2 and bas_w * 2 < larg[y_max] and haut_w * 2 < larg[y_max])
		_verifier("%s : bouton entier dans l'image %s" % [etiquette, img.get_size()], Rect2i(Vector2i.ZERO, img.get_size()).encloses(r))
		sub.queue_free()
		await _trames(3)
	print("=== %s (%d échec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
