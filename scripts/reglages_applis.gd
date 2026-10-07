## Sous-écran réglages adulte — LA LOGITHÈQUE v2 « centre d'applications »
## (spec : spec-logitheque.md, maquette validée Freddy 2026-07-20).
## Trois zones, sur le modèle des centres d'applications :
##   - volet gauche : les ÉTIQUETTES (Toutes + une entrée par étiquette en usage)
##   - droite : barre de RECHERCHE (nom + descriptif) puis grille de CARTES
##   - clic sur une carte → la FICHE : icône + titre, interrupteur « Sur le
##     bureau », icône sur l'appareil, descriptif, étiquettes configurables
##     (défauts du manifeste + ajouts de l'adulte), emplacement galerie.
## Toutes les familles y vivent ensemble : jeux CoccOs, applications externes
## (installables graphiquement, jamais de terminal), applis du téléphone.
## Sauvegarde immédiate à chaque geste.
extends Control

const PinConfig = preload("res://scripts/pin_config.gd")
const UIStyle = preload("res://scripts/ui_style.gd")
const AppliExternes = preload("res://scripts/applis_externes.gd")
const Registre = preload("res://scripts/registre_jeux.gd")
const Lang = preload("res://scripts/lang.gd")
const Raccourcis = preload("res://scripts/raccourcis.gd")
const Android = preload("res://scripts/android.gd")
const Pictogramme = preload("res://scripts/pictogramme.gd")
const Bureau = preload("res://scripts/bureau.gd")

const COULEUR_FOND := Color(0.12, 0.25, 0.22)
const COULEUR_VOLET := Color(0.09, 0.20, 0.17)
const COULEUR_CARTE := Color(0.97, 0.96, 0.91)
const COULEUR_TEXTE_CARTE := Color(0.22, 0.20, 0.12)
const COULEUR_TEXTE_DOUX := Color(0.45, 0.42, 0.32)
const COULEUR_ACTIF := Color(0.85, 0.32, 0.24)  # étiquette sélectionnée (rouge coccinelle)
const COULEUR_VERT := Color(0.20, 0.55, 0.35)

var _etiquette := ""  # étiquette filtrante ("" = toutes)
var _recherche := ""
var _vue_liste: Control = null
var _vue_fiche: Control = null
var _grille: GridContainer = null
var _volet: VBoxContainer = null
var _champ_recherche: LineEdit = null


func _ready() -> void:
	var fond := ColorRect.new()
	fond.color = COULEUR_FOND
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)
	_construire_liste()


## Échap : la fiche revient à la liste, la liste revient aux réglages.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _vue_fiche != null:
			_fermer_fiche()
		else:
			_retour_reglages()
		get_viewport().set_input_as_handled()


## Au retour du Play Store (Android), l'écran se reconstruit : le statut de
## l'appli fraîchement installée passe à « installée » sans quitter l'écran.
func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_APPLICATION_FOCUS_IN and OS.has_feature("android"):
		get_tree().reload_current_scene.call_deferred()


# --- Le modèle : toutes les applications, toutes familles confondues ---------

## Fiches unifiées {type, id, nom, description, couleur, etiquettes, …},
## triées par ordre alphabétique (articles et accents neutralisés).
func _toutes_les_applis() -> Array:
	var liste := []
	for appli in Registre.APPLIS:
		if Registre.existe_ici(appli):
			liste.append({"type": "coccos", "id": appli["id"],
				"nom": Lang.t(appli["nom_cle"]), "description": Lang.t(appli["description_cle"]),
				"couleur": appli["couleur"], "picto": appli.get("picto", ""),
				"categorie": appli.get("categorie", ""),
				"etiquettes": Registre.etiquettes_de(appli["id"])})
	for appli in AppliExternes.catalogue_plateforme():
		liste.append({"type": "externe", "id": appli["id"],
			"nom": Lang.t(appli["nom_cle"]), "description": Lang.t(appli["description_cle"]),
			"couleur": appli["couleur"], "picto": appli.get("picto", ""),
			"etiquettes": Registre.etiquettes_de(appli["id"], ["externes"]),
			"catalogue": appli})
	if Android.disponible():
		var choisies: Dictionary = Android.choisies()
		for entree in Android.applis_lancables():
			var id: String = "tel:" + entree["paquet"]
			liste.append({"type": "telephone", "id": id, "paquet": entree["paquet"],
				"nom": entree["nom"], "description": entree["paquet"],
				"couleur": Color(0.35, 0.45, 0.60), "choisie": choisies.has(entree["paquet"]),
				"etiquettes": Registre.etiquettes_de(id, ["téléphone"])})
	liste.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return Bureau._cle_tri(a["nom"]) < Bureau._cle_tri(b["nom"]))
	return liste


## Texte normalisé pour la recherche : minuscules, accents aplanis.
static func _normaliser(texte: String) -> String:
	const ACCENTS := {"é": "e", "è": "e", "ê": "e", "ë": "e", "à": "a", "â": "a",
		"ä": "a", "î": "i", "ï": "i", "ô": "o", "ö": "o", "ù": "u", "û": "u",
		"ü": "u", "ç": "c", "œ": "oe"}
	var bas := texte.to_lower()
	for accent in ACCENTS:
		bas = bas.replace(accent, ACCENTS[accent])
	return bas


## La fiche passe-t-elle le filtre courant (étiquette + recherche) ?
func _visible_au_filtre(appli: Dictionary) -> bool:
	if _etiquette != "" and not (appli["etiquettes"] as Array).has(_etiquette):
		return false
	if _recherche != "":
		var aiguille := _normaliser(_recherche)
		if not _normaliser(appli["nom"]).contains(aiguille) \
				and not _normaliser(appli["description"]).contains(aiguille):
			return false
	return true


## L'application est-elle sur le bureau de l'enfant ? (selon sa famille)
func _est_sur_bureau(appli: Dictionary) -> bool:
	match appli["type"]:
		"coccos":
			return Registre.est_active(appli["id"])
		"externe":
			return AppliExternes.est_active(appli["id"]) and AppliExternes.est_installee(appli["catalogue"])
		"telephone":
			return Android.choisies().has(appli["paquet"])
	return false


# --- Vue liste : volet + recherche + cartes -----------------------------------

func _construire_liste() -> void:
	if _vue_liste != null:
		_vue_liste.queue_free()
	_vue_liste = MarginContainer.new()
	_vue_liste.set_anchors_preset(Control.PRESET_FULL_RECT)
	for cote in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		_vue_liste.add_theme_constant_override(cote, 18)
	add_child(_vue_liste)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 14)
	_vue_liste.add_child(colonne)

	# En-tête : titre + retour aux réglages
	var entete := HBoxContainer.new()
	entete.add_theme_constant_override("separation", 16)
	colonne.add_child(entete)
	var titre := Label.new()
	titre.text = Lang.t("applis_titre")
	titre.add_theme_font_size_override("font_size", 40)
	titre.add_theme_color_override("font_color", Color.WHITE)
	titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entete.add_child(titre)
	# Geste adulte : annule les rangements de l'enfant (confirmation en 2 temps)
	var btn_rangement := Button.new()
	btn_rangement.text = Lang.t("logitheque_reinit_rangement")
	btn_rangement.add_theme_font_size_override("font_size", 22)
	UIStyle.styliser(btn_rangement, Color(0.55, 0.40, 0.20), 12)
	btn_rangement.pressed.connect(_reinitialiser_rangement.bind(btn_rangement))
	entete.add_child(btn_rangement)
	var btn_retour := Button.new()
	btn_retour.text = Lang.t("reglages_retour")
	btn_retour.add_theme_font_size_override("font_size", 22)
	UIStyle.styliser(btn_retour, Color(0.20, 0.55, 0.45), 12)
	btn_retour.pressed.connect(_retour_reglages)
	entete.add_child(btn_retour)

	var corps := HBoxContainer.new()
	corps.add_theme_constant_override("separation", 14)
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colonne.add_child(corps)

	# Volet gauche — les étiquettes
	var panneau_volet := PanelContainer.new()
	var style_volet := StyleBoxFlat.new()
	style_volet.bg_color = COULEUR_VOLET
	style_volet.set_corner_radius_all(14)
	style_volet.content_margin_left = 10.0
	style_volet.content_margin_right = 10.0
	style_volet.content_margin_top = 12.0
	style_volet.content_margin_bottom = 12.0
	panneau_volet.add_theme_stylebox_override("panel", style_volet)
	panneau_volet.custom_minimum_size = Vector2(250, 0)
	corps.add_child(panneau_volet)
	var defil_volet := ScrollContainer.new()
	defil_volet.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panneau_volet.add_child(defil_volet)
	_volet = VBoxContainer.new()
	_volet.add_theme_constant_override("separation", 6)
	_volet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defil_volet.add_child(_volet)

	# Droite — recherche + grille de cartes
	var droite := VBoxContainer.new()
	droite.add_theme_constant_override("separation", 12)
	droite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	corps.add_child(droite)
	_champ_recherche = LineEdit.new()
	_champ_recherche.placeholder_text = Lang.t("logitheque_recherche")
	_champ_recherche.add_theme_font_size_override("font_size", 24)
	_champ_recherche.custom_minimum_size = Vector2(0, 52)
	_champ_recherche.text = _recherche
	_champ_recherche.text_changed.connect(func(texte: String) -> void:
		_recherche = texte
		_remplir_grille())
	droite.add_child(_champ_recherche)
	var defil := ScrollContainer.new()
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defil.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defil.get_v_scroll_bar().custom_minimum_size = Vector2(14, 0)
	droite.add_child(defil)
	_grille = GridContainer.new()
	_grille.columns = 2
	_grille.add_theme_constant_override("h_separation", 12)
	_grille.add_theme_constant_override("v_separation", 12)
	_grille.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defil.add_child(_grille)

	_remplir_volet()
	_remplir_grille()


## Le volet se construit depuis les étiquettes réellement en usage.
func _remplir_volet() -> void:
	for enfant in _volet.get_children():
		enfant.queue_free()
	var titre_volet := Label.new()
	titre_volet.text = Lang.t("logitheque_etiquettes")
	titre_volet.add_theme_font_size_override("font_size", 20)
	titre_volet.add_theme_color_override("font_color", Color(0.60, 0.72, 0.66))
	_volet.add_child(titre_volet)

	var comptes := {}
	for appli in _toutes_les_applis():
		for etiquette in appli["etiquettes"]:
			comptes[etiquette] = comptes.get(etiquette, 0) + 1
	var etiquettes: Array = comptes.keys()
	etiquettes.sort()

	_volet.add_child(_bouton_etiquette(Lang.t("logitheque_toutes"), "", -1))
	for etiquette in etiquettes:
		_volet.add_child(_bouton_etiquette(etiquette, etiquette, comptes[etiquette]))


func _bouton_etiquette(libelle: String, valeur: String, compte: int) -> Button:
	var btn := Button.new()
	btn.text = libelle + ("" if compte < 0 else "  (%d)" % compte)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 22)
	btn.custom_minimum_size = Vector2(0, 48)
	if valeur == _etiquette:
		UIStyle.styliser(btn, COULEUR_ACTIF, 10)
	else:
		UIStyle.styliser(btn, COULEUR_VOLET.lightened(0.06), 10)
	btn.pressed.connect(func() -> void:
		_etiquette = valeur
		_remplir_volet()
		_remplir_grille())
	return btn


func _remplir_grille() -> void:
	for enfant in _grille.get_children():
		enfant.queue_free()
	var visibles := 0
	for appli in _toutes_les_applis():
		if _visible_au_filtre(appli):
			_grille.add_child(_creer_carte(appli))
			visibles += 1
	if visibles == 0:
		var vide := Label.new()
		vide.text = Lang.t("logitheque_aucun_resultat")
		vide.add_theme_font_size_override("font_size", 24)
		vide.add_theme_color_override("font_color", Color(0.60, 0.72, 0.66))
		_grille.add_child(vide)


## Une carte : icône + nom + descriptif court + statut. Clic = la fiche.
func _creer_carte(appli: Dictionary) -> Control:
	var carte := Button.new()
	carte.custom_minimum_size = Vector2(430, 110)
	carte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = COULEUR_CARTE
	style.set_corner_radius_all(12)
	carte.add_theme_stylebox_override("normal", style)
	var style_survol: StyleBoxFlat = style.duplicate()
	style_survol.bg_color = Color.WHITE
	carte.add_theme_stylebox_override("hover", style_survol)
	carte.add_theme_stylebox_override("pressed", style_survol)
	var style_focus: StyleBoxFlat = style.duplicate()
	style_focus.border_color = Color(0.95, 0.72, 0.15)
	style_focus.set_border_width_all(4)
	carte.add_theme_stylebox_override("focus", style_focus)

	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 14)
	ligne.set_anchors_preset(Control.PRESET_FULL_RECT)
	ligne.offset_left = 12
	ligne.offset_top = 10
	ligne.offset_right = -12
	ligne.offset_bottom = -10
	ligne.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carte.add_child(ligne)

	ligne.add_child(_creer_icone(appli, 72))

	var textes := VBoxContainer.new()
	textes.alignment = BoxContainer.ALIGNMENT_CENTER
	textes.add_theme_constant_override("separation", 2)
	textes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ligne.add_child(textes)
	var nom := Label.new()
	nom.text = appli["nom"]
	nom.add_theme_font_size_override("font_size", 25)
	nom.add_theme_color_override("font_color", COULEUR_TEXTE_CARTE)
	nom.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	textes.add_child(nom)
	var desc := Label.new()
	desc.text = appli["description"]
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", COULEUR_TEXTE_DOUX)
	desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	textes.add_child(desc)
	var statut := Label.new()
	statut.add_theme_font_size_override("font_size", 16)
	if appli["type"] == "externe" and not AppliExternes.est_installee(appli["catalogue"]):
		statut.text = Lang.t("applis_statut_non_installee")
		statut.add_theme_color_override("font_color", Color(0.75, 0.40, 0.25))
	elif _est_sur_bureau(appli):
		statut.text = "✔ " + Lang.t("logitheque_sur_bureau")
		statut.add_theme_color_override("font_color", COULEUR_VERT)
	else:
		statut.text = Lang.t("logitheque_masquee")
		statut.add_theme_color_override("font_color", COULEUR_TEXTE_DOUX)
	textes.add_child(statut)

	carte.pressed.connect(_ouvrir_fiche.bind(appli))
	return carte


## L'icône d'une appli, à la taille voulue : image « livrée coccinelle » si
## présente, icône système du téléphone si extraite, sinon plaque colorée
## avec pictogramme (ou initiale pour les applis du téléphone).
func _creer_icone(appli: Dictionary, taille: int) -> Control:
	var cadre := PanelContainer.new()
	cadre.custom_minimum_size = Vector2(taille, taille)
	cadre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(int(taille / 5.0))
	style.bg_color = appli["couleur"]

	var chemin_res := "res://assets/icones/%s.png" % appli["id"]
	var chemin_tel := "user://icones_android/%s.png" % appli.get("paquet", "")
	if appli["type"] == "coccos" and ResourceLoader.exists(chemin_res):
		style.bg_color = Color.TRANSPARENT
		cadre.add_theme_stylebox_override("panel", style)
		var image := TextureRect.new()
		image.texture = load(chemin_res)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cadre.add_child(image)
	elif appli["type"] == "telephone" and FileAccess.file_exists(chemin_tel):
		style.bg_color = Color.TRANSPARENT
		cadre.add_theme_stylebox_override("panel", style)
		var image_tel := Image.load_from_file(chemin_tel)
		if image_tel != null and not image_tel.is_empty():
			var affichage := TextureRect.new()
			affichage.texture = ImageTexture.create_from_image(image_tel)
			affichage.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			affichage.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cadre.add_child(affichage)
	elif appli["type"] == "telephone":
		# Icône système pas encore extraite : plaque + initiale
		cadre.add_theme_stylebox_override("panel", style)
		var initiale := Label.new()
		initiale.text = String(appli["nom"]).left(1).to_upper()
		initiale.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initiale.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		initiale.add_theme_font_size_override("font_size", int(taille * 0.5))
		initiale.add_theme_color_override("font_color", Color.WHITE)
		cadre.add_child(initiale)
	else:
		cadre.add_theme_stylebox_override("panel", style)
		var picto: Control = Pictogramme.new()
		picto.id = appli["picto"] if appli.get("picto", "") != "" else appli["id"]
		picto.couleur_creux = (appli["couleur"] as Color).darkened(0.25)
		picto.custom_minimum_size = Vector2(taille * 0.7, taille * 0.7)
		picto.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		picto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cadre.add_child(picto)
	return cadre


# --- La fiche d'une application ------------------------------------------------

func _ouvrir_fiche(appli: Dictionary) -> void:
	_vue_liste.visible = false
	_construire_fiche(appli)


func _fermer_fiche() -> void:
	if _vue_fiche != null:
		_vue_fiche.queue_free()
		_vue_fiche = null
	# Reconstruction : les statuts (« Sur le bureau ») ont pu changer
	_construire_liste()


func _construire_fiche(appli: Dictionary) -> void:
	if _vue_fiche != null:
		_vue_fiche.queue_free()
	var defil := ScrollContainer.new()
	defil.set_anchors_preset(Control.PRESET_FULL_RECT)
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(defil)
	_vue_fiche = defil

	var marge := MarginContainer.new()
	marge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for cote in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		marge.add_theme_constant_override(cote, 28)
	defil.add_child(marge)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 18)
	colonne.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marge.add_child(colonne)

	# ← Retour à la logithèque
	var btn_retour := Button.new()
	btn_retour.text = "←  " + Lang.t("logitheque_retour_liste")
	btn_retour.add_theme_font_size_override("font_size", 22)
	btn_retour.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	UIStyle.styliser(btn_retour, Color(0.20, 0.55, 0.45), 12)
	btn_retour.pressed.connect(_fermer_fiche)
	colonne.add_child(btn_retour)

	# En-tête : icône + titre/type + actions
	var entete := HBoxContainer.new()
	entete.add_theme_constant_override("separation", 20)
	colonne.add_child(entete)
	entete.add_child(_creer_icone(appli, 110))
	var titres := VBoxContainer.new()
	titres.alignment = BoxContainer.ALIGNMENT_CENTER
	titres.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entete.add_child(titres)
	var nom := Label.new()
	nom.text = appli["nom"]
	nom.add_theme_font_size_override("font_size", 38)
	nom.add_theme_color_override("font_color", Color.WHITE)
	titres.add_child(nom)
	var type_appli := Label.new()
	type_appli.text = Lang.t("logitheque_type_" + appli["type"])
	if appli["type"] == "coccos" and appli.get("categorie", "") != "":
		type_appli.text += " · " + Lang.t(Registre.CATEGORIES[appli["categorie"]]["nom_cle"])
	type_appli.add_theme_font_size_override("font_size", 20)
	type_appli.add_theme_color_override("font_color", Color(0.60, 0.72, 0.66))
	titres.add_child(type_appli)

	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	entete.add_child(actions)
	_creer_actions(appli, actions)

	# Descriptif
	var desc := Label.new()
	desc.text = appli["description"]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 24)
	desc.add_theme_color_override("font_color", Color(0.88, 0.93, 0.90))
	colonne.add_child(desc)

	# Étiquettes configurables
	colonne.add_child(_creer_rang_etiquettes(appli))

	# Galerie (emplacement réservé — captures à venir)
	var galerie := Label.new()
	galerie.text = Lang.t("logitheque_galerie")
	galerie.add_theme_font_size_override("font_size", 18)
	galerie.add_theme_color_override("font_color", Color(0.45, 0.58, 0.52))
	colonne.add_child(galerie)


## Les actions de l'en-tête selon la famille : interrupteur « Sur le bureau »,
## installation (externes), icône sur l'appareil (jeux CoccOs).
func _creer_actions(appli: Dictionary, actions: VBoxContainer) -> void:
	var id: String = appli["id"]
	match appli["type"]:
		"coccos":
			actions.add_child(_interrupteur_bureau(Registre.est_active(id),
				func(actif: bool) -> void: Registre.activer(id, actif)))
			if Raccourcis.possible():
				var btn_icone := Button.new()
				btn_icone.text = Lang.t("logitheque_btn_raccourci")
				btn_icone.add_theme_font_size_override("font_size", 18)
				UIStyle.styliser(btn_icone, Color(0.35, 0.50, 0.65), 10)
				var nom_appli: String = appli["nom"]
				btn_icone.pressed.connect(func() -> void:
					btn_icone.text = Lang.t(Raccourcis.creer(id, nom_appli)))
				actions.add_child(btn_icone)
		"externe":
			if AppliExternes.est_installee(appli["catalogue"]):
				actions.add_child(_interrupteur_bureau(AppliExternes.est_active(id),
					func(actif: bool) -> void:
						PinConfig.ecrire_option("applis_externes", id, actif)))
			else:
				var statut := Label.new()
				statut.text = Lang.t("applis_statut_non_installee")
				statut.add_theme_font_size_override("font_size", 20)
				statut.add_theme_color_override("font_color", Color(1.0, 0.6, 0.45))
				actions.add_child(statut)
				var btn_installer := Button.new()
				btn_installer.text = Lang.t("applis_btn_installer")
				btn_installer.add_theme_font_size_override("font_size", 22)
				UIStyle.styliser(btn_installer, Color(0.25, 0.45, 0.75), 12)
				btn_installer.pressed.connect(
					_installer.bind(appli["catalogue"], statut, btn_installer))
				actions.add_child(btn_installer)
		"telephone":
			var paquet: String = appli["paquet"]
			var nom_tel: String = appli["nom"]
			actions.add_child(_interrupteur_bureau(Android.choisies().has(paquet),
				func(actif: bool) -> void: Android.choisir(paquet, nom_tel, actif)))


func _interrupteur_bureau(actif: bool, au_changement: Callable) -> CheckButton:
	var interrupteur := CheckButton.new()
	interrupteur.text = " " + Lang.t("logitheque_sur_bureau")
	interrupteur.add_theme_font_size_override("font_size", 22)
	for etat in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		interrupteur.add_theme_color_override(etat, Color.WHITE)
	interrupteur.button_pressed = actif
	interrupteur.toggled.connect(au_changement)
	return interrupteur


## La rangée d'étiquettes : défauts du manifeste (fixes) + ajouts de l'adulte
## (retirables d'un tap) + le bouton « + étiquette… » qui ouvre un champ.
func _creer_rang_etiquettes(appli: Dictionary) -> Control:
	var rang := HFlowContainer.new()
	rang.add_theme_constant_override("h_separation", 10)
	rang.add_theme_constant_override("v_separation", 8)
	var ajouts: Array = Registre.etiquettes_ajoutees(appli["id"])
	for etiquette in appli["etiquettes"]:
		var chip := Button.new()
		var ajoutee: bool = ajouts.has(etiquette)
		chip.text = (etiquette + "  ✕") if ajoutee else etiquette
		chip.add_theme_font_size_override("font_size", 19)
		chip.disabled = not ajoutee
		UIStyle.styliser(chip, Color(0.25, 0.42, 0.38) if ajoutee else Color(0.20, 0.34, 0.30), 16)
		if ajoutee:
			var id: String = appli["id"]
			chip.pressed.connect(func() -> void:
				Registre.retirer_etiquette(id, etiquette)
				_rafraichir_fiche(id))
		rang.add_child(chip)

	var champ := LineEdit.new()
	champ.placeholder_text = Lang.t("logitheque_etiquette_placeholder")
	champ.add_theme_font_size_override("font_size", 19)
	champ.custom_minimum_size = Vector2(240, 0)
	champ.visible = false
	var btn_plus := Button.new()
	btn_plus.text = Lang.t("logitheque_ajouter_etiquette")
	btn_plus.add_theme_font_size_override("font_size", 19)
	UIStyle.styliser(btn_plus, Color(0.30, 0.30, 0.26), 16)
	btn_plus.pressed.connect(func() -> void:
		btn_plus.visible = false
		champ.visible = true
		champ.grab_focus())
	var id_appli: String = appli["id"]
	champ.text_submitted.connect(func(texte: String) -> void:
		Registre.ajouter_etiquette(id_appli, texte)
		_rafraichir_fiche(id_appli))
	rang.add_child(btn_plus)
	rang.add_child(champ)
	return rang


## Reconstruit la fiche après une modification d'étiquettes (données fraîches).
func _rafraichir_fiche(id: String) -> void:
	for appli in _toutes_les_applis():
		if appli["id"] == id:
			_construire_fiche(appli)
			return


## Installation graphique d'une externe, suivie depuis la fiche (jamais de
## terminal — pkexec/apt sur Linux, fiche Play Store sur Android).
func _installer(catalogue: Dictionary, statut: Label, btn: Button) -> void:
	var pid: int = AppliExternes.installer(catalogue)
	if pid == -1:
		statut.text = Lang.t("applis_statut_play_store" if OS.has_feature("android")
			else "applis_statut_logitheque")
		statut.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		return
	btn.disabled = true
	statut.text = Lang.t("applis_statut_en_cours")
	statut.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	while OS.is_process_running(pid):
		await get_tree().create_timer(2.0).timeout
		if not is_instance_valid(statut):
			return  # l'écran a été quitté pendant l'installation
	if not is_instance_valid(statut):
		return
	if AppliExternes.est_installee(catalogue):
		_rafraichir_fiche(catalogue["id"])
	else:
		statut.text = Lang.t("applis_statut_echec")
		statut.add_theme_color_override("font_color", Color(1.0, 0.6, 0.45))
		btn.disabled = false


## « Remettre le rangement par défaut » : 1er clic = « Confirmer ? », 2e clic =
## chaque jeu retourne dans son dossier du manifeste ([bureau_rangement] effacée,
## rien d'autre). Le bureau relit ce choix à sa prochaine ouverture.
func _reinitialiser_rangement(btn: Button) -> void:
	if btn.text.ends_with(Lang.t("classeur_btn_confirmer")):
		Registre.reinitialiser_rangement()
		btn.text = Lang.t("logitheque_reinit_fait")
		btn.disabled = true
	else:
		btn.text = Lang.t("logitheque_reinit_rangement") + "  —  " + Lang.t("classeur_btn_confirmer")


func _retour_reglages() -> void:
	get_tree().change_scene_to_file("res://scenes/adult_settings.tscn")
