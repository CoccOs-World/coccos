# Preuve : gamme des tailles du curseur x2 (REQ_261007 android curseur tailles x2).
# Pour chaque reglage [souris] taille_curseur ecrit dans un user:// ISOLE, monte le curseur
# de l'OS (scripts/effets/curseur.gd, celui du bureau) et celui du jeu des lettres
# (scripts/clavier/curseur.gd, facteur 2.0) et lit l'echelle effective.
# Attendus recalcules ICI (ancienne gamme 0.55 / 1.0 / 1.45, x2) — pas lus dans le code teste.
# Lancement :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_curseur_tailles.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const ANCIENNE := {"petit": 0.55, "moyen": 1.0, "grand": 1.45}
const FACTEUR_LETTRES := 2.0   # jeu_lettres.gd FACTEUR_CURSEUR

var _echecs := 0


func _verifier(libelle: String, vrai: bool, detail: String = "") -> void:
	print("  %s %s%s" % ["ok   " if vrai else "ECHEC", libelle, (" — " + detail) if detail != "" else ""])
	if not vrai:
		_echecs += 1


func _initialize() -> void:
	_derouler.call_deferred()


func _monter(chemin: String, facteur := 1.0) -> Node2D:
	var c: Node2D = (load(chemin) as GDScript).new()
	if facteur != 1.0:
		c.facteur = facteur
	root.add_child(c)
	return c


func _derouler() -> void:
	print("-- A. sans config.cfg (installation neuve) = moyen")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://config.cfg"))
	var c := _monter("res://scripts/effets/curseur.gd")
	_verifier("bureau sans reglage", is_equal_approx(c.scale.x, 2.0), "echelle = %.3f" % c.scale.x)
	c.free()
	for taille in ["petit", "moyen", "grand"]:
		print("-- B. taille_curseur = %s" % taille)
		var cfg := ConfigFile.new()
		cfg.set_value("souris", "taille_curseur", taille)
		cfg.save("user://config.cfg")
		var attendu: float = ANCIENNE[taille] * 2.0
		for chemin in ["res://scripts/effets/curseur.gd", "res://scripts/souris/curseur.gd",
				"res://scripts/ballons/curseur.gd", "res://scripts/clavier/curseur.gd"]:
			var n := _monter(chemin)
			_verifier("%s = %.2f" % [chemin.get_file().get_basename() + "@" + chemin.get_base_dir().get_file(), attendu],
				is_equal_approx(n.scale.x, attendu), "echelle = %.3f" % n.scale.x)
			n.free()
		var l := _monter("res://scripts/clavier/curseur.gd", FACTEUR_LETTRES)
		print("     lettres : echelle effective = %.3f (= %.2f x ancien « %s » ; = %.2f x curseur normal)" % [
			l.scale.x, l.scale.x / ANCIENNE[taille], taille, l.scale.x / attendu])
		_verifier("lettres = 2 x curseur normal", is_equal_approx(l.scale.x, attendu * 2.0))
		l.free()
	print("-- C. molette depuis « grand » : un cran vers le haut GROSSIT (ne s'effondre pas sur la borne)")
	var g := _monter("res://scripts/effets/curseur.gd")
	var avant: float = g._echelle_base
	g.zoomer(1)
	_verifier("cran + : %.2f -> %.2f" % [avant, g._echelle_base], g._echelle_base > avant)
	for i in 20:
		g.zoomer(-1)
	_verifier("plancher molette = petit (1.10)", is_equal_approx(g._echelle_base, 1.10), "%.3f" % g._echelle_base)
	g.free()
	print("RESULTAT : %s (%d echec(s))" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
