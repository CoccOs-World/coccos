## Découverte de la souris — écran unique du jeu (v0.2 : bouton Quitter + activité auto-contenue).
## L'enfant bouge la souris et clique : chaque bouton déclenche une animation
## et un son différents. Aucun échec possible, aucun texte.
##
## - Déplacement      → traînée d'étoiles dorées (toujours — « plus léger à l'écran »)
## - Clic gauche      → ronde de fleurs qui éclosent (+ pop joyeux)
## - Clic droit       → explosion d'étoiles + halo doré (+ carillon)
##   (pairing imaginaire Freddy 2026-07-06 : pop ↔ fleurs, carillon ↔ étoiles ;
##    inversion gauche/droite appliquée le 2026-07-07)
## - Clic molette     → feu d'artifice arc-en-ciel
## - Molette (roulée) → le curseur grossit / rétrécit
## - Bouton MAINTENU pendant le déplacement (découverte du glisser) :
##     gauche → chapelet de fleurs · droit → ondulations dorées ·
##     molette → traînée arc-en-ciel — et le schéma reste illuminé.
## Le schéma de souris en bas à droite illumine le bouton réellement pressé.
##
## Sortie : bouton croix (haut droit) ou Échap — retourne au bureau enfant
## si la scène res://scenes/bureau.tscn existe (jeu intégré), sinon quitte (jeu autonome).
##
## Activité AUTO-CONTENUE : les briques (étoile, fleur, anneau, curseur, schéma,
## sons) sont chargées relativement au dossier de CE script — le même code
## fonctionne quel que soit l'emplacement du dossier dans un projet.
## Seule dépendance externe partagée : res://scripts/fond.gd (fond prairie).
extends Control

const Fond := preload("res://scripts/fond.gd")
const Tactile := preload("res://scripts/tactile.gd")
const CHEMIN_BUREAU := "res://scenes/bureau.tscn"
const Lancement := preload("res://scripts/lancement.gd")
const ViseePointe := preload("res://scripts/visee_pointe.gd")

const PAS_TRAINEE := 26.0  # distance (px) entre deux étoiles de la traînée

const COULEURS_TRAINEE: Array[Color] = [
	Color(1.0, 0.9, 0.35), Color(1.0, 1.0, 1.0), Color(1.0, 0.75, 0.25),
]
const COULEURS_ETOILES: Array[Color] = [
	Color(1.0, 0.85, 0.25), Color(1.0, 0.6, 0.15), Color(1.0, 0.95, 0.6),
	Color(1.0, 1.0, 1.0), Color(1.0, 0.45, 0.35),
]
const COULEURS_FLEURS: Array[Color] = [
	Color(1.0, 0.45, 0.7), Color(0.8, 0.5, 0.95), Color(0.5, 0.6, 1.0),
	Color(1.0, 0.6, 0.85),
]
const COULEURS_FEU: Array[Color] = [
	Color(1.0, 0.35, 0.35), Color(1.0, 0.65, 0.2), Color(1.0, 0.95, 0.35),
	Color(0.45, 0.9, 0.45), Color(0.35, 0.8, 1.0), Color(0.75, 0.5, 1.0),
]
# Le schéma s'illumine de la couleur de l'effet : rose fleurs à gauche,
# jaune étoiles à droite (inversion 2026-07-07)
const COULEUR_SCHEMA_GAUCHE := Color(1.0, 0.4, 0.7)
const COULEUR_SCHEMA_DROIT := Color(1.0, 0.8, 0.2)
const COULEUR_SCHEMA_MOLETTE := Color(0.3, 0.9, 1.0)
const COULEUR_BOUTON_QUITTER := Color(0.85, 0.35, 0.30)

# Briques de l'activité, chargées relativement au dossier de ce script
var _Etoile: GDScript
var _Fleur: GDScript
var _Anneau: GDScript
var _Curseur: GDScript
var _SchemaSouris: GDScript
var _Sons: GDScript

var _calque_effets: Node2D
var _curseur: Node2D
var _schema: Node2D
var _lecteurs := {}
var _dernier_point := Vector2.ZERO
var _distance_cumulee := 0.0
var _bouton_tenu := 0  # bouton actuellement maintenu (MOUSE_BUTTON_*) — 0 = aucun


func _ready() -> void:
	_charger_briques()
	Fond.appliquer(self)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	# Mode tactile : l'appui long du doigt vaut clic droit (explosion d'étoiles)
	var tactile: Node = Tactile.new()
	add_child(tactile)
	tactile.appui_long.connect(_clic_droit)

	# Ordre des enfants = ordre d'affichage : effets < schéma < bouton < curseur (toujours dessus)
	_calque_effets = Node2D.new()
	add_child(_calque_effets)

	_schema = _SchemaSouris.new()
	add_child(_schema)
	_placer_schema()
	get_viewport().size_changed.connect(_placer_schema)

	_creer_bouton_quitter()

	_curseur = _Curseur.new()
	add_child(_curseur)
	_dernier_point = get_viewport().get_mouse_position()
	_curseur.position = _dernier_point
	_brancher_visee()

	_creer_lecteurs()


## Charge étoile/fleur/anneau/curseur/schéma/sons depuis le dossier du script.
func _charger_briques() -> void:
	var dossier: String = (get_script() as GDScript).resource_path.get_base_dir()
	_Etoile = load(dossier + "/etoile.gd")
	_Fleur = load(dossier + "/fleur.gd")
	_Anneau = load(dossier + "/anneau.gd")
	_Curseur = load(dossier + "/curseur.gd")
	_SchemaSouris = load(dossier + "/schema_souris.gd")
	_Sons = load(dossier + "/sons.gd")


func _creer_lecteurs() -> void:
	var flux := {
		"gauche": _Sons.pop_joyeux(),
		"droit": _Sons.carillon(),
		"molette": _Sons.boum_doux(),
		"tic": _Sons.tic(),
	}
	for nom in flux:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux[nom]
		lecteur.max_polyphony = 4  # clics rapprochés = sons superposés, pas coupés
		add_child(lecteur)
		_lecteurs[nom] = lecteur


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_quitter()
		return
	if event is InputEventMouseMotion:
		_sur_mouvement(event.position)
	elif event is InputEventMouseButton:
		if event.pressed:
			if event.device == InputEvent.DEVICE_ID_EMULATION:
				# Tap Android : aucun mouvement émulé, seul ce clic (déjà ramené à la pointe) → le curseur s'y pose
				_curseur.position = event.position
				_dernier_point = event.position
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					_bouton_tenu = MOUSE_BUTTON_LEFT
					_clic_gauche(event.position)
				MOUSE_BUTTON_RIGHT:
					_bouton_tenu = MOUSE_BUTTON_RIGHT
					_clic_droit(event.position)
				MOUSE_BUTTON_MIDDLE:
					_bouton_tenu = MOUSE_BUTTON_MIDDLE
					_clic_molette(event.position)
				MOUSE_BUTTON_WHEEL_UP:
					_molette_roulee(1)
				MOUSE_BUTTON_WHEEL_DOWN:
					_molette_roulee(-1)
		elif event.button_index == _bouton_tenu:
			# Relâchement du bouton tenu → retour à la traînée normale
			_bouton_tenu = 0


## Android : le doigt déplace le curseur, la POINTE vise (clics, croix) — cf. visee_pointe.gd.
func _brancher_visee() -> void:
	var visee: Node = ViseePointe.new()
	visee.curseur = _curseur
	add_child(visee)


# --- Sortie du jeu ---------------------------------------------------------

## Bouton croix rond en haut à droite — la seule « porte de sortie » visible.
func _creer_bouton_quitter() -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(72, 72)
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.position = Vector2(-88, 16)
	btn.focus_mode = Control.FOCUS_NONE  # pas de vol de focus dans un jeu tout-souris
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


## Retour au bureau enfant si le jeu est intégré, sinon fermeture (jeu autonome).
func _quitter() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# En lancement direct (--app), la croix quitte CoccOs au lieu du retour bureau
	if Lancement.app_directe() == "" and ResourceLoader.exists(CHEMIN_BUREAU):
		get_tree().change_scene_to_file(CHEMIN_BUREAU)
	else:
		get_tree().quit()


# --- Déplacement : traînée (différente selon le bouton maintenu) ----------

func _sur_mouvement(position_souris: Vector2) -> void:
	_curseur.position = position_souris
	_distance_cumulee += position_souris.distance_to(_dernier_point)
	_dernier_point = position_souris
	if _distance_cumulee < PAS_TRAINEE:
		return
	_distance_cumulee = 0.0
	var autour := position_souris + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	match _bouton_tenu:
		MOUSE_BUTTON_LEFT:
			# Gauche maintenu : chapelet de fleurs qui éclosent sur le passage
			_poser_fleur(autour, randf_range(9.0, 14.0), 0.0)
			_schema.allumer("gauche", COULEUR_SCHEMA_GAUCHE)
		MOUSE_BUTTON_RIGHT:
			# Droit maintenu : ondulations dorées le long du chemin
			_poser_anneau(autour, Color(1.0, 0.85, 0.3), randf_range(28.0, 42.0), 0.0)
			_schema.allumer("droit", COULEUR_SCHEMA_DROIT)
		MOUSE_BUTTON_MIDDLE:
			# Molette maintenue : traînée arc-en-ciel
			_poser_etoile(autour, COULEURS_FEU.pick_random(), randf_range(14, 20),
				Vector2(0, randf_range(20, 60)), 60.0, randf_range(0.5, 0.8))
			_schema.allumer("molette", COULEUR_SCHEMA_MOLETTE)
		_:
			# Rien de maintenu : traînée d'étoiles dorées habituelle
			_poser_etoile(autour, COULEURS_TRAINEE.pick_random(), randf_range(13, 19),
				Vector2(0, randf_range(20, 60)), 60.0, randf_range(0.5, 0.8))


# --- Clic gauche : ronde de fleurs (+ pop joyeux) --------------------------

func _clic_gauche(ou: Vector2) -> void:
	_lecteurs["gauche"].play()
	_curseur.pulser()
	_schema.allumer("gauche", COULEUR_SCHEMA_GAUCHE)
	_poser_fleur(ou, randf_range(18, 24), 0.0)
	for i in 6:
		var angle := TAU * float(i) / 6.0 + randf_range(-0.2, 0.2)
		var autour := ou + Vector2.from_angle(angle) * randf_range(50, 70)
		_poser_fleur(autour, randf_range(12, 18), 0.06 + 0.06 * float(i))


# --- Clic droit : explosion d'étoiles + halo doré (+ carillon) -------------

func _clic_droit(ou: Vector2) -> void:
	_lecteurs["droit"].play()
	_curseur.pulser()
	_schema.allumer("droit", COULEUR_SCHEMA_DROIT)
	_poser_anneau(ou, Color(1.0, 0.85, 0.3), 80.0, 0.0)
	for i in 14:
		var direction := Vector2.from_angle(randf() * TAU)
		_poser_etoile(ou, COULEURS_ETOILES.pick_random(), randf_range(22, 34),
			direction * randf_range(160, 420), 480.0, randf_range(0.7, 1.1))


# --- Clic molette : feu d'artifice arc-en-ciel ----------------------------

func _clic_molette(ou: Vector2) -> void:
	_lecteurs["molette"].play()
	_curseur.pulser()
	_schema.allumer("molette", COULEUR_SCHEMA_MOLETTE)
	for i in 3:
		_poser_anneau(ou, COULEURS_FEU[i * 2], 60.0 + 45.0 * float(i), 0.08 * float(i))
	for i in 18:
		var direction := Vector2.from_angle(randf() * TAU)
		_poser_etoile(ou, COULEURS_FEU.pick_random(), randf_range(18, 28),
			direction * randf_range(220, 500), 120.0, randf_range(0.8, 1.2))


# --- Molette roulée : le curseur grossit / rétrécit -----------------------

func _molette_roulee(direction: int) -> void:
	_lecteurs["tic"].play()
	_curseur.zoomer(direction)
	_schema.allumer("molette", COULEUR_SCHEMA_MOLETTE)


# --- Fabriques d'effets ----------------------------------------------------

func _poser_etoile(ou: Vector2, couleur: Color, rayon: float,
		vitesse: Vector2, gravite: float, duree_vie: float) -> void:
	var etoile: Node2D = _Etoile.new()
	etoile.position = ou
	etoile.couleur = couleur
	etoile.rayon = rayon
	etoile.vitesse = vitesse
	etoile.gravite = gravite
	etoile.rotation_vitesse = randf_range(-6.0, 6.0)
	etoile.duree_vie = duree_vie
	_calque_effets.add_child(etoile)


func _poser_fleur(ou: Vector2, taille: float, delai: float) -> void:
	var fleur: Node2D = _Fleur.new()
	fleur.position = ou
	fleur.couleur = COULEURS_FLEURS.pick_random()
	fleur.rayon = taille
	fleur.delai = delai
	_calque_effets.add_child(fleur)


func _poser_anneau(ou: Vector2, couleur: Color, rayon_max: float, delai: float) -> void:
	var anneau: Node2D = _Anneau.new()
	anneau.position = ou
	anneau.couleur = couleur
	anneau.rayon_max = rayon_max
	anneau.delai = delai
	_calque_effets.add_child(anneau)


func _placer_schema() -> void:
	_schema.position = get_viewport_rect().size - Vector2(85, 110)


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
