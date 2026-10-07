## Sous-écran réglages adulte — section Interface.
## - fenêtres déplaçables par l'enfant (case, fixes par défaut)
## - couleur des fenêtres : barre de titre et fond — pastilles qui ouvrent un
##   sélecteur de couleur AVEC validation (Valider / Annuler / croix) ;
##   la couleur n'est enregistrée qu'à la validation
## - fond d'écran du bureau : image prairie (défaut), image importée depuis
##   l'ordinateur (copiée dans les données du jeu), ou couleur unie
## Retour aux couleurs d'origine possible (barre = couleur de la catégorie).
extends Control

const PinConfig = preload("res://scripts/pin_config.gd")
const UIStyle = preload("res://scripts/ui_style.gd")
const Lang = preload("res://scripts/lang.gd")
const Android = preload("res://scripts/android.gd")
const Tactile = preload("res://scripts/tactile.gd")

const COULEUR_BARRE_DEFAUT := Color(0.25, 0.45, 0.75)   # affichage pastille (auto = couleur du jeu)
const COULEUR_FOND_DEFAUT := Color(0.98, 0.97, 0.93)    # ivoire des fenêtres
const COULEUR_BUREAU_DEFAUT := Color(0.55, 0.75, 0.55)  # proposition de vert doux
const CHEMIN_FOND_PERSO := "user://fond_bureau_perso.png"
const LARGEUR_MAX_FOND := 1920  # les images importées plus larges sont réduites

var _pastille_barre: Button
var _pastille_fond: Button
var _message: Label


func _ready() -> void:
	# --- Fond plein (même atmosphère sobre que les écrans adulte) ---
	var fond := ColorRect.new()
	fond.color = Color(0.12, 0.25, 0.22)
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	# Zone défilante : molette + barre de défilement si le contenu dépasse l'écran
	var defilement := ScrollContainer.new()
	defilement.set_anchors_preset(Control.PRESET_FULL_RECT)
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defilement.get_v_scroll_bar().custom_minimum_size = Vector2(14, 0)
	add_child(defilement)
	var centre := CenterContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defilement.add_child(centre)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 22)
	centre.add_child(vbox)

	# --- Titre ---
	var titre := Label.new()
	titre.text = Lang.t("interface_titre")
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 48)
	titre.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(titre)

	# --- Fenêtres déplaçables ---
	var case_fenetres := CheckBox.new()
	case_fenetres.text = " " + Lang.t("interface_fenetres_deplacables")
	case_fenetres.add_theme_font_size_override("font_size", 28)
	for etat in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		case_fenetres.add_theme_color_override(etat, Color.WHITE)
	case_fenetres.button_pressed = PinConfig.lire_option("bureau", "fenetres_deplacables", false)
	case_fenetres.toggled.connect(func(actif: bool) -> void:
		PinConfig.ecrire_option("bureau", "fenetres_deplacables", actif))
	vbox.add_child(case_fenetres)

	# --- Plein écran au lancement (appliqué aussi immédiatement) ---
	var case_plein_ecran := CheckBox.new()
	case_plein_ecran.text = " " + Lang.t("interface_plein_ecran")
	case_plein_ecran.add_theme_font_size_override("font_size", 28)
	for etat in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		case_plein_ecran.add_theme_color_override(etat, Color.WHITE)
	case_plein_ecran.button_pressed = PinConfig.lire_option("interface", "plein_ecran", false)
	case_plein_ecran.toggled.connect(func(actif: bool) -> void:
		PinConfig.ecrire_option("interface", "plein_ecran", actif)
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if actif else DisplayServer.WINDOW_MODE_WINDOWED))
	vbox.add_child(case_plein_ecran)

	# --- Bouton éteindre protégé par le PIN (brique kiosque) ---
	var case_pin_eteindre := CheckBox.new()
	case_pin_eteindre.text = " " + Lang.t("interface_pin_eteindre")
	case_pin_eteindre.add_theme_font_size_override("font_size", 28)
	for etat in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		case_pin_eteindre.add_theme_color_override(etat, Color.WHITE)
	case_pin_eteindre.button_pressed = PinConfig.lire_option("interface", "eteindre_sous_pin", false)
	case_pin_eteindre.toggled.connect(func(actif: bool) -> void:
		PinConfig.ecrire_option("interface", "eteindre_sous_pin", actif))
	vbox.add_child(case_pin_eteindre)

	# --- Mode écran tactile (cochée par défaut sur Android, décochée sur PC ;
	#     activable à la main sur un PC-tablette Ubuntu/Windows) ---
	var case_tactile := CheckBox.new()
	case_tactile.text = " " + Lang.t("interface_mode_tactile")
	case_tactile.add_theme_font_size_override("font_size", 28)
	for etat in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		case_tactile.add_theme_color_override(etat, Color.WHITE)
	case_tactile.button_pressed = PinConfig.lire_option("interface", "mode_tactile", Tactile.par_defaut())
	case_tactile.toggled.connect(func(actif: bool) -> void:
		PinConfig.ecrire_option("interface", "mode_tactile", actif))
	vbox.add_child(case_tactile)

	# --- Menu du bureau : appui long au doigt sur le bureau nu = bulle de menu
	#     (décochée par défaut : l'appui long y garde les étoiles) ---
	var case_menu := CheckBox.new()
	case_menu.text = " " + Lang.t("interface_menu_contextuel")
	case_menu.add_theme_font_size_override("font_size", 28)
	for etat in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		case_menu.add_theme_color_override(etat, Color.WHITE)
	case_menu.button_pressed = PinConfig.lire_option("interface", "menu_contextuel_bureau", false)
	case_menu.toggled.connect(func(actif: bool) -> void:
		PinConfig.ecrire_option("interface", "menu_contextuel_bureau", actif))
	vbox.add_child(case_menu)

	# --- Bouton de volume enfant (barre des tâches) — cochée par défaut ---
	var case_volume := CheckBox.new()
	case_volume.text = " " + Lang.t("interface_bouton_volume")
	case_volume.add_theme_font_size_override("font_size", 28)
	for etat in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		case_volume.add_theme_color_override(etat, Color.WHITE)
	case_volume.button_pressed = PinConfig.lire_option("interface", "bouton_volume", true)
	case_volume.toggled.connect(func(actif: bool) -> void:
		PinConfig.ecrire_option("interface", "bouton_volume", actif))
	vbox.add_child(case_volume)

	# --- Mode bureau du téléphone (Android) : ouvre le réglage système où l'on
	#     choisit CoccOs (entrée) ou le lanceur d'origine (sortie) ---
	if Android.disponible():
		var btn_bureau_tel := Button.new()
		btn_bureau_tel.text = Lang.t("interface_bureau_telephone")
		btn_bureau_tel.custom_minimum_size = Vector2(460, 64)
		btn_bureau_tel.add_theme_font_size_override("font_size", 24)
		UIStyle.styliser(btn_bureau_tel, Color(0.30, 0.45, 0.60), 14)
		btn_bureau_tel.pressed.connect(func() -> void:
			Android.ouvrir_reglage_bureau())
		vbox.add_child(btn_bureau_tel)

	# --- Couleur des fenêtres ---
	vbox.add_child(_creer_sous_titre(Lang.t("interface_couleur_fenetres")))

	var ligne_couleurs := HBoxContainer.new()
	ligne_couleurs.add_theme_constant_override("separation", 16)
	ligne_couleurs.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(ligne_couleurs)

	ligne_couleurs.add_child(_creer_libelle(Lang.t("interface_barre")))
	_pastille_barre = _creer_pastille(
		PinConfig.lire_option("interface", "couleur_barre_fenetre", COULEUR_BARRE_DEFAUT))
	_pastille_barre.pressed.connect(func() -> void:
		_choisir_couleur(Lang.t("interface_couleur_barre_titre"), _pastille_barre,
			func(couleur: Color) -> void:
				PinConfig.ecrire_option("interface", "couleur_barre_fenetre", couleur)))
	ligne_couleurs.add_child(_pastille_barre)

	ligne_couleurs.add_child(_creer_libelle(Lang.t("interface_fond")))
	_pastille_fond = _creer_pastille(
		PinConfig.lire_option("interface", "couleur_fond_fenetre", COULEUR_FOND_DEFAUT))
	_pastille_fond.pressed.connect(func() -> void:
		_choisir_couleur(Lang.t("interface_couleur_fond_titre"), _pastille_fond,
			func(couleur: Color) -> void:
				PinConfig.ecrire_option("interface", "couleur_fond_fenetre", couleur)))
	ligne_couleurs.add_child(_pastille_fond)

	var btn_defaut := Button.new()
	btn_defaut.text = Lang.t("interface_couleurs_origine")
	btn_defaut.custom_minimum_size = Vector2(240, 52)
	btn_defaut.add_theme_font_size_override("font_size", 24)
	UIStyle.styliser(btn_defaut, Color(0.40, 0.40, 0.45), 12)
	btn_defaut.pressed.connect(_couleurs_origine)
	ligne_couleurs.add_child(btn_defaut)

	# --- Fond d'écran du bureau ---
	vbox.add_child(_creer_sous_titre(Lang.t("interface_fond_bureau")))

	var ligne_fond := HBoxContainer.new()
	ligne_fond.add_theme_constant_override("separation", 16)
	ligne_fond.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(ligne_fond)

	var btn_prairie := Button.new()
	btn_prairie.text = Lang.t("interface_btn_prairie")
	btn_prairie.custom_minimum_size = Vector2(230, 52)
	btn_prairie.add_theme_font_size_override("font_size", 24)
	UIStyle.styliser(btn_prairie, Color(0.25, 0.55, 0.30), 12)
	btn_prairie.pressed.connect(func() -> void:
		PinConfig.ecrire_option("interface", "fond_bureau_type", "image")
		_informer(Lang.t("interface_msg_prairie")))
	ligne_fond.add_child(btn_prairie)

	var btn_importer := Button.new()
	btn_importer.text = Lang.t("interface_btn_importer")
	btn_importer.custom_minimum_size = Vector2(300, 52)
	btn_importer.add_theme_font_size_override("font_size", 24)
	UIStyle.styliser(btn_importer, Color(0.25, 0.45, 0.75), 12)
	btn_importer.pressed.connect(_ouvrir_import_image)
	ligne_fond.add_child(btn_importer)

	ligne_fond.add_child(_creer_libelle(Lang.t("interface_ou_couleur")))
	var pastille_bureau := _creer_pastille(
		PinConfig.lire_option("interface", "fond_bureau_couleur", COULEUR_BUREAU_DEFAUT))
	pastille_bureau.pressed.connect(func() -> void:
		_choisir_couleur(Lang.t("interface_couleur_bureau_titre"), pastille_bureau,
			func(couleur: Color) -> void:
				PinConfig.ecrire_option("interface", "fond_bureau_type", "couleur")
				PinConfig.ecrire_option("interface", "fond_bureau_couleur", couleur)
				_informer(Lang.t("interface_msg_couleur"))))
	ligne_fond.add_child(pastille_bureau)

	# --- Message d'information (import réussi/raté, choix appliqué) ---
	_message = Label.new()
	_message.text = ""
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 24)
	_message.add_theme_color_override("font_color", Color(0.55, 0.95, 0.60))
	vbox.add_child(_message)

	# --- Bouton retour vers les réglages ---
	var btn_retour := Button.new()
	btn_retour.text = Lang.t("reglages_retour")
	btn_retour.custom_minimum_size = Vector2(420, 84)
	btn_retour.add_theme_font_size_override("font_size", 32)
	UIStyle.styliser(btn_retour, Color(0.20, 0.55, 0.45), 16)
	btn_retour.pressed.connect(_retour_reglages)
	vbox.add_child(btn_retour)

	btn_retour.grab_focus()


## Échap = revenir aux réglages (réflexe universel).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_retour_reglages()


# --- Sélecteur de couleur avec validation ------------------------------------

## Ouvre un dialogue (Valider / Annuler / croix) ; `rappel` n'est appelé —
## et la pastille repeinte — qu'à la validation.
func _choisir_couleur(titre: String, pastille: Button, rappel: Callable) -> void:
	var dialogue := AcceptDialog.new()
	dialogue.title = titre
	dialogue.ok_button_text = Lang.t("interface_valider")
	dialogue.add_cancel_button(Lang.t("interface_annuler"))

	var selecteur := ColorPicker.new()
	selecteur.color = (pastille.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
	selecteur.edit_alpha = false
	# Version compacte : roue + zone de teinte, sans curseurs ni hexadécimal
	selecteur.sliders_visible = false
	selecteur.hex_visible = false
	selecteur.sampler_visible = false
	selecteur.presets_visible = false
	selecteur.color_modes_visible = false
	dialogue.add_child(selecteur)

	add_child(dialogue)
	dialogue.confirmed.connect(func() -> void:
		_peindre_pastille(pastille, selecteur.color)
		rappel.call(selecteur.color)
		dialogue.queue_free())
	dialogue.canceled.connect(dialogue.queue_free)
	dialogue.popup_centered()


func _creer_pastille(couleur: Color) -> Button:
	var pastille := Button.new()
	pastille.custom_minimum_size = Vector2(96, 52)
	_peindre_pastille(pastille, couleur)
	return pastille


func _peindre_pastille(pastille: Button, couleur: Color) -> void:
	for etat in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = couleur.lightened(0.1) if etat == "hover" else couleur
		style.set_corner_radius_all(10)
		style.set_border_width_all(3)
		style.border_color = Color(1.0, 1.0, 0.2) if etat == "focus" else Color(1, 1, 1, 0.6)
		pastille.add_theme_stylebox_override(etat, style)


## Efface les couleurs personnalisées : la barre reprend la couleur de la
## catégorie du jeu, le fond redevient ivoire.
func _couleurs_origine() -> void:
	PinConfig.effacer_option("interface", "couleur_barre_fenetre")
	PinConfig.effacer_option("interface", "couleur_fond_fenetre")
	_peindre_pastille(_pastille_barre, COULEUR_BARRE_DEFAUT)
	_peindre_pastille(_pastille_fond, COULEUR_FOND_DEFAUT)
	_informer(Lang.t("interface_msg_origine"))


# --- Import d'une image de fond ------------------------------------------------

## Sélecteur de fichiers de l'ordinateur (dialogue natif du système).
func _ouvrir_import_image() -> void:
	var dialogue := FileDialog.new()
	dialogue.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialogue.access = FileDialog.ACCESS_FILESYSTEM
	dialogue.use_native_dialog = true
	dialogue.title = Lang.t("interface_import_titre")
	dialogue.add_filter("*.png, *.jpg, *.jpeg, *.webp, *.bmp", Lang.t("interface_filtre_images"))
	dialogue.file_selected.connect(_importer_fond)
	add_child(dialogue)
	dialogue.popup_centered(Vector2i(900, 600))


## Copie l'image choisie dans les données du jeu (le fond survit même si
## l'original est déplacé ou supprimé), en la réduisant si elle est très grande.
func _importer_fond(chemin: String) -> void:
	var image := Image.load_from_file(chemin)
	if image == null or image.is_empty():
		_informer(Lang.t("interface_msg_illisible") + " " + chemin.get_file(), true)
		return
	if image.get_width() > LARGEUR_MAX_FOND:
		var hauteur := int(image.get_height() * float(LARGEUR_MAX_FOND) / float(image.get_width()))
		image.resize(LARGEUR_MAX_FOND, hauteur, Image.INTERPOLATE_LANCZOS)
	if image.save_png(CHEMIN_FOND_PERSO) != OK:
		_informer(Lang.t("interface_msg_enregistrement"), true)
		return
	PinConfig.ecrire_option("interface", "fond_bureau_type", "perso")
	_informer(Lang.t("interface_msg_importe") + " " + chemin.get_file())


func _informer(texte: String, erreur := false) -> void:
	_message.text = texte
	_message.add_theme_color_override("font_color",
		Color(1.0, 0.45, 0.40) if erreur else Color(0.55, 0.95, 0.60))


func _creer_sous_titre(texte: String) -> Label:
	var label := Label.new()
	label.text = texte
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.82))
	return label


func _creer_libelle(texte: String) -> Label:
	var label := Label.new()
	label.text = texte
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


func _retour_reglages() -> void:
	get_tree().change_scene_to_file("res://scenes/adult_settings.tscn")
