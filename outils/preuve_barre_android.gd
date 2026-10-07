# Preuve : la barre des taches du bureau fait +30 % d'epaisseur sur ANDROID, rien ne change sur PC
# (REQ_261007 android barre taches +30).
# Monte le VRAI bureau (scenes/bureau.tscn) dans root, deux fois :
#   ① PC (plateforme du run)      = barre de 76 px, boutons 60x60, marges 8 — valeurs d'origine ;
#   ② Android (hauteur forcee par hauteur_barre_pour(true) AVANT _ready, la feature
#      « android » ne pouvant pas etre simulee sur PC) = barre de 99 px ;
# et, dans chaque cas : contenu de la barre DEDANS et centre verticalement, pictos centres
# dans leur bouton, fenetre-categorie / boite a icones / icones / glissiere de volume
# bornees AU-DESSUS de la barre (aucune fenetre sous la barre, meme poussee tout en bas).
# Les attendus 76 et 99 sont ecrits ICI (76 x 1,30 = 98,8 -> 99), pas relus dans le code teste.
# Imprime aussi une SIGNATURE de la barre PC (rect de chaque noeud) : la meme preuve
# rejouee sur la branche d'origine doit sortir la meme signature (desktop inchange).
# Lancement (user:// ISOLE) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_barre_android.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const BARRE_PC := 76
const BARRE_ANDROID := 99
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


func _monter_bureau(hauteur_forcee: int) -> Control:
	var bureau: Control = load("res://scenes/bureau.tscn").instantiate()
	if hauteur_forcee > 0:
		bureau.set("hauteur_barre", hauteur_forcee)
	root.add_child(bureau)
	current_scene = bureau
	await _trames(6)
	return bureau


func _barre(bureau: Control) -> PanelContainer:
	for n in bureau.get_children():
		if n is PanelContainer and n.anchor_top == 1.0 and n.anchor_bottom == 1.0:
			return n
	return null


func _descendants(n: Node, acc: Array) -> Array:
	for c in n.get_children():
		if c is Control:
			acc.append(c)
		_descendants(c, acc)
	return acc


func _signature(barre: Control) -> String:
	var lignes := []
	for c in _descendants(barre, [barre]):
		var r: Rect2 = c.get_global_rect()
		var texte := ""
		if c is Label:
			texte = " valign=%d" % c.vertical_alignment
		lignes.append("%s %s%s" % [c.get_class(), r, texte])
	return "\n".join(lignes)


func _contenu_barre(nom: String, bureau: Control, barre: Control, attendu: int) -> void:
	var rb: Rect2 = barre.get_global_rect()
	_verifier("%s : barre de %d px" % [nom, attendu], absf(rb.size.y - attendu) < 0.01,
		"hauteur %.1f, offset_top %.1f" % [rb.size.y, barre.offset_top])
	_verifier("%s : barre collee au bas" % nom, absf(rb.end.y - bureau.size.y) < 0.01,
		"bas %.1f / ecran %.1f" % [rb.end.y, bureau.size.y])
	var ligne: Control = barre.get_child(0).get_child(0)
	var cote_attendu := 60.0 if attendu == BARRE_PC else 79.0  # hauteur - 2 marges (8 -> 10)
	for c in ligne.get_children():
		var r: Rect2 = c.get_global_rect()
		if r.size.x <= 0.0:
			continue  # espace extensible / horloge vide
		var dedans := r.position.y >= rb.position.y - 0.01 and r.end.y <= rb.end.y + 0.01
		var centre := absf(r.get_center().y - rb.get_center().y) <= TOL
		_verifier("%s : %s dans la barre et centre" % [nom, c.get_class()], dedans and centre,
			"rect %s, centre barre y=%.1f" % [r, rb.get_center().y])
		if c is Button and c.text == "":
			_verifier("%s : bouton carre de %d" % [nom, cote_attendu],
				absf(r.size.x - cote_attendu) < 0.01 and absf(r.size.y - r.size.x) <= TOL,
				"taille %s" % r.size)
			for p in c.get_children():
				var rp: Rect2 = p.get_global_rect()
				_verifier("%s : picto centre dans son bouton" % nom,
					rp.get_center().distance_to(r.get_center()) <= TOL, "picto %s" % rp)
		if c is Label:
			var police: Font = c.get_theme_font("font")
			var h := police.get_height(c.get_theme_font_size("font_size"))
			var haut_texte := r.position.y + (r.size.y - h) / 2.0 if c.vertical_alignment == VERTICAL_ALIGNMENT_CENTER else r.position.y
			var ecart := absf(haut_texte + h / 2.0 - rb.get_center().y)
			_verifier("%s : horloge lisible (taille 34 gardee) et centree" % nom,
				c.get_theme_font_size("font_size") == 34 and ecart <= (6.5 if attendu == BARRE_PC else TOL),
				"ecart au centre %.1f px" % ecart)


func _bornes(nom: String, bureau: Control, attendu: int) -> void:
	var plafond := bureau.size.y - attendu
	# Fenetre-categorie : poussee tout en bas, elle doit rester au-dessus de la barre
	var dossier := ""
	for n in bureau.get_children():
		if n.has_signal("deplacee") and n.est_dossier:
			dossier = n.id
			_verifier("%s : icone bornee par la barre" % nom, n.limite_basse == attendu,
				"limite_basse %s" % n.limite_basse)
			n.position.y = 5000.0
			n.garder_dans_l_ecran()
			_verifier("%s : icone poussee en bas reste au-dessus" % nom,
				n.get_global_rect().end.y <= plafond + 0.01, "bas %.1f / plafond %.1f" % [n.get_global_rect().end.y, plafond])
			break
	if dossier != "":
		bureau._ouvrir_fenetre(dossier, "test", Color.WHITE)
		await _trames(4)
		var f: Control = bureau._fenetres_ouvertes[dossier]
		_verifier("%s : fenetre bornee par la barre" % nom, f.limite_basse == attendu, "limite_basse %s" % f.limite_basse)
		_verifier("%s : fenetre centree au-dessus de la barre" % nom,
			absf(f.get_global_rect().get_center().y - plafond / 2.0) <= TOL,
			"centre y %.1f, attendu %.1f" % [f.get_global_rect().get_center().y, plafond / 2.0])
		f.position.y = 5000.0
		f._rester_dans_l_ecran()
		_verifier("%s : fenetre poussee en bas ne passe pas sous la barre" % nom,
			f.get_global_rect().end.y <= plafond + 0.01, "bas %.1f / plafond %.1f" % [f.get_global_rect().end.y, plafond])
		f.queue_free()
		bureau._fenetres_ouvertes.clear()
	# Boite a icones (menu)
	bureau._basculer_menu()
	await _trames(4)
	var voile: Control = bureau.get("_menu")
	var boite: Control = voile.get_child(0) if voile != null and voile.get_child_count() > 0 else null
	_verifier("%s : boite a icones bornee par la barre" % nom, boite != null and boite.limite_basse == attendu,
		"limite_basse %s" % (boite.limite_basse if boite else "?"))
	if boite != null:
		_verifier("%s : boite a icones au-dessus de la barre" % nom, boite.get_global_rect().end.y <= plafond + 0.01,
			"bas %.1f / plafond %.1f" % [boite.get_global_rect().end.y, plafond])
	bureau._fermer_menu()
	await _trames(2)
	# Glissiere de volume : posee au-dessus de la barre
	bureau._basculer_volume()
	await _trames(4)
	var pv: Control = bureau.get("_panneau_volume")
	if pv != null:
		_verifier("%s : glissiere de volume au-dessus de la barre" % nom,
			absf(pv.get_global_rect().end.y - (plafond - 12.0)) <= TOL, "bas %.1f" % pv.get_global_rect().end.y)
		bureau._basculer_volume()


func _derouler() -> void:
	print("=== PREUVE BARRE DES TACHES ANDROID +30 % (bureau) ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	var Bureau: Script = load("res://scripts/bureau.gd")
	var calcule := Bureau.has_method("hauteur_barre_pour")
	_verifier("hauteur_barre_pour existe", calcule)
	if calcule:
		_verifier("Android = %d px (76 x 1,30)" % BARRE_ANDROID, Bureau.hauteur_barre_pour(true) == BARRE_ANDROID,
			str(Bureau.hauteur_barre_pour(true)))
		_verifier("PC = %d px" % BARRE_PC, Bureau.hauteur_barre_pour(false) == BARRE_PC, str(Bureau.hauteur_barre_pour(false)))
	_verifier("ce run tourne sur PC (feature android absente)", not OS.has_feature("android"))

	# ① PC — plateforme reelle du run
	var bureau := await _monter_bureau(0)
	var barre := _barre(bureau)
	_verifier("① PC : barre trouvee", barre != null)
	if barre != null:
		if "hauteur_barre" in bureau:
			_verifier("① PC : hauteur effective = 76", bureau.hauteur_barre == BARRE_PC, str(bureau.hauteur_barre))
		_contenu_barre("① PC", bureau, barre, BARRE_PC)
		await _bornes("① PC", bureau, BARRE_PC)
		print("--- SIGNATURE BARRE PC ---\n" + _signature(barre) + "\n--- FIN SIGNATURE ---")
	bureau.queue_free()
	await _trames(3)

	# ② Android — hauteur forcee avant _ready
	if calcule:
		bureau = await _monter_bureau(Bureau.hauteur_barre_pour(true))
		barre = _barre(bureau)
		_verifier("② Android : barre trouvee", barre != null)
		if barre != null:
			_verifier("② Android : hauteur effective = 99", bureau.hauteur_barre == BARRE_ANDROID, str(bureau.hauteur_barre))
			_contenu_barre("② Android", bureau, barre, BARRE_ANDROID)
			await _bornes("② Android", bureau, BARRE_ANDROID)
		bureau.queue_free()
		await _trames(3)
	_fin()


func _fin() -> void:
	print("=== %s (%d echec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(0 if _echecs == 0 else 1)
