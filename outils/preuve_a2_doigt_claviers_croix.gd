# Preuve A2 (Fabrice 04-11) : sur Android, TOUS les claviers virtuels et TOUTES les croix de
# fermeture se prennent au DOIGT du joueur, plus a la pointe du curseur. Regle #224 (roue /
# eteindre, validee Redmi 22-10) etendue : decidee a l'appui sur le doigt brut, tenue jusqu'au
# relache ; et la pointe ne les prend plus. Clavier des Lettres remis a sa place (plus de remontee).
# Monte les VRAIS jeux / le VRAI bureau en mode tactile (user:// isole), curseur a la gamme
# Android, doigts poses par le VRAI chemin du moteur (outils/doigt_moteur.gd). Cas DISCRIMINANTS :
#   X[jeu]  croix de fermeture (Ballons, Decouverte, Chasse, Lettres) :
#           Xa pointe SUR la croix, doigt dehors → le jeu RESTE ;
#           Xb doigt SUR la croix (pointe dehors si possible) → QUITTE ;
#   F[...]  croix des fenetres du bureau (fenetre d'un dossier, boite a icones) : idem Fa / Fb ;
#   K       Lettres, CHAQUE touche (37) : doigt au centre de la touche → c'est ELLE qui est tapee
#           (on compte celles dont la pointe tombe sur une AUTRE touche ou hors clavier : discriminant) ;
#   Kg      Lettres : doigt entre deux touches (marge du clavier), pointe sur une touche → AUCUNE touche ;
#   Kp      Lettres : clavier A SA PLACE (remontee 0, bas du clavier = bas de l'ecran, fond creme
#           jusqu'en bas, pas de bande sous les touches), curseur VISIBLE ;
#   M       Mots (inchange, deja au doigt) : doigt sur une touche → tapee (temoin, vert partout) ;
#   P       souris de PC inchangee (Lettres) : clic au pointeur sur une touche → tapee ; croix au pointeur → quitte.
# Lancement :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_a2_doigt_claviers_croix.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const PinConfig := preload("res://scripts/pin_config.gd")
const Doigt := preload("res://outils/doigt_moteur.gd")

const ANDROID := 2.0  # gamme Android des curseur.gd (comme preuve_visee_pointe_jeux)

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


func _monter(chemin: String, android: bool) -> void:
	_jeu = load(chemin).instantiate()
	root.add_child(_jeu)
	current_scene = _jeu
	await _trames(6)
	_curseur = _jeu.get("_curseur")
	if android:
		_curseur.gamme = ANDROID
		_curseur.set("_echelle_base", float(_curseur.get("_echelle_base")) * ANDROID)
	await _trames(2)


func _demonter() -> void:
	if is_instance_valid(_jeu):
		_jeu.queue_free()
	await _trames(4)


## Croix de fermeture d'un jeu = bouton enfant direct branche sur `_quitter`. Le vrai handler
## (retour bureau) est debranche et remplace par un compteur.
func _croix_du_jeu(compteur: Array) -> Button:
	for b in _jeu.get_children():
		if b is Button and (b as Button).pressed.is_connected(Callable(_jeu, "_quitter")):
			(b as Button).pressed.disconnect(Callable(_jeu, "_quitter"))
			(b as Button).pressed.connect(func() -> void: compteur[0] += 1)
			return b
	return null


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


## Xa / Xb (ou Fa / Fb) sur une croix ; `compteur[0]` = nombre de `pressed` recus.
## `encore_la` dit si la chose fermee est toujours la (fenetre) — facultatif.
func _cas_croix(nom: String, croix: Button, compteur: Array, encore_la := Callable()) -> void:
	_verifier("%s croix trouvee" % nom, croix != null)
	if croix == null:
		return
	var r := croix.get_global_rect()
	var sur := func(q: Vector2) -> bool: return r.grow(-4.0).has_point(q)
	var hors := func(q: Vector2) -> bool: return not r.grow(4.0).has_point(q)
	# a : pointe SUR la croix, doigt dehors → rien
	var d := _chercher_doigt(r.grow(320.0), r.get_center(), hors, sur)
	if d == Vector2.INF:
		_verifier("%sa mise en place : pointe sur la croix, doigt dehors" % nom, false, "croix %s" % r)
	else:
		var avant: int = compteur[0]
		await _tap_doigt(d)
		_verifier("%sa pointe SUR la croix, doigt dehors → PAS de fermeture" % nom,
			compteur[0] == avant and (not encore_la.is_valid() or encore_la.call()),
			"doigt %s, pointe %s, croix %s, pressee %d fois" % [d, _pointe_pour(d), r, compteur[0] - avant])
	# b : doigt SUR la croix ; pointe dehors si la geometrie le permet (sinon centre, signale)
	d = _chercher_doigt(r, r.get_center(), sur, hors)
	var discriminant := d != Vector2.INF
	if not discriminant:
		d = r.get_center()
	var avant_b: int = compteur[0]
	await _tap_doigt(d)
	_verifier("%sb doigt SUR la croix%s → FERMETURE" % [nom, ", pointe dehors" if discriminant else " (pointe aussi dessus : bord fondu)"],
		compteur[0] == avant_b + 1, "doigt %s, pointe %s, croix %s, pressee %d fois" % [d, _pointe_pour(d), r, compteur[0] - avant_b])


# --- Croix des jeux -----------------------------------------------------------------

func _croix_jeu(nom: String, scene: String) -> void:
	print("--- CROIX %s ---" % nom)
	await _monter(scene, true)
	for n in _jeu.get_children():
		if n is Timer:
			(n as Timer).stop()  # pas de ballon / bulle qui passe sous le doigt pendant la mesure
	var compteur := [0]
	var croix := _croix_du_jeu(compteur)
	await _cas_croix("X[%s]" % nom, croix, compteur)
	await _demonter()


# --- Lettres : clavier au doigt, a sa place ---------------------------------------

func _touches(clavier: Control) -> Array:
	return clavier.find_children("*", "Button", true, false)


func _touche_sous(clavier: Control, p: Vector2) -> Button:
	for t in _touches(clavier):
		if (t as Button).get_global_rect().has_point(p):
			return t
	return null


func _nom(t: Button) -> String:
	return "∅" if t == null else ("⌫" if t.text == "" else t.text)


func _lettres() -> void:
	print("--- LETTRES (clavier dessine) ---")
	await _monter("res://scenes/lettres.tscn", true)
	var clavier: Control = _jeu.get("_clavier")
	_verifier("Kp clavier dessine present (mode tactile)", clavier != null)
	if clavier == null:
		await _demonter()
		return
	var z := _zone()
	var rc := clavier.get_global_rect()
	_verifier("Kp clavier A SA PLACE : remontee 0", is_zero_approx(float(clavier.get("remontee"))),
		"remontee %.1f px" % float(clavier.get("remontee")))
	_verifier("Kp bas du clavier = bas de l'ecran, hauteur %d px" % int(clavier.HAUTEUR),
		absf(rc.end.y - z.end.y) < 0.6 and absf(rc.size.y - clavier.HAUTEUR) < 0.6, "clavier %s, ecran %s" % [rc, z])
	var fond: Rect2 = clavier.rect_fond_touches()
	_verifier("Kp fond creme jusqu'en bas (aucune bande sous les touches)", absf(fond.end.y - z.end.y) < 0.6,
		"fond %s" % fond)
	var bas_touches := 0.0
	for t in _touches(clavier):
		bas_touches = maxf(bas_touches, (t as Button).get_global_rect().end.y)
	_verifier("Kp rangee du bas a 12 px du bord (marge du clavier, pas de remontee)", absf(z.end.y - bas_touches - 12.0) < 1.0,
		"bas des touches %.1f, bas ecran %.1f" % [bas_touches, z.end.y])
	_verifier("Kp curseur des Lettres VISIBLE", _curseur.visible)
	var centre: Control = _jeu.get("_centre")
	_verifier("Kp le contenu se pousse au-dessus du clavier (offset_bottom = -%d)" % int(clavier.HAUTEUR),
		absf(centre.offset_bottom + clavier.HAUTEUR) < 0.6, "offset_bottom %.1f" % centre.offset_bottom)

	var tapees := []
	for t in _touches(clavier):
		(t as Button).pressed.connect(func() -> void: tapees.append(_nom(t)))
	# K : chaque touche, doigt au centre
	var bonnes := 0
	var discriminantes := 0
	var rates := []
	for t in _touches(clavier):
		var d: Vector2 = (t as Button).get_global_rect().get_center()
		if _touche_sous(clavier, _pointe_pour(d)) != t:
			discriminantes += 1
		tapees.clear()
		await _tap_doigt(d)
		if tapees == [_nom(t)]:
			bonnes += 1
		else:
			rates.append("%s→%s (pointe sur %s)" % [_nom(t), tapees, _nom(_touche_sous(clavier, _pointe_pour(d)))])
	var n := _touches(clavier).size()
	_verifier("K doigt au centre de CHAQUE touche → c'est elle qui est tapee (%d/%d)" % [bonnes, n],
		bonnes == n and n == 37, "rates : %s" % [rates])
	_verifier("K discriminant : pour %d touche(s) sur %d la pointe tombe AILLEURS (autre touche / hors clavier)" % [discriminantes, n],
		discriminantes >= n / 2)
	# Kg : doigt entre deux touches, pointe sur une touche → aucune
	var sur_touche := func(q: Vector2) -> bool:
		var t := _touche_sous(clavier, q)
		return t != null and t.get_global_rect().grow(-4.0).has_point(q)
	var entre := func(q: Vector2) -> bool: return clavier.contient(q) and _touche_sous(clavier, q) == null \
			and q.y > rc.position.y + 4.0
	var d := _chercher_doigt(rc, rc.get_center(), entre, sur_touche)
	if d == Vector2.INF:
		_verifier("Kg mise en place : doigt entre deux touches, pointe sur une touche", false)
	else:
		tapees.clear()
		await _tap_doigt(d)
		_verifier("Kg doigt ENTRE deux touches, pointe sur « %s » → AUCUNE touche" % _nom(_touche_sous(clavier, _pointe_pour(d))),
			tapees.is_empty(), "doigt %s, pointe %s, tapees %s" % [d, _pointe_pour(d), tapees])
	await _demonter()

	# P : souris de PC inchangee (touche + croix au pointeur)
	await _monter("res://scenes/lettres.tscn", false)
	clavier = _jeu.get("_clavier")
	tapees = []
	for t in _touches(clavier):
		(t as Button).pressed.connect(func() -> void: tapees.append(_nom(t)))
	var t0: Button = _touches(clavier)[12]
	var c := t0.get_global_rect().get_center()
	Doigt.souris_mouvement(root, c + Vector2(0, -200), c)
	await _trames(2)
	Doigt.souris_bouton(root, c, true)
	await _trames(2)
	Doigt.souris_bouton(root, c, false)
	await _trames(2)
	_verifier("P[lettres] souris PC : curseur ET touche au pointeur (« %s »)" % _nom(t0),
		_curseur.position.distance_to(c) < 0.6 and tapees == [_nom(t0)], "curseur %s / %s, tapees %s" % [_curseur.position, c, tapees])
	var compteur := [0]
	var croix := _croix_du_jeu(compteur)
	c = croix.get_global_rect().get_center()
	Doigt.souris_mouvement(root, c + Vector2(-200, 200), c)
	await _trames(2)
	Doigt.souris_bouton(root, c, true)
	await _trames(2)
	Doigt.souris_bouton(root, c, false)
	await _trames(2)
	_verifier("P[lettres] souris PC : croix au pointeur → quitte", compteur[0] == 1)
	await _demonter()


# --- Mots : temoin inchange ------------------------------------------------------

func _mots() -> void:
	print("--- MOTS (temoin, inchange) ---")
	await _monter("res://scenes/mots.tscn", true)
	var clavier: Control = _jeu.get("_clavier")
	var tapees := []
	for t in _touches(clavier):
		(t as Button).pressed.connect(func() -> void: tapees.append(_nom(t)))
	var t0: Button = _touches(clavier)[15]
	await _tap_doigt(t0.get_global_rect().get_center())
	_verifier("M doigt sur « %s » → tapee (Mots deja au doigt)" % _nom(t0), tapees == [_nom(t0)], "tapees %s" % [tapees])
	await _demonter()


# --- Bureau : fenetre d'un dossier + boite a icones ---------------------------------

func _croix_fenetre(fenetre: Control, compteur: Array) -> Button:
	for b in fenetre.find_children("*", "Button", true, false):
		if (b as Button).pressed.is_connected(Callable(fenetre, "queue_free")):
			(b as Button).pressed.connect(func() -> void: compteur[0] += 1)
			return b
	return null


func _bureau() -> void:
	print("--- BUREAU (fenetres) ---")
	var bureau: Control = load("res://scenes/bureau.tscn").instantiate()
	bureau.hauteur_barre = bureau.hauteur_barre_pour(true)
	root.add_child(bureau)
	current_scene = bureau
	await _trames(4)
	_curseur = bureau.get("_curseur")
	_curseur.android = true
	_curseur.gamme = _curseur.gamme_pour(true)
	_curseur._ready()
	await _trames(2)
	# Fenetre d'un dossier, posee au milieu de l'ecran
	bureau.call("_ouvrir_fenetre", "souris", "Souris", Color(0.3, 0.5, 0.8))
	await _trames(3)
	var fenetres: Dictionary = bureau.get("_fenetres_ouvertes")
	var fenetre: Control = fenetres.get("souris")
	_verifier("F[dossier] fenetre ouverte", is_instance_valid(fenetre))
	if is_instance_valid(fenetre):
		fenetre.position = (_zone().size - fenetre.size) / 2.0
		await _trames(2)
		var compteur := [0]
		await _cas_croix("F[dossier]", _croix_fenetre(fenetre, compteur), compteur,
			func() -> bool: return is_instance_valid(fenetre) and not fenetre.is_queued_for_deletion())
	await _trames(3)
	# Boite a icones (bouton Menu)
	bureau.call("_basculer_menu")
	await _trames(3)
	var voile: Control = bureau.get("_menu")
	var boite: Control = null
	if voile != null:
		for n in voile.get_children():
			if n is PanelContainer:
				boite = n
	_verifier("F[boite] boite a icones ouverte", boite != null)
	if boite != null:
		var compteur := [0]
		await _cas_croix("F[boite]", _croix_fenetre(boite, compteur), compteur,
			func() -> bool: return bureau.get("_menu") != null)
	bureau.queue_free()
	await _trames(4)


func _derouler() -> void:
	print("=== PREUVE A2 — CLAVIERS ET CROIX AU DOIGT DU JOUEUR (Android) ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	PinConfig.ecrire_option("interface", "mode_tactile", true)
	await _croix_jeu("ballons", "res://scenes/ballons.tscn")
	await _croix_jeu("souris", "res://scenes/souris.tscn")
	await _croix_jeu("chasse", "res://scenes/chasse.tscn")
	await _croix_jeu("lettres", "res://scenes/lettres.tscn")
	await _lettres()
	await _mots()
	await _bureau()
	_fin()


func _fin() -> void:
	print("=== %s (%d echec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
