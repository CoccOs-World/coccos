# Preuve REQ_261007 lettres_curseur_reglable_fond (retours Fabrice : « le curseur des lettres ne suit pas
# la taille du reglage, il est trop grand » ; « en bas, du blanc : j'aurais prefere la verdure »).
#   A  ECHELLE du curseur, mesuree dans les VRAIS jeux montes (lettres, ballons, decouverte, mots, chasse),
#      aux 3 reglages [souris] taille_curseur ecrits dans un user:// ISOLE, sur PC (gamme reelle) et
#      Android (gamme x2 reposee puis _ready() rejoue : relit la config comme au lancement sur Android).
#      Attendu : lettres = MEME echelle que les autres petits jeux, et l'echelle CHANGE avec le reglage.
#   B  BAS DE L'ECRAN de Lettres en mode tactile : la bande sous les touches (repose-doigt de remontee).
#      Ce qui y est peint : fond du panneau du clavier (rect + couleur) vs la prairie (Fond.appliquer) ;
#      couleur moyenne REELLE de la prairie dans cette bande (pixels de l'image, mise en « couvrir »).
#   L  lisibilite : les touches gardent leur fond creme de panneau et leur couleur ; aucune touche
#      dans la bande.
# Lancement :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_lettres_reglable_fond.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const ANDROID := 2.0  # AGRANDI_TAILLE_ANDROID des curseur.gd
const TAILLES := {"petit": 0.55, "moyen": 1.0, "grand": 1.45}  # gamme d'origine, ecrite ICI
const JEUX := {
	"lettres": "res://scenes/lettres.tscn",
	"ballons": "res://scenes/ballons.tscn",
	"decouverte": "res://scenes/souris.tscn",
	"mots": "res://scenes/mots.tscn",
	"chasse": "res://scenes/chasse.tscn",
}
const IMAGE_FOND := "res://assets/backgrounds/fond_prairie.png"

var _echecs := 0
var _jeu: Control


func _verifier(libelle: String, vrai: bool, detail: String = "") -> void:
	print("  %s %s%s" % ["ok   " if vrai else "ECHEC", libelle, (" — " + detail) if detail != "" else ""])
	if not vrai:
		_echecs += 1


func _initialize() -> void:
	_derouler.call_deferred()


func _trames(n: int) -> void:
	for i in n:
		await process_frame


func _config(taille: String, tactile: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("souris", "taille_curseur", taille)
	cfg.set_value("interface", "mode_tactile", tactile)
	cfg.save("user://config.cfg")


func _monter(chemin: String, android: bool) -> Node2D:
	_jeu = load(chemin).instantiate()
	root.add_child(_jeu)
	current_scene = _jeu
	await _trames(6)
	var c: Node2D = _jeu.get("_curseur")
	if android:
		c.gamme = ANDROID
		c._ready()  # relit la config avec la gamme Android, comme au lancement sur l'appareil
	await _trames(4)  # le clavier suit la taille du curseur (_process) puis la mise en page
	return c


func _demonter() -> void:
	if is_instance_valid(_jeu):
		_jeu.free()
	await _trames(3)


## A : tableau des echelles, jeu par jeu, aux 3 reglages.
func _echelles(android: bool) -> void:
	var x := ANDROID if android else 1.0
	print("== A. ECHELLE DU CURSEUR — %s (mode tactile %s)" % ["ANDROID" if android else "PC", "oui" if android else "non"])
	print("     %-11s %8s %8s %8s" % ["jeu", "petit", "moyen", "grand"])
	var mesures := {}
	for nom in JEUX:
		mesures[nom] = {}
		for taille in TAILLES:
			_config(taille, android)
			var c := await _monter(JEUX[nom], android)
			mesures[nom][taille] = c.scale.x
			await _demonter()
		print("     %-11s %8.3f %8.3f %8.3f" % [nom, mesures[nom]["petit"], mesures[nom]["moyen"], mesures[nom]["grand"]])
	var l: Dictionary = mesures["lettres"]
	_verifier("A lettres CHANGE avec le reglage (petit < moyen < grand)",
		l["petit"] < l["moyen"] and l["moyen"] < l["grand"],
		"%.2f / %.2f / %.2f" % [l["petit"], l["moyen"], l["grand"]])
	for taille in TAILLES:
		var attendu: float = TAILLES[taille] * x
		for nom in JEUX:
			_verifier("A %s %s = %.2f (reglage x gamme, sans facteur propre)" % [nom, taille, attendu],
				is_equal_approx(mesures[nom][taille], attendu), "echelle = %.3f" % mesures[nom][taille])


## Couleur moyenne de la prairie dans `bande` (rect viewport), image posee en « couvrir ».
func _couleur_prairie(bande: Rect2, vue: Vector2) -> Color:
	var img: Image = (load(IMAGE_FOND) as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	var t := Vector2(img.get_size())
	var e := maxf(vue.x / t.x, vue.y / t.y)
	var origine := (vue - t * e) / 2.0
	var somme := Color(0, 0, 0, 0)
	var n := 0
	var y := bande.position.y + 1.0
	while y < bande.end.y:
		var xx := bande.position.x + 1.0
		while xx < bande.end.x:
			var p := ((Vector2(xx, y) - origine) / e).floor()
			p = p.clamp(Vector2.ZERO, t - Vector2.ONE)
			var c := img.get_pixelv(Vector2i(p))
			somme += c
			n += 1
			xx += 8.0
		y += 2.0
	return somme / float(maxi(n, 1))


## Rect peint par le fond du panneau du clavier (repere viewport).
func _rect_peint_clavier(clavier: Control) -> Rect2:
	var r := clavier.get_global_rect()
	if clavier.has_method("rect_fond_touches"):
		return clavier.rect_fond_touches()
	var style := clavier.get_theme_stylebox("panel")
	if style is StyleBoxFlat and (style as StyleBoxFlat).bg_color.a > 0.0:
		return r
	return Rect2()


func _bas_ecran() -> void:
	# Fenetre de telephone Android 20:9 (le headless accepte le redimensionnement ; a poser deux fois)
	for i in 2:
		root.size = Vector2i(2400, 1080)
		await _trames(2)
	print("== B. BAS DE L'ECRAN — Lettres, Android (mode tactile, gamme x2), fenetre %s" % root.size)
	for taille in TAILLES:
		_config(taille, true)
		await _monter(JEUX["lettres"], true)
		var clavier: Control = _jeu.get("_clavier")
		var vue := _jeu.get_viewport_rect().size
		var remontee: float = clavier.get("remontee")
		var bande := Rect2(0.0, vue.y - remontee, vue.x, remontee)
		var peint := _rect_peint_clavier(clavier)
		var style := clavier.get_theme_stylebox("panel")
		var couleur_panneau := (style as StyleBoxFlat).bg_color if style is StyleBoxFlat else Color(0, 0, 0, 0)
		if clavier.has_method("rect_fond_touches"):
			couleur_panneau = clavier.get("_style_fond").bg_color
		var couvre := peint.intersection(bande).get_area()
		print("  [%s] vue %s, clavier %s, bande repose-doigt y=%.0f..%.0f (%.0f px)" % [taille, vue,
			clavier.get_global_rect(), bande.position.y, bande.end.y, bande.size.y])
		print("  [%s] fond du panneau peint sur %s, couleur %s (luminance %.2f)" % [taille, peint, couleur_panneau,
			couleur_panneau.get_luminance()])
		# Qui est peint dans la bande ? (Controls visibles qui la recoupent, hors fond d'ecran et clavier)
		var fond: TextureRect = null
		var autres: Array = []
		for n in _jeu.find_children("*", "Control", true, false):
			var c := n as Control
			if not c.is_visible_in_tree() or not c.get_global_rect().intersects(bande):
				continue
			if c is TextureRect and (c as TextureRect).texture != null and (c as TextureRect).texture.resource_path == IMAGE_FOND:
				fond = c
			elif c == clavier or clavier.is_ancestor_of(c) or c is ColorRect:
				if c is Button:
					autres.append("touche « %s »" % (c as Button).text)
			elif c != _jeu:
				autres.append("%s %s" % [c.get_class(), c.get_global_rect()])
		_verifier("B[%s] la prairie (Fond) couvre la bande" % taille,
			fond != null and fond.get_global_rect().encloses(bande))
		_verifier("B[%s] le fond creme du clavier ne peint PLUS la bande" % taille, couvre < 1.0,
			"%.0f px² de la bande sous le creme (%.0f %%)" % [couvre, 100.0 * couvre / maxf(bande.get_area(), 1.0)])
		_verifier("B[%s] rien d'autre peint dans la bande (aucune touche)" % taille, autres.is_empty(), str(autres))
		var vert := _couleur_prairie(bande, vue)
		print("  [%s] prairie dans la bande : moyenne %s (R %.2f V %.2f B %.2f)" % [taille, vert.to_html(false), vert.r, vert.g, vert.b])
		_verifier("B[%s] la bande montre de la VERDURE (vert dominant)" % taille, vert.g > vert.r and vert.g > vert.b)
		# L : les touches gardent leur fond de panneau et leur place
		var touches := clavier.find_children("*", "Button", true, false)
		var hors := 0
		for t in touches:
			if not peint.encloses((t as Button).get_global_rect()):
				hors += 1
		_verifier("L[%s] %d touches, toutes sur le fond creme du panneau" % [taille, touches.size()], hors == 0 and touches.size() == 37,
			"%d hors du fond" % hors)
		_verifier("L[%s] fond des touches inchange (creme 0.97/0.96/0.92 a 0.92)" % taille,
			couleur_panneau.is_equal_approx(Color(0.97, 0.96, 0.92, 0.92)))
		await _demonter()


func _derouler() -> void:
	_verifier("ce run tourne sur PC (feature android absente)", not OS.has_feature("android"))
	await _echelles(false)
	await _echelles(true)
	await _bas_ecran()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://config.cfg"))
	print("RESULTAT : %s (%d echec(s))" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
