# Preuve du CLAVIER REMONTE (REQ_261007 android_clavier_remonte, decision Fabrice : « remonter le
# clavier, suffisamment pour qu'on puisse atteindre les lettres ; pas de zoom de bord » ).
# Monte le VRAI jeu Lettres en mode tactile (user:// isole), curseur a la gamme Android (x2), sur les
# 4 cibles (fenetre redimensionnee : le headless l'accepte) et les 3 tailles. Mots et Chasse ne sont plus
# remontes (decision Fabrice 07-10 : Mots revient a l'origine, Chasse n'a pas de clavier) — leur preuve :
# outils/preuve_chasse_mots_android.gd ; ils restent dans la signature desktop D.
#   R  PORTEE : chaque touche ENTIERE est visable par la pointe avec le doigt a GARDE_DOIGT px
#      au-dessus du bord bas (on ne demande jamais le dernier pixel : bande des gestes Android) ;
#   K  rangee du bas TAPEE A LA POINTE (doigt moteur) : W, N et ⌫ — la touche tapee est celle de
#      la pointe, le doigt est plus bas (sur la bande de remontee ou une autre touche) ;
#   E  ⌫ efface reellement (Lettres : mot raccourci) ;
#   G  mise en page : rien ne deborde de l'ecran, rien ne chevauche le clavier ni la croix ;
#   D  desktop (mode tactile decoche) : pas de clavier, signature de mise en page imprimee
#      (a comparer a la meme preuve rejouee sur le commit d'origine).
# Lancement :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_clavier_remonte.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const PinConfig := preload("res://scripts/pin_config.gd")
const Doigt := preload("res://outils/doigt_moteur.gd")

const ANDROID := 2.0  # AGRANDI_TAILLE_ANDROID des curseur.gd
const GARDE_DOIGT := 12.0
## Cibles responsive (taille de fenetre → viewport 1280x720 « expand »)
const CIBLES := {
	"projecteur 4:3": Vector2i(1024, 768),
	"portable 16:9": Vector2i(1920, 1080),
	"Android 20:9": Vector2i(2400, 1080),
	"iOS 19,5:9": Vector2i(2532, 1170),
}
const JEUX := {
	"lettres": "res://scenes/lettres.tscn",
}
## Desktop : les trois jeux du dossier clavier (signature de mise en page inchangee)
const JEUX_DESKTOP := {
	"lettres": "res://scenes/lettres.tscn",
	"mots": "res://scenes/mots.tscn",
	"chasse": "res://scenes/chasse.tscn",
}

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


func _fenetre(taille: Vector2i) -> void:
	root.size = taille
	await _trames(2)
	root.size = taille  # la 1re demande peut etre ignoree en headless
	await _trames(2)


func _monter(chemin: String, android: bool) -> void:
	_jeu = load(chemin).instantiate()
	root.add_child(_jeu)
	current_scene = _jeu
	await _trames(6)
	_curseur = _jeu.get("_curseur")
	if android:
		_curseur.gamme = ANDROID
		_curseur.set("_echelle_base", float(_curseur.get("_echelle_base")) * ANDROID)
	await _trames(4)  # le clavier suit la taille du curseur (_process) puis la mise en page


func _demonter() -> void:
	if is_instance_valid(_jeu):
		_jeu.queue_free()
	await _trames(4)


func _touches() -> Array:
	var clavier: Control = _jeu.get("_clavier")
	return [] if clavier == null else clavier.find_children("*", "Button", true, false)


func _touche(texte: String) -> Button:
	for t in _touches():
		if (t as Button).text == texte:
			return t
	return null


func _touche_sous(p: Vector2) -> Button:
	for t in _touches():
		if (t as Button).get_global_rect().has_point(p):
			return t
	return null


func _tap(d: Vector2) -> void:
	Doigt.toucher(root, d, true)
	await _trames(2)
	Doigt.toucher(root, d, false)
	await _trames(3)


func _rect(n: Control) -> Rect2:
	return n.get_global_rect()


## R : chaque touche entiere sous la pointe la plus basse permise.
func _portee(nom: String) -> void:
	var z := _zone()
	var bas_max: float = _curseur.pointe_pour_doigt(Vector2(z.get_center().x, z.end.y - GARDE_DOIGT), z).y
	var pire := INF
	var pire_touche := ""
	for t in _touches():
		var marge: float = bas_max - _rect(t).end.y
		if marge < pire:
			pire = marge
			pire_touche = (t as Button).text if (t as Button).text != "" else "⌫"
	var clavier: Control = _jeu.get("_clavier")
	_verifier("R[%s] toutes les touches ENTIERES a portee de la pointe (doigt a %d px du bas)" % [nom, int(GARDE_DOIGT)],
		pire >= 0.0, "pointe la plus basse y=%.0f, pire touche « %s » (marge %.1f px) ; remontee %.0f px, decalage %.1f px" \
			% [bas_max, pire_touche, pire, float(clavier.get("remontee")), -float(_curseur.decalage_doigt().y)])


## K : la touche `texte` de la rangee du bas, tapee par la pointe (doigt plus bas).
func _taper_a_la_pointe(nom: String, texte: String, tapees: Array) -> bool:
	var t := _touche(texte)
	var cible := _rect(t).get_center()
	var d := Doigt.doigt_pour_pointe(_curseur, cible, _zone())
	var pointe: Vector2 = _curseur.pointe_pour_doigt(d, _zone())
	var sous_doigt := _touche_sous(d)
	var libelle := "« %s »" % (texte if texte != "" else "⌫")
	var mise_en_place: bool = pointe.distance_to(cible) < 1.0 and _zone().has_point(d) and sous_doigt != t
	_verifier("K[%s] %s : pointe dessus, doigt %.0f px plus bas, sur %s" % [nom, libelle, d.y - pointe.y,
			"la bande de remontee" if sous_doigt == null else "« %s »" % sous_doigt.text],
		mise_en_place, "doigt %s, pointe %s, cible %s" % [d, pointe, cible])
	tapees.clear()
	await _tap(d)
	_verifier("K[%s] %s TAPEE a la pointe" % [nom, libelle], tapees == [texte], "tapees %s" % [tapees])
	return tapees == [texte]


func _espionner() -> Array:
	var tapees := []
	for t in _touches():
		(t as Button).pressed.connect(func() -> void: tapees.append((t as Button).text))
	return tapees


## G : rien hors ecran, rien sur le clavier, rien sur la croix.
func _mise_en_page(nom: String, elements: Dictionary) -> void:
	var z := _zone()
	var clavier: Rect2 = _rect(_jeu.get("_clavier"))
	var croix: Rect2 = _rect(_croix())
	var ok := true
	var detail := []
	if not (clavier.end.y <= z.end.y + 0.5 and is_equal_approx(clavier.size.x, z.size.x)):
		ok = false
		detail.append("clavier %s" % clavier)
	for cle in elements:
		var r: Rect2 = elements[cle]
		if not z.encloses(r):
			ok = false
			detail.append("%s DEBORDE %s" % [cle, r])
		if r.end.y > clavier.position.y + 0.5:
			ok = false
			detail.append("%s SUR le clavier (%.0f > %.0f)" % [cle, r.end.y, clavier.position.y])
		if r.intersects(croix):
			ok = false
			detail.append("%s SUR la croix %s" % [cle, croix])
	var resume := []
	for cle in elements:
		var r: Rect2 = elements[cle]
		resume.append("%s y%.0f→%.0f" % [cle, r.position.y, r.end.y])
	_verifier("G[%s] mise en page : %s | clavier y%.0f→%.0f" % [nom, ", ".join(resume), clavier.position.y, clavier.end.y],
		ok, "; ".join(detail))


func _croix() -> Button:
	for b in _jeu.get_children():
		if b is Button:
			return b
	return null


# --- Par jeu ------------------------------------------------------------------------

func _elements_lettres() -> Dictionary:
	var bulle: Control = _jeu.get("_bulle")
	var label_mot: Label = _jeu.get("_label_mot")
	var ligne: Control = label_mot.get_parent().get_parent()  # tableau → ligne_tableau
	var els := {"bulle": _rect(bulle)}
	var lettre: Label = _jeu.get("_label_lettre")
	var ecart: float = _rect(lettre).get_center().distance_to(_rect(bulle).get_center())
	_verifier("G[lettres] la grande lettre reste CENTREE dans la bulle (%.0f px de cote, police %d)" \
			% [_rect(bulle).size.y, lettre.get_theme_font_size("font_size")], ecart < 1.0, "ecart %.1f px" % ecart)
	var i := 0
	for c in ligne.get_children():
		els["tableau" if c == label_mot.get_parent() else "bouton%d" % i] = _rect(c)
		i += 1
	return els


func _jouer(nom: String, cible: String) -> void:
	var etiquette := "%s · %s" % [nom, cible]
	_portee(etiquette)
	var els: Dictionary = call("_elements_" + nom)
	_mise_en_page(etiquette, els)


func _bas_de_clavier(nom: String) -> void:
	var tapees := _espionner()
	if nom == "lettres":
		await _taper_a_la_pointe(nom, "W", tapees)
		await _trames(2)
		await _taper_a_la_pointe(nom, "N", tapees)
		await _trames(2)
		var avant := String(_jeu.get("_mot"))
		await _taper_a_la_pointe(nom, "", tapees)
		await _trames(2)
		var apres := String(_jeu.get("_mot"))
		_verifier("E[lettres] ⌫ a la pointe EFFACE (« %s » → « %s »)" % [avant, apres],
			avant == "WN" and apres == "W")


func _derouler() -> void:
	print("=== PREUVE CLAVIER REMONTE — Lettres (doigt Android) ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	PinConfig.ecrire_option("interface", "mode_tactile", true)
	if OS.get_environment("SEULEMENT_DESKTOP") == "":
		await _tactile()
	await _desktop()
	_fin()


func _tactile() -> void:
	# 1. Les 4 cibles, taille « moyen » : portee + mise en page
	for cible in CIBLES:
		await _fenetre(CIBLES[cible])
		print("--- %s : fenetre %s → viewport %s ---" % [cible, CIBLES[cible], _zone().size])
		for nom in JEUX:
			await _monter(JEUX[nom], true)
			_jouer(nom, cible)
			await _demonter()
	# 2. Rangee du bas tapee a la pointe (Android 20:9)
	await _fenetre(CIBLES["Android 20:9"])
	print("--- rangee du bas TAPEE a la pointe (Android 20:9, « moyen ») ---")
	for nom in JEUX:
		await _monter(JEUX[nom], true)
		await _bas_de_clavier(nom)
		await _demonter()
	# 3. Les tailles « petit » et « grand » (le decalage suit la taille) sur la cible la plus basse
	for taille in ["petit", "grand"]:
		PinConfig.ecrire_option("souris", "taille_curseur", taille)
		for cible in ["portable 16:9", "Android 20:9"]:
			await _fenetre(CIBLES[cible])
			print("--- taille « %s », %s ---" % [taille, cible])
			for nom in JEUX:
				await _monter(JEUX[nom], true)
				_jouer(nom, "%s %s" % [cible, taille])
				await _demonter()
	PinConfig.ecrire_option("souris", "taille_curseur", "moyen")


func _desktop() -> void:
	# 4. Desktop (mode tactile decoche) : signature de mise en page
	PinConfig.ecrire_option("interface", "mode_tactile", false)
	await _fenetre(CIBLES["portable 16:9"])
	print("--- desktop (mode tactile decoche, 16:9) ---")
	for nom in JEUX_DESKTOP:
		seed(7)  # le mot tire par Mots fixe le nombre de tuiles
		await _monter(JEUX_DESKTOP[nom], false)
		_verifier("D[%s] desktop : pas de clavier dessine" % nom, _jeu.get("_clavier") == null)
		var sig := []
		for c in _jeu.find_children("*", "Control", true, false):
			if (c as Control).is_visible_in_tree():
				sig.append("%s%s" % [(c as Control).get_class(), _rect(c)])
		print("  SIGNATURE[%s] %d controles, empreinte %s" % [nom, sig.size(), str(sig).md5_text()])
		await _demonter()


func _fin() -> void:
	print("=== %s (%d echec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)
