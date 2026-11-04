## Fenêtre du bureau enfant, façon OS : barre de titre colorée (déplaçable à la
## souris) + croix rouge de fermeture + zone de contenu où déposer des icônes.
## L'enfant apprend les gestes universels : ouvrir, déplacer, fermer une fenêtre.
## Usage :
##   var f := Fenetre.new()
##   f.titre = "La souris" ; f.couleur = Color(...)
##   add_child(f)  →  puis ajouter les icônes dans f.contenu
extends PanelContainer

const UIStyle := preload("res://scripts/ui_style.gd")
const PinConfig := preload("res://scripts/pin_config.gd")

const COULEUR_FOND_DEFAUT := Color(0.98, 0.97, 0.93, 0.98)

var titre := ""
var couleur := Color(0.25, 0.45, 0.75)
var limite_basse := 0.0  # hauteur réservée en bas (barre des tâches du bureau)
var deplacable := false  # réglage adulte : fixe par défaut, déplaçable si activé
var contenu: HBoxContainer

var _glisse := false


func _ready() -> void:
	# Couleurs personnalisées (réglages adulte → Interface) : la barre remplace
	# la couleur de catégorie, le fond remplace l'ivoire. Absentes = défauts.
	var couleur_barre: Variant = PinConfig.lire_option("interface", "couleur_barre_fenetre", null)
	if couleur_barre is Color:
		couleur = couleur_barre
	var couleur_fond: Variant = PinConfig.lire_option("interface", "couleur_fond_fenetre", null)

	# Corps de la fenêtre : fond ivoire (ou personnalisé), coins arrondis, ombre portée
	var style := StyleBoxFlat.new()
	style.bg_color = couleur_fond if couleur_fond is Color else COULEUR_FOND_DEFAUT
	style.set_corner_radius_all(16)
	style.shadow_size = 12
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_offset = Vector2(0, 4)
	add_theme_stylebox_override("panel", style)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 0)
	add_child(colonne)

	# --- Barre de titre (traînable) ---
	var barre := PanelContainer.new()
	var style_barre := StyleBoxFlat.new()
	style_barre.bg_color = couleur
	style_barre.corner_radius_top_left = 16
	style_barre.corner_radius_top_right = 16
	barre.add_theme_stylebox_override("panel", style_barre)
	if deplacable:
		barre.mouse_default_cursor_shape = Control.CURSOR_MOVE
		barre.gui_input.connect(_sur_saisie_barre)
	colonne.add_child(barre)

	var marge_barre := MarginContainer.new()
	marge_barre.add_theme_constant_override("margin_left", 18)
	marge_barre.add_theme_constant_override("margin_right", 10)
	marge_barre.add_theme_constant_override("margin_top", 8)
	marge_barre.add_theme_constant_override("margin_bottom", 8)
	barre.add_child(marge_barre)

	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 14)
	marge_barre.add_child(ligne)

	var label := Label.new()
	label.text = titre
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(label)

	# Croix de fermeture — le geste universel des fenêtres
	var btn_fermer := Button.new()
	btn_fermer.custom_minimum_size = Vector2(44, 44)
	btn_fermer.focus_mode = Control.FOCUS_NONE
	UIStyle.styliser(btn_fermer, Color(0.85, 0.30, 0.25), 22)
	var croix := _IconeCroix.new()
	croix.set_anchors_preset(Control.PRESET_FULL_RECT)
	croix.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_fermer.add_child(croix)
	btn_fermer.add_to_group(&"au_doigt")  # Android : prise au doigt du joueur (A2, cf. visee_pointe.gd)
	btn_fermer.pressed.connect(queue_free)
	ligne.add_child(btn_fermer)

	# --- Zone de contenu : rangée d'icônes ---
	var marge_contenu := MarginContainer.new()
	for cote in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		marge_contenu.add_theme_constant_override(cote, 26)
	colonne.add_child(marge_contenu)

	contenu = HBoxContainer.new()
	contenu.add_theme_constant_override("separation", 22)
	contenu.alignment = BoxContainer.ALIGNMENT_CENTER
	marge_contenu.add_child(contenu)


## Glisser-déposer de la fenêtre par sa barre de titre (si `deplacable`).
func _sur_saisie_barre(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_glisse = event.pressed
	elif event is InputEventMouseMotion and _glisse:
		position += event.relative
		_rester_dans_l_ecran()


## La fenêtre ne peut pas s'échapper de l'écran ni passer sous la barre des tâches.
func _rester_dans_l_ecran() -> void:
	var zone: Vector2 = get_parent_area_size()
	position.x = clampf(position.x, 0.0, maxf(0.0, zone.x - size.x))
	position.y = clampf(position.y, 0.0, maxf(0.0, zone.y - limite_basse - size.y))


## Croix blanche dessinée dans le bouton de fermeture.
class _IconeCroix extends Control:
	func _draw() -> void:
		var c := size / 2.0
		var u := minf(size.x, size.y) * 0.22
		draw_line(c + Vector2(-u, -u), c + Vector2(u, u), Color.WHITE, 5.0)
		draw_line(c + Vector2(-u, u), c + Vector2(u, -u), Color.WHITE, 5.0)
