## Clavier virtuel CoccOs — bande AZERTY dessinée en bas de l'écran, qui
## remplace le clavier du système en mode tactile (celui-ci prenait la moitié
## de l'écran et masquait le tableau blanc). Paysage uniquement (décidé).
## Grosses touches colorées : chaque touche porte la couleur de sa lettre
## (même palette et même modulo que les bulles de la chasse et les tuiles des
## mots — la touche A est de la couleur du A partout). Rangée des chiffres,
## trois rangées AZERTY, retour arrière (le plaisir d'effacer d'Isabella).
## Pas d'accents ni de ponctuation : clavier simple (décision Freddy 2026-07-07).
##
## Chaque tap INJECTE un InputEventKey synthétique (Input.parse_input_event) :
## les jeux le reçoivent exactement comme une touche physique — aucune logique
## de saisie dupliquée, le clavier dessiné est un clavier de plus.
##
## Usage (jeux clavier, en mode tactile seulement — voir tactile.gd) :
##   _clavier = (load(dossier + "/clavier_virtuel.gd") as GDScript).new()
##   _clavier.curseur = _curseur   # remontée à la portée de la pointe (voir plus bas)
##   _clavier.encombrement_change.connect(_ajuster_au_clavier)   # le contenu se pousse au-dessus
##   add_child(_clavier)
##   _curseur.move_to_front()   # le curseur-doigt reste visible sur les touches
## puis garder les clics du jeu hors de la bande :
##   if _clavier and _clavier.contient(event.position): return
extends PanelContainer

## Émis quand la place prise en bas change (création, taille du curseur) : le jeu
## remonte son contenu de `hauteur` (= encombrement()).
signal encombrement_change(hauteur: float)

## Hauteur des touches — les jeux remontent leur contenu d'au moins autant.
## (≥ la taille minimale des 4 rangées de touches, mesurée à 314 px.)
const HAUTEUR := 320.0
## REMONTÉE DU CLAVIER (décision Fabrice 07-10, Android) : on vise à la POINTE du curseur,
## qui est AU-DESSUS du doigt. Le doigt ne descendant pas sous le bas de l'écran, la pointe
## ne descend pas sous (bas − décalage vertical) : les touches sont donc remontées d'autant,
## et la bande libérée dessous (même panneau) sert de repose-doigt. Leçon des 7 différences
## (sept_differences.gd, encadrés B10→B34) : tant qu'une marge sous la cible valait le
## décalage, tout était atteignable ; et on ne demande JAMAIS au doigt le dernier pixel de
## l'écran (bande des gestes système d'Android) → GARDE en plus du décalage. Ni zoom de bord,
## ni fondu du décalage en bas (décision Fabrice).
const GARDE := 12.0

var curseur: Node2D = null  # curseur du jeu, posé avant add_child (null = pas de remontée)
var remontee := 0.0         # bande sous les touches, en px viewport

var _marge: MarginContainer

const RANGEES := ["1234567890", "AZERTYUIOP", "QSDFGHJKLM", "WXCVBN"]
const TAILLE_POLICE := 46
## Palette des lettres (identique aux jeux : couleur = unicode % 8).
const COULEURS_LETTRES: Array[Color] = [
	Color(0.90, 0.30, 0.40), Color(0.95, 0.55, 0.15), Color(0.80, 0.65, 0.10),
	Color(0.25, 0.65, 0.35), Color(0.20, 0.60, 0.90), Color(0.45, 0.40, 0.85),
	Color(0.75, 0.35, 0.75), Color(0.20, 0.70, 0.65),
]
const COULEUR_RETOUR := Color(0.40, 0.50, 0.65)  # bleu-gris des boutons effacer


func _ready() -> void:
	# _ready s'exécute APRÈS l'ajout à l'arbre : set_anchors_preset préserverait
	# la taille courante (offsets compensatoires) — il faut aussi poser les offsets.
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	mouse_filter = Control.MOUSE_FILTER_STOP  # la bande avale les taps entre les touches

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.97, 0.96, 0.92, 0.92)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.border_width_top = 4
	style.border_color = Color(0.60, 0.66, 0.72)
	add_theme_stylebox_override("panel", style)

	var marge := MarginContainer.new()
	for cote in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		marge.add_theme_constant_override(cote, 12)
	add_child(marge)
	_marge = marge

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 10)
	marge.add_child(colonne)

	for rangee in RANGEES:
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 10)
		ligne.size_flags_vertical = Control.SIZE_EXPAND_FILL
		colonne.add_child(ligne)
		for i in rangee.length():
			ligne.add_child(_creer_touche(rangee[i]))
	# Retour arrière au bout de la dernière rangée, deux fois plus large
	var derniere: HBoxContainer = colonne.get_child(colonne.get_child_count() - 1)
	derniere.add_child(_creer_touche(""))
	_remonter(remontee_pour(curseur))


## Remontée qui met la rangée du bas à portée de la pointe de `c` (0 sans curseur).
static func remontee_pour(c: Node2D) -> float:
	if c == null:
		return 0.0
	return ceilf(maxf(0.0, -(c.decalage_doigt() as Vector2).y)) + GARDE


## Place totale prise en bas de l'écran (touches + bande de remontée).
func encombrement() -> float:
	return HAUTEUR + remontee


## La taille du curseur peut changer en cours de jeu (molette) : la remontée suit.
func _process(_delta: float) -> void:
	if is_instance_valid(curseur):
		var voulue := remontee_pour(curseur)
		if absf(voulue - remontee) > 0.5:
			_remonter(voulue)


func _remonter(valeur: float) -> void:
	remontee = valeur
	offset_top = -encombrement()
	offset_bottom = 0.0
	_marge.add_theme_constant_override("margin_bottom", 12 + int(remontee))
	encombrement_change.emit(encombrement())


## Le tap appartient-il à la bande ? (les jeux ignorent alors le clic)
func contient(point: Vector2) -> bool:
	return get_global_rect().has_point(point)


## Une grosse touche colorée. Caractère vide = retour arrière (flèche).
func _creer_touche(caractere: String) -> Button:
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var couleur := COULEUR_RETOUR
	if caractere != "":
		couleur = COULEURS_LETTRES[caractere.unicode_at(0) % COULEURS_LETTRES.size()]
		btn.text = caractere
		btn.add_theme_font_size_override("font_size", TAILLE_POLICE)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_pressed_color", Color.WHITE)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
	else:
		btn.size_flags_stretch_ratio = 2.0
		var fleche := _IconeRetourArriere.new()
		fleche.set_anchors_preset(Control.PRESET_FULL_RECT)
		fleche.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(fleche)
	for etat in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = couleur
		if etat == "hover":
			style.bg_color = couleur.lightened(0.12)
		elif etat == "pressed":
			style.bg_color = couleur.darkened(0.18)
		style.set_corner_radius_all(16)
		btn.add_theme_stylebox_override(etat, style)
	btn.pressed.connect(_appuyer.bind(caractere))
	return btn


## Injecte la touche dans le flux d'entrée : le jeu la reçoit comme une
## vraie frappe (pression puis relâchement, pour ne rien laisser « enfoncé »).
func _appuyer(caractere: String) -> void:
	var pression := InputEventKey.new()
	pression.pressed = true
	if caractere == "":
		pression.keycode = KEY_BACKSPACE
	else:
		pression.unicode = caractere.unicode_at(0)
	Input.parse_input_event(pression)
	var relachement: InputEventKey = pression.duplicate()
	relachement.pressed = false
	Input.parse_input_event(relachement)


## Flèche vers la gauche (même dessin que les boutons effacer des jeux).
class _IconeRetourArriere extends Control:
	func _draw() -> void:
		var centre := size / 2.0
		var u := minf(size.x, size.y) / 2.0
		draw_line(centre + Vector2(-u * 0.45, 0.0), centre + Vector2(u * 0.5, 0.0), Color.WHITE, 6.0)
		draw_colored_polygon(PackedVector2Array([
			centre + Vector2(-u * 0.6, 0.0),
			centre + Vector2(-u * 0.15, -u * 0.38),
			centre + Vector2(-u * 0.15, u * 0.38),
		]), Color.WHITE)
