## PREUVE PIXEL — lisibilité du caractère des bulles de la chasse (REQ_261007_mots_sans_curseur_chasse, §D).
## Rend la VRAIE classe _BulleLettre de jeu_chasse.gd sur le VRAI fond prairie, dans un SubViewport
## 1024x768, aux 8 couleurs de lettre × 3 rangées de verdure. Pour chaque bulle, deux rendus :
## avec le caractère et SANS (lettre vide) → la différence = les pixels du caractère (masque).
## Mesure par bulle : luminance relative du caractère (cœur du masque) et du fond SOUS le caractère,
## puis contraste WCAG (Lmax+0,05)/(Lmin+0,05) — un contraste de LUMINANCE (lisible daltonien).
## Rejouer la même preuve sur l'origine (worktree 9927e7d) pour comparer avant / après.
## Lancer : DISPLAY=:0 Godot_v4.7.2 --path . --audio-driver Dummy res://outils/preuve_bulles_contraste.tscn
## Sortie : /tmp/preuve_bulles/<etiquette>.png + lignes « MESURE » ; code 0 (mesure seule, pas de seuil).
## Outil de preuve : non embarqué dans le jeu.
extends Node

const LARGEUR := 1024
const HAUTEUR := 768
const SORTIE := "/tmp/preuve_bulles/"
const Fond := preload("res://scripts/fond.gd")
# Une lettre par couleur : couleur = unicode % 8 (H=0, A=1 … G=7)
const LETTRES := ["H", "A", "B", "C", "D", "E", "F", "G"]
const RANGEES := [170.0, 400.0, 630.0]

var _vue: SubViewport
var _bulles := []


func _ready() -> void:
	var f := get_window()
	f.set_flag(Window.FLAG_NO_FOCUS, true)
	f.size = Vector2i(1, 1)
	f.position = Vector2i(0, 0)
	DirAccess.make_dir_recursive_absolute(SORTIE)
	_vue = SubViewport.new()
	_vue.size = Vector2i(LARGEUR, HAUTEUR)
	_vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vue)
	var ecran := Control.new()
	ecran.size = Vector2(LARGEUR, HAUTEUR)
	_vue.add_child(ecran)
	Fond.appliquer(ecran)
	var Bulle: GDScript = (load("res://scripts/clavier/jeu_chasse.gd") as GDScript).get_script_constant_map()["_BulleLettre"]
	var couleurs: Array = (load("res://scripts/clavier/jeu_chasse.gd") as GDScript).get_script_constant_map()["COULEURS_LETTRES"]
	for y in RANGEES:
		for i in LETTRES.size():
			var b: Node2D = Bulle.new()
			b.lettre = LETTRES[i]
			b.couleur = couleurs[LETTRES[i].unicode_at(0) % couleurs.size()]
			b.position = Vector2(64.0 + 128.0 * i, y)
			ecran.add_child(b)
			b.set_process(false)  # figée : ni montée ni balancement
			_bulles.append(b)
	await _trames(40)  # le tween d'apparition (0,4 s) est fini
	var avec := _vue.get_texture().get_image()
	avec.save_png(SORTIE + _etiquette() + ".png")
	for b in _bulles:
		b.lettre = ""
		b.queue_redraw()
	await _trames(4)
	var sans := _vue.get_texture().get_image()

	print("=== PREUVE CONTRASTE BULLES — ", _etiquette(), " ===")
	var mini := 99.0
	var somme := 0.0
	for k in _bulles.size():
		var b: Node2D = _bulles[k]
		var m := _mesurer(avec, sans, b.position, b.rayon)
		mini = minf(mini, m.contraste)
		somme += m.contraste
		print("MESURE %s rangee=%d lettre=%s L_lettre=%.3f L_fond=%.3f contraste=%.2f pixels=%d" % [
			_etiquette(), k / LETTRES.size(), LETTRES[k % LETTRES.size()], m.l_lettre, m.l_fond, m.contraste, m.n])
	print("SYNTHESE %s contraste_min=%.2f contraste_moyen=%.2f" % [_etiquette(), mini, somme / _bulles.size()])
	get_tree().quit(0)


func _etiquette() -> String:
	var e := OS.get_environment("ETIQUETTE")
	return e if e != "" else "bulles"


func _trames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


static func _lin(c: float) -> float:
	return c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)


static func _lum(c: Color) -> float:
	return 0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b)


## Masque = pixels nettement changés par le caractère ; cœur = les plus changés (moitié haute).
func _mesurer(avec: Image, sans: Image, centre: Vector2, rayon: float) -> Dictionary:
	var ecarts := []
	var r := int(rayon)
	for y in range(int(centre.y) - r, int(centre.y) + r):
		for x in range(int(centre.x) - r, int(centre.x) + r):
			var a := avec.get_pixel(x, y)
			var s := sans.get_pixel(x, y)
			var d := absf(a.r - s.r) + absf(a.g - s.g) + absf(a.b - s.b)
			if d > 0.15:
				ecarts.append([d, _lum(a), _lum(s)])
	if ecarts.is_empty():
		return {"l_lettre": 0.0, "l_fond": 0.0, "contraste": 0.0, "n": 0}
	ecarts.sort_custom(func(p, q): return p[0] > q[0])
	var coeur := ecarts.slice(0, maxi(1, ecarts.size() / 2))
	var l_lettre := 0.0
	var l_fond := 0.0
	for e in coeur:
		l_lettre += e[1]
		l_fond += e[2]
	l_lettre /= coeur.size()
	l_fond /= coeur.size()
	var contraste := (maxf(l_lettre, l_fond) + 0.05) / (minf(l_lettre, l_fond) + 0.05)
	return {"l_lettre": l_lettre, "l_fond": l_fond, "contraste": contraste, "n": ecarts.size()}
