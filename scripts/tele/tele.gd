## Ma télé 📺 — la télévision à liste fermée (spec : DOCS/specs/spec-tele.md).
## Un MUR de grosses vignettes choisies par l'adulte — toujours les mêmes,
## toujours à la même place. Pas de recherche, pas de suggestion, pas de flux :
## l'enfant choisit, regarde, et revient au mur. Une télé, pas un puits.
##
## Toucher une vignette → la vidéo joue dans une FENÊTRE façon OS (déplaçable,
## croix, bouton agrandir → plein écran) posée par-dessus le mur : gros bouton
## pause/lecture, et à la fin de la vidéo la fenêtre se ferme toute seule —
## retour au mur (pas d'enchaînement automatique : l'enfant re-choisit).
##
## Écran calme (comme le classeur) : pas de traînée ni d'effets de clic —
## seul le curseur OS accompagne. Sortie : croix (haut droit) ou Échap.
extends Control

const Fond := preload("res://scripts/fond.gd")
const Lang := preload("res://scripts/lang.gd")
const CurseurOS := preload("res://scripts/effets/curseur.gd")
const Videotheque := preload("res://scripts/tele/videotheque.gd")
const PinConfig := preload("res://scripts/pin_config.gd")
const CHEMIN_BUREAU := "res://scenes/bureau.tscn"
const Lancement := preload("res://scripts/lancement.gd")

## Le clip « CoccOs World », livré avec CoccOs (res://, jamais copié dans
## user://tele/) : toujours en tête du mur, même vidéothèque vide. Les vidéos de
## l'adulte s'ajoutent à la suite.
const VIDEO_PAR_DEFAUT := {
	"nom": "CoccOs World",
	"chemin": "res://assets/tele/coccos_world.ogv",
	"vignette": preload("res://assets/tele/coccos_world.png"),
}

const COULEUR_BOUTON_QUITTER := Color(0.85, 0.35, 0.30)
const COULEUR_TELE := Color(0.45, 0.40, 0.85)

var _curseur: Node2D
var _lecteur: Control = null


func _ready() -> void:
	Fond.appliquer(self)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_creer_mur()
	_creer_bouton_quitter()

	var couche_curseur := CanvasLayer.new()
	couche_curseur.layer = 10
	add_child(couche_curseur)
	_curseur = CurseurOS.new()
	couche_curseur.add_child(_curseur)
	_curseur.position = get_viewport().get_mouse_position()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _lecteur != null:
			_fermer_lecteur()
		else:
			_quitter()
		return
	if event is InputEventMouseMotion:
		_curseur.position = event.position
	elif event is InputEventMouseButton and event.pressed:
		_curseur.pulser()


# --- Le mur : la liste fermée en grosses vignettes -------------------------------

func _creer_mur() -> void:
	var defilement := ScrollContainer.new()
	defilement.set_anchors_preset(Control.PRESET_FULL_RECT)
	defilement.offset_top = 100.0
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defilement.get_v_scroll_bar().custom_minimum_size = Vector2(14, 0)
	add_child(defilement)

	var centre := CenterContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defilement.add_child(centre)

	var colonne := VBoxContainer.new()
	colonne.alignment = BoxContainer.ALIGNMENT_CENTER
	colonne.add_theme_constant_override("separation", 26)
	centre.add_child(colonne)

	var titre := Label.new()
	titre.text = Lang.t("bureau_app_tele")
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 52)
	titre.add_theme_color_override("font_color", Color.WHITE)
	titre.add_theme_constant_override("outline_size", 10)
	titre.add_theme_color_override("font_outline_color", Color(0.10, 0.20, 0.15, 0.85))
	colonne.add_child(titre)

	var videos: Array = [VIDEO_PAR_DEFAUT] + Videotheque.lister()
	if videos.is_empty():
		var vide := Label.new()
		vide.text = Lang.t("tele_mur_vide")
		vide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vide.add_theme_font_size_override("font_size", 26)
		vide.add_theme_color_override("font_color", Color.WHITE)
		vide.add_theme_constant_override("outline_size", 8)
		vide.add_theme_color_override("font_outline_color", Color(0.10, 0.20, 0.15, 0.85))
		colonne.add_child(vide)
		return

	var grille := GridContainer.new()
	grille.columns = 4
	grille.add_theme_constant_override("h_separation", 22)
	grille.add_theme_constant_override("v_separation", 22)
	colonne.add_child(grille)
	for video in videos:
		grille.add_child(_creer_vignette(video))


## Vignette du mur : l'image de la vidéo + son titre — même esprit que le classeur.
func _creer_vignette(video: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(260, 200)
	btn.focus_mode = Control.FOCUS_NONE
	for etat in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.99, 0.98, 0.94, 0.96)
		style.set_corner_radius_all(18)
		style.set_border_width_all(4)
		style.border_color = Color(0.95, 0.72, 0.15) if etat == "hover" else Color(0.25, 0.30, 0.38)
		btn.add_theme_stylebox_override(etat, style)

	if video["vignette"] != null:
		var image := TextureRect.new()
		image.texture = video["vignette"]
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.position = Vector2(10, 8)
		image.size = Vector2(240, 138)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(image)
	else:
		var ecran := _IconeTele.new()
		ecran.position = Vector2(10, 8)
		ecran.size = Vector2(240, 138)
		ecran.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(ecran)

	var etiquette := Label.new()
	etiquette.text = video["nom"]
	etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiquette.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiquette.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiquette.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	etiquette.clip_contents = true
	etiquette.add_theme_font_size_override("font_size", 20)
	etiquette.add_theme_color_override("font_color", Color(0.12, 0.16, 0.24))
	etiquette.position = Vector2(8, 148)
	etiquette.size = Vector2(244, 48)
	etiquette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(etiquette)

	btn.pressed.connect(_ouvrir_video.bind(video))
	return btn


# --- Le lecteur : une fenêtre façon OS par-dessus le mur --------------------------

func _ouvrir_video(video: Dictionary) -> void:
	if _lecteur != null:
		return  # une seule télé à la fois
	_lecteur = _LecteurVideo.new()
	_lecteur.titre = video["nom"]
	_lecteur.chemin = video["chemin"]
	_lecteur.fermee.connect(_fermer_lecteur)
	add_child(_lecteur)  # le curseur reste au-dessus (CanvasLayer 10)


func _fermer_lecteur() -> void:
	if _lecteur != null:
		_lecteur.queue_free()
		_lecteur = null


# --- Sortie ------------------------------------------------------------------------

func _creer_bouton_quitter() -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(72, 72)
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.position = Vector2(-88, 16)
	btn.focus_mode = Control.FOCUS_NONE
	for etat in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = COULEUR_BOUTON_QUITTER
		if etat == "hover":
			style.bg_color = COULEUR_BOUTON_QUITTER.lightened(0.15)
		elif etat == "pressed":
			style.bg_color = COULEUR_BOUTON_QUITTER.darkened(0.15)
		style.set_corner_radius_all(36)
		btn.add_theme_stylebox_override(etat, style)
	var icone := _IconeCroixFermer.new()
	icone.set_anchors_preset(Control.PRESET_FULL_RECT)
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icone)
	btn.pressed.connect(_quitter)
	add_child(btn)


func _quitter() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# En lancement direct (--app), la croix quitte CoccOs au lieu du retour bureau
	if Lancement.app_directe() == "" and ResourceLoader.exists(CHEMIN_BUREAU):
		get_tree().change_scene_to_file(CHEMIN_BUREAU)
	else:
		get_tree().quit()


# --- La fenêtre-télé : barre de titre, agrandir, croix, vidéo, pause --------------

class _LecteurVideo extends PanelContainer:
	signal fermee

	const TAILLE_FENETRE := Vector2(880, 620)

	var titre := ""
	var chemin := ""

	var _video: VideoStreamPlayer
	var _btn_pause: Button
	var _icone_pause: Control
	var _plein_ecran := false
	var _glisse := false

	func _ready() -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.10, 0.10, 0.14, 0.99)
		style.set_corner_radius_all(16)
		style.shadow_size = 14
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
		add_theme_stylebox_override("panel", style)
		_poser_fenetre()

		var colonne := VBoxContainer.new()
		colonne.add_theme_constant_override("separation", 0)
		add_child(colonne)

		# --- Barre de titre (déplaçable) : titre + agrandir + croix ---
		var barre := PanelContainer.new()
		var style_barre := StyleBoxFlat.new()
		style_barre.bg_color = Color(0.45, 0.40, 0.85)
		style_barre.corner_radius_top_left = 16
		style_barre.corner_radius_top_right = 16
		barre.add_theme_stylebox_override("panel", style_barre)
		barre.gui_input.connect(_sur_saisie_barre)
		colonne.add_child(barre)

		var marge_barre := MarginContainer.new()
		for cote in ["margin_left", "margin_right"]:
			marge_barre.add_theme_constant_override(cote, 14)
		for cote in ["margin_top", "margin_bottom"]:
			marge_barre.add_theme_constant_override(cote, 8)
		barre.add_child(marge_barre)
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 12)
		marge_barre.add_child(ligne)

		var label := Label.new()
		label.text = titre
		label.add_theme_font_size_override("font_size", 26)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ligne.add_child(label)

		var btn_agrandir := _bouton_barre(Color(0.25, 0.55, 0.40))
		var icone_agrandir := _IconeAgrandir.new()
		icone_agrandir.set_anchors_preset(Control.PRESET_FULL_RECT)
		icone_agrandir.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_agrandir.add_child(icone_agrandir)
		btn_agrandir.pressed.connect(_basculer_plein_ecran)
		ligne.add_child(btn_agrandir)

		var btn_fermer := _bouton_barre(Color(0.85, 0.30, 0.25))
		var croix := _IconeCroix.new()
		croix.set_anchors_preset(Control.PRESET_FULL_RECT)
		croix.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_fermer.add_child(croix)
		btn_fermer.pressed.connect(func() -> void: fermee.emit())
		ligne.add_child(btn_fermer)

		# --- L'écran ---
		_video = VideoStreamPlayer.new()
		var flux := VideoStreamTheora.new()
		flux.file = chemin
		_video.stream = flux
		_video.expand = true
		_video.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_video.finished.connect(func() -> void: fermee.emit())  # fin → retour au mur
		colonne.add_child(_video)

		# --- La barre de commandes : un seul gros bouton pause/lecture ---
		var commandes := CenterContainer.new()
		commandes.custom_minimum_size = Vector2(0, 86)
		colonne.add_child(commandes)
		_btn_pause = Button.new()
		_btn_pause.custom_minimum_size = Vector2(120, 64)
		_btn_pause.focus_mode = Control.FOCUS_NONE
		for etat in ["normal", "hover", "pressed", "focus"]:
			var style_pause := StyleBoxFlat.new()
			style_pause.bg_color = Color(0.45, 0.40, 0.85) if etat != "hover" \
					else Color(0.45, 0.40, 0.85).lightened(0.15)
			style_pause.set_corner_radius_all(32)
			_btn_pause.add_theme_stylebox_override(etat, style_pause)
		_icone_pause = _IconePauseLecture.new()
		_icone_pause.proprietaire = self
		_icone_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
		_icone_pause.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_btn_pause.add_child(_icone_pause)
		_btn_pause.pressed.connect(_basculer_pause)
		commandes.add_child(_btn_pause)

		_video.play()

	func _basculer_pause() -> void:
		_video.paused = not _video.paused
		_icone_pause.queue_redraw()

	func _basculer_plein_ecran() -> void:
		_plein_ecran = not _plein_ecran
		_poser_fenetre()

	func _poser_fenetre() -> void:
		if _plein_ecran:
			set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		else:
			set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			size = TAILLE_FENETRE
			if is_inside_tree():
				position = (get_parent_area_size() - TAILLE_FENETRE) / 2.0

	## Déplacement par la barre de titre (hors plein écran).
	func _sur_saisie_barre(event: InputEvent) -> void:
		if _plein_ecran:
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			_glisse = event.pressed
		elif event is InputEventMouseMotion and _glisse:
			position += event.relative
			var zone: Vector2 = get_parent_area_size()
			position.x = clampf(position.x, 0.0, maxf(0.0, zone.x - size.x))
			position.y = clampf(position.y, 0.0, maxf(0.0, zone.y - size.y))

	func _bouton_barre(couleur: Color) -> Button:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(44, 44)
		btn.focus_mode = Control.FOCUS_NONE
		for etat in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = couleur if etat != "hover" else couleur.lightened(0.15)
			style.set_corner_radius_all(22)
			btn.add_theme_stylebox_override(etat, style)
		return btn


## Icônes dessinées (aucun émoji : la police web ne les a pas).

class _IconePauseLecture extends Control:
	var proprietaire: Control = null
	func _draw() -> void:
		var c := size / 2.0
		var u := minf(size.x, size.y) / 2.0
		var en_pause: bool = proprietaire != null and proprietaire._video != null \
				and proprietaire._video.paused
		if en_pause:
			# Triangle « lecture »
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-u * 0.35, -u * 0.5), c + Vector2(u * 0.55, 0.0),
				c + Vector2(-u * 0.35, u * 0.5),
			]), Color.WHITE)
		else:
			# Deux barres « pause »
			draw_rect(Rect2(c + Vector2(-u * 0.45, -u * 0.5), Vector2(u * 0.32, u * 1.0)), Color.WHITE)
			draw_rect(Rect2(c + Vector2(u * 0.13, -u * 0.5), Vector2(u * 0.32, u * 1.0)), Color.WHITE)


class _IconeAgrandir extends Control:
	func _draw() -> void:
		var c := size / 2.0
		var u := minf(size.x, size.y) * 0.24
		draw_rect(Rect2(c - Vector2(u, u), Vector2(u * 2.0, u * 2.0)), Color.WHITE, false, 4.0)


class _IconeCroix extends Control:
	func _draw() -> void:
		var c := size / 2.0
		var u := minf(size.x, size.y) * 0.22
		draw_line(c + Vector2(-u, -u), c + Vector2(u, u), Color.WHITE, 5.0)
		draw_line(c + Vector2(-u, u), c + Vector2(u, -u), Color.WHITE, 5.0)


class _IconeTele extends Control:
	func _draw() -> void:
		var c := size / 2.0
		var u := minf(size.x, size.y) / 2.0
		var ecran := StyleBoxFlat.new()
		ecran.bg_color = Color(0.45, 0.40, 0.85)
		ecran.set_corner_radius_all(int(u * 0.2))
		ecran.draw(get_canvas_item(), Rect2(c - Vector2(u * 1.1, u * 0.75), Vector2(u * 2.2, u * 1.5)))
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(-u * 0.25, -u * 0.35), c + Vector2(u * 0.4, 0.0),
			c + Vector2(-u * 0.25, u * 0.35),
		]), Color.WHITE)


## Croix blanche du bouton Quitter — « fermer », le geste universel des fenêtres
## (préférence Freddy 2026-07-09, retour du test d'Isabella : plus parlant que la maison).
class _IconeCroixFermer extends Control:
	func _draw() -> void:
		var centre := size / 2.0
		var u := minf(size.x, size.y) / 2.0
		var bras := u * 0.42
		var epaisseur := u * 0.24
		draw_line(centre + Vector2(-bras, -bras), centre + Vector2(bras, bras), Color.WHITE, epaisseur)
		draw_line(centre + Vector2(-bras, bras), centre + Vector2(bras, -bras), Color.WHITE, epaisseur)
		for coin: Vector2 in [Vector2(-bras, -bras), Vector2(bras, -bras), Vector2(-bras, bras), Vector2(bras, bras)]:
			draw_circle(centre + coin, epaisseur / 2.0, Color.WHITE)


## Bouton Retour d'Android (mode bureau/launcher) : même geste que la croix.
func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_WM_GO_BACK_REQUEST:
		_quitter()
