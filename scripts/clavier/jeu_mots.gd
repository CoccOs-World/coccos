## Les mots — deuxième jeu clavier (idée Freddy, inspirée par Isabella).
## Un mot de la liste « mots à apprendre » (réglages adulte → Clavier) s'affiche
## en tuiles ; l'enfant retape ses lettres dans l'ordre :
##   - lettre juste  → la tuile se colore + gerbe d'étoiles + la voix dit la lettre
##   - lettre fausse → rien (ni rouge ni son : la bonne lettre seule fait avancer)
##   - mot complété  → explosion de fleurs + pop joyeux + la voix dit le mot,
##                     puis un nouveau mot arrive (au hasard, différent du courant)
## Le mot est prononcé à son apparition. Aucun échec, aucun chrono, aucun texte.
## La souris garde ses effets (curseur OS, traînée, clics) — cohérence de l'OS.
##
## Sortie : bouton croix (haut droit) ou Échap.
## Activité AUTO-CONTENUE (briques chargées depuis le dossier de CE script).
extends Control

const Fond := preload("res://scripts/fond.gd")
const Voix := preload("res://scripts/voix.gd")
const Tactile := preload("res://scripts/tactile.gd")
const CHEMIN_BUREAU := "res://scenes/bureau.tscn"
const Lancement := preload("res://scripts/lancement.gd")
const CHEMIN_CONFIG := "user://config.cfg"

const MOTS_DEFAUT := ["ISABELLA", "PAPA", "MAMAN"]
const COULEUR_BOUTON_QUITTER := Color(0.85, 0.35, 0.30)
const PAS_TRAINEE := 26.0
const COULEURS_LETTRES: Array[Color] = [
	Color(0.90, 0.30, 0.40), Color(0.95, 0.55, 0.15), Color(0.80, 0.65, 0.10),
	Color(0.25, 0.65, 0.35), Color(0.20, 0.60, 0.90), Color(0.45, 0.40, 0.85),
	Color(0.75, 0.35, 0.75), Color(0.20, 0.70, 0.65),
]
const COULEURS_TRAINEE: Array[Color] = [
	Color(1.0, 0.9, 0.35), Color(1.0, 1.0, 1.0), Color(1.0, 0.75, 0.25),
]
const COULEURS_FLEURS: Array[Color] = [
	Color(1.0, 0.45, 0.7), Color(0.8, 0.5, 0.95), Color(0.5, 0.6, 1.0),
	Color(1.0, 0.6, 0.85),
]

# Briques de l'activité, chargées relativement au dossier de ce script
var _Etoile: GDScript
var _Fleur: GDScript
var _Anneau: GDScript
var _Sons: GDScript
var _Clavier: GDScript

var _clavier: Control = null
var _mots := []
var _mot_cible := ""
var _position := 0
var _en_transition := false
var _banque: RefCounted = null   # la banque du classeur (mots + pictos)
var _picto_mot: Control = null   # le pictogramme montré à la complétion

var _ligne_tuiles: HBoxContainer
var _tuiles := []  # [PanelContainer, StyleBoxFlat, Label] par lettre
var _calque_effets: Node2D
var _curseur: Node2D
var _lecteurs := {}
var _dernier_point := Vector2.ZERO
var _distance_cumulee := 0.0


func _ready() -> void:
	_charger_briques()
	Fond.appliquer(self)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_calque_effets = Node2D.new()
	add_child(_calque_effets)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	if Tactile.actif():
		centre.offset_bottom = -_Clavier.HAUTEUR  # les tuiles remontent au-dessus du clavier
	add_child(centre)
	_ligne_tuiles = HBoxContainer.new()
	_ligne_tuiles.add_theme_constant_override("separation", 14)
	centre.add_child(_ligne_tuiles)

	_creer_bouton_quitter()
	var dossier: String = (get_script() as GDScript).resource_path.get_base_dir()
	_curseur = (load(dossier + "/curseur.gd") as GDScript).new()
	add_child(_curseur)
	_curseur.position = get_viewport().get_mouse_position()
	_dernier_point = _curseur.position

	_creer_lecteurs()
	Voix.amorcer()  # natif : voix prête tout de suite ; web : résolue à la volée
	if Tactile.actif():
		_clavier = _Clavier.new()  # clavier CoccOs dessiné (remplace celui du système)
		add_child(_clavier)
		_curseur.move_to_front()  # le curseur-doigt reste visible sur les touches
	_charger_mots()
	_nouveau_mot()


func _charger_briques() -> void:
	var dossier: String = (get_script() as GDScript).resource_path.get_base_dir()
	_Etoile = load(dossier + "/etoile.gd")
	_Fleur = load(dossier + "/fleur.gd")
	_Anneau = load(dossier + "/anneau.gd")
	_Sons = load(dossier + "/sons.gd")
	_Clavier = load(dossier + "/clavier_virtuel.gd")


func _creer_lecteurs() -> void:
	var flux := {
		"pop": _Sons.pop_joyeux(),
		"carillon": _Sons.carillon(),
		"boum": _Sons.boum_doux(),
		"tic": _Sons.tic(),
	}
	for nom in flux:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux[nom]
		lecteur.max_polyphony = 4
		add_child(lecteur)
		_lecteurs[nom] = lecteur


## Les mots du jeu = liste manuelle (réglages adulte, [clavier] mots)
## + LES MOTS DU CLASSEUR (idée Freddy 2026-07-08 : le classeur est LA banque
## de vocabulaire de la plateforme — catégories Personnes avec photos, animaux,
## aliments… taper le mot qu'on sait « dire » en vignette = le pont
## communication → écriture). Filtre des mots tapables : un seul mot, lettres
## uniquement, ≤ 12 caractères ; en mode tactile, les accentués sortent aussi
## (le clavier dessiné n'a pas d'accents).
func _charger_mots() -> void:
	var cfg := ConfigFile.new()
	_mots = []
	if cfg.load(CHEMIN_CONFIG) == OK:
		for mot in cfg.get_value("clavier", "mots", PackedStringArray()):
			var propre: String = String(mot).strip_edges().to_upper()
			if propre != "" and not propre in _mots:
				_mots.append(propre)
	_banque = (load("res://scripts/classeur/banque.gd") as GDScript).charger()
	for id in _banque.ids_vignettes():
		var mot: String = String(_banque.mot(id)).strip_edges().to_upper()
		if _mot_tapable(mot) and not mot in _mots:
			_mots.append(mot)
	if _mots.is_empty():
		_mots = MOTS_DEFAUT.duplicate()


## Un mot du classeur entre dans le jeu s'il se TAPE bien : un seul mot,
## lettres uniquement, pas trop long — et sans accents en mode tactile.
func _mot_tapable(mot: String) -> bool:
	if mot.length() < 2 or mot.length() > 12:
		return false
	var sans_accents := Tactile.actif()
	for i in mot.length():
		var caractere := mot[i]
		if not "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(caractere):
			if sans_accents or not "ÉÈÊËÀÂÄÎÏÔÖÙÛÜÇ".contains(caractere):
				return false
	return true


# --- Déroulé du jeu -----------------------------------------------------------

## Nouveau mot au hasard (différent du courant si possible), tuiles reconstruites.
func _nouveau_mot() -> void:
	if _picto_mot != null:
		_picto_mot.queue_free()  # l'image du mot précédent s'efface
		_picto_mot = null
	var candidat: String = _mots.pick_random()
	if _mots.size() > 1:
		while candidat == _mot_cible:
			candidat = _mots.pick_random()
	_mot_cible = candidat
	_position = 0
	for tuile in _tuiles:
		tuile[0].queue_free()
	_tuiles.clear()
	for i in _mot_cible.length():
		_tuiles.append(_creer_tuile(_mot_cible[i]))
	_maj_tuiles()
	_prononcer(_mot_cible)


func _creer_tuile(caractere: String) -> Array:
	var panneau := PanelContainer.new()
	panneau.custom_minimum_size = Vector2(88, 112)
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(18)
	style.set_border_width_all(5)
	panneau.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = caractere
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 68)
	panneau.add_child(label)
	_ligne_tuiles.add_child(panneau)
	return [panneau, style, label]


## Met à jour l'apparence des tuiles : faites (colorées), courante (bord jaune), à venir.
func _maj_tuiles() -> void:
	for i in _tuiles.size():
		var style: StyleBoxFlat = _tuiles[i][1]
		var label: Label = _tuiles[i][2]
		if i < _position:
			var couleur := COULEURS_LETTRES[_mot_cible.unicode_at(i) % COULEURS_LETTRES.size()]
			style.bg_color = couleur
			style.border_color = couleur.darkened(0.2)
			label.add_theme_color_override("font_color", Color.WHITE)
		else:
			style.bg_color = Color(0.99, 0.98, 0.94, 0.95)
			style.border_color = Color(1.0, 0.85, 0.2) if i == _position else Color(0.65, 0.70, 0.75)
			label.add_theme_color_override("font_color",
				Color(0.35, 0.42, 0.52) if i == _position else Color(0.65, 0.70, 0.75))


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
		_curseur.pulser()
		if _clavier and _clavier.contient(event.position):
			return  # le tap appartient au clavier dessiné : la touche fera le travail
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_curseur.zoomer(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_curseur.zoomer(-1)
		return
	if not (event is InputEventKey) or not event.pressed or event.echo or _en_transition:
		return
	if event.unicode == 0:
		return
	var caractere := char(event.unicode).to_upper()
	if _position < _mot_cible.length() and caractere == _mot_cible[_position]:
		_lettre_juste()
	# Lettre fausse : rien — ni rouge, ni son. La bonne lettre seule fait avancer.


## Lettre juste : la tuile se remplit, gerbe d'étoiles, la voix dit la lettre.
func _lettre_juste() -> void:
	var tuile: PanelContainer = _tuiles[_position][0]
	var centre_tuile: Vector2 = tuile.global_position + tuile.size / 2.0
	var couleur := COULEURS_LETTRES[_mot_cible.unicode_at(_position) % COULEURS_LETTRES.size()]
	for i in 6:
		var direction := Vector2.from_angle(randf() * TAU)
		_poser_etoile(centre_tuile, couleur, randf_range(12, 18),
			direction * randf_range(100, 220), 300.0, randf_range(0.5, 0.8))
	_prononcer(_mot_cible[_position])
	_position += 1
	_maj_tuiles()
	if _position >= _mot_cible.length():
		_mot_complete()


## Mot complété : explosion de fleurs + pop joyeux + la voix dit le mot —
## et si le mot a une vignette au classeur, SON IMAGE apparaît (taper « MAMAN »
## fait apparaître la photo de maman : le mot écrit devient la chose).
func _mot_complete() -> void:
	_en_transition = true
	_lecteurs["pop"].play()
	_montrer_picto_du_mot()
	for tuile_infos in _tuiles:
		var tuile: PanelContainer = tuile_infos[0]
		var ou: Vector2 = tuile.global_position + tuile.size / 2.0
		_poser_fleur(ou, randf_range(16, 22), randf_range(0.0, 0.25))
		for i in 3:
			var angle := TAU * randf()
			_poser_fleur(ou + Vector2.from_angle(angle) * randf_range(40, 90),
				randf_range(10, 16), randf_range(0.1, 0.5))
	await get_tree().create_timer(0.7).timeout
	if not is_inside_tree():
		return
	_prononcer(_mot_cible)
	await get_tree().create_timer(1.8).timeout
	if not is_inside_tree():
		return
	_nouveau_mot()
	_en_transition = false


## L'image de la vignette du classeur portant ce mot, en douceur au-dessus des
## tuiles (rien si le mot n'a pas de vignette — la fête aux fleurs suffit).
func _montrer_picto_du_mot() -> void:
	if _banque == null:
		return
	for id in _banque.ids_vignettes():
		if String(_banque.mot(id)).strip_edges().to_upper() != _mot_cible:
			continue
		var texture: ImageTexture = _banque.texture(id)
		if texture == null:
			return
		_picto_mot = TextureRect.new()
		_picto_mot.texture = texture
		_picto_mot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_picto_mot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_picto_mot.size = Vector2(220, 220)
		_picto_mot.position = get_viewport_rect().size / 2.0 - Vector2(110, 340)
		_picto_mot.pivot_offset = Vector2(110, 110)
		_picto_mot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_picto_mot)
		_picto_mot.scale = Vector2.ZERO
		var animation := create_tween()
		animation.tween_property(_picto_mot, "scale", Vector2.ONE, 0.4) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		return


## Enregistrement (lang/<code>/voix/) s'il existe, synthèse vocale sinon.
func _prononcer(texte: String) -> void:
	if texte.length() == 1:
		Voix.dire(self, texte, "lettres")
	else:
		Voix.dire(self, texte, "mots")


# --- Fabriques d'effets ---------------------------------------------------------

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
