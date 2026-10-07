## La chasse aux lettres — troisième jeu clavier : LE pont clavier → souris.
## Des lettres flottent dans des bulles (montée douce, balancement) ; on les
## attrape de DEUX façons — en tapant la lettre au clavier OU en cliquant la
## bulle à la souris. Même récompense dans les deux cas : gerbe d'étoiles +
## la voix dit la lettre + elle rejoint le tableau blanc en bas.
## Les lettres et chiffres proposés sont COMPLÈTEMENT ALÉATOIRES (A-Z + 0-9) :
## un apprentissage de tout le clavier — retour Freddy 2026-07-06 (la pioche
## basée sur les mots rendait la construction de mots frustrante).
## Une bulle qui s'échappe par le haut disparaît sans bruit : aucun échec.
## Boutons du tableau : flèche = effacer une lettre, croix = tout effacer.
##
## Sur Android, AUCUN clavier dessiné (décision Fabrice 07-10, comme sous Linux) :
## c'est un jeu SOURIS, les bulles s'attrapent à la pointe du curseur.
##
## Sortie : bouton croix (haut droit) ou Échap.
## Activité AUTO-CONTENUE (briques chargées depuis le dossier de CE script).
extends Control

const Fond := preload("res://scripts/fond.gd")
const Voix := preload("res://scripts/voix.gd")
const CHEMIN_BUREAU := "res://scenes/bureau.tscn"
const Lancement := preload("res://scripts/lancement.gd")
const ViseePointe := preload("res://scripts/visee_pointe.gd")

const CARACTERES_CHASSE := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
const MAX_BULLES := 6
const CADENCE_LACHER := 2.2
const LONGUEUR_MAX_MOT := 14
const PAS_TRAINEE := 26.0
const COULEUR_BOUTON_QUITTER := Color(0.85, 0.35, 0.30)
const COULEURS_LETTRES: Array[Color] = [
	Color(0.90, 0.30, 0.40), Color(0.95, 0.55, 0.15), Color(0.80, 0.65, 0.10),
	Color(0.25, 0.65, 0.35), Color(0.20, 0.60, 0.90), Color(0.45, 0.40, 0.85),
	Color(0.75, 0.35, 0.75), Color(0.20, 0.70, 0.65),
]
const COULEURS_TRAINEE: Array[Color] = [
	Color(1.0, 0.9, 0.35), Color(1.0, 1.0, 1.0), Color(1.0, 0.75, 0.25),
]

# Briques de l'activité, chargées relativement au dossier de ce script
var _Etoile: GDScript
var _Anneau: GDScript
var _Sons: GDScript

var _pioche := []  # lettres proposées (tirées des mots à apprendre)
var _mot := ""
var _label_mot: Label
var _calque_bulles: Node2D
var _calque_effets: Node2D
var _curseur: Node2D
var _lecteurs := {}
var _dernier_point := Vector2.ZERO
var _distance_cumulee := 0.0


func _ready() -> void:
	_charger_briques()
	Fond.appliquer(self)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	_calque_bulles = Node2D.new()
	add_child(_calque_bulles)
	_calque_effets = Node2D.new()
	add_child(_calque_effets)

	_creer_tableau()
	_creer_bouton_quitter()

	var dossier: String = (get_script() as GDScript).resource_path.get_base_dir()
	_curseur = (load(dossier + "/curseur.gd") as GDScript).new()
	add_child(_curseur)
	_curseur.position = get_viewport().get_mouse_position()
	_dernier_point = _curseur.position
	_brancher_visee()

	_creer_lecteurs()
	Voix.amorcer()  # natif : voix prête tout de suite ; web : résolue à la volée
	_construire_pioche()

	var minuterie := Timer.new()
	minuterie.wait_time = CADENCE_LACHER
	minuterie.timeout.connect(_lacher_bulle)
	add_child(minuterie)
	minuterie.start()
	for i in 3:
		get_tree().create_timer(0.3 + 0.6 * float(i)).timeout.connect(_lacher_bulle)


func _charger_briques() -> void:
	var dossier: String = (get_script() as GDScript).resource_path.get_base_dir()
	_Etoile = load(dossier + "/etoile.gd")
	_Anneau = load(dossier + "/anneau.gd")
	_Sons = load(dossier + "/sons.gd")


func _creer_lecteurs() -> void:
	var flux := {"pop": _Sons.pop_joyeux(), "tic": _Sons.tic()}
	for nom in flux:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux[nom]
		lecteur.max_polyphony = 4
		add_child(lecteur)
		_lecteurs[nom] = lecteur


## Voix française du système, résolue PARESSEUSEMENT et mise en cache (les voix
## du navigateur se chargent en asynchrone : liste vide au démarrage sur le web).
## Repli : n'importe quelle voix disponible. "" si le système n'a aucune voix.
## La pioche = tout l'alphabet + les chiffres, à égalité — on explore
## l'ensemble du clavier (le travail des mots, c'est le jeu « Les mots »).
func _construire_pioche() -> void:
	_pioche = []
	for i in CARACTERES_CHASSE.length():
		_pioche.append(CARACTERES_CHASSE[i])


# --- Les bulles ---------------------------------------------------------------

func _lacher_bulle() -> void:
	if _calque_bulles.get_child_count() >= MAX_BULLES:
		return
	var taille := get_viewport_rect().size
	var bulle := _BulleLettre.new()
	bulle.lettre = _pioche.pick_random()
	bulle.couleur = COULEURS_LETTRES[bulle.lettre.unicode_at(0) % COULEURS_LETTRES.size()]
	bulle.vitesse = randf_range(35.0, 65.0)
	bulle.amplitude = randf_range(14.0, 30.0)
	bulle.frequence = randf_range(0.6, 1.1)
	bulle.position = Vector2(randf_range(90.0, taille.x - 90.0), taille.y + 60.0)
	_calque_bulles.add_child(bulle)


## Attraper une bulle (au clavier ou à la souris) — même fête dans les deux cas.
func _attraper(bulle: Node2D) -> void:
	var anneau: Node2D = _Anneau.new()
	anneau.position = bulle.position
	anneau.couleur = bulle.couleur
	anneau.rayon_max = 70.0
	_calque_effets.add_child(anneau)
	for i in 8:
		var direction := Vector2.from_angle(randf() * TAU)
		_poser_etoile(bulle.position, bulle.couleur, randf_range(14, 22),
			direction * randf_range(120, 300), 350.0, randf_range(0.6, 0.9))
	_prononcer(bulle.lettre)
	_ajouter_au_mot(bulle.lettre)
	bulle.queue_free()


## Android : le doigt déplace le curseur, la POINTE vise (bulles, boutons du tableau, croix) — cf. visee_pointe.gd.
func _brancher_visee() -> void:
	var visee: Node = ViseePointe.new()
	visee.curseur = _curseur
	add_child(visee)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_quitter()
		return
	if event is InputEventMouseMotion:
		_curseur.position = event.position
		_distance_cumulee += event.position.distance_to(_dernier_point)
		_dernier_point = event.position
		if _distance_cumulee >= PAS_TRAINEE:
			_distance_cumulee = 0.0
			_poser_etoile(
				event.position + Vector2(randf_range(-10, 10), randf_range(-10, 10)),
				COULEURS_TRAINEE.pick_random(), randf_range(13, 19),
				Vector2(0, randf_range(20, 60)), 60.0, randf_range(0.5, 0.8))
		return
	if event is InputEventMouseButton and event.pressed:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			# Tap Android : aucun mouvement émulé, seul ce clic (déjà ramené à la pointe) → le curseur s'y pose
			_curseur.position = event.position
			_dernier_point = event.position
		_curseur.pulser()
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_curseur.zoomer(1)
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_curseur.zoomer(-1)
			return
		# Clic : la bulle touchée est attrapée ; sinon petit scintillement
		var bulles := _calque_bulles.get_children()
		for i in range(bulles.size() - 1, -1, -1):
			if bulles[i].contient(event.position):
				_attraper(bulles[i])
				return
		_lecteurs["tic"].play()
		for i in 3:
			var direction := Vector2.from_angle(randf() * TAU)
			_poser_etoile(event.position, Color(1.0, 0.95, 0.7), randf_range(8, 12),
				direction * randf_range(60, 140), 150.0, randf_range(0.4, 0.6))
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_BACKSPACE:
		_effacer_derniere()
		return
	# Taper une lettre ou un chiffre attrape la plus ancienne bulle qui le porte
	var caractere := _caractere_de(event)
	if caractere == "":
		return
	for bulle in _calque_bulles.get_children():
		if bulle.lettre == caractere:
			_attraper(bulle)
			return
	# Lettre absente de l'écran : rien — aucune touche ne punit


## Le caractère qu'une touche attrape. Les chiffres se lisent à la POSITION de
## la touche (rangée du haut + pavé numérique) : sur un AZERTY physique, la
## rangée des chiffres envoie & é " ' ( … sans Maj — par le caractère seul, un
## enfant ne peut jamais attraper un chiffre (retour du test d'Isabella,
## 2026-07-09).
static func _caractere_de(event: InputEventKey) -> String:
	if event.physical_keycode >= KEY_0 and event.physical_keycode <= KEY_9:
		return String.chr(event.physical_keycode)  # KEY_0..KEY_9 = codes ASCII
	if event.physical_keycode >= KEY_KP_0 and event.physical_keycode <= KEY_KP_9:
		return String.num_int64(event.physical_keycode - KEY_KP_0)
	if event.unicode == 0:
		return ""
	return char(event.unicode).to_upper()


# --- Le tableau blanc (la récolte) ---------------------------------------------

func _creer_tableau() -> void:
	var conteneur := CenterContainer.new()
	conteneur.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	conteneur.offset_top = -128.0
	conteneur.offset_bottom = -20.0
	add_child(conteneur)

	var ligne := HBoxContainer.new()
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	ligne.add_theme_constant_override("separation", 16)
	conteneur.add_child(ligne)

	var tableau := PanelContainer.new()
	tableau.custom_minimum_size = Vector2(620, 92)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.995, 0.995, 0.98)
	style.set_corner_radius_all(18)
	style.set_border_width_all(5)
	style.border_color = Color(0.60, 0.66, 0.72)
	style.shadow_size = 8
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	tableau.add_theme_stylebox_override("panel", style)
	ligne.add_child(tableau)

	_label_mot = Label.new()
	_label_mot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_mot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_mot.add_theme_font_size_override("font_size", 54)
	_label_mot.add_theme_color_override("font_color", Color(0.16, 0.22, 0.34))
	tableau.add_child(_label_mot)

	var btn_retour_arriere := _creer_bouton_rond(Color(0.40, 0.50, 0.65))
	var fleche := _IconeRetourArriere.new()
	fleche.set_anchors_preset(Control.PRESET_FULL_RECT)
	fleche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_retour_arriere.add_child(fleche)
	btn_retour_arriere.pressed.connect(_effacer_derniere)
	ligne.add_child(btn_retour_arriere)

	var btn_effacer := _creer_bouton_rond(Color(0.85, 0.45, 0.30))
	var croix := _IconeCroix.new()
	croix.set_anchors_preset(Control.PRESET_FULL_RECT)
	croix.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_effacer.add_child(croix)
	btn_effacer.pressed.connect(func() -> void:
		_mot = ""
		_label_mot.text = "")
	ligne.add_child(btn_effacer)


func _ajouter_au_mot(caractere: String) -> void:
	_mot += caractere
	if _mot.length() > LONGUEUR_MAX_MOT:
		_mot = _mot.substr(_mot.length() - LONGUEUR_MAX_MOT)
	_label_mot.text = _mot


func _effacer_derniere() -> void:
	if _mot.is_empty():
		return
	_mot = _mot.substr(0, _mot.length() - 1)
	_label_mot.text = _mot


func _creer_bouton_rond(couleur: Color) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(64, 64)
	btn.focus_mode = Control.FOCUS_NONE
	for etat in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = couleur
		if etat == "hover":
			style.bg_color = couleur.lightened(0.15)
		elif etat == "pressed":
			style.bg_color = couleur.darkened(0.15)
		style.set_corner_radius_all(32)
		btn.add_theme_stylebox_override(etat, style)
	return btn


## Enregistrement (lang/<code>/voix/) s'il existe, synthèse vocale sinon.
func _prononcer(texte: String) -> void:
	if "0123456789".contains(texte):
		Voix.dire(self, texte, "chiffres")
	else:
		Voix.dire(self, texte, "lettres")


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


# --- Sortie du jeu ----------------------------------------------------------------

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


## Bulle-lettre flottante : corps de bulle de savon (image de Freddy,
## assets/chasse/bulle.png — reflets faits main dans GIMP) cerclé de couleur,
## lettre colorée. Repli : disque blanc dessiné si l'image manque.
class _BulleLettre extends Node2D:
	const CHEMIN_BULLE := "res://assets/chasse/bulle.png"
	const RAYON_GALET := 0.66  # fraction du rayon de la bulle : couvre le caractère
	const COULEUR_GALET := Color(0.99, 0.98, 0.94, 0.85)
	const EPAISSEUR_LISERE := 6
	# Godot met les ressources chargées en cache : load() par bulle est gratuit
	# (une statique retiendrait la texture à la fermeture → fuite signalée)
	var texture_bulle: Texture2D = null

	var lettre := "A"
	var couleur := Color(0.3, 0.6, 0.9)
	var rayon := 46.0
	var vitesse := 50.0
	var amplitude := 20.0
	var frequence := 0.8

	var _x_base := 0.0
	var _temps := 0.0

	func _ready() -> void:
		_x_base = position.x
		_temps = randf() * TAU
		scale = Vector2.ONE * 0.2
		var animation := create_tween()
		animation.tween_property(self, "scale", Vector2.ONE, 0.4) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func _process(delta: float) -> void:
		_temps += delta
		position.y -= vitesse * delta
		position.x = _x_base + sin(_temps * frequence) * amplitude
		if position.y < -rayon * 2.0:
			queue_free()  # échappée par le haut : aucun échec

	func contient(point: Vector2) -> bool:
		return point.distance_to(position) <= rayon * 1.25  # marge petites mains

	func _draw() -> void:
		if texture_bulle == null and ResourceLoader.exists(CHEMIN_BULLE):
			texture_bulle = load(CHEMIN_BULLE)
		if texture_bulle != null:
			# Corps de bulle de savon (image) + anneau de couleur par-dessus
			var cote := (rayon + 5.0) * 2.0
			draw_texture_rect(texture_bulle, Rect2(Vector2(-cote / 2.0, -cote / 2.0),
				Vector2(cote, cote)), false)
			draw_arc(Vector2.ZERO, rayon + 2.0, 0.0, TAU, 48,
				Color(couleur.darkened(0.15), 0.9), 5.0, true)
		else:
			# Repli : le dessin d'origine (disque blanc cerclé)
			draw_circle(Vector2.ZERO, rayon + 5.0, Color(couleur.darkened(0.15), 0.95))
			draw_circle(Vector2.ZERO, rayon, Color(0.99, 0.98, 0.94, 0.96))
		# Galet crème semi-opaque derrière le caractère : il le détache de la verdure
		# vue à travers la bulle (retour Fabrice 07-10 : bulles peu contrastées)
		draw_circle(Vector2.ZERO, rayon * RAYON_GALET, COULEUR_GALET)
		var police := ThemeDB.fallback_font
		var taille := int(rayon * 1.15)
		var hauteur := police.get_ascent(taille) - police.get_descent(taille)
		# Liseré foncé de la même teinte : contraste de LUMINANCE (daltonien) même pour
		# les lettres jaunes et orangées, que le galet clair seul ne détache pas assez
		draw_string_outline(police, Vector2(-rayon, hauteur / 2.0), lettre,
			HORIZONTAL_ALIGNMENT_CENTER, rayon * 2.0, taille, EPAISSEUR_LISERE, couleur.darkened(0.55))
		draw_string(police, Vector2(-rayon, hauteur / 2.0), lettre,
			HORIZONTAL_ALIGNMENT_CENTER, rayon * 2.0, taille, couleur)


## Flèche « retour arrière » (efface une lettre du tableau).
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


## Croix « tout effacer ».
class _IconeCroix extends Control:
	func _draw() -> void:
		var centre := size / 2.0
		var u := minf(size.x, size.y) * 0.24
		draw_line(centre + Vector2(-u, -u), centre + Vector2(u, u), Color.WHITE, 6.0)
		draw_line(centre + Vector2(-u, u), centre + Vector2(u, -u), Color.WHITE, 6.0)


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
