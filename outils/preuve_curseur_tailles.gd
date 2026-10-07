# Preuve : gamme des tailles du curseur x2 sur ANDROID UNIQUEMENT, PC inchange
# (REQ_261007 android curseur tailles x2 ANDROID ONLY).
# Pour chaque plateforme (PC = feature reelle ; Android = gamme forcee par gamme_pour(true)
# AVANT _ready, la feature « android » ne pouvant pas etre simulee sur PC — meme principe que
# preuve_barre_android) et chaque reglage [souris] taille_curseur ecrit dans un user:// ISOLE,
# monte les 4 copies de curseur.gd (le jeu des lettres n'a plus de facteur propre : il suit la gamme
# comme les autres, cf. outils/preuve_lettres_reglable_fond.gd)
# et lit l'echelle effective, les bornes de la molette et le defaut sans config.
# Attendus ecrits ICI (gamme d'origine 0.55 / 1.0 / 1.45) — pas lus dans le code teste.
# Lancement :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_curseur_tailles.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const ORIGINE := {"petit": 0.55, "moyen": 1.0, "grand": 1.45}
const BORNES_ORIGINE := Vector2(0.55, 1.8)
const COPIES := ["res://scripts/effets/curseur.gd", "res://scripts/souris/curseur.gd",
	"res://scripts/ballons/curseur.gd", "res://scripts/clavier/curseur.gd"]

var _echecs := 0


func _verifier(libelle: String, vrai: bool, detail: String = "") -> void:
	print("  %s %s%s" % ["ok   " if vrai else "ECHEC", libelle, (" — " + detail) if detail != "" else ""])
	if not vrai:
		_echecs += 1


func _initialize() -> void:
	_derouler.call_deferred()


func _monter(chemin: String, android: bool) -> Node2D:
	var c: Node2D = (load(chemin) as GDScript).new()
	if android:
		c.gamme = c.gamme_pour(true)
	root.add_child(c)
	return c


func _nom(chemin: String) -> String:
	return chemin.get_base_dir().get_file()


func _plateforme(android: bool) -> void:
	var x := 2.0 if android else 1.0
	var nom := "ANDROID" if android else "PC"
	print("== %s (gamme attendue x%.0f)" % [nom, x])
	print("-- A. sans config.cfg (installation neuve) = moyen = %.2f" % (1.0 * x))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://config.cfg"))
	for chemin in COPIES:
		var c := _monter(chemin, android)
		_verifier("%s sans reglage = %.2f" % [_nom(chemin), x], is_equal_approx(c.scale.x, x), "echelle = %.3f" % c.scale.x)
		c.free()
	for taille in ["petit", "moyen", "grand"]:
		var attendu: float = ORIGINE[taille] * x
		print("-- B. taille_curseur = %s -> %.2f" % [taille, attendu])
		var cfg := ConfigFile.new()
		cfg.set_value("souris", "taille_curseur", taille)
		cfg.save("user://config.cfg")
		for chemin in COPIES:
			var n := _monter(chemin, android)
			_verifier("%s = %.2f" % [_nom(chemin), attendu], is_equal_approx(n.scale.x, attendu), "echelle = %.3f" % n.scale.x)
			n.free()
	print("-- C. bornes molette = %.2f / %.2f" % [BORNES_ORIGINE.x * x, BORNES_ORIGINE.y * x])
	for chemin in COPIES:
		var g := _monter(chemin, android)
		for i in 40:
			g.zoomer(1)
		var haut: float = g._echelle_base
		for i in 40:
			g.zoomer(-1)
		var bas: float = g._echelle_base
		_verifier("%s molette %.2f -> %.2f" % [_nom(chemin), bas, haut],
			is_equal_approx(bas, BORNES_ORIGINE.x * x) and is_equal_approx(haut, BORNES_ORIGINE.y * x))
		g.free()


func _derouler() -> void:
	_verifier("ce run tourne sur PC (feature android absente)", not OS.has_feature("android"))
	_plateforme(false)
	_plateforme(true)
	print("RESULTAT : %s (%d echec(s))" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
