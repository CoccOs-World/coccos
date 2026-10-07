## Bureau de l'enfant — écran principal (remplace le dashboard à tuiles).
## Un vrai bureau d'ordinateur en miniature :
## - icônes d'applications sur le fond prairie (colonnes depuis le haut-gauche)
## - barre des tâches en bas : bouton Menu (étoile), horloge, roue crantée (adulte)
## - menu « boîte à icônes » : TOUTES les applications en grille alphabétique
##   (fenêtre CoccOs au-dessus de la barre — l'icône est le geste de notre époque)
## - fenêtres façon OS : une icône-catégorie (ex. « La souris ») ouvre une
##   fenêtre déplaçable, fermable par sa croix, contenant les icônes des jeux
## Les applications non développées ouvrent l'écran « Bientôt disponible ».
extends Control

const Fond := preload("res://scripts/fond.gd")
const UIStyle := preload("res://scripts/ui_style.gd")
const IconeBureau := preload("res://scripts/icone_bureau.gd")
const Pictogramme := preload("res://scripts/pictogramme.gd")
const Fenetre := preload("res://scripts/fenetre.gd")
const PinConfig := preload("res://scripts/pin_config.gd")
const AppliExternes := preload("res://scripts/applis_externes.gd")
const CurseurOS := preload("res://scripts/effets/curseur.gd")
const Etoile := preload("res://scripts/effets/etoile.gd")
const Fleur := preload("res://scripts/effets/fleur.gd")
const Anneau := preload("res://scripts/effets/anneau.gd")
const Sons := preload("res://scripts/effets/sons.gd")
const Lang := preload("res://scripts/lang.gd")
const Tactile := preload("res://scripts/tactile.gd")
const Migration := preload("res://scripts/migration.gd")
const Voix := preload("res://scripts/voix.gd")
const Lancement := preload("res://scripts/lancement.gd")
const Android := preload("res://scripts/android.gd")

## Registre des applications du bureau (id = pictogramme, sauf "picto" fourni).
## "scene" = lancée directement ; "fenetre" = ouvre la fenêtre-catégorie du même
## id ; "externe" = lance un programme installé (ajouté par _applis_bureau()).
## Règle : AUCUNE icône fantôme — pas de stimuli inutiles. Les activités à
## venir vivent dans la ROADMAP, pas sur le bureau de l'enfant.
## Le bureau se construit depuis le REGISTRE (scripts/registre_jeux.gd, spec
## logithèque) : catégories nées des jeux actifs, applications activables par
## l'adulte dans la logithèque — plus de liste en dur ici.
const Registre := preload("res://scripts/registre_jeux.gd")

const HAUTEUR_BARRE := 76
const COULEUR_BARRE := Color(0.13, 0.17, 0.28, 0.92)
const COULEUR_MENU := Color(0.95, 0.72, 0.15)  # bouton Menu jaune soleil
const COULEUR_ENGRENAGE := Color(0.45, 0.45, 0.50)
const COULEUR_VOLUME := Color(0.32, 0.58, 0.45)  # bouton haut-parleur vert doux

# Retours sensoriels du bureau (réglages adulte, section Souris)
const PAS_TRAINEE := 26.0
const COULEURS_TRAINEE: Array[Color] = [
	Color(1.0, 0.9, 0.35), Color(1.0, 1.0, 1.0), Color(1.0, 0.75, 0.25),
]
const COULEURS_ETOILES: Array[Color] = [
	Color(1.0, 0.85, 0.25), Color(1.0, 0.6, 0.15), Color(1.0, 0.95, 0.6), Color(1.0, 1.0, 1.0),
]
const COULEURS_FLEURS: Array[Color] = [
	Color(1.0, 0.45, 0.7), Color(0.8, 0.5, 0.95), Color(0.5, 0.6, 1.0), Color(1.0, 0.6, 0.85),
]

var _menu: Control = null  # voile plein écran portant la boîte à icônes (null = fermé)
var _horloge: Label
var _panneau_volume: PanelContainer = null
var _fenetres_ouvertes := {}  # id catégorie → instance de Fenetre
var _icones := []  # icônes du bureau (reconstruites quand l'enfant range un jeu)
var _index_icones := -1  # leur rang parmi les enfants (sous fenêtres et barre)
var _icone_rangee := ""  # jeu qui vient d'entrer dans un dossier : sa place n'est pas retenue
var _places_courantes := {}  # id → position avant reconstruction (les autres icônes ne sautent pas)

var _curseur: Node2D
var _calque_effets: Node2D
var _trainee_active := true
var _anim_gauche := true
var _anim_droit := true
var _sons_clics := true
var _lecteurs := {}
var _dernier_point := Vector2.ZERO
var _distance_cumulee := 0.0


func _ready() -> void:
	# AVANT toute lecture de config : rapatrier les données de l'ancien nom
	# d'application (« GCompris 2 » → « CoccOs ») si c'est le premier lancement
	Migration.migrer()
	# Plein écran au lancement (réglages adulte → Interface)
	if DisplayServer.get_name() != "headless" \
			and PinConfig.lire_option("interface", "plein_ecran", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_appliquer_volume(Voix.volume())
	# Lancement direct « --app <id> » : on saute le bureau et on entre dans l'appli
	# (icône dédiée sur l'appareil — ex. « Mon classeur » sans passer par CoccOs)
	var app_directe := Lancement.app_directe()
	if app_directe != "":
		var fiche: Dictionary = Registre.appli(app_directe)
		if not fiche.is_empty() and fiche.has("scene") \
				and ResourceLoader.exists(fiche["scene"]):
			get_tree().change_scene_to_file.call_deferred(fiche["scene"])
			return
	_appliquer_fond_bureau()
	_creer_icones()
	_creer_barre_taches()
	_mettre_a_jour_horloge()
	_creer_curseur_et_effets()


## Fond d'écran du bureau : image prairie (défaut), image importée par l'adulte
## ou couleur unie — réglages adulte → Interface. Les jeux gardent la prairie.
func _appliquer_fond_bureau() -> void:
	match PinConfig.lire_option("interface", "fond_bureau_type", "image"):
		"couleur":
			var fond := ColorRect.new()
			fond.color = PinConfig.lire_option("interface", "fond_bureau_couleur", Color(0.55, 0.75, 0.55))
			fond.set_anchors_preset(Control.PRESET_FULL_RECT)
			fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(fond)
		"perso":
			_appliquer_fond_perso()
		_:
			Fond.appliquer(self)


## Fond importé (user://fond_bureau_perso.png) — repli sur la prairie si absent/illisible.
func _appliquer_fond_perso() -> void:
	const CHEMIN_FOND_PERSO := "user://fond_bureau_perso.png"
	if not FileAccess.file_exists(CHEMIN_FOND_PERSO):
		Fond.appliquer(self)
		return
	var image := Image.load_from_file(CHEMIN_FOND_PERSO)
	if image == null or image.is_empty():
		Fond.appliquer(self)
		return
	# Repli couleur derrière (même filet de sécurité que fond.gd)
	var base := ColorRect.new()
	base.color = Color(0.90, 0.94, 0.86)
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	var affichage := TextureRect.new()
	affichage.texture = ImageTexture.create_from_image(image)
	affichage.set_anchors_preset(Control.PRESET_FULL_RECT)
	affichage.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	affichage.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	affichage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(affichage)


## Le curseur de l'OS + les retours sensoriels du bureau (réglages adulte).
## CanvasLayers : les effets (5) et le curseur (10) restent au-dessus de tout,
## y compris des fenêtres ouvertes ensuite.
func _creer_curseur_et_effets() -> void:
	_trainee_active = PinConfig.lire_option("souris", "trainee_bureau", true)
	_anim_gauche = PinConfig.lire_option("souris", "anim_clic_gauche_bureau", true)
	_anim_droit = PinConfig.lire_option("souris", "anim_clic_droit_bureau", true)
	_sons_clics = PinConfig.lire_option("souris", "sons_clics_bureau", true)

	# Sons des clics (pairing imaginaire Freddy : pop ↔ fleurs, carillon ↔ étoiles),
	# un peu plus doux que dans les jeux — c'est le bureau
	var flux := {"etoiles": Sons.carillon(), "fleurs": Sons.pop_joyeux()}
	for nom in flux:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux[nom]
		lecteur.volume_db = -6.0
		lecteur.max_polyphony = 3
		add_child(lecteur)
		_lecteurs[nom] = lecteur

	var couche_effets := CanvasLayer.new()
	couche_effets.layer = 5
	add_child(couche_effets)
	_calque_effets = Node2D.new()
	couche_effets.add_child(_calque_effets)

	var couche_curseur := CanvasLayer.new()
	couche_curseur.layer = 10
	add_child(couche_curseur)
	_curseur = CurseurOS.new()
	couche_curseur.add_child(_curseur)

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_dernier_point = get_viewport().get_mouse_position()
	_curseur.position = _dernier_point

	# Mode tactile : l'appui long vaut clic droit (étoiles + carillon, selon réglages)
	var tactile: Node = Tactile.new()
	add_child(tactile)
	tactile.appui_long.connect(func(ou: Vector2) -> void:
		_curseur.pulser()
		if _anim_droit:
			_animation_etoiles(ou)
		if _sons_clics:
			_lecteurs["etoiles"].play())


func _input(event: InputEvent) -> void:
	# Échap ferme la boîte à icônes si elle est ouverte (avant tout le reste)
	if _menu != null and event.is_action_pressed("ui_cancel"):
		_fermer_menu()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		_curseur.position = event.position
		if _trainee_active:
			_distance_cumulee += event.position.distance_to(_dernier_point)
			if _distance_cumulee >= PAS_TRAINEE:
				_distance_cumulee = 0.0
				_poser_etoile(
					event.position + Vector2(randf_range(-10, 10), randf_range(-10, 10)),
					COULEURS_TRAINEE.pick_random(), randf_range(13, 19),
					Vector2(0, randf_range(20, 60)), 60.0, randf_range(0.5, 0.8))
		_dernier_point = event.position
	elif event is InputEventMouseButton and event.pressed:
		# Inversion 2026-07-07 : gauche = fleurs + pop, droit = étoiles + carillon
		if event.button_index == MOUSE_BUTTON_LEFT:
			_curseur.pulser()
			if _anim_gauche:
				_animation_fleurs(event.position)
			if _sons_clics:
				_lecteurs["fleurs"].play()  # pop joyeux — le son des fleurs
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_curseur.pulser()
			if _anim_droit:
				_animation_etoiles(event.position)
			if _sons_clics:
				_lecteurs["etoiles"].play()  # carillon — le son des étoiles


## Version « bureau » de l'explosion d'étoiles — plus légère que dans le jeu.
func _animation_etoiles(ou: Vector2) -> void:
	var anneau: Node2D = Anneau.new()
	anneau.position = ou
	anneau.couleur = Color(1.0, 0.85, 0.3)
	anneau.rayon_max = 60.0
	_calque_effets.add_child(anneau)
	for i in 8:
		var direction := Vector2.from_angle(randf() * TAU)
		_poser_etoile(ou, COULEURS_ETOILES.pick_random(), randf_range(14, 22),
			direction * randf_range(140, 320), 480.0, randf_range(0.5, 0.8))


## Version « bureau » de la ronde de fleurs — plus légère que dans le jeu.
func _animation_fleurs(ou: Vector2) -> void:
	for i in 4:
		var angle := TAU * float(i) / 4.0 + randf_range(-0.3, 0.3)
		var fleur: Node2D = Fleur.new()
		fleur.position = ou + Vector2.from_angle(angle) * randf_range(30, 50)
		fleur.couleur = COULEURS_FLEURS.pick_random()
		fleur.rayon = randf_range(10, 15)
		fleur.delai = 0.05 * float(i)
		_calque_effets.add_child(fleur)


func _poser_etoile(ou: Vector2, couleur: Color, rayon: float,
		vitesse: Vector2, gravite: float, duree_vie: float) -> void:
	var etoile: Node2D = Etoile.new()
	etoile.position = ou
	etoile.couleur = couleur
	etoile.rayon = rayon
	etoile.vitesse = vitesse
	etoile.gravite = gravite
	etoile.rotation_vitesse = randf_range(-6.0, 6.0)
	etoile.duree_vie = duree_vie
	_calque_effets.add_child(etoile)


# --- Icônes du bureau -------------------------------------------------------

## Liste réelle du bureau : catégories ayant des jeux actifs + applications
## directes actives + applications externes cochées/installées — tout vient
## du registre et des choix de l'adulte (aucune icône fantôme).
func _applis_bureau() -> Array:
	var liste := []
	for categorie in Registre.categories_visibles():
		liste.append({"id": categorie["id"], "nom_cle": categorie["nom_cle"],
			"couleur": categorie["couleur"], "fenetre": true})
	liste.append_array(Registre.actives_directes())
	liste.append_array(AppliExternes.applis_actives())
	# Les applis du téléphone choisies dans la logithèque (Android, phase B) —
	# leur icône système est affichée telle quelle (nom_cle = nom réel : le
	# repli de Lang.t rend la clé, donc le nom, sans traduction à fournir)
	var telephone: Dictionary = Android.choisies()
	for paquet in telephone:
		liste.append({"id": "tel:" + paquet, "nom_cle": telephone[paquet],
			"couleur": Color(0.35, 0.45, 0.60), "telephone": paquet,
			"image": Android.chemin_icone(paquet)})
	return liste


func _creer_icones() -> void:
	var par_colonne := 3
	var premiere: Control = null
	var applis := _applis_bureau()
	var reconstruction := _index_icones >= 0
	if not reconstruction:
		_index_icones = get_child_count()
	var ranges: Dictionary = PinConfig.lire_option("bureau", "places_icones", {})
	for i in applis.size():
		var appli: Dictionary = applis[i]
		var icone: Control = IconeBureau.new()
		icone.id = appli["id"]
		icone.nom = Lang.t(appli["nom_cle"])
		icone.couleur = appli["couleur"]
		icone.picto = appli.get("picto", "")
		icone.chemin_image = appli.get("image", "")
		icone.est_dossier = appli.has("fenetre")  # catégorie = icône dossier
		@warning_ignore("integer_division")
		icone.position = Vector2(30 + (i / par_colonne) * 180, 26 + (i % par_colonne) * 178)
		# Place choisie par l'enfant (glisser-déposer) — sinon disposition par défaut
		if ranges.has(icone.id):
			icone.position = ranges[icone.id]
		elif _places_courantes.has(icone.id):
			icone.position = _places_courantes[icone.id]
		icone.limite_basse = HAUTEUR_BARRE
		# Souris seulement : en mode tactile, un doigt qui dérive doit rester un tap
		icone.deplacable = not Tactile.actif()
		icone.lancee.connect(_lancer_appli)
		icone.deplacee.connect(_memoriser_place_icone)
		icone.survol.connect(_viser_dossier)
		icone.lachee.connect(_ranger_dans_dossier)
		add_child(icone)
		if reconstruction:
			move_child(icone, _index_icones + i)  # reste sous les fenêtres et la barre
		_icones.append(icone)
		if ranges.has(icone.id):
			icone.garder_dans_l_ecran.call_deferred()  # écran plus petit qu'au rangement
		if premiere == null:
			premiere = icone
	# Focus clavier initial sur la première icône (accessibilité)
	if premiere != null and not reconstruction:
		premiere.ready.connect(premiere.focus, CONNECT_ONE_SHOT | CONNECT_DEFERRED)


## L'enfant a posé une icône : sa place est retenue (user://config.cfg, qui
## voyage avec l'espace famille) et resservie au prochain lancement.
func _memoriser_place_icone(id: String, ou: Vector2) -> void:
	if id == _icone_rangee:
		return  # lâchée sur un dossier : elle quitte le bureau
	var ranges: Dictionary = PinConfig.lire_option("bureau", "places_icones", {})
	ranges[id] = ou
	PinConfig.ecrire_option("bureau", "places_icones", ranges)


# --- Ranger un jeu dans un dossier / l'en ressortir (glissé souris) -----------
# Seules les applications du registre se rangent (pas les dossiers eux-mêmes,
# ni les applis externes ou du téléphone). Choix retenu par enfant :
# Registre.ranger() → user://config.cfg [bureau_rangement].

## Le dossier du bureau sous ce point (null si aucun, ou si une fenêtre le couvre).
func _dossier_sous(point: Vector2) -> Control:
	for fenetre in _fenetres_ouvertes.values():
		if is_instance_valid(fenetre) and fenetre.get_global_rect().has_point(point):
			return null
	for icone in _icones:
		if is_instance_valid(icone) and icone.est_dossier and icone.contient(point):
			return icone
	return null


## Pendant le vol d'un jeu : le dossier survolé se signale comme cible.
func _viser_dossier(id: String, point: Vector2) -> void:
	var cible: Control = _dossier_sous(point) if not Registre.appli(id).is_empty() else null
	for icone in _icones:
		if is_instance_valid(icone) and icone.est_dossier:
			icone.signaler_cible(icone == cible)


## Jeu du bureau lâché : sur un dossier, il y entre (et quitte le bureau).
func _ranger_dans_dossier(id: String, point: Vector2, _coin: Vector2) -> void:
	var cible: Control = _dossier_sous(point) if not Registre.appli(id).is_empty() else null
	for icone in _icones:
		if is_instance_valid(icone) and icone.est_dossier:
			icone.signaler_cible(false)
	if cible == null:
		return
	Registre.ranger(id, cible.id)
	_icone_rangee = id
	_reconstruire_bureau.call_deferred(cible.id)


## Jeu lâché depuis une fenêtre-dossier : hors de la fenêtre, il ressort sur le
## bureau, posé là où l'enfant l'a lâché ; dans la fenêtre, il reprend sa place.
func _ressortir_du_dossier(id: String, point: Vector2, coin: Vector2, categorie: String) -> void:
	var fenetre: Control = _fenetres_ouvertes.get(categorie)
	if fenetre == null or not is_instance_valid(fenetre) or fenetre.get_global_rect().has_point(point):
		return
	Registre.ranger(id, "")
	_memoriser_place_icone(id, get_global_transform().affine_inverse() * coin)
	_reconstruire_bureau.call_deferred(categorie)


## Après un rangement : icônes du bureau refaites, fenêtre du dossier remise à jour
## (fermée si le dossier n'a plus de jeu — il disparaît alors du bureau).
func _reconstruire_bureau(categorie: String) -> void:
	_icone_rangee = ""
	_places_courantes.clear()
	for icone in _icones:
		if is_instance_valid(icone):
			_places_courantes[icone.id] = icone.position
			remove_child(icone)
			icone.queue_free()
	_icones.clear()
	_creer_icones()
	var fenetre: Control = _fenetres_ouvertes.get(categorie)
	if fenetre == null or not is_instance_valid(fenetre):
		return
	for ancienne in fenetre.contenu.get_children():
		fenetre.contenu.remove_child(ancienne)
		ancienne.queue_free()
	if Registre.jeux_de(categorie).is_empty():
		fenetre.queue_free()
		_fenetres_ouvertes.erase(categorie)
	else:
		_remplir_fenetre(fenetre, categorie)


func _lancer_appli(id: String) -> void:
	_fermer_menu()
	for appli in _applis_bureau():
		if appli["id"] == id:
			if appli.has("telephone"):
				# Appli du téléphone : elle s'ouvre par-dessus, retour = bureau intact
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				Android.lancer_paquet(appli["telephone"])
				Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			elif appli.has("externe"):
				_lancer_externe(appli)
			elif appli.has("scene"):
				# Curseur système rendu visible (les jeux le remasquent eux-mêmes)
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				get_tree().change_scene_to_file(appli["scene"])
			elif appli.has("fenetre"):
				_ouvrir_fenetre(id, Lang.t(appli["nom_cle"]), appli["couleur"])
			return


## Lance une application externe (TuxPaint…) — elle s'ouvre par-dessus le
## bureau ; à sa fermeture, l'enfant retrouve le bureau tel quel.
## Multi-plateforme : AppliExternes.lancer choisit le bon geste
## (processus Linux, intent Android).
func _lancer_externe(appli: Dictionary) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # l'appli externe a son propre curseur
	if not AppliExternes.lancer(appli):
		push_warning("Impossible de lancer : " + String(appli["id"]))
	# Le curseur du bureau reste utilisable en attendant / au retour
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


## Lance un jeu depuis une fenêtre-catégorie.
func _lancer_jeu(id: String) -> void:
	var jeu: Dictionary = Registre.appli(id)
	if not jeu.is_empty():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file(jeu["scene"])


# --- Fenêtres-catégories ------------------------------------------------------

## Ouvre (ou remet devant) la fenêtre d'une catégorie, avec ses icônes de jeux.
func _ouvrir_fenetre(id: String, titre: String, couleur: Color) -> void:
	# Déjà ouverte → juste la remettre au premier plan
	if _fenetres_ouvertes.has(id) and is_instance_valid(_fenetres_ouvertes[id]):
		move_child(_fenetres_ouvertes[id], get_child_count() - 1)
		return

	var fenetre: PanelContainer = Fenetre.new()
	fenetre.titre = titre
	fenetre.couleur = couleur
	fenetre.limite_basse = HAUTEUR_BARRE
	# Réglage adulte : fenêtres fixes par défaut, déplaçables si l'option est cochée
	fenetre.deplacable = PinConfig.lire_option("bureau", "fenetres_deplacables", false)
	add_child(fenetre)  # dernier enfant = dessiné au-dessus du reste
	_fenetres_ouvertes[id] = fenetre

	_remplir_fenetre(fenetre, id)

	# Centrage différé : la taille n'est connue qu'après le premier calcul de layout
	fenetre.position = Vector2.ZERO
	_centrer_fenetre.call_deferred(fenetre)


## Les icônes des jeux d'une catégorie dans sa fenêtre (glissables hors d'elle).
func _remplir_fenetre(fenetre: Control, id: String) -> void:
	for jeu in Registre.jeux_de(id):
		var icone: Control = IconeBureau.new()
		icone.id = jeu["id"]
		icone.nom = Lang.t(jeu["nom_cle"])
		icone.couleur = jeu["couleur"]
		# Souris seulement : en mode tactile, un doigt qui dérive doit rester un tap
		icone.rangeable = not Tactile.actif()
		icone.lancee.connect(_lancer_jeu)
		icone.lachee.connect(_ressortir_du_dossier.bind(id))
		fenetre.contenu.add_child(icone)


func _centrer_fenetre(fenetre: Control) -> void:
	fenetre.position = ((size - Vector2(0, HAUTEUR_BARRE)) - fenetre.size) / 2.0


# --- Barre des tâches -------------------------------------------------------

func _creer_barre_taches() -> void:
	var barre := PanelContainer.new()
	barre.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	barre.offset_top = -HAUTEUR_BARRE
	var style := StyleBoxFlat.new()
	style.bg_color = COULEUR_BARRE
	barre.add_theme_stylebox_override("panel", style)
	add_child(barre)

	var marge := MarginContainer.new()
	marge.add_theme_constant_override("margin_left", 12)
	marge.add_theme_constant_override("margin_right", 12)
	marge.add_theme_constant_override("margin_top", 8)
	marge.add_theme_constant_override("margin_bottom", 8)
	barre.add_child(marge)

	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 16)
	marge.add_child(ligne)

	# Bouton Menu (étoile + texte), à gauche comme un vrai bureau
	var btn_menu := Button.new()
	btn_menu.text = Lang.t("bureau_menu")
	btn_menu.custom_minimum_size = Vector2(180, 0)
	btn_menu.add_theme_font_size_override("font_size", 30)
	UIStyle.styliser(btn_menu, COULEUR_MENU, 18)
	for etat in ["normal", "hover", "focus", "pressed"]:
		var s: StyleBoxFlat = btn_menu.get_theme_stylebox(etat)
		s.content_margin_left = 62.0
	var picto_menu: Control = Pictogramme.new()
	picto_menu.id = "etoile"
	picto_menu.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	picto_menu.offset_left = 10
	picto_menu.offset_right = 54
	picto_menu.offset_top = 8
	picto_menu.offset_bottom = -8
	btn_menu.add_child(picto_menu)
	btn_menu.pressed.connect(_basculer_menu)
	ligne.add_child(btn_menu)

	# Espace extensible entre le menu (gauche) et l'horloge/réglages (droite)
	var espace := Control.new()
	espace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(espace)

	# Horloge numérique — l'enfant voit l'heure vivre
	_horloge = Label.new()
	_horloge.add_theme_font_size_override("font_size", 34)
	_horloge.add_theme_color_override("font_color", Color.WHITE)
	ligne.add_child(_horloge)
	var minuterie := Timer.new()
	minuterie.wait_time = 1.0
	minuterie.timeout.connect(_mettre_a_jour_horloge)
	add_child(minuterie)
	minuterie.start()

	# Haut-parleur (volume, accessible à l'enfant SANS code) — né du 2ᵉ test
	# d'Isabella : elle voulait monter le son et, sans bouton pour ça, a fini
	# sur le bouton éteindre. Masquable dans Réglages → Interface.
	if PinConfig.lire_option("interface", "bouton_volume", true):
		var btn_volume := Button.new()
		btn_volume.custom_minimum_size = Vector2(60, 60)
		UIStyle.styliser(btn_volume, COULEUR_VOLUME, 30)
		var picto_volume: Control = Pictogramme.new()
		picto_volume.id = "haut_parleur"
		picto_volume.set_anchors_preset(Control.PRESET_FULL_RECT)
		picto_volume.offset_left = 12
		picto_volume.offset_top = 12
		picto_volume.offset_right = -12
		picto_volume.offset_bottom = -12
		picto_volume.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_volume.add_child(picto_volume)
		btn_volume.pressed.connect(_basculer_volume)
		ligne.add_child(btn_volume)

	# Roue crantée (réglages adulte) — reprend le parcours PIN existant
	var btn_reglages := Button.new()
	btn_reglages.custom_minimum_size = Vector2(60, 60)
	UIStyle.styliser(btn_reglages, COULEUR_ENGRENAGE, 30)
	var picto_reglages: Control = Pictogramme.new()
	picto_reglages.id = "engrenage"
	picto_reglages.couleur_creux = COULEUR_ENGRENAGE
	picto_reglages.set_anchors_preset(Control.PRESET_FULL_RECT)
	picto_reglages.offset_left = 10
	picto_reglages.offset_top = 10
	picto_reglages.offset_right = -10
	picto_reglages.offset_bottom = -10
	btn_reglages.add_child(picto_reglages)
	btn_reglages.pressed.connect(_aller_reglages)
	ligne.add_child(btn_reglages)

	# Bouton éteindre (quitte l'OS) — symbole marche/arrêt, tout à droite
	var btn_eteindre := Button.new()
	btn_eteindre.custom_minimum_size = Vector2(60, 60)
	UIStyle.styliser(btn_eteindre, Color(0.75, 0.25, 0.22), 30)
	var picto_eteindre: Control = Pictogramme.new()
	picto_eteindre.id = "eteindre"
	picto_eteindre.set_anchors_preset(Control.PRESET_FULL_RECT)
	picto_eteindre.offset_left = 14
	picto_eteindre.offset_top = 14
	picto_eteindre.offset_right = -14
	picto_eteindre.offset_bottom = -14
	btn_eteindre.add_child(picto_eteindre)
	btn_eteindre.pressed.connect(_eteindre)
	ligne.add_child(btn_eteindre)


func _mettre_a_jour_horloge() -> void:
	var heure := Time.get_time_dict_from_system()
	_horloge.text = "%02d:%02d" % [heure["hour"], heure["minute"]]


# --- Volume de l'enfant -----------------------------------------------------------

## Grande glissière sans chiffres au-dessus de la barre des tâches — un tap sur
## le haut-parleur l'ouvre, un second la ferme. Un petit pop au relâchement fait
## entendre le niveau choisi.
func _basculer_volume() -> void:
	if _panneau_volume != null:
		_panneau_volume.queue_free()
		_panneau_volume = null
		return
	var panneau := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COULEUR_BARRE
	style.set_corner_radius_all(18)
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	panneau.add_theme_stylebox_override("panel", style)

	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 18)
	panneau.add_child(ligne)
	var picto_doux: Control = Pictogramme.new()
	picto_doux.id = "haut_parleur"
	picto_doux.custom_minimum_size = Vector2(34, 34)
	picto_doux.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ligne.add_child(picto_doux)
	var glissiere := HSlider.new()
	glissiere.min_value = 0.0
	glissiere.max_value = 100.0
	glissiere.step = 5.0
	glissiere.custom_minimum_size = Vector2(380, 56)
	glissiere.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	glissiere.value = Voix.volume()
	glissiere.value_changed.connect(func(v: float) -> void:
		PinConfig.ecrire_option("interface", "volume", int(v))
		_appliquer_volume(int(v)))
	glissiere.drag_ended.connect(func(changee: bool) -> void:
		if changee and _lecteurs.has("fleurs"):
			_lecteurs["fleurs"].play())
	ligne.add_child(glissiere)
	var picto_fort: Control = Pictogramme.new()
	picto_fort.id = "haut_parleur"
	picto_fort.custom_minimum_size = Vector2(52, 52)
	picto_fort.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ligne.add_child(picto_fort)

	add_child(panneau)
	_panneau_volume = panneau
	# Placement une fois la taille calculée : au-dessus de la barre, côté droit
	panneau.reset_size()
	await get_tree().process_frame
	if _panneau_volume != panneau:
		return
	panneau.position = Vector2(size.x - panneau.size.x - 16.0,
		size.y - HAUTEUR_BARRE - panneau.size.y - 12.0)


## Le volume choisi pilote le bus audio maître (sons ET voix enregistrées) ;
## la synthèse vocale lit la même option (voir voix.gd).
func _appliquer_volume(v: int) -> void:
	var lineaire := clampf(v / 100.0, 0.0, 1.0)
	AudioServer.set_bus_mute(0, v == 0)
	if v > 0:
		AudioServer.set_bus_volume_db(0, linear_to_db(lineaire))


func _aller_reglages() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/pin_gate.tscn")


## Quitte l'OS (bouton éteindre de la barre des tâches).
## Si le réglage « éteindre sous PIN » est actif (Réglages → Interface),
## l'écran du code adulte s'ouvre d'abord — il éteindra après un code correct.
## Sur le web, quit() figerait la page : on retourne au site vitrine à la place
## (le jeu est servi dans jeu/, la page d'accueil est juste au-dessus).
func _eteindre() -> void:
	if PinConfig.lire_option("interface", "eteindre_sous_pin", false):
		var PinGate := preload("res://scripts/pin_gate.gd")
		PinGate.action_apres = "eteindre"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://scenes/pin_gate.tscn")
		return
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.href = '../';")
	elif Android.ouvrir_reglage_bureau():
		# Sortie du mode bureau : le réglage « Écran d'accueil » s'ouvre, le
		# parent y rebascule sur le lanceur d'origine. CoccOs se replace sur
		# son bureau, prêt pour la prochaine fois.
		get_tree().change_scene_to_file("res://scenes/bureau.tscn")
	else:
		get_tree().quit()


# --- Menu des applications (boîte à icônes) ----------------------------------

const COULEUR_TITRE_MENU := Color(0.90, 0.33, 0.24)  # barre de titre de la boîte
const COLONNES_MENU := 5

## TOUTES les applications lançables, à plat : les jeux des catégories, les
## applis directes, les externes cochées et les applis du téléphone — triées
## par ordre alphabétique, articles ignorés (« Les mots » se range à M).
func _toutes_les_applis() -> Array:
	var liste := []
	for appli in Registre.APPLIS:
		if Registre.existe_ici(appli) and Registre.est_active(appli["id"]):
			liste.append(appli)
	liste.append_array(AppliExternes.applis_actives())
	var telephone: Dictionary = Android.choisies()
	for paquet in telephone:
		liste.append({"id": "tel:" + paquet, "nom_cle": telephone[paquet],
			"couleur": Color(0.35, 0.45, 0.60), "telephone": paquet,
			"image": Android.chemin_icone(paquet)})
	liste.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _cle_tri(Lang.t(a["nom_cle"])) < _cle_tri(Lang.t(b["nom_cle"])))
	return liste


## Clé de tri alphabétique d'un nom affiché : minuscules, accents aplanis
## (sinon « é » se range après « z ») et article initial ignoré
## (sinon La/Le/Les/Ma/Mon regrouperaient tout n'importe comment).
static func _cle_tri(nom: String) -> String:
	var bas := nom.to_lower().strip_edges()
	const ACCENTS := {"é": "e", "è": "e", "ê": "e", "ë": "e", "à": "a", "â": "a",
		"ä": "a", "î": "i", "ï": "i", "ô": "o", "ö": "o", "ù": "u", "û": "u",
		"ü": "u", "ç": "c", "œ": "oe"}
	for accent in ACCENTS:
		bas = bas.replace(accent, ACCENTS[accent])
	if bas.begins_with("l'") or bas.begins_with("l’"):
		return bas.substr(2)
	var premier := bas.get_slice(" ", 0)
	if bas.contains(" ") and premier in ["le", "la", "les", "un", "une", "des", "mon", "ma", "mes"]:
		return bas.substr(premier.length() + 1)
	return bas


## Ouvre/ferme la boîte à icônes : une fenêtre CoccOs (barre de titre + croix)
## posée sur un voile transparent — croix, Échap, bouton Menu ou tap à côté
## la referment. La grille réutilise IconeBureau : mêmes icônes que le bureau
## (livrée coccinelle, icônes système du téléphone…).
func _basculer_menu() -> void:
	if _menu != null:
		_fermer_menu()
		return
	# Voile plein écran : un tap à côté de la boîte la ferme
	var voile := Control.new()
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	voile.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_fermer_menu())
	add_child(voile)
	_menu = voile

	var fenetre: PanelContainer = Fenetre.new()
	fenetre.titre = Lang.t("bureau_menu_titre")
	fenetre.couleur = COULEUR_TITRE_MENU
	fenetre.limite_basse = HAUTEUR_BARRE
	voile.add_child(fenetre)
	# La croix de la fenêtre la libère elle-même (comportement Fenetre) : le
	# voile doit suivre — sans double libération quand c'est nous qui fermons
	fenetre.tree_exiting.connect(func() -> void:
		if _menu == voile:
			_menu = null
			voile.queue_free())

	var grille := GridContainer.new()
	grille.columns = COLONNES_MENU
	grille.add_theme_constant_override("h_separation", 10)
	grille.add_theme_constant_override("v_separation", 18)
	var premiere: Control = null
	for appli in _toutes_les_applis():
		var icone: Control = IconeBureau.new()
		icone.id = appli["id"]
		icone.nom = Lang.t(appli["nom_cle"])
		icone.couleur = appli["couleur"]
		icone.picto = appli.get("picto", "")
		icone.chemin_image = appli.get("image", "")
		icone.lancee.connect(_lancer_depuis_menu)
		grille.add_child(icone)
		if premiere == null:
			premiere = icone
	fenetre.contenu.add_child(grille)

	# Centrage différé (taille connue après layout) + focus clavier initial
	fenetre.position = Vector2.ZERO
	_centrer_fenetre.call_deferred(fenetre)
	if premiere != null:
		premiere.ready.connect(premiere.focus, CONNECT_ONE_SHOT | CONNECT_DEFERRED)


func _fermer_menu() -> void:
	if _menu == null:
		return
	var voile := _menu
	_menu = null
	voile.queue_free()


## Lancement depuis la boîte à icônes : les jeux des catégories n'existent pas
## dans _applis_bureau() (ils vivent dans leurs fenêtres) — on passe donc par
## le registre d'abord, puis par le chemin standard (externes, téléphone).
func _lancer_depuis_menu(id: String) -> void:
	_fermer_menu()
	var jeu: Dictionary = Registre.appli(id)
	if not jeu.is_empty() and jeu.has("scene"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file(jeu["scene"])
		return
	_lancer_appli(id)
