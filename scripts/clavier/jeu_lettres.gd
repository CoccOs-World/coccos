## Les lettres — premier jeu clavier (inspiré de l'application d'Isabella).
## L'enfant tape une touche : le caractère s'affiche en très grand dans une
## bulle carrée au centre de l'écran et une voix le prononce (synthèse vocale
## du système — silencieuse si indisponible). En dessous, le tableau blanc :
## les lettres s'accumulent — l'enfant voit son prénom se construire.
## Espace et ponctuation s'affichent aussi et sont prononcés par leur nom
## (« espace », « point », « virgule »… — ce que GCompris ne fait pas).
## Un petit trait bleu clignote dans le tableau, là où la prochaine lettre
## arrivera — le repère des champs de texte, visible même tableau vide.
## Ce trait (le caret) se déplace dans le mot : flèches gauche/droite, ou clic
## (tap sur Android) entre deux lettres. La lettre tapée s'INSÈRE au caret,
## retour arrière retire la lettre à sa gauche — une lettre oubliée se corrige
## sans tout effacer. Par défaut le caret reste en fin de mot (écrire à la suite).
## Retour arrière = efface le caractère avant le caret · bouton croix = efface tout.
## À gauche du tableau, le bouton au visage jaune qui parle : il prononce le
## mot écrit (rien si le tableau est vide).
## Majuscules partout, lettres accentuées et chiffres acceptés.
## Aucun échec possible, aucun chrono, aucun texte d'instruction.
##
## Sortie : bouton croix (haut droit) ou Échap — retour au bureau si
## res://scenes/bureau.tscn existe, sinon fermeture (jeu autonome).
##
## Activité AUTO-CONTENUE (patron du projet). Dépendances partagées tolérées :
## res://scripts/fond.gd, lang.gd et voix.gd. La voix passe par Voix.dire :
## enregistrement lang/<code>/voix/ s'il existe, sinon synthèse vocale
## (réglage projet audio/general/text_to_speech, activé dans project.godot).
extends Control

const Fond := preload("res://scripts/fond.gd")
const Lang := preload("res://scripts/lang.gd")
const Voix := preload("res://scripts/voix.gd")
const Tactile := preload("res://scripts/tactile.gd")
const CHEMIN_BUREAU := "res://scenes/bureau.tscn"
const Lancement := preload("res://scripts/lancement.gd")
const ViseePointe := preload("res://scripts/visee_pointe.gd")

const CARACTERES_ACCEPTES := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ÉÈÊËÀÂÄÎÏÔÖÙÛÜÇ"
## Caractères spéciaux : affichés dans la bulle ET prononcés par leur nom.
## caractère → clé de texte (les noms vivent dans lang/<code>/textes.xml).
const CLES_SPECIAUX := {
	" ": "car_espace", ".": "car_point", ",": "car_virgule", "!": "car_exclamation",
	"?": "car_interrogation", "'": "car_apostrophe", "-": "car_tiret",
	":": "car_deux_points", ";": "car_point_virgule", "(": "car_parenthese",
	")": "car_parenthese", "\"": "car_guillemet", "/": "car_barre", "+": "car_plus",
	"=": "car_egal", "*": "car_etoile", "@": "car_arobase", "_": "car_tiret_bas",
	"&": "car_et_commercial", "€": "car_euro", "$": "car_dollar", "%": "car_pour_cent",
	"#": "car_diese", "<": "car_inferieur", ">": "car_superieur",
}
## Ce que la bulle affiche pour certains caractères peu visibles.
const AFFICHAGES_SPECIAUX := {" ": "_"}
const LONGUEUR_MAX_MOT := 14  # au-delà, la ligne « glisse » (les plus anciennes sortent)
## Mode tactile : bulle de la lettre à côté du tableau, à la hauteur laissée par le clavier.
const BULLE_TACTILE_MIN := 120.0
const BULLE_TACTILE_MAX := 260.0
const MARGE_BULLE_TACTILE := 14.0
const FACTEUR_CURSEUR := 2.0  # le curseur de ce jeu, deux fois plus gros (demande Fabrice 2026-10-07)
const COULEUR_BOUTON_QUITTER := Color(0.85, 0.35, 0.30)
const COULEUR_BOUTON_DIRE := Color(0.30, 0.62, 0.45)   # vert doux : le bouton « dire le mot »
const COULEUR_PACMAN := Color(1.0, 0.85, 0.25)          # jaune : le visage qui parle
const COULEURS_LETTRES: Array[Color] = [
	Color(0.90, 0.30, 0.40), Color(0.95, 0.55, 0.15), Color(0.80, 0.65, 0.10),
	Color(0.25, 0.65, 0.35), Color(0.20, 0.60, 0.90), Color(0.45, 0.40, 0.85),
	Color(0.75, 0.35, 0.75), Color(0.20, 0.70, 0.65),
]

const PAS_TRAINEE := 26.0
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

# Briques de l'activité, chargées relativement au dossier de ce script
var _Etoile: GDScript
var _Fleur: GDScript
var _Anneau: GDScript
var _Sons: GDScript
var _Clavier: GDScript

var _clavier: Control = null
var _centre: CenterContainer       # contenu au-dessus du clavier dessiné
var _bulle: PanelContainer
var _style_bulle: StyleBoxFlat
var _label_lettre: Label
var _label_mot: Label
var _mot := ""
var _caret := 0                     # position d'écriture dans _mot (0 = avant la 1re lettre)
var _trait_ecriture: Control        # le curseur clignotant du tableau blanc
var _curseur: Node2D                # le gros curseur de souris (tout autre chose)
var _calque_effets: Node2D
var _lecteurs := {}
var _dernier_point := Vector2.ZERO
var _distance_cumulee := 0.0


func _ready() -> void:
	_charger_briques()
	Fond.appliquer(self)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN  # le curseur de l'OS remplace le système
	# Calque des effets souris : derrière la bulle et le tableau (l'écrit reste roi)
	_calque_effets = Node2D.new()
	add_child(_calque_effets)
	_creer_bulle_et_mot()
	_creer_bouton_quitter()
	_creer_curseur()
	_creer_lecteurs()
	Voix.amorcer()  # natif : voix prête tout de suite ; web : résolue à la volée

	# Mode tactile : appui long = clic droit (étoiles) + clavier CoccOs dessiné
	var tactile: Node = Tactile.new()
	add_child(tactile)
	tactile.appui_long.connect(_clic_droit)
	if Tactile.actif():
		_clavier = _Clavier.new()
		_clavier.curseur = _curseur  # touches remontées à portée de la POINTE
		_clavier.encombrement_change.connect(_ajuster_au_clavier)
		add_child(_clavier)
		_curseur.move_to_front()  # le curseur-doigt reste visible sur les touches


## Charge étoile/fleur/anneau/sons/curseur depuis le dossier du script.
func _charger_briques() -> void:
	var dossier: String = (get_script() as GDScript).resource_path.get_base_dir()
	_Etoile = load(dossier + "/etoile.gd")
	_Fleur = load(dossier + "/fleur.gd")
	_Anneau = load(dossier + "/anneau.gd")
	_Sons = load(dossier + "/sons.gd")
	_Clavier = load(dossier + "/clavier_virtuel.gd")


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
		lecteur.max_polyphony = 4
		add_child(lecteur)
		_lecteurs[nom] = lecteur


## Le gros curseur de l'OS (forme/taille des réglages), au-dessus de tout.
func _creer_curseur() -> void:
	var dossier: String = (get_script() as GDScript).resource_path.get_base_dir()
	_curseur = (load(dossier + "/curseur.gd") as GDScript).new()
	_curseur.facteur = FACTEUR_CURSEUR  # taille ×2, pointe toujours en (0, 0)
	add_child(_curseur)
	_curseur.position = get_viewport().get_mouse_position()
	_dernier_point = _curseur.position
	_brancher_visee()


## Voix française du système, résolue PARESSEUSEMENT et mise en cache.
## Sur le web, les voix du navigateur se chargent de façon asynchrone : la liste
## est vide au démarrage puis se remplit (~1-2 s). On réessaie donc à chaque
## appel tant qu'aucune voix n'a été trouvée. Repli : n'importe quelle voix
## disponible (mieux qu'un silence). "" si le système n'a aucune voix.
func _creer_bulle_et_mot() -> void:
	# En mode tactile, le clavier dessiné (REMONTÉ à portée de la pointe, ×4 ici)
	# occupe le bas : il ne reste qu'une bande au-dessus. La bulle passe donc À
	# CÔTÉ du tableau (une seule rangée) et prend la hauteur qui reste —
	# cf. _ajuster_au_clavier.
	var tactile_actif := Tactile.actif()
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	if tactile_actif:
		centre.offset_bottom = -_Clavier.HAUTEUR
	add_child(centre)
	_centre = centre

	var colonne: BoxContainer = HBoxContainer.new() if tactile_actif else VBoxContainer.new()
	colonne.alignment = BoxContainer.ALIGNMENT_CENTER
	colonne.add_theme_constant_override("separation", 18 if tactile_actif else 34)
	centre.add_child(colonne)

	# --- La bulle carrée au centre ---
	_bulle = PanelContainer.new()
	_bulle.custom_minimum_size = Vector2(260, 260) if tactile_actif else Vector2(340, 340)
	_style_bulle = StyleBoxFlat.new()
	_style_bulle.bg_color = Color(0.99, 0.98, 0.94, 0.96)
	_style_bulle.set_corner_radius_all(48)
	_style_bulle.set_border_width_all(10)
	_style_bulle.border_color = Color(0.20, 0.60, 0.90)
	_bulle.add_theme_stylebox_override("panel", _style_bulle)
	var conteneur_bulle := CenterContainer.new()
	conteneur_bulle.add_child(_bulle)
	colonne.add_child(conteneur_bulle)

	_label_lettre = Label.new()
	_label_lettre.text = ""
	_label_lettre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_lettre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_lettre.add_theme_font_size_override("font_size", 170 if tactile_actif else 230)
	_label_lettre.add_theme_color_override("font_color", Color(0.20, 0.60, 0.90))
	if tactile_actif:
		# La hauteur de LIGNE de la police (OpenDyslexic : ~1,7 × sa taille) dépasse la
		# bulle réduite et la ferait grossir sur le clavier : la lettre est posée sur un
		# support sans taille minimale, centrée, et déborde à vide en haut comme en bas.
		var support := Control.new()
		support.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bulle.add_child(support)
		_label_lettre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_label_lettre.grow_vertical = Control.GROW_DIRECTION_BOTH
		support.add_child(_label_lettre)
	else:
		_bulle.add_child(_label_lettre)

	# --- Le tableau blanc (le prénom se construit ici) + bouton tout effacer ---
	var ligne_tableau := HBoxContainer.new()
	ligne_tableau.alignment = BoxContainer.ALIGNMENT_CENTER
	ligne_tableau.add_theme_constant_override("separation", 18)
	ligne_tableau.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # à côté de la bulle (tactile)
	colonne.add_child(ligne_tableau)

	# Bouton « dire le mot » : en première position, à gauche du tableau.
	# Icône seule (l'enfant ne lit pas encore) : un visage jaune bouche ouverte
	# d'où sortent de petits traits — le signe qu'il parle.
	var btn_dire := _creer_bouton_rond(COULEUR_BOUTON_DIRE)
	var bouche := _IconeDireMot.new()
	bouche.set_anchors_preset(Control.PRESET_FULL_RECT)
	bouche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_dire.add_child(bouche)
	btn_dire.pressed.connect(_dire_mot)
	ligne_tableau.add_child(btn_dire)

	var tableau := PanelContainer.new()
	tableau.custom_minimum_size = Vector2(620, 104) if tactile_actif else Vector2(720, 104)
	var style_tableau := StyleBoxFlat.new()
	style_tableau.bg_color = Color(0.995, 0.995, 0.98)          # blanc feuille
	style_tableau.set_corner_radius_all(18)
	style_tableau.set_border_width_all(5)
	style_tableau.border_color = Color(0.60, 0.66, 0.72)         # cadre gris doux
	style_tableau.shadow_size = 8
	style_tableau.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	style_tableau.shadow_offset = Vector2(0, 3)
	tableau.add_theme_stylebox_override("panel", style_tableau)
	ligne_tableau.add_child(tableau)

	_label_mot = Label.new()
	_label_mot.text = ""
	_label_mot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_mot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_mot.add_theme_font_size_override("font_size", 60)
	_label_mot.add_theme_color_override("font_color", Color(0.16, 0.22, 0.34))  # bleu feutre
	tableau.add_child(_label_mot)

	# Le trait clignotant : enfant du Label, donc dans le repère du texte —
	# le mot étant centré, le trait se pose simplement au bout de ce centrage.
	_trait_ecriture = _TraitEcriture.new(_label_mot)
	_label_mot.add_child(_trait_ecriture)

	# Bouton retour arrière : efface caractère par caractère (comme la touche)
	var btn_retour_arriere := _creer_bouton_rond(Color(0.40, 0.50, 0.65))
	var fleche := _IconeRetourArriere.new()
	fleche.set_anchors_preset(Control.PRESET_FULL_RECT)
	fleche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_retour_arriere.add_child(fleche)
	btn_retour_arriere.pressed.connect(_effacer_derniere)
	ligne_tableau.add_child(btn_retour_arriere)

	# Bouton croix : efface tout le tableau (croix = symbole qu'elle connaît)
	var btn_effacer := _creer_bouton_rond(Color(0.85, 0.45, 0.30))
	var croix := _IconeCroix.new()
	croix.set_anchors_preset(Control.PRESET_FULL_RECT)
	croix.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_effacer.add_child(croix)
	btn_effacer.pressed.connect(_effacer_tout)
	ligne_tableau.add_child(btn_effacer)


## Petit bouton rond coloré (retour arrière, tout effacer).
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


## Le clavier dessiné prend `hauteur` en bas : le contenu se pousse au-dessus et la
## bulle prend la hauteur restante (bornée), sa lettre en proportion.
func _ajuster_au_clavier(hauteur: float) -> void:
	_centre.offset_bottom = -hauteur
	var dispo := get_viewport_rect().size.y - hauteur - 2.0 * MARGE_BULLE_TACTILE
	var cote := clampf(dispo, BULLE_TACTILE_MIN, BULLE_TACTILE_MAX)
	_bulle.custom_minimum_size = Vector2(cote, cote)
	_label_lettre.add_theme_font_size_override("font_size", int(cote * 0.65))


## Android : le doigt déplace le curseur, la POINTE vise (touches du clavier dessiné, caret, boutons) — cf. visee_pointe.gd.
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
		# Traînée d'étoiles (comme le jeu Découverte)
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
		if _clavier and _clavier.contient(event.position):
			return  # le tap appartient au clavier dessiné : la touche fera le travail
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_placer_caret_au_point(event.position)
				_clic_gauche(event.position)
			MOUSE_BUTTON_RIGHT:
				_clic_droit(event.position)
			MOUSE_BUTTON_MIDDLE:
				_clic_molette(event.position)
			MOUSE_BUTTON_WHEEL_UP:
				_lecteurs["tic"].play()
				_curseur.zoomer(1)
			MOUSE_BUTTON_WHEEL_DOWN:
				_lecteurs["tic"].play()
				_curseur.zoomer(-1)
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_BACKSPACE:
		_effacer_derniere()
		return
	if event.keycode == KEY_LEFT:
		_deplacer_caret(_caret - 1)
		return
	if event.keycode == KEY_RIGHT:
		_deplacer_caret(_caret + 1)
		return
	if event.unicode == 0:
		return  # touche sans caractère (Maj, Ctrl, F1…) → ignorée en douceur
	var caractere := char(event.unicode).to_upper()
	if not CARACTERES_ACCEPTES.contains(caractere) and not CLES_SPECIAUX.has(caractere):
		return
	_afficher_lettre(caractere)


# --- Les effets du jeu Découverte, invités dans le jeu des lettres ----------
# (inversion 2026-07-07 : gauche = fleurs + pop, droit = étoiles + carillon)

func _clic_gauche(ou: Vector2) -> void:
	_lecteurs["gauche"].play()
	_poser_fleur(ou, randf_range(18, 24), 0.0)
	for i in 6:
		var angle := TAU * float(i) / 6.0 + randf_range(-0.2, 0.2)
		_poser_fleur(ou + Vector2.from_angle(angle) * randf_range(50, 70),
			randf_range(12, 18), 0.06 + 0.06 * float(i))


func _clic_droit(ou: Vector2) -> void:
	_lecteurs["droit"].play()
	_poser_anneau(ou, Color(1.0, 0.85, 0.3), 80.0)
	for i in 14:
		var direction := Vector2.from_angle(randf() * TAU)
		_poser_etoile(ou, COULEURS_ETOILES.pick_random(), randf_range(22, 34),
			direction * randf_range(160, 420), 480.0, randf_range(0.7, 1.1))


func _clic_molette(ou: Vector2) -> void:
	_lecteurs["molette"].play()
	for i in 3:
		_poser_anneau(ou, COULEURS_FEU[i * 2], 60.0 + 45.0 * float(i), 0.08 * float(i))
	for i in 18:
		var direction := Vector2.from_angle(randf() * TAU)
		_poser_etoile(ou, COULEURS_FEU.pick_random(), randf_range(18, 28),
			direction * randf_range(220, 500), 120.0, randf_range(0.8, 1.2))


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


func _poser_anneau(ou: Vector2, couleur: Color, rayon_max: float, delai := 0.0) -> void:
	var anneau: Node2D = _Anneau.new()
	anneau.position = ou
	anneau.couleur = couleur
	anneau.rayon_max = rayon_max
	anneau.delai = delai
	_calque_effets.add_child(anneau)


# --- Cœur du jeu : la lettre s'affiche et se prononce -----------------------

func _afficher_lettre(caractere: String) -> void:
	var couleur := COULEURS_LETTRES[caractere.unicode_at(0) % COULEURS_LETTRES.size()]
	_label_lettre.text = AFFICHAGES_SPECIAUX.get(caractere, caractere)
	# Petite gerbe d'étoiles de la couleur de la lettre, autour de la bulle
	var centre_bulle: Vector2 = _bulle.global_position + _bulle.size / 2.0
	for i in 6:
		var direction := Vector2.from_angle(randf() * TAU)
		_poser_etoile(centre_bulle + direction * 150.0, couleur, randf_range(12, 18),
			direction * randf_range(80, 180), 200.0, randf_range(0.5, 0.8))
	_label_lettre.add_theme_color_override("font_color", couleur)
	_style_bulle.border_color = couleur
	# Petit rebond de la bulle (pop doux, prévisible)
	_bulle.pivot_offset = _bulle.size / 2.0
	_bulle.scale = Vector2.ONE * 0.85
	var animation := create_tween()
	animation.tween_property(_bulle, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_ajouter_au_mot(caractere)
	_prononcer(caractere)


## Insère le caractère au caret (en fin de mot par défaut : écrire à la suite).
func _ajouter_au_mot(caractere: String) -> void:
	_mot = _mot.insert(_caret, caractere)
	_caret += 1
	if _mot.length() > LONGUEUR_MAX_MOT:
		var surplus := _mot.length() - LONGUEUR_MAX_MOT
		_mot = _mot.substr(surplus)
		_caret = maxi(_caret - surplus, 0)
	_rafraichir_mot()


## Retire le caractère juste avant le caret (rien si le caret est au début).
func _effacer_derniere() -> void:
	if _caret == 0:
		return
	_mot = _mot.erase(_caret - 1, 1)
	_caret -= 1
	_rafraichir_mot()


## Efface tout le tableau (bouton croix) — ardoise propre, bulle comprise.
func _effacer_tout() -> void:
	_mot = ""
	_caret = 0
	_label_lettre.text = ""
	_rafraichir_mot()


## Déplace le caret (flèches), borné entre le début et la fin du mot.
func _deplacer_caret(position_voulue: int) -> void:
	_caret = clampi(position_voulue, 0, _mot.length())
	_rafraichir_mot()


## Clic (ou tap) sur le tableau : le caret saute entre les deux lettres les plus
## proches du point. Hors du tableau, rien ne change.
func _placer_caret_au_point(point: Vector2) -> void:
	if not _label_mot.get_global_rect().has_point(point):
		return
	var x_local: float = (_label_mot.get_global_transform().affine_inverse() * point).x
	_deplacer_caret(_trait_ecriture.index_le_plus_proche(x_local))


func _rafraichir_mot() -> void:
	_label_mot.text = _mot
	_trait_ecriture.caret = _caret
	_trait_ecriture.reveiller()


## Prononce le mot entier du tableau blanc (bouton visage jaune, à gauche).
## Tableau vide = rien à dire : aucun son, le bouton reste sans effet.
## Catégorie « mots » : enregistrement lang/<code>/voix/mots/ s'il existe,
## synthèse vocale du système sinon (même repli que les lettres).
func _dire_mot() -> void:
	if _mot.is_empty():
		return
	Voix.dire(self, _mot, "mots")


## Prononce le caractère avec la voix française du système (si disponible).
## Les caractères spéciaux sont prononcés par leur nom (« espace », « point »…).
## Le précédent est interrompu : en tapant vite, on entend le dernier.
## Enregistrement (lang/<code>/voix/) s'il existe, synthèse vocale sinon.
func _prononcer(caractere: String) -> void:
	if CLES_SPECIAUX.has(caractere):
		Voix.dire(self, Lang.t(CLES_SPECIAUX[caractere]), "phrases")
	elif "0123456789".contains(caractere):
		Voix.dire(self, caractere, "chiffres")
	else:
		Voix.dire(self, caractere, "lettres")


# --- Sortie du jeu ------------------------------------------------------------

func _creer_bouton_quitter() -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(72, 72)
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.position = Vector2(-88, 16)
	btn.focus_mode = Control.FOCUS_NONE  # le clavier reste entièrement au jeu
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


## Le trait vertical qui clignote à l'endroit où la PROCHAINE lettre s'écrira —
## le repère que l'enfant voit dans toutes les fenêtres. Enfant du Label du
## tableau : il hérite de son rectangle, et comme le Label est centré, le bout
## du mot se déduit de la largeur du texte mesurée avec la même police.
## Tableau vide = largeur nulle = trait au milieu : il montre où ça commence.
## Clignotement doux (fondu sinusoïdal), jamais un clignotement sec.
class _TraitEcriture extends Control:
	const LARGEUR := 4.0        # épaisseur du trait, à l'échelle du feutre
	const ECART := 4.0          # blanc entre la dernière lettre et le trait
	const DEMI_PERIODE := 0.55  # fondu plein → presque éteint (et retour)
	const REPOS := 0.20         # temps plein avant de commencer à s'éteindre
	const OPACITE_BASSE := 0.12
	const COULEUR := Color(0.16, 0.22, 0.34)  # le bleu feutre du mot

	var caret := 0  # index d'écriture dans le texte du Label (posé par le jeu)
	var _label: Label
	var _battement: Tween

	func _init(label: Label) -> void:
		_label = label

	func _ready() -> void:
		# Pas d'ancrage : on reste cale sur l'origine du Label et on lit SA taille
		# a chaque dessin — un Control enfant n'est pas redimensionne par un Label,
		# et son propre rectangle mentirait sur la place reelle du texte.
		position = Vector2.ZERO
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.resized.connect(queue_redraw)  # la mise en page bouge → on se replace
		reveiller()

	## Repositionne le trait et le rallume plein pour un cycle neuf : à chaque
	## frappe on le voit tout de suite à sa nouvelle place, jamais dans un creux.
	func reveiller() -> void:
		queue_redraw()
		if _battement != null:
			_battement.kill()
		modulate.a = 1.0
		_battement = create_tween().set_loops()
		_battement.tween_interval(REPOS)
		_battement.tween_property(self, "modulate:a", OPACITE_BASSE, DEMI_PERIODE) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_battement.tween_property(self, "modulate:a", 1.0, DEMI_PERIODE) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	## Abscisse (repère du Label) de la frontière avant la lettre d'indice i :
	## le Label centre le mot, la frontière est au début du mot + le préfixe.
	func _frontiere(i: int) -> float:
		var police: Font = _label.get_theme_font("font")
		var taille: int = _label.get_theme_font_size("font_size")
		var largeur_mot: float = police.get_string_size(
			_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, taille).x
		var largeur_prefixe: float = police.get_string_size(
			_label.text.substr(0, i), HORIZONTAL_ALIGNMENT_LEFT, -1, taille).x
		return _label.size.x / 2.0 - largeur_mot / 2.0 + largeur_prefixe

	## Indice de la frontière entre lettres la plus proche d'une abscisse.
	func index_le_plus_proche(x: float) -> int:
		if _label.get_theme_font("font") == null:
			return _label.text.length()
		var meilleur := 0
		for i in range(_label.text.length() + 1):
			if absf(_frontiere(i) - x) < absf(_frontiere(meilleur) - x):
				meilleur = i
		return meilleur

	func _draw() -> void:
		var police: Font = _label.get_theme_font("font")
		if police == null:
			return
		var taille: int = _label.get_theme_font_size("font_size")
		var cadre := _label.size
		var n := _label.text.length()
		var index := clampi(caret, 0, n)
		var x := _frontiere(index)
		# En fin de mot, petit blanc après la dernière lettre (comme avant) ;
		# au début d'un mot non vide, même blanc avant la première ; entre deux
		# lettres, le trait se pose pile sur la frontière.
		if index == n:
			x += ECART + LARGEUR / 2.0
		elif index == 0:
			x -= ECART + LARGEUR / 2.0
		x = clampf(x, LARGEUR, maxf(cadre.x - LARGEUR, LARGEUR))
		var demi_hauteur := float(taille) * 0.46
		var milieu := cadre.y / 2.0
		draw_line(Vector2(x, milieu - demi_hauteur), Vector2(x, milieu + demi_hauteur),
			COULEUR, LARGEUR)


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


## Croix blanche du bouton « tout effacer ».
class _IconeCroix extends Control:
	func _draw() -> void:
		var centre := size / 2.0
		var u := minf(size.x, size.y) * 0.24
		draw_line(centre + Vector2(-u, -u), centre + Vector2(u, u), Color.WHITE, 6.0)
		draw_line(centre + Vector2(-u, u), centre + Vector2(u, -u), Color.WHITE, 6.0)


## Flèche vers la gauche du bouton « retour arrière » (efface un caractère).
class _IconeRetourArriere extends Control:
	func _draw() -> void:
		var centre := size / 2.0
		var u := minf(size.x, size.y) / 2.0
		# Trait horizontal + pointe de flèche vers la gauche
		draw_line(centre + Vector2(-u * 0.45, 0.0), centre + Vector2(u * 0.5, 0.0), Color.WHITE, 6.0)
		draw_colored_polygon(PackedVector2Array([
			centre + Vector2(-u * 0.6, 0.0),
			centre + Vector2(-u * 0.15, -u * 0.38),
			centre + Vector2(-u * 0.15, u * 0.38),
		]), Color.WHITE)


## Visage jaune qui ouvre la bouche, avec de petits traits qui en sortent :
## le bouton « dire le mot ». Dessiné en code, sans texte — l'enfant ne lit pas.
class _IconeDireMot extends Control:
	func _draw() -> void:
		var centre := size / 2.0
		var u := minf(size.x, size.y) / 2.0
		var rayon := u * 0.56
		var pivot := centre - Vector2(u * 0.16, 0.0)  # décalé à gauche : place aux traits
		var demi_bouche := deg_to_rad(30.0)
		# Disque privé du secteur de la bouche (ouverte vers la droite)
		var contour := PackedVector2Array([pivot])
		var pas := 48
		for i in range(pas + 1):
			var angle := demi_bouche + (TAU - 2.0 * demi_bouche) * float(i) / float(pas)
			contour.append(pivot + Vector2(cos(angle), sin(angle)) * rayon)
		draw_colored_polygon(contour, COULEUR_PACMAN)
		# L'œil : ce qui en fait un visage et non une pastille
		draw_circle(pivot + Vector2(-rayon * 0.10, -rayon * 0.46), maxf(u * 0.08, 1.5), Color(0.22, 0.18, 0.08))
		# Les petits traits devant la bouche : il parle
		for i in range(3):
			var direction := Vector2.RIGHT.rotated(deg_to_rad(-21.0 + 21.0 * float(i)))
			var depart := pivot + direction * (rayon * 1.24)
			var longueur := u * (0.28 if i == 1 else 0.21)
			draw_line(depart, depart + direction * longueur, Color.WHITE, maxf(u * 0.09, 2.0))


## Bouton Retour d'Android (mode bureau/launcher) : même geste que la croix.
func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_WM_GO_BACK_REQUEST:
		_quitter()
