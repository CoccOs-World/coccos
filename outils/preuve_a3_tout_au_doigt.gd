# Preuve A3 (Fabrice 04-11, suite d'A2) : sur Android, se prennent au DOIGT du joueur SEUL (la pointe
# dessus, doigt ailleurs → rien) : la roue des reglages et le bouton eteindre, la croix « tout effacer »
# (Lettres, Chasse), le bouton « dire le mot » (Lettres), les icones du bureau (dossiers ET jeux) et
# les icones des fenetres-dossiers. Rien de ce qui se prend au doigt ne s'allume au survol de la pointe.
# Fenetres CoccOs du bureau : barre de titre +15 % et rond de la croix +15 % sur Android seulement.
# Monte les VRAIS jeux / le VRAI bureau en mode tactile (user:// isole), curseur a la gamme Android,
# doigts poses par le VRAI chemin du moteur (outils/doigt_moteur.gd). Cas DISCRIMINANTS :
#   <nom>a  pointe SUR l'element, doigt dehors (sur rien de « au doigt ») → RIEN ;
#   <nom>b  doigt SUR l'element, pointe dehors → PRIS (presse / lance / ouvert) ;
#   <nom>s  pas d'allumage : l'etat « survole » de l'element est dessine comme l'etat normal ;
#   Sd      pointe qui GLISSE sur un dossier et sur une touche (doigt ailleurs) → ni l'un ni l'autre ne s'eclaire ;
#   W       fenetres du bureau : barre 60 → 69 px, rond de la croix 44 → 51 px (Android), PC identique (60 / 44) ;
#   Wm      doigt pose sur une fenetre-dossier AU-DESSUS d'une icone du bureau → l'icone cachee n'est pas prise.
# Lancement :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_a3_tout_au_doigt.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const PinConfig := preload("res://scripts/pin_config.gd")
const Registre := preload("res://scripts/registre_jeux.gd")
const Doigt := preload("res://outils/doigt_moteur.gd")

const ANDROID := 2.0  # gamme Android des curseur.gd des jeux (comme preuve_a2_doigt_claviers_croix)

var _echecs := 0
var _jeu: Control
var _curseur: Node2D


func _verifier(libelle: String, vrai: bool, detail: String = "") -> void:
	print("  %s %s%s" % ["ok   " if vrai else "ECHEC", libelle, (" — " + detail) if detail != "" else ""])
	if not vrai:
		_echecs += 1


func _initialize() -> void:
	_derouler.call_deferred()


func _trames(n: int) -> void:
	for i in n:
		await process_frame


func _zone() -> Rect2:
	return root.get_visible_rect()


func _pointe_pour(doigt: Vector2) -> Vector2:
	return _curseur.pointe_pour_doigt(doigt, _zone())


func _tap_doigt(d: Vector2) -> void:
	Doigt.toucher(root, d, true)
	await _trames(2)
	Doigt.toucher(root, d, false)
	await _trames(3)


## Le point n'est sur AUCUN element pris au doigt (marge 4 px) — un doigt « dehors » ne doit rien prendre.
func _libre(q: Vector2) -> bool:
	for n in get_nodes_in_group(&"au_doigt"):
		if n is Control and (n as Control).is_visible_in_tree() and (n as Control).get_global_rect().grow(4.0).has_point(q):
			return false
	return true


## Doigt (grille de 3 px dans `cadre`) tel que `pour_doigt(doigt)` et `pour_pointe(pointe)`,
## le plus proche de `autour`. Vector2.INF si aucun.
func _chercher_doigt(cadre: Rect2, autour: Vector2, pour_doigt: Callable, pour_pointe: Callable) -> Vector2:
	var meilleur := Vector2.INF
	var y := cadre.position.y
	while y <= cadre.end.y:
		var x := cadre.position.x
		while x <= cadre.end.x:
			var d := Vector2(x, y)
			if _zone().has_point(d) and pour_doigt.call(d) and pour_pointe.call(_pointe_pour(d)) \
					and d.distance_to(autour) < meilleur.distance_to(autour):
				meilleur = d
			x += 3.0
		y += 3.0
	return meilleur


## L'etat « survole » d'un bouton est-il dessine comme l'etat normal (aucun allumage) ?
func _survol_eteint(btn: Button) -> bool:
	var h := btn.get_theme_stylebox("hover")
	var n := btn.get_theme_stylebox("normal")
	var meme_fond := h == n or (h is StyleBoxEmpty and n is StyleBoxEmpty) \
			or (h is StyleBoxFlat and n is StyleBoxFlat and (h as StyleBoxFlat).bg_color.is_equal_approx((n as StyleBoxFlat).bg_color))
	return meme_fond and btn.get_theme_color("font_hover_color").is_equal_approx(btn.get_theme_color("font_color"))


## a / b / s sur un element : `cible` = zone a toucher, `compte` = Callable → int (fois ou il a ete pris).
func _cas(nom: String, cible: Control, compte: Callable, bouton: Button = null) -> void:
	_verifier("%s element trouve" % nom, cible != null)
	if cible == null:
		return
	var r := cible.get_global_rect()
	var sur := func(q: Vector2) -> bool: return r.grow(-4.0).has_point(q)
	var hors := func(q: Vector2) -> bool: return not r.grow(4.0).has_point(q) and _libre(q)
	# a : pointe SUR l'element, doigt dehors → rien
	var d := _chercher_doigt(r.grow(320.0), r.get_center(), hors, sur)
	if d == Vector2.INF:
		_verifier("%sa mise en place : pointe sur l'element, doigt dehors" % nom, false, "element %s" % r)
	else:
		var avant: int = compte.call()
		await _tap_doigt(d)
		_verifier("%sa pointe SUR l'element, doigt dehors → RIEN" % nom, compte.call() == avant,
			"doigt %s, pointe %s, element %s, pris %d fois" % [d, _pointe_pour(d), r, compte.call() - avant])
	# s : pas d'allumage (etat survole dessine comme le normal)
	var b := bouton if bouton != null else (cible as Button)
	if b != null:
		_verifier("%ss pas d'allumage au survol (survole = normal)" % nom, _survol_eteint(b))
	# b : doigt SUR l'element ; pointe dehors si la geometrie le permet (sinon centre, signale)
	d = _chercher_doigt(r, r.get_center(), sur, func(q: Vector2) -> bool: return not r.grow(4.0).has_point(q))
	var discriminant := d != Vector2.INF
	if not discriminant:
		d = r.get_center()
	var avant_b: int = compte.call()
	await _tap_doigt(d)
	_verifier("%sb doigt SUR l'element%s → PRIS" % [nom, ", pointe dehors" if discriminant else " (pointe aussi dessus : bord fondu)"],
		compte.call() == avant_b + 1, "doigt %s, pointe %s, element %s, pris %d fois" % [d, _pointe_pour(d), r, compte.call() - avant_b])


## Debranche `methode` de `btn` (s'il y est branche) et compte les `pressed`.
func _compter(btn: Button, cible: Object, methode: String) -> Array:
	var compteur := [0]
	if btn == null:
		return compteur
	if cible != null and btn.pressed.is_connected(Callable(cible, methode)):
		btn.pressed.disconnect(Callable(cible, methode))
	btn.pressed.connect(func() -> void: compteur[0] += 1)
	return compteur


# --- Jeux : Lettres (dire le mot, tout effacer), Chasse (tout effacer) -----------------

func _monter(chemin: String) -> void:
	_jeu = load(chemin).instantiate()
	root.add_child(_jeu)
	current_scene = _jeu
	await _trames(6)
	_curseur = _jeu.get("_curseur")
	_curseur.gamme = ANDROID
	_curseur.set("_echelle_base", float(_curseur.get("_echelle_base")) * ANDROID)
	for n in _jeu.get_children():
		if n is Timer:
			(n as Timer).stop()  # pas de bulle qui passe sous le doigt pendant la mesure
	await _trames(2)


func _demonter() -> void:
	if is_instance_valid(_jeu):
		_jeu.queue_free()
	await _trames(4)


## Bouton du jeu branche sur la methode `methode`.
func _bouton_branche(methode: String) -> Button:
	for b in _jeu.find_children("*", "Button", true, false):
		if (b as Button).pressed.is_connected(Callable(_jeu, methode)):
			return b
	return null


func _lettres() -> void:
	print("--- LETTRES (dire le mot, tout effacer, touches) ---")
	await _monter("res://scenes/lettres.tscn")
	var dire := _bouton_branche("_dire_mot")
	var effacer := _bouton_branche("_effacer_tout")
	var n_dire := _compter(dire, _jeu, "_dire_mot")
	var n_effacer := _compter(effacer, _jeu, "_effacer_tout")
	await _cas("L-dire ", dire, func() -> int: return n_dire[0])
	await _cas("L-effacer ", effacer, func() -> int: return n_effacer[0])
	# Sd touches : la pointe glisse sur une touche (doigt au-dessus du clavier) → pas d'allumage
	var clavier: Control = _jeu.get("_clavier")
	if clavier != null:
		var touches := clavier.find_children("*", "Button", true, false)
		var eteintes := touches.filter(func(t: Button) -> bool: return _survol_eteint(t)).size()
		_verifier("Sd touches du clavier : aucune ne s'allume au survol (%d/%d)" % [eteintes, touches.size()],
			touches.size() == 37 and eteintes == touches.size())
		var croix := _bouton_branche("_quitter")
		_verifier("Sd croix de fermeture (A2) : pas d'allumage au survol", croix != null and _survol_eteint(croix))
	await _demonter()


func _chasse() -> void:
	print("--- CHASSE (tout effacer) ---")
	await _monter("res://scenes/chasse.tscn")
	var effacer: Button = null
	for b in _jeu.find_children("*", "Button", true, false):
		var methodes := (b as Button).pressed.get_connections().map(
			func(c: Dictionary) -> String: return (c["callable"] as Callable).get_method())
		if not ("_quitter" in methodes or "_effacer_derniere" in methodes) and not methodes.is_empty():
			effacer = b
	var n_effacer := _compter(effacer, null, "")
	await _cas("C-effacer ", effacer, func() -> int: return n_effacer[0])
	await _demonter()


# --- Bureau : roue, eteindre, icones, fenetres -------------------------------------------

func _monter_bureau(android: bool) -> Control:
	var bureau: Control = load("res://scenes/bureau.tscn").instantiate()
	if android:
		bureau.hauteur_barre = bureau.hauteur_barre_pour(true)
		bureau.set("echelle_fenetres", 1.15)  # la feature android n'est pas simulable sur PC (absent sur l'origine)
	root.add_child(bureau)
	current_scene = bureau
	await _trames(4)
	_curseur = bureau.get("_curseur")
	if android:
		_curseur.android = true
		_curseur.gamme = _curseur.gamme_pour(true)
		_curseur._ready()
	await _trames(2)
	return bureau


func _bouton_picto(bureau: Control, id_picto: String) -> Button:
	for b in bureau.find_children("*", "Button", true, false):
		for enfant in b.get_children():
			if enfant.get("id") == id_picto:
				return b
	return null


func _icones(bureau: Control) -> Array:
	return bureau.get_children().filter(func(n: Node) -> bool: return n.has_signal("deplacee") and not n.is_queued_for_deletion())


func _icone(bureau: Control, id: String) -> Control:
	for ic in _icones(bureau):
		if ic.id == id:
			return ic
	return null


func _jeu_direct(bureau: Control) -> Control:
	for ic in _icones(bureau):
		var a: Dictionary = Registre.appli(ic.id)
		if not ic.est_dossier and not a.is_empty() and a.has("scene"):
			return ic
	return null


## Icone : ses `lancee` sont comptes, le vrai lancement (changement de scene) est debranche.
func _compter_icone(ic: Control, handler: Callable) -> Array:
	var compteur := [0]
	if ic == null:
		return compteur
	if handler.is_valid() and ic.lancee.is_connected(handler):
		ic.lancee.disconnect(handler)
	ic.lancee.connect(func(_id: String) -> void: compteur[0] += 1)
	return compteur


## Icone eteinte : ni le dossier ni l'image ne s'eclairent, le bouton garde son dessin normal.
func _icone_eteinte(ic: Control) -> bool:
	var ok := _survol_eteint(ic.get("_btn"))
	var dessin: Control = ic.get("_dossier")
	if dessin != null:
		ok = ok and (dessin.get("couleur") as Color).is_equal_approx(ic.get("_couleur_dossier"))
	for tr in (ic.get("_btn") as Control).find_children("*", "TextureRect", true, false):
		ok = ok and (tr as TextureRect).modulate.is_equal_approx(Color.WHITE)
	return ok


func _fenetre_mesures(fenetre: Control) -> Array:
	var barre: Control = fenetre.get_child(0).get_child(0)
	var croix: Button = null
	for b in fenetre.find_children("*", "Button", true, false):
		if (b as Button).pressed.is_connected(Callable(fenetre, "queue_free")):
			croix = b
	var rayon := 0
	if croix != null and croix.get_theme_stylebox("normal") is StyleBoxFlat:
		rayon = (croix.get_theme_stylebox("normal") as StyleBoxFlat).corner_radius_top_left
	return [barre.size.y, croix.size if croix != null else Vector2.ZERO, rayon]


func _bureau_android() -> void:
	print("--- BUREAU ANDROID (roue, eteindre, icones, fenetres) ---")
	var bureau := await _monter_bureau(true)
	print("  zone %s, barre %d px, decalage doigt → pointe = %s" % [_zone(), bureau.hauteur_barre, _curseur.decalage_doigt()])
	# roue / eteindre (#224 → au doigt SEUL)
	var roue := _bouton_picto(bureau, "engrenage")
	var eteindre := _bouton_picto(bureau, "eteindre")
	var n_roue := _compter(roue, bureau, "_aller_reglages")
	var n_eteindre := _compter(eteindre, bureau, "_eteindre")
	await _cas("B-roue ", roue, func() -> int: return n_roue[0])
	await _cas("B-eteindre ", eteindre, func() -> int: return n_eteindre[0])

	# icone de jeu du bureau
	var jeu := _jeu_direct(bureau)
	var n_jeu := _compter_icone(jeu, Callable(bureau, "_lancer_appli"))
	await _cas("I-jeu ", jeu.get("_btn") if jeu else null, func() -> int: return n_jeu[0], jeu.get("_btn") if jeu else null)
	if jeu != null:
		_verifier("I-jeu s pas d'eclat au survol", _icone_eteinte(jeu))

	# icone de dossier du bureau : prise = la fenetre s'ouvre
	var dossier := _icone(bureau, "clavier")
	var ouvertes := func() -> int:
		var f: Variant = bureau.get("_fenetres_ouvertes").get("clavier")
		return 1 if f != null and is_instance_valid(f) and not (f as Node).is_queued_for_deletion() else 0
	await _cas("I-dossier ", dossier.get("_btn") if dossier else null, ouvertes, dossier.get("_btn") if dossier else null)
	var f_clavier: Variant = bureau.get("_fenetres_ouvertes").get("clavier")
	if f_clavier != null and is_instance_valid(f_clavier):
		(f_clavier as Node).queue_free()
		await _trames(3)

	# Sd : la pointe GLISSE sur le dossier (doigt ailleurs, tenu) → il ne s'eclaire pas
	if dossier != null:
		var rd: Rect2 = (dossier.get("_btn") as Control).get_global_rect()
		var sur := func(q: Vector2) -> bool: return rd.grow(-6.0).has_point(q)
		var d := _chercher_doigt(rd.grow(320.0), rd.get_center(), func(q: Vector2) -> bool: return _libre(q), sur)
		if d == Vector2.INF:
			_verifier("Sd mise en place : pointe sur le dossier, doigt libre", false)
		else:
			var depart := d + Vector2(0, 120) if _libre(d + Vector2(0, 120)) and _zone().has_point(d + Vector2(0, 120)) else d + Vector2(160, 0)
			Doigt.toucher(root, depart, true)
			await _trames(2)
			var prec := depart
			for i in range(1, 7):
				var q := depart.lerp(d, i / 6.0)
				Doigt.glisser(root, prec, q)
				prec = q
				await _trames(1)
			await _trames(2)
			var dessin: Control = dossier.get("_dossier")
			_verifier("Sd pointe qui glisse SUR le dossier (doigt libre) : il ne s'eclaire PAS",
				dessin != null and (dessin.get("couleur") as Color).is_equal_approx(dossier.get("_couleur_dossier")),
				"pointe %s dans %s ; couleur %s / repos %s" % [_pointe_pour(d), rd, dessin.get("couleur") if dessin else "?", dossier.get("_couleur_dossier")])
			Doigt.toucher(root, prec, false)
			await _trames(3)

	# icone d'un jeu DANS une fenetre-dossier (« souris » : puzzle…)
	bureau.call("_ouvrir_fenetre", "souris", "Souris", Color(0.3, 0.5, 0.8))
	await _trames(4)
	var fenetre: Control = bureau.get("_fenetres_ouvertes").get("souris")
	_verifier("W fenetre « souris » ouverte", fenetre != null and is_instance_valid(fenetre))
	if fenetre != null and is_instance_valid(fenetre):
		fenetre.position = (_zone().size - fenetre.size) / 2.0
		await _trames(2)
		var m := _fenetre_mesures(fenetre)
		_verifier("W Android : barre de titre 69 px (60 × 1,15)", absf(float(m[0]) - 69.0) < 0.6, "barre %.1f px" % m[0])
		_verifier("W Android : rond de la croix 51 × 51 px (44 × 1,15), rayon 26 (rond)",
			(m[1] as Vector2).is_equal_approx(Vector2(51, 51)) and int(m[2]) == 26, "croix %s, rayon %d" % [m[1], m[2]])
		var dans: Control = null
		for n in fenetre.get("contenu").get_children():
			if n.has_signal("lancee"):
				dans = n
				break
		var n_dans := _compter_icone(dans, Callable(bureau, "_lancer_jeu"))
		await _cas("I-fenetre ", dans.get("_btn") if dans else null, func() -> int: return n_dans[0], dans.get("_btn") if dans else null)
		if dans != null:
			_verifier("I-fenetre s pas d'eclat au survol", _icone_eteinte(dans))

		# Wm : doigt sur la fenetre, au-dessus d'une icone du bureau cachee → elle n'est pas prise
		var cachee: Control = null
		var point := Vector2.INF
		var rf := fenetre.get_global_rect()
		for ic in _icones(bureau):
			var rb: Rect2 = (ic.get("_btn") as Control).get_global_rect()
			var inter := rb.intersection(rf)
			if inter.has_area():
				for y in range(int(inter.position.y) + 3, int(inter.end.y) - 3, 4):
					for x in range(int(inter.position.x) + 3, int(inter.end.x) - 3, 4):
						var q := Vector2(x, y)
						var sur_fenetre := false
						for n in get_nodes_in_group(&"au_doigt"):
							if n is Control and fenetre.is_ancestor_of(n) and (n as Control).get_global_rect().grow(4.0).has_point(q):
								sur_fenetre = true
						if not sur_fenetre and point == Vector2.INF:
							point = q
				if point != Vector2.INF:
					cachee = ic
					break
		if cachee == null:
			# aucune icone sous la fenetre : on la pose sur le jeu direct
			fenetre.position = (jeu.get("_btn") as Control).get_global_rect().get_center() - Vector2(fenetre.size.x / 2.0, fenetre.size.y - 20.0)
			await _trames(2)
			_verifier("Wm mise en place : une icone du bureau sous la fenetre", false, "fenetre %s" % fenetre.get_global_rect())
		else:
			var n_cachee := _compter_icone(cachee, Callable(bureau, "_lancer_appli"))
			Doigt.toucher(root, point, true)
			await _trames(2)
			_verifier("Wm doigt sur la fenetre au-dessus de « %s » : visee a la pointe gardee (pas « au doigt »)" % cachee.id,
				bureau.get("_doigt_sur_bouton") == false, "point %s" % point)
			Doigt.toucher(root, point, false)
			await _trames(3)
			_verifier("Wm l'icone cachee n'est pas prise", n_cachee[0] == 0)
	# boite a icones : meme barre agrandie
	bureau.call("_basculer_menu")
	await _trames(3)
	var voile: Control = bureau.get("_menu")
	var boite: Control = null
	if voile != null:
		for n in voile.get_children():
			if n is PanelContainer:
				boite = n
	if boite != null:
		var mb := _fenetre_mesures(boite)
		_verifier("W Android : boite a icones, barre 69 px et croix 51 px",
			absf(float(mb[0]) - 69.0) < 0.6 and (mb[1] as Vector2).is_equal_approx(Vector2(51, 51)), "barre %.1f, croix %s" % [mb[0], mb[1]])
	else:
		_verifier("W boite a icones ouverte", false)
	bureau.queue_free()
	await _trames(4)


func _bureau_pc() -> void:
	print("--- BUREAU PC (souris : fenetres inchangees, survols gardes) ---")
	PinConfig.ecrire_option("interface", "mode_tactile", false)
	var bureau := await _monter_bureau(false)
	bureau.call("_ouvrir_fenetre", "souris", "Souris", Color(0.3, 0.5, 0.8))
	await _trames(4)
	var fenetre: Control = bureau.get("_fenetres_ouvertes").get("souris")
	if fenetre != null:
		var m := _fenetre_mesures(fenetre)
		_verifier("P PC : barre de titre 60 px, croix 44 × 44, rayon 22 (inchanges)",
			absf(float(m[0]) - 60.0) < 0.6 and (m[1] as Vector2).is_equal_approx(Vector2(44, 44)) and int(m[2]) == 22,
			"barre %.1f, croix %s, rayon %d" % [m[0], m[1], m[2]])
	var roue := _bouton_picto(bureau, "engrenage")
	var c := roue.get_global_rect().get_center()
	Doigt.souris_mouvement(root, c + Vector2(-200, -200), c)
	await _trames(2)
	_verifier("P PC : la roue garde son allumage au survol de la souris", not _survol_eteint(roue))
	var n_roue := _compter(roue, bureau, "_aller_reglages")
	Doigt.souris_bouton(root, c, true)
	await _trames(2)
	Doigt.souris_bouton(root, c, false)
	await _trames(2)
	_verifier("P PC : clic au pointeur sur la roue → pressee", n_roue[0] == 1)
	bureau.queue_free()
	await _trames(4)
	PinConfig.ecrire_option("interface", "mode_tactile", true)


func _derouler() -> void:
	print("=== PREUVE A3 — TOUT AU DOIGT (suite) + FENETRES +15 % (Android) ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	PinConfig.ecrire_option("interface", "mode_tactile", true)
	await _lettres()
	await _chasse()
	await _bureau_android()
	await _bureau_pc()
	_fin()


func _fin() -> void:
	print("=== %s (%d echec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
