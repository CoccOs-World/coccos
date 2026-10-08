## Preuve REQ_261008_classeur_migration_mots_manquants — migration non destructive
## des mots vides (vieux classeur sans « serviette »).
##
##   XDG_DATA_HOME=<dossier> godot --headless --path <dépôt> --script <ce_fichier> -- <mode>
## Modes :
##   preparer  (lancé sur un dépôt AVANT 7005c46) : sème le vieux classeur puis
##             simule l'adulte — un mot personnalisé, une photo au mot vide.
##   controle  (dépôt migré) : 1er démarrage = seuls des mots vides remplis,
##             2e démarrage = fichier identique à l'octet.
##   empreinte (n'importe quel dépôt) : vidage canonique de la banque (sans le
##             repère migration_mots), pour comparer un classeur neuf avant/après.
extends SceneTree

const CHEMIN := "user://classeur/banque.cfg"
const MOT_PARENT := "doudou d'Isabella"


func _init() -> void:
	var mode: String = OS.get_cmdline_user_args()[0]
	var Banque = load("res://scripts/classeur/banque.gd")
	var ok := true
	match mode:
		"preparer":
			var banque = Banque.charger()
			var cible := -1
			for id in banque.ids_vignettes():
				if banque.mot(id) == "je":
					cible = id
			banque.renommer(cible, MOT_PARENT)
			var photo := Image.create(32, 32, false, Image.FORMAT_RGBA8)
			photo.fill(Color(0.8, 0.3, 0.2))
			var id_photo: int = banque.creer_vignette("", photo, ["toilette"])
			print("vieux classeur : %d vignettes, mot parent sur id %d, photo sans mot id %d" % [banque.ids_vignettes().size(), cible, id_photo])
			for id in banque.ids_vignettes():
				if banque.mot(id) == "":
					print("  mot vide : id %d  tags=%s" % [id, banque.tags(id)])
		"controle":
			var avant := ConfigFile.new()
			avant.load(CHEMIN)
			var octets_avant := FileAccess.get_file_as_bytes(CHEMIN)
			var t0 := Time.get_ticks_msec()
			Banque.charger()
			print("1er démarrage : %d ms" % (Time.get_ticks_msec() - t0))
			var apres := ConfigFile.new()
			apres.load(CHEMIN)
			var octets_1 := FileAccess.get_file_as_bytes(CHEMIN)
			var diffs := _differences(avant, apres)
			for d in diffs:
				print("  changé : ", d)
			var remplis := 0
			for d in diffs:
				if d[0] == "banque" and d[1] == "migration_mots":
					continue
				if d[1] == "mot" and d[2] == "" and d[3] == "serviette":
					remplis += 1
				else:
					print("ROUGE : changement non autorisé ", d)
					ok = false
			print("vignettes remplies « serviette » : %d (attendu 1)" % remplis)
			ok = ok and remplis == 1 and octets_avant != octets_1
			var mot_parent_intact := false
			var photo_vide := false
			for s in apres.get_sections():
				if s.begins_with("vignette_"):
					if apres.get_value(s, "mot", "") == MOT_PARENT:
						mot_parent_intact = true
					# La photo de l'adulte = la dernière vignette créée
					if s == "vignette_%d" % (int(apres.get_value("banque", "prochain_id")) - 1):
						photo_vide = apres.get_value(s, "mot", "") == ""
					if apres.get_value(s, "mot", "") == "":
						print("  reste vide : %s tags=%s" % [s, Array(apres.get_value(s, "categories"))])
			print("mot du parent intact : ", mot_parent_intact, " · photo sans mot laissée vide : ", photo_vide)
			ok = ok and mot_parent_intact and photo_vide
			t0 = Time.get_ticks_msec()
			Banque.charger()
			print("2e démarrage : %d ms" % (Time.get_ticks_msec() - t0))
			var identique := FileAccess.get_file_as_bytes(CHEMIN) == octets_1
			print("2e démarrage identique à l'octet : ", identique)
			ok = ok and identique
			print("VERDICT : ", "VERT" if ok else "ROUGE")
		"empreinte":
			Banque.charger()
			var cfg := ConfigFile.new()
			cfg.load(CHEMIN)
			if cfg.has_section_key("banque", "migration_mots"):
				cfg.erase_section_key("banque", "migration_mots")
			var lignes := PackedStringArray()
			for s in cfg.get_sections():
				for k in cfg.get_section_keys(s):
					lignes.append("%s.%s=%s" % [s, k, var_to_str(cfg.get_value(s, k))])
			var pictos := Array(DirAccess.get_files_at("user://classeur/pictos"))
			pictos.sort()
			for p in pictos:
				lignes.append("picto %s %s" % [p, FileAccess.get_md5("user://classeur/pictos/" + p)])
			print("EMPREINTE ", "\n".join(lignes).md5_text(), " (", lignes.size(), " lignes)")
	quit(0 if ok else 1)


func _differences(a: ConfigFile, b: ConfigFile) -> Array:
	var diffs := []
	var sections := {}
	for s in a.get_sections() + b.get_sections():
		sections[s] = true
	for s in sections:
		var cles := {}
		for k in (a.get_section_keys(s) if a.has_section(s) else PackedStringArray()):
			cles[k] = true
		for k in (b.get_section_keys(s) if b.has_section(s) else PackedStringArray()):
			cles[k] = true
		for k in cles:
			var va = a.get_value(s, k, null) if a.has_section_key(s, k) else null
			var vb = b.get_value(s, k, null) if b.has_section_key(s, k) else null
			if var_to_str(va) != var_to_str(vb):
				diffs.append([s, k, va, vb])
	return diffs
