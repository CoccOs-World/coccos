## Icône du bureau enfant : bouton carré arrondi coloré avec pictogramme,
## et libellé blanc en dessous — comme une icône de vrai bureau d'ordinateur.
## Les catégories (`est_dossier`) prennent une forme de dossier à onglet,
## avec le pictogramme posé sur le corps du dossier.
## Un simple clic lance l'application (adapté aux enfants : pas de double-clic).
## Sur le bureau (`deplacable`), clic gauche MAINTENU + déplacement au-delà de
## SEUIL_GLISSE : l'icône se soulève, suit la souris et se pose au relâché
## (signal `deplacee`) — sans lancer l'application.
## Rangement : pendant le vol, `survol` dit où passe la souris (le bureau signale
## le dossier visé) ; au relâché, `lachee` dit où elle a été lâchée. Dans une
## fenêtre-dossier (`rangeable`), le jeu se soulève de la même façon et peut
## être lâché HORS de la fenêtre pour le ressortir sur le bureau.
extends VBoxContainer

signal lancee(id: String)
signal deplacee(id: String, position: Vector2)
signal survol(id: String, point: Vector2)
signal lachee(id: String, point: Vector2, coin: Vector2)

const SEUIL_GLISSE := 10.0  # px : en deçà, c'est un clic (mains tremblantes)
const ECHELLE_SOULEVEE := 1.12  # l'icône « soulevée » grossit…
const OPACITE_SOULEVEE := 0.85  # … et s'éclaircit un peu (pas la couleur seule)
const ECHELLE_CIBLE := 1.15  # dossier visé par un glissé : il grossit ET s'éclaircit

const UIStyle := preload("res://scripts/ui_style.gd")
const Pictogramme := preload("res://scripts/pictogramme.gd")

var id := ""
var nom := ""
var couleur := Color(0.3, 0.5, 0.8)
var est_dossier := false  # true = catégorie : dessinée comme un dossier à onglet
var picto := ""  # pictogramme à dessiner si différent de l'id (applis externes)
var chemin_image := ""  # PNG hors ressources (user:// — icônes du téléphone)

var deplacable := false  # bureau seulement (pas les fenêtres ni la boîte à icônes)
var limite_basse := 0.0  # hauteur réservée en bas (barre des tâches)
var rangeable := false  # jeu dans une fenêtre-dossier : glissé = le ressortir

var _btn: Button
var _appui := false  # clic gauche maintenu sur le bouton
var _origine := Vector2.ZERO  # point d'appui (coordonnées du parent)
var _prise := Vector2.ZERO  # écart curseur ↔ coin de l'icône au moment de l'appui
var _glisse := false  # le maintien est devenu un déplacement
var _a_glisse := false  # le dernier relâché terminait un déplacement : pas de lancement
var return_apres_image := false  # une icône-image remplace le pictogramme
var _dossier: Control = null  # le dessin du dossier (catégorie) — éclairci quand visé
var _visee := false  # dossier actuellement visé par un jeu en vol


func _ready() -> void:
	custom_minimum_size = Vector2(150, 0)
	add_theme_constant_override("separation", 6)

	# Bouton carré centré (le pictogramme est un enfant plein cadre avec marge)
	var centre := CenterContainer.new()
	add_child(centre)
	_btn = Button.new()
	_btn.custom_minimum_size = Vector2(104, 104)
	centre.add_child(_btn)

	var picto_ctrl: Control = Pictogramme.new()
	picto_ctrl.id = picto if picto != "" else id
	picto_ctrl.couleur_creux = couleur.darkened(0.25)
	picto_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)

	if est_dossier:
		# Bouton transparent (le dossier fait le visuel), focus = bordure seule
		var vide := StyleBoxEmpty.new()
		for etat in ["normal", "hover", "pressed"]:
			_btn.add_theme_stylebox_override(etat, vide)
		var focus := UIStyle.creer_style(Color(0, 0, 0, 0), 24, true)
		focus.draw_center = false
		_btn.add_theme_stylebox_override("focus", focus)

		var dossier := _IconeDossier.new()
		dossier.couleur = couleur
		dossier.set_anchors_preset(Control.PRESET_FULL_RECT)
		dossier.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_btn.add_child(dossier)
		_dossier = dossier
		# Survol : le dossier s'éclaircit (retour visuel du bouton transparent)
		_btn.mouse_entered.connect(func() -> void:
			dossier.couleur = couleur.lightened(0.15)
			dossier.queue_redraw())
		_btn.mouse_exited.connect(func() -> void:
			if not _visee:
				dossier.couleur = couleur
				dossier.queue_redraw())

		# Pictogramme plus petit, posé sur le corps du dossier
		picto_ctrl.offset_left = 26
		picto_ctrl.offset_top = 38
		picto_ctrl.offset_right = -26
		picto_ctrl.offset_bottom = -12
	elif chemin_image != "" and FileAccess.file_exists(chemin_image):
		# Icône du téléphone (PNG déposé par la logithèque Android) : l'icône
		# système posée sur la plaque colorée, comme les autres icônes
		UIStyle.styliser(_btn, couleur, 24)
		var image_tel := Image.load_from_file(chemin_image)
		if image_tel != null and not image_tel.is_empty():
			var affichage := TextureRect.new()
			affichage.texture = ImageTexture.create_from_image(image_tel)
			affichage.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			affichage.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			affichage.set_anchors_preset(Control.PRESET_FULL_RECT)
			affichage.offset_left = 14
			affichage.offset_top = 14
			affichage.offset_right = -14
			affichage.offset_bottom = -14
			affichage.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_btn.add_child(affichage)
			return_apres_image = true
		else:
			picto_ctrl.offset_left = 16
			picto_ctrl.offset_top = 16
			picto_ctrl.offset_right = -16
			picto_ctrl.offset_bottom = -16
	elif ResourceLoader.exists("res://assets/icones/%s.png" % (picto if picto != "" else id)):
		# Icône-image (plaque « livrée coccinelle » de Freddy) : elle EST le
		# bouton — fond transparent, l'image plein cadre, survol par éclat
		var vide := StyleBoxEmpty.new()
		for etat in ["normal", "hover", "pressed"]:
			_btn.add_theme_stylebox_override(etat, vide)
		var focus := UIStyle.creer_style(Color(0, 0, 0, 0), 24, true)
		focus.draw_center = false
		_btn.add_theme_stylebox_override("focus", focus)
		var image := TextureRect.new()
		image.texture = load("res://assets/icones/%s.png" % (picto if picto != "" else id))
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.set_anchors_preset(Control.PRESET_FULL_RECT)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_btn.add_child(image)
		_btn.mouse_entered.connect(func() -> void: image.modulate = Color(1.12, 1.12, 1.12))
		_btn.mouse_exited.connect(func() -> void: image.modulate = Color.WHITE)
		return_apres_image = true
	else:
		UIStyle.styliser(_btn, couleur, 24)
		picto_ctrl.offset_left = 16
		picto_ctrl.offset_top = 16
		picto_ctrl.offset_right = -16
		picto_ctrl.offset_bottom = -16
	if not return_apres_image:
		_btn.add_child(picto_ctrl)

	# Libellé sous l'icône, blanc à contour sombre (lisible sur la prairie)
	var libelle := Label.new()
	libelle.text = nom
	libelle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	libelle.add_theme_font_size_override("font_size", 24)
	libelle.add_theme_color_override("font_color", Color.WHITE)
	libelle.add_theme_color_override("font_outline_color", Color(0.10, 0.12, 0.10))
	libelle.add_theme_constant_override("outline_size", 6)
	add_child(libelle)

	_btn.pressed.connect(func() -> void:
		if _a_glisse:
			_a_glisse = false
			return
		lancee.emit(id))
	if deplacable:
		_btn.gui_input.connect(_sur_saisie_bouton)
	elif rangeable:
		_btn.gui_input.connect(_sur_saisie_fenetre)
	pivot_offset = size / 2.0
	resized.connect(func() -> void: pivot_offset = size / 2.0)


## Maintien + déplacement = glisser l'icône ; simple clic = laissé au bouton.
func _sur_saisie_bouton(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var ici := _dans_le_parent(event.global_position)
		if event.pressed:
			_appui = true
			_a_glisse = false
			_origine = ici
			_prise = ici - position
		elif _appui:
			_appui = false
			if _glisse:
				_glisse = false
				_a_glisse = true  # le `pressed` du bouton suit : il ne lancera rien
				scale = Vector2.ONE
				modulate = Color.WHITE
				z_index = 0
				garder_dans_l_ecran()
				lachee.emit(id, event.global_position, position)
				deplacee.emit(id, position)
	elif event is InputEventMouseMotion and _appui:
		var ici := _dans_le_parent(event.global_position)
		if not _glisse and ici.distance_to(_origine) >= SEUIL_GLISSE:
			_glisse = true
			scale = Vector2(ECHELLE_SOULEVEE, ECHELLE_SOULEVEE)
			modulate = Color(1, 1, 1, OPACITE_SOULEVEE)
			z_index = 1  # passe au-dessus des autres icônes pendant le vol
		if _glisse:
			position = ici - _prise
			garder_dans_l_ecran()
			survol.emit(id, event.global_position)


## Jeu dans une fenêtre-dossier : maintien + déplacement = il se soulève et suit
## la souris par-dessus tout (top_level, hors de la rangée) ; au relâché, le
## bureau décide (`lachee`) — hors de la fenêtre, il ressort sur le bureau.
## Simple clic = laissé au bouton (lance le jeu, comme avant).
func _sur_saisie_fenetre(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_appui = true
			_a_glisse = false
			_origine = event.global_position
			_prise = event.global_position - global_position
		elif _appui:
			_appui = false
			if _glisse:
				_glisse = false
				_a_glisse = true  # le `pressed` du bouton suit : il ne lancera rien
				scale = Vector2.ONE
				modulate = Color.WHITE
				z_index = 0
				var coin := global_position
				top_level = false  # reprend sa place dans la rangée…
				if get_parent() is Container:
					(get_parent() as Container).queue_sort()
				lachee.emit(id, event.global_position, coin)  # … sauf si le bureau le ressort
	elif event is InputEventMouseMotion and _appui:
		if not _glisse and event.global_position.distance_to(_origine) >= SEUIL_GLISSE:
			_glisse = true
			var ici := global_position
			top_level = true  # quitte la rangée : libre de sortir de la fenêtre
			global_position = ici
			scale = Vector2(ECHELLE_SOULEVEE, ECHELLE_SOULEVEE)
			modulate = Color(1, 1, 1, OPACITE_SOULEVEE)
			z_index = 1
		if _glisse:
			global_position = event.global_position - _prise


## Dossier visé (ou plus) par un jeu en vol : il grossit et s'éclaircit —
## la taille porte l'information autant que la teinte (daltonisme).
func signaler_cible(oui: bool) -> void:
	if _dossier == null or oui == _visee:
		return
	_visee = oui
	_dossier.couleur = couleur.lightened(0.3) if oui else couleur
	_dossier.queue_redraw()
	scale = Vector2(ECHELLE_CIBLE, ECHELLE_CIBLE) if oui else Vector2.ONE


## Le point (viewport) tombe-t-il sur le bouton de l'icône ?
func contient(point: Vector2) -> bool:
	return _btn != null and _btn.get_global_rect().has_point(point)


## Point du viewport ramené dans le repère du parent (le bureau).
func _dans_le_parent(point: Vector2) -> Vector2:
	return get_parent_control().get_global_transform().affine_inverse() * point


## L'icône reste entière dans l'écran, au-dessus de la barre des tâches.
func garder_dans_l_ecran() -> void:
	var zone: Vector2 = get_parent_area_size()
	position.x = clampf(position.x, 0.0, maxf(0.0, zone.x - size.x))
	position.y = clampf(position.y, 0.0, maxf(0.0, zone.y - limite_basse - size.y))


## Donne le focus clavier au bouton de l'icône (accessibilité).
func focus() -> void:
	_btn.grab_focus()


## Dossier à onglet dessiné par code (couleur de la catégorie).
class _IconeDossier extends Control:
	var couleur := Color(0.3, 0.5, 0.8)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var ci := get_canvas_item()
		# Onglet (haut gauche, un peu plus sombre)
		var onglet := StyleBoxFlat.new()
		onglet.bg_color = couleur.darkened(0.18)
		onglet.corner_radius_top_left = 10
		onglet.corner_radius_top_right = 10
		onglet.draw(ci, Rect2(w * 0.05, h * 0.03, w * 0.44, h * 0.22))
		# Corps du dossier
		var corps := StyleBoxFlat.new()
		corps.bg_color = couleur
		corps.set_corner_radius_all(12)
		corps.draw(ci, Rect2(0.0, h * 0.16, w, h * 0.84))
		# Liseré supérieur du corps (donne le relief du rabat)
		var rabat := StyleBoxFlat.new()
		rabat.bg_color = couleur.lightened(0.12)
		rabat.corner_radius_top_left = 12
		rabat.corner_radius_top_right = 12
		rabat.draw(ci, Rect2(0.0, h * 0.16, w, h * 0.12))
