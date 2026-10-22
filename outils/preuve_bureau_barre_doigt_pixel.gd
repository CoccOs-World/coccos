# Preuve PIXEL #223/#224 : le bureau Android RENDU en 16:9 et 20:9 — barre de 114 px en bas, roue des
# reglages et bouton eteindre dessines a droite, coccinelle « petit » (defaut Android #223) posee SUR la
# roue comme apres un tap au doigt brut (#224 : hotspot sous le doigt, decalage annule).
# `--headless` ne rend AUCUN pixel → vrai affichage sans prendre l'ecran : SubViewport a la taille de
# l'ecran visible, fenetre 64x64 sans focus. Mesures :
#   - hauteur RENDUE de la coccinelle (difference curseur visible / masque), mesuree au CENTRE de
#     l'ecran (posee sur la roue, elle deborde sous le bord bas et la mesure serait rognee) :
#     ≈ 72 px x 0,55 x 2 = 79 ; en « moyen » (origine) elle ferait 144 px → la mesure departage ;
#   - roue (gris 0.45/0.45/0.50) et eteindre (rouge 0.75/0.25/0.22) presents dans leur rect, dans la barre.
# Captures (HORS projet Godot, jamais dans l'APK) : <dossier>/preuve_bureau_<format>.png + …_coin_x3.png.
# Lancement :
#   DISPLAY=:0 XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --path . --windowed --resolution 64x64 --position 0,0 \
#       --audio-driver Dummy --script res://outils/preuve_bureau_barre_doigt_pixel.gd -- <dossier_de_sortie>
extends SceneTree

const PinConfig := preload("res://scripts/pin_config.gd")
const FORMATS := {"16-9": Vector2i(1280, 720), "20-9": Vector2i(1600, 720)}
const HAUTEUR_PETIT := 72.0 * 0.55 * 2.0  # 79,2 px
const GRIS_ROUE := Color(0.45, 0.45, 0.50)
const ROUGE_ETEINDRE := Color(0.75, 0.25, 0.22)

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
	root.set_flag(Window.FLAG_NO_FOCUS, true)
	_derouler.call_deferred()


func _trames(n: int) -> void:
	for i in n:
		await process_frame


func _capturer(sub: SubViewport) -> Image:
	await _trames(4)
	await RenderingServer.frame_post_draw
	return sub.get_texture().get_image()


func _proche(c: Color, ref: Color) -> bool:
	return absf(c.r - ref.r) <= 0.06 and absf(c.g - ref.g) <= 0.06 and absf(c.b - ref.b) <= 0.06


func _compter(img: Image, zone: Rect2i, ref: Color) -> int:
	var n := 0
	for y in range(zone.position.y, zone.end.y):
		for x in range(zone.position.x, zone.end.x):
			if _proche(img.get_pixel(x, y), ref):
				n += 1
	return n


## Boite englobante des pixels qui different entre deux rendus (le curseur).
func _bbox_difference(a: Image, b: Image) -> Rect2i:
	var mn := Vector2i(a.get_width(), a.get_height())
	var mx := Vector2i(-1, -1)
	for y in a.get_height():
		for x in a.get_width():
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b) > 0.1:
				mn = Vector2i(mini(mn.x, x), mini(mn.y, y))
				mx = Vector2i(maxi(mx.x, x), maxi(mx.y, y))
	if mx.x < 0:
		return Rect2i()
	return Rect2i(mn, mx - mn + Vector2i.ONE)


func _bouton_picto(bureau: Control, id_picto: String) -> Button:
	for b in bureau.find_children("*", "Button", true, false):
		for enfant in b.get_children():
			if enfant.get("id") == id_picto:
				return b
	return null


func _derouler() -> void:
	print("=== PREUVE PIXEL BUREAU ANDROID #223/#224 (SubViewport, fenetre 64x64) ===")
	PinConfig.ecrire_option("interface", "mode_tactile", true)
	DirAccess.make_dir_recursive_absolute(_dossier)
	for nom_f in FORMATS:
		var sub := SubViewport.new()
		sub.size = FORMATS[nom_f]
		sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(sub)
		var bureau: Control = load("res://scenes/bureau.tscn").instantiate()
		bureau.hauteur_barre = bureau.hauteur_barre_pour(true)
		sub.add_child(bureau)
		await _trames(6)
		var curseur: Node2D = bureau.get("_curseur")
		curseur.android = true
		curseur.gamme = curseur.gamme_pour(true)
		curseur._ready()
		var roue := _bouton_picto(bureau, "engrenage")
		var eteindre := _bouton_picto(bureau, "eteindre")
		var etiquette := "%s %s" % [nom_f, sub.size]
		_verifier("%s roue + eteindre trouves" % etiquette, roue != null and eteindre != null)
		if roue == null or eteindre == null:
			continue
		var rr := roue.get_global_rect()
		var re := eteindre.get_global_rect()
		curseur.scale = Vector2.ONE * float(curseur.get("_echelle_base"))
		# Mesure de la taille rendue au centre de l'ecran (entierement visible)
		curseur.position = Vector2(sub.size) * 0.5
		var centre_avec: Image = await _capturer(sub)
		curseur.visible = false
		var sans: Image = await _capturer(sub)
		curseur.visible = true
		var bb := _bbox_difference(centre_avec, sans)
		# Tap au doigt brut sur la roue : le hotspot se pose sous le doigt (centre de la roue)
		curseur.position = rr.get_center()
		var avec: Image = await _capturer(sub)
		var bb_roue := _bbox_difference(avec, sans)
		avec.save_png("%s/preuve_bureau_%s.png" % [_dossier, nom_f])
		var coin_r := Rect2i(sub.size.x - 400, sub.size.y - 160, 400, 160)
		var coin := avec.get_region(coin_r)
		coin.resize(coin_r.size.x * 3, coin_r.size.y * 3, Image.INTERPOLATE_NEAREST)
		coin.save_png("%s/preuve_bureau_%s_coin_x3.png" % [_dossier, nom_f])
		var barre_haut: int = sub.size.y - bureau.hauteur_barre
		_verifier("%s barre en bas : roue %s et eteindre %s dans les %d derniers px" % [etiquette, rr, re, bureau.hauteur_barre],
			rr.position.y >= barre_haut and re.position.y >= barre_haut and re.end.x <= sub.size.x and re.position.x > rr.end.x)
		var n_roue := _compter(sans, Rect2i(rr.position, rr.size), GRIS_ROUE)
		var n_rouge := _compter(sans, Rect2i(re.position, re.size), ROUGE_ETEINDRE)
		_verifier("%s roue RENDUE (gris : %d px sur %d, ≥ 30 %%)" % [etiquette, n_roue, int(rr.get_area())], n_roue >= rr.get_area() * 0.30)
		_verifier("%s eteindre RENDU (rouge : %d px sur %d, ≥ 30 %%)" % [etiquette, n_rouge, int(re.get_area())], n_rouge >= re.get_area() * 0.30)
		_verifier("%s coccinelle « petit » rendue : hauteur %d px (attendu %.0f ± 4, « moyen » ferait 144)" % [etiquette, bb.size.y, HAUTEUR_PETIT],
			bb.size.y > 0 and absf(float(bb.size.y) - HAUTEUR_PETIT) <= 4.0, "bbox %s" % bb)
		_verifier("%s coccinelle posee sur la roue (hotspot %s dans %s, rendu %s)" % [etiquette, curseur.position, rr, bb_roue],
			rr.has_point(curseur.position) and bb_roue.intersects(Rect2i(rr.position, rr.size)))
		sub.queue_free()
		await _trames(3)
	print("=== %s (%d echec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
