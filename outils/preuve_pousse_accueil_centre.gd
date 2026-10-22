# Preuve : ACCUEIL de Pousse-Pollen CENTRÉ sur l'écran réel (REQ_pousse_android_complet 21-10).
# Le projet est en 1280×720 « expand » : l'écran visible vaut 1280×960 (4:3), 1280×720 (16:9), 1600×720 (20:9).
# Monte le VRAI jeu à chaque format, en mode tactile (Android) puis PC (section curseur), et vérifie par mesure :
#   ① le bloc d'accueil (titres, cases, « Jouer ») est centré : marges gauche/droite égales, rien calé à gauche ;
#   ② « Jouer » est ENTIÈREMENT dans l'écran visible (non rogné) et centré ;
#   ③ la prairie couvre l'écran visible jusqu'aux bords ;
#   ④ la mise en page de conception est conservée : chaque nœud = position 1024×768 + UN SEUL décalage commun ;
#      (22-10) sauf la croix de fermeture « CroixFermer », ancrée au coin HAUT-DROIT réel comme sur les autres jeux
#      → hors du bloc centré, et son décalage propre = (écran − 1024×768) × (1, 0) ;
#   ⑤ fenêtre redimensionnée pendant l'accueil (4:3 → 20:9) : le bloc se recentre.
# Lancement (user:// ISOLÉ) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_pousse_accueil_centre.gd
# Code de sortie 0 = tout vert, 1 = au moins un échec.
extends SceneTree

const SCENE := "res://scenes/pousse_pollen.tscn"
const FORMATS := [Vector2i(1024, 768), Vector2i(1366, 768), Vector2i(2400, 1080)]
const NOMS_FORMAT := ["4:3", "16:9", "20:9"]
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


# Contrôles du bloc d'accueil (hors voile brun et prairie, qui couvrent tout l'écran).
func _bloc(accueil: Node) -> Array:
	var l := []
	for c in accueil.get_children():
		if c is Control and str(c.name) not in ["Prairie", "CroixFermer"] and not (c is ColorRect and (c as Control).anchor_right == 1.0):
			l.append(c)
	return l


func _englobant(noeuds: Array) -> Rect2:
	var r := Rect2()
	var premier := true
	for c: Control in noeuds:
		var g := c.get_global_rect()
		r = g if premier else r.merge(g)
		premier = false
	return r


func _controler(jeu: Node, etiquette: String) -> void:
	var vis: Rect2 = root.get_visible_rect()
	var accueil: Node = jeu.get_node("Accueil")
	var bloc := _bloc(accueil)
	var env := _englobant(bloc)
	var marge_g := env.position.x
	var marge_d := vis.size.x - env.end.x
	_verifier("① %s bloc centré (marges %.0f / %.0f, %d nœuds)" % [etiquette, marge_g, marge_d, bloc.size()],
		absf(marge_g - marge_d) <= 2.0 and marge_g > 50.0)
	var jouer: Button = accueil.get_node("Jouer")
	var rj := jouer.get_global_rect()
	_verifier("② %s « Jouer » non rogné et centré %s" % [etiquette, rj], vis.grow(TOL).encloses(rj)
		and absf(rj.get_center().x - vis.size.x * 0.5) <= 1.0)
	_verifier("② %s tout le bloc dans l'écran" % etiquette, vis.grow(TOL).encloses(env), "%s dans %s" % [env, vis.size])
	var prairie: Control = accueil.get_node("Prairie")
	var tr: TextureRect = null
	for c in prairie.get_children():
		if c is TextureRect:
			tr = c
	_verifier("③ %s prairie bord à bord" % etiquette, tr != null and tr.get_global_rect().encloses(vis)
		and prairie.get_global_rect().is_equal_approx(vis), str(tr.get_global_rect() if tr else null))
	var attendu: Vector2 = (vis.size - Vector2(1024, 768)) * 0.5
	var ecarts := 0
	var attendu_croix: Vector2 = (vis.size - Vector2(1024, 768)) * Vector2(1, 0)   # (22-10) la croix suit le coin haut-droit
	var croix_ok := false
	for a in jeu._ancrages:
		if is_instance_valid(a[0]) and a[0].get_parent() == accueil:
			if str(a[0].name) == "CroixFermer":
				croix_ok = (a[0].position - a[1]).is_equal_approx(attendu_croix)
			elif not (a[0].position - a[1]).is_equal_approx(attendu):
				ecarts += 1
	_verifier("④ %s mise en page 1024×768 conservée, décalage unique %s" % [etiquette, attendu], ecarts == 0, "%d écart(s)" % ecarts)
	_verifier("④ %s croix de fermeture ancrée au coin haut-droit réel (décalage %s)" % [etiquette, attendu_croix], croix_ok)


func _derouler() -> void:
	print("=== PREUVE ACCUEIL CENTRÉ POUSSE-POLLEN ===")
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
			var etiquette := "%s %s %s" % ["Android" if tactile else "PC", NOMS_FORMAT[i], root.get_visible_rect().size]
			_verifier("%s section curseur %s" % [etiquette, "absente" if tactile else "présente"],
				(jeu._surbrillance_curseur.size() == 0) == tactile)
			_controler(jeu, etiquette)
			jeu.queue_free()
			await _trames(3)
	print("--- ⑤ redimensionnement pendant l'accueil 4:3 → 20:9")
	root.size = Vector2i(1024, 768)
	await _trames(2)
	var jeu2: Node = load(SCENE).instantiate()
	root.add_child(jeu2)
	await _trames(6)
	root.size = Vector2i(2400, 1080)
	await _trames(4)
	_controler(jeu2, "⑤ après rotation %s" % root.get_visible_rect().size)
	jeu2.queue_free()
	await _trames(3)
	print("=== %s (%d échec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
