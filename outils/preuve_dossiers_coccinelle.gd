## PREUVE PIXEL des dossiers coccinelle « souris » et « clavier » (REQ_261007 v2).
## Monte le VRAI bureau (scenes/bureau.tscn) dans un SubViewport, rend de vrais pixels :
##   ① souris et clavier restent des DOSSIERS (_IconeDossier) habillés d'une image centrale ;
##   ② un dossier témoin sans image reste le dossier d'origine (pictogramme posé dessus) ;
##   ③ les icônes directes du bureau ne sont pas des dossiers (inchangées) ;
##   ④ un clic injecté sur chaque dossier ouvre sa fenêtre (lancement intact).
## Planche : les dossiers à 104 px (taille bureau) et en grand (312 px).
## Lancement (user:// ISOLÉ, fenêtre 1×1 sans focus) :
##   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --path . res://outils/preuve_dossiers_coccinelle.tscn
extends Node

const IconeBureau := preload("res://scripts/icone_bureau.gd")
const SORTIE := "/tmp/preuve_dossiers_coccinelle/"

var _echecs := 0


func _verifier(libelle: String, vrai: bool, detail: String = "") -> void:
	print("  %s %s%s" % ["ok   " if vrai else "ECHEC", libelle, (" — " + detail) if detail != "" else ""])
	if not vrai:
		_echecs += 1


func _trames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _vue(taille: Vector2i, fond: Color) -> SubViewport:
	var vue := SubViewport.new()
	vue.size = taille
	vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vue)
	var aplat := ColorRect.new()
	aplat.color = fond
	aplat.size = Vector2(taille)
	vue.add_child(aplat)
	return vue


func _capturer(vue: SubViewport, nom: String) -> Image:
	await RenderingServer.frame_post_draw
	var image := vue.get_texture().get_image()
	image.save_png(SORTIE + nom + ".png")
	return image


## Le dessin de dossier (_IconeDossier) porté par le bouton d'une icône, ou null.
func _dossier_de(icone: Node) -> Control:
	var btn: Control = icone.get("_btn")
	for enfant in btn.get_children():
		# le dessin de dossier a une couleur et pas d'id (le pictogramme a un id)
		if enfant.get("couleur") != null and enfant.get("id") == null:
			return enfant
	return null


func _clic(vue: SubViewport, ou: Vector2) -> void:
	for appui in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = appui
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT if appui else 0
		ev.position = ou
		ev.global_position = ou
		vue.push_input(ev, true)
		await _trames(2)


func _ready() -> void:
	var f := get_window()
	f.set_flag(Window.FLAG_NO_FOCUS, true)
	f.size = Vector2i(1, 1)
	DirAccess.make_dir_recursive_absolute(SORTIE)
	print("=== PREUVE DOSSIERS COCCINELLE ===")

	# ---- Vrai bureau ----
	var vue_bureau := _vue(Vector2i(1280, 720), Color.BLACK)
	var bureau: Control = load("res://scenes/bureau.tscn").instantiate()
	vue_bureau.add_child(bureau)
	await _trames(12)
	await _capturer(vue_bureau, "bureau")
	var icones := bureau.find_children("*", "VBoxContainer", true, false).filter(
		func(n: Node) -> bool: return n.get_script() == IconeBureau)
	var par_id := {}
	for ic in icones:
		var d := _dossier_de(ic)
		par_id[ic.id] = ic
		print("  icône %-14s dossier=%s  image_centre=%s" % [ic.id, ic.est_dossier,
			d != null and d.get("image_centre") != null])
	for id in ["souris", "clavier"]:
		var ic: Node = par_id.get(id)
		var d: Control = _dossier_de(ic) if ic else null
		_verifier("① %s = dossier habillé" % id, ic != null and ic.est_dossier and d != null
			and d.get("image_centre") != null, "")
	for id in par_id:
		if id not in ["souris", "clavier"]:
			_verifier("③ %s inchangé (icône directe, pas de dossier)" % id,
				not par_id[id].est_dossier and _dossier_de(par_id[id]) == null)

	# ---- Planche : 104 px (vraies icônes) + grand format ----
	var vue_planche := _vue(Vector2i(1000, 420), Color(0.30, 0.62, 0.30))
	var x := 20.0
	for spec in [["souris", "Souris"], ["clavier", "Clavier"], ["temoin", "Témoin"]]:
		var ic: VBoxContainer = IconeBureau.new()
		ic.id = spec[0]
		ic.nom = spec[1]
		ic.couleur = Color(0.20, 0.60, 0.90)
		ic.est_dossier = true
		ic.picto = "souris" if spec[0] == "temoin" else ""
		ic.position = Vector2(x, 20)
		vue_planche.add_child(ic)
		x += 160
		if spec[0] == "temoin":
			await _trames(2)
			var d := _dossier_de(ic)
			var btn: Control = ic.get("_btn")
			_verifier("② témoin sans image = dossier d'origine + pictogramme",
				d != null and d.get("image_centre") == null and btn.get_child_count() == 2,
				"%d enfants" % btn.get_child_count())
	x = 20.0
	for id in ["souris", "clavier"]:
		var grand: Control = IconeBureau._IconeDossier.new()
		grand.couleur = Color8(232, 37, 37)
		grand.set("image_centre", load("res://assets/icones/dossiers/%s.png" % id))
		grand.position = Vector2(500 + x, 40)
		grand.size = Vector2(220, 220)
		vue_planche.add_child(grand)
		x += 240
	await _trames(6)
	var planche := await _capturer(vue_planche, "planche")
	planche.get_region(Rect2i(20 + 23, 20, 104, 104)).save_png(SORTIE + "souris_104.png")
	planche.get_region(Rect2i(180 + 23, 20, 104, 104)).save_png(SORTIE + "clavier_104.png")
	planche.get_region(Rect2i(340 + 23, 20, 104, 104)).save_png(SORTIE + "temoin_104.png")

	# ---- ④ Lancement au clic ----
	for id in ["souris", "clavier"]:
		var ic: Node = par_id.get(id)
		if ic == null:
			continue
		var btn: Control = ic.get("_btn")
		await _clic(vue_bureau, btn.get_global_rect().get_center())
		await _trames(4)
		_verifier("④ clic sur %s : fenêtre ouverte" % id, bureau._fenetres_ouvertes.has(id))
	await _capturer(vue_bureau, "bureau_fenetres")

	print("=== FIN : %s ===" % ("TOUT VERT" if _echecs == 0 else "%d ECHEC(S)" % _echecs))
	get_tree().quit(0 if _echecs == 0 else 1)
