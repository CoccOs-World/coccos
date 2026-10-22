# Preuve PIXEL : la croix rouge de fermeture est RENDUE sur l'accueil (coin haut-droit) et ABSENTE en jeu, en 16:9 et 20:9.
# `--headless` ne rend AUCUN pixel → vrai affichage, sans prendre l'écran : SubViewport à la taille de l'écran visible,
# fenêtre 64×64. Mesure dans le carré 72×72 à 16 px du bord droit et du haut : à l'accueil, pixels du ROUGE de la croix
# (0.85, 0.35, 0.30 — le rouge des autres jeux, distinct du rouge sombre des loges) majoritaires + pixels BLANCS (la croix) ;
# en jeu, AUCUN pixel de ce rouge dans ce carré.
# Captures (HORS projet Godot, jamais dans l'APK) : <dossier>/preuve_croix_<format>_{accueil,jeu}.png et …_coin_x3.png.
# Lancement :
#   DISPLAY=:0 XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --path . --windowed --resolution 64x64 --position 0,0 \
#       --script res://outils/preuve_pousse_croix_pixel.gd -- <dossier_de_sortie>
extends SceneTree

const SCENE := "res://scenes/pousse_pollen.tscn"
const FORMATS := {"16-9": Vector2i(1280, 720), "20-9": Vector2i(1600, 720)}
const ROUGE := Color(0.85, 0.35, 0.30)

var _echecs := 0
var _dossier := "/tmp"


func _verifier(libelle: String, vrai: bool, detail: String = "") -> void:
	print("  %s %s%s" % ["ok   " if vrai else "ECHEC", libelle, (" — " + detail) if detail != "" else ""])
	if not vrai:
		_echecs += 1


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_dossier = args[0]
	_derouler.call_deferred()


func _trames(n: int) -> void:
	for i in n:
		await process_frame


func _est_rouge(c: Color) -> bool:
	return absf(c.r - ROUGE.r) <= 0.08 and absf(c.g - ROUGE.g) <= 0.08 and absf(c.b - ROUGE.b) <= 0.08


func _compter(img: Image, zone: Rect2i) -> Dictionary:
	var rouges := 0
	var blancs := 0
	for y in range(zone.position.y, zone.end.y):
		for x in range(zone.position.x, zone.end.x):
			var c := img.get_pixel(x, y)
			if _est_rouge(c):
				rouges += 1
			elif c.r > 0.95 and c.g > 0.95 and c.b > 0.95:
				blancs += 1
	return {"rouges": rouges, "blancs": blancs}


func _capturer(sub: SubViewport) -> Image:
	await _trames(4)
	await RenderingServer.frame_post_draw
	return sub.get_texture().get_image()


func _derouler() -> void:
	print("=== PREUVE PIXEL CROIX DE FERMETURE À L'ACCUEIL — POUSSE-POLLEN (SubViewport, fenêtre 64×64) ===")
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
		var taille: Vector2i = sub.size
		var zone := Rect2i(taille.x - 88, 16, 72, 72)
		var etiquette := "%s %s" % [nom_f, taille]
		var accueil: Image = await _capturer(sub)
		accueil.save_png("%s/preuve_croix_%s_accueil.png" % [_dossier, nom_f])
		var coin := accueil.get_region(Rect2i(taille.x - 200, 0, 200, 120))
		coin.resize(600, 360, Image.INTERPOLATE_NEAREST)
		coin.save_png("%s/preuve_croix_%s_accueil_coin_x3.png" % [_dossier, nom_f])
		var ca := _compter(accueil, zone)
		_verifier("%s ACCUEIL : rond rouge rendu au coin haut-droit (%d px rouges sur %d, ≥ 45 %%)" % [etiquette, ca.rouges, zone.get_area()], ca.rouges >= zone.get_area() * 0.45)
		_verifier("%s ACCUEIL : croix blanche dessinée (%d px blancs, ≥ 150)" % [etiquette, ca.blancs], ca.blancs >= 150)
		jeu._quitter_accueil()
		var en_jeu: Image = await _capturer(sub)
		en_jeu.save_png("%s/preuve_croix_%s_jeu.png" % [_dossier, nom_f])
		var coin2 := en_jeu.get_region(Rect2i(taille.x - 200, 0, 200, 120))
		coin2.resize(600, 360, Image.INTERPOLATE_NEAREST)
		coin2.save_png("%s/preuve_croix_%s_jeu_coin_x3.png" % [_dossier, nom_f])
		var cj := _compter(en_jeu, zone)
		_verifier("%s JEU : aucun pixel du rouge de la croix au coin haut-droit (%d px)" % [etiquette, cj.rouges], cj.rouges == 0)
		sub.queue_free()
		await _trames(3)
	print("=== %s (%d échec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
