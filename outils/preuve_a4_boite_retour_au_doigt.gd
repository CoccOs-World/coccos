# Preuve A4 (Fabrice 04-11, suite d'A3 : « Question 2. Oui. Question 3. Oui. ») : sur Android, se prennent
# au DOIGT du joueur SEUL (la pointe dessus, doigt ailleurs → rien), sans allumage au survol de la pointe :
# les icones de la BOITE A ICONES (bouton Menu) et la fleche « retour arriere » des tableaux de Lettres et
# de Chasse. La boite ne souleve ni ne range ses icones (ni deplacables ni rangeables) : seul le tap compte.
# Monte les VRAIS jeux / le VRAI bureau en mode tactile (user:// isole), curseur a la gamme Android,
# doigts poses par le VRAI chemin du moteur (outils/doigt_moteur.gd). Cas DISCRIMINANTS :
#   <nom>a  pointe SUR l'element, doigt dehors (sur rien de « au doigt » ; dans la boite pour ses icones,
#           sinon le tap sur le voile la fermerait) → RIEN ;
#   <nom>b  doigt SUR l'element, pointe dehors → PRIS (efface une lettre / lance) ;
#   <nom>s  pas d'allumage : l'etat « survole » est dessine comme l'etat normal ;
#   Bg      les icones de la boite ne se soulevent pas (appui long au doigt → aucun deplacement) ;
#   P       PC (souris) : un clic sur une icone de la boite la lance, la souris garde son survol.
# Lancement :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_a4_boite_retour_au_doigt.gd
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


## Le point n'est sur AUCUN bouton d'un element pris au doigt (marge 4 px) — un doigt « dehors » ne
## doit rien prendre (il peut tomber sur le libelle d'une icone : un libelle ne lance rien).
func _libre(q: Vector2) -> bool:
	for n in get_nodes_in_group(&"au_doigt"):
		if not (n is Control and (n as Control).is_visible_in_tree()):
			continue
		var boutons: Array = (n as Control).find_children("*", "BaseButton", true, false)
		if n is BaseButton:
			boutons.append(n)
		for b in boutons:
			if (b as Control).is_visible_in_tree() and (b as Control).get_global_rect().grow(4.0).has_point(q):
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
func _cas(nom: String, cible: Control, compte: Callable, bouton: Button = null, dehors_dans := Rect2()) -> void:
	_verifier("%s element trouve" % nom, cible != null)
	if cible == null:
		return
	var r := cible.get_global_rect()
	var sur := func(q: Vector2) -> bool: return r.grow(-4.0).has_point(q)
	var hors := func(q: Vector2) -> bool: return not r.grow(4.0).has_point(q) and _libre(q) \
			and (dehors_dans.size == Vector2.ZERO or dehors_dans.grow(-6.0).has_point(q))
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




# --- Jeux : fleche « retour arriere » de Lettres et de Chasse ---------------------------

func _retour(nom: String, scene: String) -> void:
	print("--- %s (retour arriere) ---" % nom)
	await _monter(scene)
	var fleche := _bouton_branche("_effacer_derniere")
	var n := _compter(fleche, _jeu, "_effacer_derniere")
	await _cas("%s-retour " % nom.left(1), fleche, func() -> int: return n[0])
	_verifier("%s la fleche est dans le groupe « au_doigt »" % nom, fleche != null and fleche.is_in_group(&"au_doigt"))
	await _demonter()


# --- Bureau : icones de la boite a icones -------------------------------------------------

func _boite(bureau: Control) -> Control:
	var voile: Control = bureau.get("_menu")
	if voile != null:
		for n in voile.get_children():
			if n is PanelContainer:
				return n
	return null


func _icones_boite(boite: Control) -> Array:
	return boite.find_children("*", "", true, false).filter(func(n: Node) -> bool: return n.has_signal("lancee"))


func _bureau_android() -> void:
	print("--- BUREAU ANDROID (icones de la boite a icones) ---")
	var bureau := await _monter_bureau(true)
	print("  zone %s, barre %d px, decalage doigt → pointe = %s" % [_zone(), bureau.hauteur_barre, _curseur.decalage_doigt()])
	bureau.call("_basculer_menu")
	await _trames(4)
	var boite := _boite(bureau)
	_verifier("boite a icones ouverte", boite != null)
	if boite == null:
		bureau.queue_free()
		await _trames(4)
		return
	var icones := _icones_boite(boite)
	_verifier("boite : des icones (%d)" % icones.size(), icones.size() >= 2)
	var a_tester: Array = []
	if icones.size() >= 1:
		a_tester.append(icones[0])
	if icones.size() >= 2:
		a_tester.append(icones[icones.size() - 1])
	for ic in a_tester:
		if _boite(bureau) == null:
			_verifier("boite toujours ouverte avant « %s »" % ic.id, false)
			break
		var n := _compter_icone(ic, Callable(bureau, "_lancer_depuis_menu"))
		var btn: Button = ic.get("_btn")
		await _cas("M-%s " % ic.id, btn, func() -> int: return n[0], btn, boite.get_global_rect())
		_verifier("M-%s s pas d'eclat au survol (icone)" % ic.id, _icone_eteinte(ic))
		_verifier("M-%s dans le groupe « au_doigt »" % ic.id, ic.is_in_group(&"au_doigt"))
	# Bg : appui long au doigt sur une icone de la boite → elle ne bouge pas (ni deplacable ni rangeable)
	if _boite(bureau) != null and icones.size() >= 1:
		var ic: Control = icones[0]
		var avant := ic.global_position
		var c: Vector2 = (ic.get("_btn") as Control).get_global_rect().get_center()
		Doigt.toucher(root, c, true)
		await create_timer(1.2).timeout
		Doigt.glisser(root, c, c + Vector2(60, 40))
		await _trames(3)
		Doigt.toucher(root, c + Vector2(60, 40), false)
		await _trames(3)
		_verifier("Bg appui long + glisse au doigt : l'icone de la boite ne bouge pas",
			is_instance_valid(ic) and ic.global_position.is_equal_approx(avant), "avant %s apres %s" % [avant, ic.global_position if is_instance_valid(ic) else "?"])
	bureau.queue_free()
	await _trames(4)


func _bureau_pc() -> void:
	print("--- BUREAU PC (souris : icones de la boite inchangees) ---")
	PinConfig.ecrire_option("interface", "mode_tactile", false)
	var bureau := await _monter_bureau(false)
	bureau.call("_basculer_menu")
	await _trames(4)
	var boite := _boite(bureau)
	_verifier("P boite a icones ouverte (PC)", boite != null)
	if boite != null:
		var ic: Control = _icones_boite(boite)[0]
		var btn: Button = ic.get("_btn")
		var c := btn.get_global_rect().get_center()
		Doigt.souris_mouvement(root, c + Vector2(-200, -200), c)
		await _trames(2)
		var eclat := false
		for tr in btn.find_children("*", "TextureRect", true, false):
			eclat = eclat or not (tr as TextureRect).modulate.is_equal_approx(Color.WHITE)
		_verifier("P PC : survol souris non eteint (icone non marquee)", not bool(ic.get("survol_eteint")),
			"eclat image %s" % eclat)
		var n := _compter_icone(ic, Callable(bureau, "_lancer_depuis_menu"))
		Doigt.souris_bouton(root, c, true)
		await _trames(2)
		Doigt.souris_bouton(root, c, false)
		await _trames(3)
		_verifier("P PC : clic au pointeur sur une icone de la boite → lancee", n[0] == 1)
	bureau.queue_free()
	await _trames(4)
	PinConfig.ecrire_option("interface", "mode_tactile", true)


func _derouler() -> void:
	print("=== PREUVE A4 — BOITE A ICONES + RETOUR ARRIERE AU DOIGT (Android) ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	PinConfig.ecrire_option("interface", "mode_tactile", true)
	await _retour("LETTRES", "res://scenes/lettres.tscn")
	await _retour("CHASSE", "res://scenes/chasse.tscn")
	await _bureau_android()
	await _bureau_pc()
	_fin()


func _fin() -> void:
	print("=== %s (%d echec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
