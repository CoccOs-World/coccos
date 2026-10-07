## Preuve REQ_261007_android_classeur_vide — « Mon classeur » sur un user:// NEUF,
## à partir du PAQUET LIVRÉ (pas des sources du dépôt).
##
## À lancer depuis un projet VIDE (sinon res://classeur/ du dépôt fausse la mesure) :
##   XDG_DATA_HOME=$(mktemp -d) godot --headless --path <projet_vide> \
##     --script <ce_fichier> -- <paquet.pck>
## Témoin desktop (sources du dépôt) : --path <dépôt> ... -- sources
## Monte le .pck, ouvre la banque comme le fait classeur.gd (Banque.charger())
## et compte : planches embarquées, catégories semées, vignettes par catégorie,
## couleur de tuile (même calcul que classeur.gd : COULEURS_TUILES[i % n]).
extends SceneTree

const ATTENDUES := ["coloriage", "general", "habillage", "pate a modeler", "peinture", "toilette"]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	# « sources » = témoin desktop : lit les planches du dépôt, sans paquet
	if args.is_empty() or (args[0] != "sources" and not ProjectSettings.load_resource_pack(args[0])):
		print("ÉCHEC : paquet non monté ", args)
		quit(2)
		return
	print("paquet : ", args[0])
	print("user:// : ", ProjectSettings.globalize_path("user://"))
	print("res://classeur/ dans le paquet : ", Array(DirAccess.get_files_at("res://classeur")))
	var Banque = load("res://scripts/classeur/banque.gd")
	var couleurs: Array = load("res://scripts/classeur/classeur.gd").get_script_constant_map()["COULEURS_TUILES"]
	var banque = Banque.charger()
	var categories: Array = banque.categories()
	print("catégories semées : %d %s" % [categories.size(), categories])
	var vertes := 0
	for i in categories.size():
		var nom: String = categories[i]
		var n: int = banque.plaquette(nom).size()
		var avec_image := 0
		for entree in banque.plaquette(nom):
			if entree["texture"] != null:
				avec_image += 1
		print("  %-16s vignettes=%2d (images=%2d)  tuile=%s" % [nom, n, avec_image, couleurs[i % couleurs.size()].to_html(false)])
		if n > 0 and avec_image == n:
			vertes += 1
	var ok := categories == ATTENDUES and vertes == ATTENDUES.size()
	print("VERDICT : ", "VERT" if ok else "ROUGE")
	quit(0 if ok else 1)
