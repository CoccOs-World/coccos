# Preuve de l'integration d'un jeu frere dans la logitheque (LOGITHEQUE, 01-10).
# Ne mesure pas « le code compile » (scan_scenes.gd le fait deja) mais les QUATRE
# faits qui font qu'une icone apparait VRAIMENT sur le bureau de l'enfant :
#   ① l'entree existe dans le registre et elle est ACTIVE (= « deja installe ») ;
#   ② sa categorie est vide, donc elle est une ICONE DIRECTE du bureau ;
#   ③ sa scene se charge et s'instancie ;
#   ④ sa plaque PNG existe, donc l'icone est l'IMAGE livree et non un pictogramme dessine.
# Lancement :
#   Godot_v4.7.2 --headless --path . --script res://outils/preuve_logitheque_puzzle.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const Registre := preload("res://scripts/registre_jeux.gd")

const ID := "puzzle"

var _echecs := 0

func _verifier(libelle: String, vrai: bool, detail: String = "") -> void:
	if vrai:
		print("  ok   %s%s" % [libelle, (" — " + detail) if detail != "" else ""])
	else:
		print("  ECHEC %s%s" % [libelle, (" — " + detail) if detail != "" else ""])
		_echecs += 1

func _initialize() -> void:
	print("=== PREUVE LOGITHEQUE : « %s » ===" % ID)

	var fiche := Registre.appli(ID)
	_verifier("① entree au registre", not fiche.is_empty())
	if fiche.is_empty():
		print("=== BILAN : %d echec(s) ===" % _echecs)
		quit(1)
		return

	_verifier("① activee par defaut (deja installe)", Registre.est_active(ID))
	_verifier("② icone DIRECTE du bureau", fiche["categorie"] == "",
		"categorie = « %s »" % fiche["categorie"])
	_verifier("② presente dans actives_directes()",
		Registre.actives_directes().any(func(a: Dictionary) -> bool: return a["id"] == ID))

	var chemin: String = fiche["scene"]
	_verifier("③ scene sous jeux_integres/", chemin.begins_with("res://jeux_integres/%s/" % ID), chemin)
	var paquet: PackedScene = ResourceLoader.load(chemin, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)
	_verifier("③ scene chargee", paquet != null, chemin)
	if paquet != null:
		var noeud: Node = paquet.instantiate()
		_verifier("③ scene instanciee", noeud != null)
		if noeud != null:
			noeud.free()

	var plaque := "res://assets/icones/%s.png" % ID
	_verifier("④ plaque livree presente", ResourceLoader.exists(plaque), plaque)
	var texture: Texture2D = ResourceLoader.load(plaque, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
	_verifier("④ plaque chargeable", texture != null,
		("%d x %d" % [texture.get_width(), texture.get_height()]) if texture != null else "")

	# Les deux cles de texte doivent EXISTER et etre traduites : sans elles, l'icone
	# porterait sa cle brute en guise de nom sous le bureau.
	var Lang := load("res://scripts/lang.gd")
	for cle in [fiche["nom_cle"], fiche["description_cle"]]:
		var texte: String = Lang.t(cle)
		_verifier("⑤ cle de texte « %s »" % cle, texte != "" and texte != cle, texte)

	print("=== BILAN : %d echec(s) ===" % _echecs)
	quit(1 if _echecs > 0 else 0)
