## Sous-écran réglages adulte — section Souris.
## L'adulte dose les retours sensoriels du BUREAU (les jeux gardent les leurs) :
##   - traînée d'étoiles au déplacement          (case, activée par défaut)
##   - animation du clic gauche (fleurs)         (case, activée par défaut)
##   - animation du clic droit (étoiles)         (case, activée par défaut)
## Et règle, pour TOUT l'OS (bureau + jeux) : la taille du curseur (petit/moyen/
## grand), sa forme, et la VITESSE du pointeur (glissière 30 %–150 % — ralentir
## la souris aide les petites mains qui apprennent ; sans effet sur la version web).
## Sauvegarde immédiate à chaque changement (pas de bouton Enregistrer).
extends Control

const PinConfig = preload("res://scripts/pin_config.gd")
const UIStyle = preload("res://scripts/ui_style.gd")
const CurseurOS = preload("res://scripts/effets/curseur.gd")
const Lang = preload("res://scripts/lang.gd")

## Options de cette section : [clé de config, clé de texte]
const CASES := [
	["trainee_bureau", "souris_case_trainee"],
	["anim_clic_gauche_bureau", "souris_case_clic_gauche"],
	["anim_clic_droit_bureau", "souris_case_clic_droit"],
	["sons_clics_bureau", "souris_case_sons"],
]
const TAILLES := [["petit", "souris_taille_petit"], ["moyen", "souris_taille_moyen"], ["grand", "souris_taille_grand"]]
const FORMES := [
	["fleche", "souris_forme_fleche"], ["main", "souris_forme_main"],
	["abeille", "souris_forme_abeille"], ["coccinelle", "souris_forme_coccinelle"],
]


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
	# Séparation compacte : l'écran doit toujours tenir sous 720 px de haut
	vbox.add_theme_constant_override("separation", 20)
	centre.add_child(vbox)

	# --- Titre ---
	var titre := Label.new()
	titre.text = Lang.t("souris_titre")
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 48)
	titre.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(titre)

	# --- Cases : retours sensoriels du bureau ---
	var sous_titre := Label.new()
	sous_titre.text = Lang.t("souris_retours")
	sous_titre.add_theme_font_size_override("font_size", 24)
	sous_titre.add_theme_color_override("font_color", Color(0.78, 0.88, 0.82))
	vbox.add_child(sous_titre)

	for definition in CASES:
		var cle: String = definition[0]
		var case_option := CheckBox.new()
		case_option.text = " " + Lang.t(definition[1])
		case_option.add_theme_font_size_override("font_size", 28)
		for etat in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			case_option.add_theme_color_override(etat, Color.WHITE)
		case_option.button_pressed = PinConfig.lire_option("souris", cle, true)
		case_option.toggled.connect(func(actif: bool) -> void:
			PinConfig.ecrire_option("souris", cle, actif))
		vbox.add_child(case_option)

	# --- Taille du curseur (tout l'OS) : petit / moyen / grand ---
	var sous_titre_taille := Label.new()
	sous_titre_taille.text = Lang.t("souris_taille")
	sous_titre_taille.add_theme_font_size_override("font_size", 24)
	sous_titre_taille.add_theme_color_override("font_color", Color(0.78, 0.88, 0.82))
	vbox.add_child(sous_titre_taille)

	# Sans réglage enregistré, la case cochée est celle que le curseur applique vraiment
	# (« petit » sur Android, « moyen » sur PC — #223)
	var taille_actuelle: String = PinConfig.lire_option("souris", "taille_curseur",
		CurseurOS.taille_par_defaut(OS.has_feature("android")))
	var groupe := ButtonGroup.new()
	var ligne_tailles := HBoxContainer.new()
	ligne_tailles.add_theme_constant_override("separation", 30)
	vbox.add_child(ligne_tailles)

	for definition in TAILLES:
		var cle: String = definition[0]
		var bouton_radio := CheckBox.new()  # avec un ButtonGroup → comportement radio
		bouton_radio.text = " " + Lang.t(definition[1])
		bouton_radio.button_group = groupe
		bouton_radio.add_theme_font_size_override("font_size", 28)
		for etat in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			bouton_radio.add_theme_color_override(etat, Color.WHITE)
		bouton_radio.button_pressed = (cle == taille_actuelle)
		bouton_radio.toggled.connect(func(actif: bool) -> void:
			if actif:
				PinConfig.ecrire_option("souris", "taille_curseur", cle))
		ligne_tailles.add_child(bouton_radio)

	# --- Forme du curseur (tout l'OS) : flèche / main / abeille / coccinelle ---
	vbox.add_child(_creer_sous_titre(Lang.t("souris_forme")))

	var forme_actuelle: String = PinConfig.lire_option("souris", "forme_curseur", "coccinelle")
	var groupe_formes := ButtonGroup.new()
	var ligne_formes := HBoxContainer.new()
	ligne_formes.add_theme_constant_override("separation", 22)
	vbox.add_child(ligne_formes)

	for definition in FORMES:
		var cle: String = definition[0]
		# Aperçu dessiné du curseur, à côté de sa case
		var apercu := Control.new()
		apercu.custom_minimum_size = Vector2(42, 62)
		var mini: Node2D = CurseurOS.new()
		mini.forme_forcee = cle
		apercu.add_child(mini)
		mini.position = Vector2(14, 8)
		mini.scale = Vector2.ONE * 0.62  # taille d'aperçu (prime sur le réglage)
		ligne_formes.add_child(apercu)

		var bouton_radio := CheckBox.new()
		bouton_radio.text = " " + Lang.t(definition[1])
		bouton_radio.button_group = groupe_formes
		bouton_radio.add_theme_font_size_override("font_size", 26)
		for etat in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			bouton_radio.add_theme_color_override(etat, Color.WHITE)
		bouton_radio.button_pressed = (cle == forme_actuelle)
		bouton_radio.toggled.connect(func(actif: bool) -> void:
			if actif:
				PinConfig.ecrire_option("souris", "forme_curseur", cle))
		ligne_formes.add_child(bouton_radio)

	# --- Vitesse du pointeur (tout l'OS) : glissière de très lente à rapide ---
	vbox.add_child(_creer_sous_titre(Lang.t("souris_vitesse")))

	var ligne_vitesse := HBoxContainer.new()
	ligne_vitesse.add_theme_constant_override("separation", 18)
	vbox.add_child(ligne_vitesse)

	var glissiere := HSlider.new()
	glissiere.min_value = 0.3
	glissiere.max_value = 1.5
	glissiere.step = 0.05
	glissiere.value = float(PinConfig.lire_option("souris", "vitesse_curseur", 1.0))
	glissiere.custom_minimum_size = Vector2(420, 44)
	glissiere.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ligne_vitesse.add_child(glissiere)

	var valeur_vitesse := Label.new()
	valeur_vitesse.text = str(roundi(glissiere.value * 100.0)) + " %"
	valeur_vitesse.custom_minimum_size = Vector2(90, 0)
	valeur_vitesse.add_theme_font_size_override("font_size", 28)
	valeur_vitesse.add_theme_color_override("font_color", Color.WHITE)
	ligne_vitesse.add_child(valeur_vitesse)

	glissiere.value_changed.connect(func(v: float) -> void:
		valeur_vitesse.text = str(roundi(v * 100.0)) + " %"
		PinConfig.ecrire_option("souris", "vitesse_curseur", v))

	var note_vitesse := Label.new()
	note_vitesse.text = Lang.t("souris_vitesse_note")
	note_vitesse.add_theme_font_size_override("font_size", 18)
	note_vitesse.add_theme_color_override("font_color", Color(0.65, 0.75, 0.70))
	vbox.add_child(note_vitesse)

	# --- Bouton retour vers les réglages ---
	var btn_retour := Button.new()
	btn_retour.text = Lang.t("reglages_retour")
	btn_retour.custom_minimum_size = Vector2(420, 90)
	btn_retour.add_theme_font_size_override("font_size", 32)
	UIStyle.styliser(btn_retour, Color(0.20, 0.55, 0.45), 16)
	btn_retour.pressed.connect(_retour_reglages)
	vbox.add_child(btn_retour)

	btn_retour.grab_focus()


## Échap = revenir aux réglages (réflexe universel).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_retour_reglages()


func _creer_sous_titre(texte: String) -> Label:
	var label := Label.new()
	label.text = texte
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.82))
	return label


func _retour_reglages() -> void:
	get_tree().change_scene_to_file("res://scenes/adult_settings.tscn")
