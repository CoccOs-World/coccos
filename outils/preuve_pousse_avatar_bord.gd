# Preuve : AVATAR JAMAIS COUPÉ PAR UN BORD de l'écran (REQ_pousse_avatar_decapite_android 21-10).
# Grief Fabrice (Android seulement) : avatar tout en haut du tableau → tête coupée par le haut de l'écran.
# Monte le VRAI jeu sur les ratios Android (16:9, 20:9) + PC 4:3, et pour CHAQUE niveau pose l'avatar sur les cases
# praticables de BORD (plus haute/plus basse de chaque colonne, plus à gauche/à droite de chaque rangée) :
#   - enveloppe des PIXELS OPAQUES de l'avatar mesurée ICI, indépendamment du jeu, sur les PNG détourés (alpha > 8),
#     membres tournés à leur amplitude max (bras BRAS_REACH + BRAS_BAL_MAX, jambes JAMBE_SWING) + penché AV_LEAN ;
#   - projetée par la VRAIE transformée caméra (get_canvas_transform) → aucun pixel hors de l'écran visible.
# Lancement (user:// ISOLÉ) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_pousse_avatar_bord.gd
# Code de sortie 0 = tout vert, 1 = au moins un échec.
extends SceneTree

const SCENE := "res://scenes/pousse_pollen.tscn"
const FORMATS := [Vector2i(1024, 768), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(2400, 1080), Vector2i(1600, 720)]
const TEX := "res://scripts/pousse_pollen/textures/av_%s_%s.png"
const PIECES := {"core": [Vector2(0.5, 0.5), 0.0], "brasG": [Vector2(0.15, 0.575), 1.21], "brasD": [Vector2(0.85, 0.575), 1.21],
	"jambeG": [Vector2(0.37, 0.85), 0.30], "jambeD": [Vector2(0.63, 0.85), 0.30]}
const TOL := 0.5

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


# Enveloppe des pixels opaques (toile normalisée : (0,0) = centre du sprite, unité = hauteur de toile).
func _enveloppe_pixels(perso: String) -> Rect2:
	var env := Rect2()
	var premier := true
	for nom in PIECES:
		var img := Image.load_from_file(ProjectSettings.globalize_path(TEX % [perso, nom]))
		var w := img.get_width()
		var h := img.get_height()
		var piv: Vector2 = PIECES[nom][0] * Vector2(w, h)
		var amp: float = PIECES[nom][1]
		var pts: Array[Vector2] = []
		for y in range(0, h, 3):
			for x in range(0, w, 3):
				if img.get_pixel(x, y).a > 8.0 / 255.0:
					pts.append(Vector2(x, y))
		var n_angles := 1 if amp == 0.0 else 25
		for k in n_angles:
			var a := 0.0 if n_angles == 1 else -amp + 2.0 * amp * k / (n_angles - 1)
			for p in pts:
				var q := piv + (p - piv).rotated(a)
				var u := (q - Vector2(w, h) * 0.5) / float(h)
				if premier:
					env = Rect2(u, Vector2.ZERO) ; premier = false
				else:
					env = env.expand(u)
	return env


func _cases_de_bord(terrain: Array) -> Array[Vector2i]:
	var d := {}
	var haut := {} ; var bas := {} ; var gauche := {} ; var droite := {}
	for y in terrain.size():
		var ligne: String = terrain[y]
		for x in ligne.length():
			if ligne[x] == "#":
				continue
			if not haut.has(x): haut[x] = y
			bas[x] = y
			if not gauche.has(y): gauche[y] = x
			droite[y] = x
	for x in haut: d[Vector2i(x, haut[x])] = true ; d[Vector2i(x, bas[x])] = true
	for y in gauche: d[Vector2i(gauche[y], y)] = true ; d[Vector2i(droite[y], y)] = true
	var r: Array[Vector2i] = []
	for c in d: r.append(c)
	return r


func _derouler() -> void:
	print("=== PREUVE AVATAR AUX BORDS POUSSE-POLLEN ===")
	var env_c := _enveloppe_pixels("cocc")
	var env_a := _enveloppe_pixels("abeille")
	var env := env_c.merge(env_a)
	print("enveloppe pixels opaques (unité = hauteur sprite) : %s" % env)
	var reglages := ConfigFile.new()
	reglages.set_value("interface", "mode_tactile", true)
	reglages.save("user://config.cfg")
	var pire_haut := INF
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
		var ko_niveaux := []
		var n_cases := 0
		for n: int in jeu.NIVEAUX.size():
			jeu._aller_a_niveau(n)
			await _trames(3)
			var xf: Transform2D = jeu.get_viewport().get_canvas_transform()
			var ky: float = jeu._plonge_ky
			var frac: float = clampf(remap(ky, jeu.PLONGE_KY, jeu.PLONGE_KY_MAX, jeu.AVATAR_FRAC_MIN, jeu.AVATAR_FRAC_MAX), jeu.AVATAR_FRAC_MIN, jeu.AVATAR_FRAC_MAX)
			var h := 2.0 * 128.0 * frac                                  # hauteur dessinée du sprite (même fit que _dessiner_avatar)
			var lean: float = jeu.AV_LEAN * 128.0
			var hors := []
			for c: Vector2i in _cases_de_bord(jeu._terrain):
				n_cases += 1
				var centre: Vector2 = jeu._centre_plonge(c) + Vector2(0.0, -(jeu.AV_PIEDS_FRAC - 0.5) * h)
				var r := Rect2(centre + env.position * h, env.size * h).grow(lean)
				var a: Vector2 = xf * r.position
				var b: Vector2 = xf * r.end
				var re := Rect2(a, b - a)
				pire_haut = minf(pire_haut, re.position.y)
				if not vis.grow(TOL).encloses(re):
					hors.append("%s haut=%.0f bas=%.0f g=%.0f d=%.0f" % [c, re.position.y, re.end.y, re.position.x, re.end.x])
			if not hors.is_empty():
				ko_niveaux.append("N%d %s" % [n + 1, hors[0]])
		_verifier("avatar entier sur %d cases de bord × %d niveaux (%s)" % [n_cases, jeu.NIVEAUX.size(), vis.size],
			ko_niveaux.is_empty(), "%d niveau(x) KO : %s" % [ko_niveaux.size(), "; ".join(ko_niveaux.slice(0, 4))])
		jeu.queue_free()
		await _trames(3)
	print("plus haut pixel d'avatar mesuré, tous formats : y = %.1f (≥ 0 attendu)" % pire_haut)
	print("=== %s (%d échec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
