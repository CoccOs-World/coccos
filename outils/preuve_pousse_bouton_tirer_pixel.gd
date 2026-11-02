# Preuve PIXEL : le LOGO TIRER (avatar + flèche vers lui + boule de pollen, REQ P1 02-11) est DESSINÉ, entier dans son
# bouton, et lisible sans la couleur (trait sombre sur fond clair), en 4:3, 16:9 et 20:9, au doigt et à la souris.
# `--headless` ne rend aucun pixel → vrai affichage SANS prendre l'écran : jeu monté dans un SubViewport à la taille de
# l'écran visible, fenêtre 64×64 (même recette que preuve_pousse_icones_pixel).
# Le LOGO est isolé par DIFFÉRENCE (même rendu, logo caché) :
#   • logo dessiné (≥ 15 % de la surface du bouton) et entier dans le bouton ;
#   • pixels SOMBRES (luminance < 0,25 : flèche, cernes, cadre) ET pixels CLAIRS (fond, luminance > 0,6) tous deux
#     présents en quantité → contraste de luminance, pas la couleur seule ;
#   • l'avatar (moitié gauche) ET la boule (moitié droite, au-dessus de la flèche) changent des pixels.
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
		var gauche := 0
		var droite_haut := 0
		var env := Rect2i()
		var premier := true
		var mx := r.position.x + r.size.x / 2
		var my := r.position.y + r.size.y / 2
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
					if x < mx:
						gauche += 1
					elif y < my:
						droite_haut += 1
		var aire := r.get_area()
		_verifier("%s : logo dessiné (%d px changés, %.0f %% du bouton ≥ 15 %%)" % [etiquette, change, 100.0 * change / aire], change >= aire * 0.15)
		_verifier("%s : logo entier dans le bouton (enveloppe %s)" % [etiquette, env], not premier and r.encloses(env))
		_verifier("%s : sombres %d (≥ 8 %%) ET clairs %d (≥ 20 %%) → contraste de luminance" % [etiquette, sombres, clairs],
			sombres >= aire * 0.08 and clairs >= aire * 0.20)
		_verifier("%s : avatar à gauche (%d px) et boule en haut à droite (%d px) dessinés" % [etiquette, gauche, droite_haut],
			gauche >= aire * 0.08 and droite_haut >= aire * 0.04)
		_verifier("%s : bouton entier dans l'image %s" % [etiquette, img.get_size()], Rect2i(Vector2i.ZERO, img.get_size()).encloses(r))
		sub.queue_free()
		await _trames(3)
	print("=== %s (%d échec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
