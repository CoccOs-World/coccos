# Preuve : boutons « Recommencer » et « Accueil » de Pousse-Pollen = ICÔNES (REQ_pousse_icones_accueil_recommencer 21-10).
# Monte le VRAI jeu (3 formats × Android/PC) et LIT sur les nœuds, sans rien supposer :
#   ① les deux boutons n'ont plus de mot (`text == ""`) ;
#   ② chacun porte UNE `IconeDessinee` (classe du script du jeu), de forme « rejouer » / « maison », ancrée plein rect,
#      transparente aux clics (MOUSE_FILTER_IGNORE) ;
#   ③ taille et position des boutons INCHANGÉES (constantes b49) et zone d'évitement caméra `_rects_boutons()[0]` inchangée ;
#   ④ fond du 7-diff : StyleBoxFlat `COL_SORTIE`, rayon 10, bordure 3 `COL_SORTIE_TXT`, mêmes 3 états ;
#   ⑤ rien d'autre ne bouge : « Jouer » reste un mot, la croix CoccOs garde son dessin blanc sur rond rouge ;
#   ⑥ les deux boutons sont entiers dans l'écran visible.
# Lancement (user:// ISOLÉ) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_pousse_icones.gd
# Code de sortie 0 = tout vert, 1 = au moins un échec.
extends SceneTree

const SCENE := "res://scenes/pousse_pollen.tscn"
const FORMATS := [Vector2i(1024, 768), Vector2i(1366, 768), Vector2i(2400, 1080)]
const NOMS_FORMAT := ["4:3", "16:9", "20:9"]
const ATTENDU := {   # bouton → [chemin, forme, position, taille, rappel]
	"Recommencer": ["BoutonRecommencer/Recommencer", "rejouer", Vector2(28, 24), Vector2(240, 38), "_recommencer"],
	"Accueil": ["BoutonAccueil/Accueil", "maison", Vector2(28, 66), Vector2(240, 38), "_afficher_accueil"],
}

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


func _controler(jeu: Node, etiquette: String) -> void:
	var vis: Rect2 = root.get_visible_rect()
	var Icone: GDScript = jeu.get_script().get_script_constant_map().get("IconeDessinee")
	_verifier("%s classe IconeDessinee présente dans le script du jeu" % etiquette, Icone != null)
	var col_fond: Color = jeu.COL_SORTIE
	var col_trait: Color = jeu.COL_SORTIE_TXT
	_verifier("%s teintes du 7-diff" % etiquette, col_fond.is_equal_approx(Color(0.88, 0.90, 0.96, 1.0))
		and col_trait.is_equal_approx(Color(0.08, 0.09, 0.14, 1.0)))
	for nom in ATTENDU:
		var a: Array = ATTENDU[nom]
		var b: Button = jeu.get_node_or_null(a[0])
		_verifier("%s %s : bouton trouvé" % [etiquette, nom], b != null)
		if b == null:
			continue
		_verifier("① %s %s : plus de mot (text = « %s »)" % [etiquette, nom, b.text], b.text == "")
		var icones := []
		for e in b.get_children():
			if Icone != null and e.get_script() == Icone:
				icones.append(e)
		_verifier("② %s %s : UNE IconeDessinee (%d)" % [etiquette, nom, icones.size()], icones.size() == 1)
		if icones.size() == 1:
			var ic: Control = icones[0]
			_verifier("② %s %s : forme « %s » (lue sur le nœud)" % [etiquette, nom, ic.forme], ic.forme == a[1])
			_verifier("② %s %s : icône plein rect du bouton %s" % [etiquette, nom, ic.get_global_rect()],
				ic.get_global_rect().is_equal_approx(b.get_global_rect()) and ic.anchor_right == 1.0 and ic.anchor_bottom == 1.0)
			_verifier("② %s %s : icône transparente aux clics" % [etiquette, nom], ic.mouse_filter == Control.MOUSE_FILTER_IGNORE)
			_verifier("② %s %s : icône reliée au jeu (ov)" % [etiquette, nom], ic.ov == jeu)
		_verifier("③ %s %s : position %s et taille %s inchangées" % [etiquette, nom, b.position, b.size],
			b.position.is_equal_approx(a[2]) and b.size.is_equal_approx(a[3]))
		_verifier("③ %s %s : rappel %s toujours branché" % [etiquette, nom, a[4]], b.pressed.is_connected(Callable(jeu, a[4])))
		var sb: StyleBox = b.get_theme_stylebox("normal")
		var ok4 := sb is StyleBoxFlat and (sb as StyleBoxFlat).bg_color.is_equal_approx(col_fond) \
			and (sb as StyleBoxFlat).corner_radius_top_left == 10 and (sb as StyleBoxFlat).border_width_left == 3 \
			and (sb as StyleBoxFlat).border_color.is_equal_approx(col_trait) \
			and b.get_theme_stylebox("hover") == sb and b.get_theme_stylebox("pressed") == sb
		_verifier("④ %s %s : fond du 7-diff (clair, rayon 10, bordure 3 sombre, 3 états)" % [etiquette, nom], ok4)
		_verifier("⑥ %s %s : entier dans l'écran visible %s" % [etiquette, nom, vis.size], vis.grow(0.5).encloses(b.get_global_rect()))
	var zone: Rect2 = jeu._rects_boutons()[0]
	_verifier("③ %s zone d'évitement caméra haut-gauche inchangée %s" % [etiquette, zone],
		zone.is_equal_approx(Rect2(Vector2(28, 24), Vector2(240, 84))))
	var jouer: Button = jeu.get_node_or_null("Accueil/Jouer")
	_verifier("⑤ %s « Jouer » reste un mot" % etiquette, jouer != null and jouer.text == "Jouer", str(jouer.text if jouer else null))
	var croix: Button = null
	var cc: Node = jeu.get_node_or_null("CroixCoccOs")
	if cc != null:
		for e in cc.get_children():
			if e is Button:
				croix = e
	var croix_ok: bool = croix != null and croix.get_child_count() == 1 \
		and croix.get_child(0).get_script() == jeu.get_script().get_script_constant_map().get("_IconeCroixFermerCoccOs") \
		and (croix.get_theme_stylebox("normal") as StyleBoxFlat).bg_color.is_equal_approx(jeu.COULEUR_CROIX_COCCOS)
	_verifier("⑤ %s croix CoccOs intacte (dessin blanc, rond rouge)" % etiquette, croix_ok)


func _derouler() -> void:
	print("=== PREUVE ICÔNES RECOMMENCER / ACCUEIL POUSSE-POLLEN ===")
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
			_controler(jeu, etiquette)
			jeu.queue_free()
			await _trames(3)
	print("=== %s (%d échec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
