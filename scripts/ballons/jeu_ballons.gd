## Les ballons — deuxième jeu souris : apprendre à VISER puis CLIQUER (clic gauche)…
## et à COMPTER : chaque ballon éclaté est dit à voix haute (« un », « deux »…)
## pendant que le grand compteur rebondit — le geste, le chiffre affiché et le
## nombre entendu s'associent.
## Des ballons colorés montent du bas de l'écran en se balançant ; l'enfant les
## éclate d'un clic gauche → confettis + « plop » + compteur qui grandit.
## La vitesse démarre très doucement puis accélère à chaque ballon éclaté
## (jamais au chrono) : l'enfant fixe son rythme, l'adulte trouve son défi.
## Aucun échec possible : un ballon manqué s'envole simplement, un clic dans le
## vide fait quand même scintiller quelques confettis (chaque geste récompense).
##
## Sortie : bouton croix (haut droit) ou Échap — retour au bureau si
## res://scenes/bureau.tscn existe, sinon fermeture (jeu autonome).
##
## Activité AUTO-CONTENUE : les briques (ballon, confetti, curseur, sons) sont
## chargées relativement au dossier de CE script — dossier déposable tel quel
## dans n'importe quel projet. Seule dépendance partagée : res://scripts/fond.gd.
extends Control

const Fond := preload("res://scripts/fond.gd")
const Voix := preload("res://scripts/voix.gd")
const CHEMIN_BUREAU := "res://scenes/bureau.tscn"
const Lancement := preload("res://scripts/lancement.gd")
const ViseePointe := preload("res://scripts/visee_pointe.gd")

const COULEURS_BALLONS: Array[Color] = [
	Color(0.95, 0.35, 0.35), Color(1.0, 0.65, 0.2), Color(1.0, 0.85, 0.25),
	Color(0.4, 0.8, 0.4), Color(0.35, 0.65, 0.95), Color(0.75, 0.5, 0.95),
	Color(1.0, 0.55, 0.75),
]
const COULEUR_BOUTON_QUITTER := Color(0.85, 0.35, 0.30)
const MAX_BALLONS := 7          # à l'écran en même temps (rythme doux)
const CADENCE_LACHER := 1.4     # secondes entre deux ballons (à vitesse 100 %)

# Briques de l'activité, chargées relativement au dossier de ce script
var _Ballon: GDScript
var _Confetti: GDScript
var _Curseur: GDScript
var _Sons: GDScript

var _calque_ballons: Node2D
var _calque_effets: Node2D
var _curseur: Node2D
var _label_compteur: Label
var _compteur := 0
var _lecteurs := {}
var _minuterie: Timer
var _tween_compteur: Tween


func _ready() -> void:
	_charger_briques()
	Fond.appliquer(self)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	# Ordre d'affichage : ballons < confettis < compteur/bouton < curseur (dessus)
	_calque_ballons = Node2D.new()
	add_child(_calque_ballons)
	_calque_effets = Node2D.new()
	add_child(_calque_effets)

	_creer_compteur()
	_creer_bouton_quitter()

	_curseur = _Curseur.new()
	add_child(_curseur)
	_curseur.position = get_viewport().get_mouse_position()
	_brancher_visee()

	_creer_lecteurs()
	Voix.amorcer()  # natif : voix prête tout de suite ; web : résolue à la volée

	# Lâcher régulier de ballons + 3 premiers ballons étagés dès le départ
	_minuterie = Timer.new()
	_minuterie.wait_time = CADENCE_LACHER / sqrt(_facteur_vitesse())
	_minuterie.timeout.connect(_lacher_ballon)
	add_child(_minuterie)
	_minuterie.start()
	for i in 3:
		get_tree().create_timer(0.3 + 0.5 * float(i)).timeout.connect(_lacher_ballon)


func _charger_briques() -> void:
	var dossier: String = (get_script() as GDScript).resource_path.get_base_dir()
	_Ballon = load(dossier + "/ballon.gd")
	_Confetti = load(dossier + "/confetti.gd")
	_Curseur = load(dossier + "/curseur.gd")
	_Sons = load(dossier + "/sons.gd")


func _creer_lecteurs() -> void:
	var flux := {
		"pop": _Sons.pop_ballon(),
		"clic": _Sons.petit_clic(),
	}
	for nom in flux:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux[nom]
		lecteur.max_polyphony = 4
		add_child(lecteur)
		_lecteurs[nom] = lecteur


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_quitter()
		return
	if event is InputEventMouseMotion:
		_curseur.position = event.position
	elif event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			# Tap Android : aucun mouvement émulé, seul ce clic (déjà ramené à la pointe) → le curseur s'y pose
			_curseur.position = event.position
		_clic_gauche(event.position)


## Android : le doigt déplace le curseur, la POINTE vise (ballons, croix) — cf. visee_pointe.gd.
func _brancher_visee() -> void:
	var visee: Node = ViseePointe.new()
	visee.curseur = _curseur
	add_child(visee)


# --- Ballons ----------------------------------------------------------------

## Vitesse générale du jeu : démarre très doucement (45 %) puis accélère à
## chaque ballon éclaté — liée au succès, jamais au chrono : l'enfant qui
## observe garde des ballons lents, celui qui éclate vite se fait un défi.
## Plafonnée pour rester rattrapable.
func _facteur_vitesse() -> float:
	return clampf(0.45 + 0.05 * float(_compteur), 0.45, 1.7)


func _lacher_ballon() -> void:
	if _calque_ballons.get_child_count() >= MAX_BALLONS:
		return
	var taille := get_viewport_rect().size
	var ballon: Node2D = _Ballon.new()
	ballon.rayon = randf_range(42.0, 64.0)
	ballon.couleur = COULEURS_BALLONS.pick_random()
	ballon.vitesse = randf_range(70.0, 130.0) * _facteur_vitesse()
	ballon.amplitude = randf_range(18.0, 40.0)
	ballon.frequence = randf_range(0.8, 1.6)
	ballon.position = Vector2(
		randf_range(90.0, taille.x - 90.0),
		taille.y + ballon.rayon * 2.2 + 20.0)
	_calque_ballons.add_child(ballon)


func _clic_gauche(ou: Vector2) -> void:
	_curseur.pulser()
	# Du plus récent au plus ancien = celui dessiné au-dessus est éclaté en premier
	var enfants := _calque_ballons.get_children()
	for i in range(enfants.size() - 1, -1, -1):
		var ballon: Node2D = enfants[i]
		if ballon.contient(ou):
			_eclater(ballon)
			return
	# Clic dans le vide : petit scintillement — jamais punitif
	_lecteurs["clic"].play()
	for i in 4:
		_poser_confetti(ou, Color(1.0, 0.95, 0.7), randf_range(6.0, 10.0), 90.0)


func _eclater(ballon: Node2D) -> void:
	_lecteurs["pop"].play()
	_compteur += 1
	_label_compteur.text = str(_compteur)
	_animer_compteur(ballon.couleur)
	_prononcer_nombre()
	# La cadence de lâcher suit la vitesse (appliquée au prochain cycle)
	_minuterie.wait_time = CADENCE_LACHER / sqrt(_facteur_vitesse())
	var couleur: Color = ballon.couleur
	for i in 14:
		_poser_confetti(ballon.position,
			[couleur, couleur.lightened(0.3), Color.WHITE].pick_random(),
			randf_range(8.0, 16.0), randf_range(180.0, 420.0))
	ballon.queue_free()


func _poser_confetti(ou: Vector2, couleur: Color, taille: float, force: float) -> void:
	var confetti: Node2D = _Confetti.new()
	confetti.position = ou
	confetti.couleur = couleur
	confetti.taille = taille
	confetti.vitesse = Vector2.from_angle(randf_range(-PI, 0.0)) * force  # vers le haut
	confetti.duree_vie = randf_range(0.6, 1.0)
	_calque_effets.add_child(confetti)


# --- Compteur (haut gauche) : mini-ballon + nombre de ballons éclatés --------
# Grand et vivant : c'est LE support d'apprentissage du comptage — il rebondit
# et prend un éclat de la couleur du ballon à chaque incrémentation.

func _creer_compteur() -> void:
	var ligne := HBoxContainer.new()
	ligne.position = Vector2(24, 16)
	ligne.add_theme_constant_override("separation", 14)
	add_child(ligne)

	var icone := _IconeBallon.new()
	icone.custom_minimum_size = Vector2(54, 78)
	ligne.add_child(icone)

	_label_compteur = Label.new()
	_label_compteur.text = "0"
	_label_compteur.add_theme_font_size_override("font_size", 80)
	_label_compteur.add_theme_color_override("font_color", Color.WHITE)
	_label_compteur.add_theme_color_override("font_outline_color", Color(0.10, 0.12, 0.10))
	_label_compteur.add_theme_constant_override("outline_size", 10)
	ligne.add_child(_label_compteur)


## Le nombre « vit » à chaque incrément : rebond + éclair de la couleur du ballon.
func _animer_compteur(couleur: Color) -> void:
	if _tween_compteur and _tween_compteur.is_valid():
		_tween_compteur.kill()
	_label_compteur.pivot_offset = _label_compteur.size / 2.0
	_label_compteur.add_theme_color_override("font_color", couleur.lightened(0.35))
	_tween_compteur = create_tween()
	_tween_compteur.tween_property(_label_compteur, "scale", Vector2.ONE * 1.3, 0.09)
	_tween_compteur.tween_property(_label_compteur, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween_compteur.parallel().tween_property(
		_label_compteur, "theme_override_colors/font_color", Color.WHITE, 0.30)


# --- Voix : compter à voix haute ----------------------------------------------

## Dit le total de ballons éclatés (« un », « deux », « douze »…) — geste +
## chiffre affiché + nombre entendu. Enregistrement lang/<code>/voix/chiffres/
## s'il existe (la voix de papa/maman peut compter !), synthèse vocale sinon.
func _prononcer_nombre() -> void:
	Voix.dire(self, str(_compteur), "chiffres")


# --- Sortie du jeu ------------------------------------------------------------

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
	Voix.arreter(self)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# En lancement direct (--app), la croix quitte CoccOs au lieu du retour bureau
	if Lancement.app_directe() == "" and ResourceLoader.exists(CHEMIN_BUREAU):
		get_tree().change_scene_to_file(CHEMIN_BUREAU)
	else:
		get_tree().quit()


## Mini-ballon blanc du compteur.
class _IconeBallon extends Control:
	func _draw() -> void:
		var c := Vector2(size.x / 2.0, size.y * 0.38)
		var r := minf(size.x, size.y) * 0.42
		draw_set_transform(c, 0.0, Vector2(0.85, 1.0))
		draw_circle(Vector2.ZERO, r, Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_line(c + Vector2(0.0, r), c + Vector2(0.0, r + size.y * 0.3), Color.WHITE, 3.0)


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
