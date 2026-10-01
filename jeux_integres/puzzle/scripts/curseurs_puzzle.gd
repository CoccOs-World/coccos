extends RefCounted
class_name CurseursPuzzle

# ============================================================================================================
# LES TROIS CURSEURS DU JEU DES PUZZLES (PUZZLE-B2, REQ_260814_PUZZLE_B2_accueil_zoom_suggestions_responsive)
#
# POURQUOI CE FICHIER EXISTE ALORS QU'IL NE FAIT QUE TROIS CHOSES : le choix du curseur se fait sur l'ACCUEIL
# (`accueil.gd`) et il s'applique DANS LE JEU (`puzzle.gd`) — deux scènes, deux fichiers, un seul réglage. Écrire
# la table à deux endroits, c'est prendre rendez-vous avec le jour où l'un des deux aura un point chaud périmé et
# où l'enfant cliquera à 40 px de là où il vise. Un seul endroit la porte, les deux la lisent.
#
# ⚠ LES POINTS CHAUDS NE SONT PAS DES VALEURS DE CONFORT : ils sont RÉGLÉS PAR FABRICE dans Pousse-Pollen, repris
#   chiffre pour chiffre par le jeu des 7 différences, et repris ici de la même façon. `chaud` est la fraction de
#   l'image où se trouve LE POINT QUI CLIQUE — le bout du doigt de la main, la tête de la coccinelle, celle de
#   l'abeille. Sans lui, le pointeur clique par son coin supérieur gauche, soit à ~55 px de la pointe visée sur un
#   curseur de 64 px : une pièce sur deux se prendrait « à côté ».
#
# ⚠ LES FICHIERS SONT DES COPIES, PAS DES EMPRUNTS (règle de Fabrice, 14-08 — GDD §6) : `images/curseurs/` de CE
#   projet contient les trois PNG en propre (copiés le 14-08 depuis les assets inter-jeux, octets identiques,
#   vérifiés au md5). Aucun chemin ne sort de « le jeu des puzzles ». C'est le contrôle ⓪ du harnais.
#
# ⚠ LE CHOIX SURVIT À L'EXTINCTION : il est noté dans `user://` (le `user://` de CE jeu — son nom de projet lui
#   est propre, il ne peut pas toucher la sauvegarde d'un autre jeu). Un enfant qui a choisi l'abeille hier la
#   retrouve aujourd'hui, et l'accueil s'ouvre avec SON ami déjà entouré.
# ============================================================================================================

# ============================================================================================================
# ⚠⚠ (B10) `ancre` ENTRE DANS LA TABLE — LÀ OÙ LE DOIGT TIENT LE SPRITE, ET C'EST CE QUI REND LA POINTE VISIBLE
#    SUR UN ÉCRAN TACTILE
# ============================================================================================================
# POURQUOI IL EN FAUT UN SECOND ALORS QUE `chaud` EXISTE DÉJÀ. Sur un téléphone il n'y a AUCUN pointeur de souris :
# le curseur y est DESSINÉ et c'est le doigt qui le promène. Si le doigt le tenait par sa POINTE, la pulpe
# couvrirait exactement le pixel qu'on vise — l'enfant prendrait ses pièces à l'aveugle. Les mots de Fabrice (7
# différences B14) : « le doigt du joueur est légèrement décalé, exprès, pour que le bout du curseur reste
# visible ». `chaud` dit CE QUI VISE, `ancre` dit CE QUE LE DOIGT TIENT ; leur différence EST le décalage.
#
# ⚠⚠ LES SIX VALEURS SONT CELLES DE FABRICE, COPIÉES CHIFFRE POUR CHIFFRE — il les a MARQUÉES lui-même sur chacun
#   des trois curseurs avec `marqueur_curseur.html` (`chaud` dans Pousse-Pollen, `ancre` au jeu des 7 différences,
#   sa B14), et le jeu des points reliés les a reprises telles quelles (sa B3). Elles ne sont NI déduites NI
#   redécouvertes ici : les redéduire à l'œil décalerait la prise de l'enfant de plusieurs dizaines de pixels, et
#   rien ne le signalerait.
# ⚠ ET LA REPRISE EST LÉGITIME PARCE QUE LES FICHIERS SONT LES MÊMES À L'OCTET : les trois PNG de
#   `res://images/curseurs/` de CE projet ont le md5 de ceux du 7 différences et des points reliés (contrôle ⓪bis
#   du harnais B10). Une fraction reprise d'une image DIFFÉRENTE serait une croyance ; reprise de la MÊME image,
#   c'est une mesure. Les VALEURS se copient, les CHEMINS ne s'empruntent pas.
# ⚠ CE QUE `ancre` VAUT, LU SUR LES SPRITES : le milieu-bas du corps (0,753 de la hauteur pour la main — la pulpe
#   tient le poignet ; 0,594 et 0,585 pour la coccinelle et l'abeille — entre la tête et l'abdomen). Les deux
#   valeurs étant des FRACTIONS, grossir le curseur ne déplace ni la pointe ni la prise.
const DOSSIER := "res://jeux_integres/puzzle/images/curseurs/"
# ============================================================================================================
# ⚠⚠ (B23 · GDD §31.1) LA **MAIN REVIENT**, ELLE REPREND L'INDEX 0, ET « SANS CURSEUR » PASSE EN **QUATRIÈME**
# ============================================================================================================
# Fabrice, mot pour mot (14-09) : « Il faut remettre la main parce que sur ordinateur Linux, il est bien courant
# qu'on ne soit pas avec des écrans tactiles, surtout si on utilise des vidéoprojecteurs. Donc bien sûr qu'il faut
# remettre la main. »
#
# CE QUE B14 (§22) AVAIT FAIT, ET POURQUOI ON LE CORRIGE : « Sans curseur » y avait PRIS LA PLACE 0 de la Main. La
# demande de l'époque portait sur le TACTILE — mais une entrée ÉCRASÉE vaut pour TOUT LE MONDE, donc le bureau
# avait basculé lui aussi et celui qui joue à la souris s'est retrouvé sans le pointeur dessiné. Le puzzle ADULTE a
# reçu la bonne forme en premier (sa B13, §26) : une QUATRIÈME entrée, les index 0 · 1 · 2 intacts. On la reprend
# ici À L'IDENTIQUE, à UNE différence près, qui est la demande de Fabrice : au BUREAU le défaut est la **MAIN**
# (le puzzle adulte, lui, garde la coccinelle).
#
# ⚠⚠ POURQUOI L'INDEX 3 POUR « SANS CURSEUR » ET NON UN INDEX −1 : tout le jeu et tout l'accueil lisent cette
#   table — les cases de l'accueil, `clampi(i, 0, size − 1)`, les groupes `case_curseur_i` de l'outil DEV, les
#   dispositions que Fabrice a réglées à la souris (§20.3). Une entrée SANS FICHIER ne demande aucun cas
#   particulier ; le seul test qui la distingue est `sans_curseur()`, ci-dessous.
# ⚠⚠ ET CE N'EST PAS L'ORDRE D'AFFICHAGE : l'accueil ne montre JAMAIS quatre cases. Il montre TROIS EMPLACEMENTS
#   (`case_curseur_0/1/2`, les mêmes qu'avant), remplis par `visibles()` — au bureau Main · Coccinelle · Abeille,
#   sur Android Sans curseur · Coccinelle · Abeille. **AUCUNE MIGRATION** des dispositions de Fabrice : seul le
#   CONTENU de la case de rang 0 change selon la cible, jamais sa place.
# ⚠ LE SEUL RÉGLAGE QUI CHANGE DE SENS EST `user://reglages_puzzle.cfg` : un « 0 » écrit sous B14 valait « Sans
#   curseur », il vaut désormais « Main ». Au bureau c'est EXACTEMENT le défaut que Fabrice demande ; sur Android
#   la Main n'est pas dans `visibles()`, donc `lire_choix()` retombe sur « Sans curseur ». Les deux cibles
#   atterrissent sur le bon curseur SANS une ligne de migration — c'est ce qui rend le changement d'index sûr.
# ------------------------------------------------------------------------------------------------------------
# ⚠⚠ (B23 · §31.2) `facteur` ENTRE DANS LA TABLE — **LA MAIN EST DEUX FOIS PLUS PETITE, ET ELLE SEULE**
# ------------------------------------------------------------------------------------------------------------
# Fabrice, mot pour mot : « cette fameuse main blanche est beaucoup moins précise que les curseurs coccos, et l'ami
# l'abeille. Pour lui donner un peu plus de précision, on va réduire sa taille. la petite main blanche deux fois
# [moins] grosse. » — « ça va être général. »
#
# ⚠ POURQUOI UN FACTEUR DANS LA TABLE PLUTÔT QU'UN `if i == 0` ÉCRIT DANS `poser()` : la taille est une PROPRIÉTÉ
#   DU CURSEUR, au même titre que son point chaud. Écrite ici, elle vaut pour les DEUX endroits qui posent un
#   curseur — le pointeur de souris (`poser`, ce fichier) et le sprite DESSINÉ au doigt (`puzzle.gd`,
#   `_taille_curseur_doigt`) — sans qu'aucun des deux n'ait à savoir LEQUEL des amis est petit. « Ça va être
#   général », au mot, et en un seul endroit.
# ⚠ ET `chaud`/`ancre` SONT DES FRACTIONS : réduire la Main ne déplace donc NI la pointe qui clique NI la prise du
#   doigt. C'est précisément ce qui rend la réduction gratuite — aucune des six valeurs de Fabrice ne bouge, et la
#   pointe reste sur le bout du doigt du gant à 32 px comme elle y était à 64.
const TABLE := [
	{"nom": "Main", "fichier": "main.png", "chaud": Vector2(0.69, 0.05), "ancre": Vector2(0.518, 0.753), "facteur": 0.5},
	{"nom": "Coccinelle", "fichier": "coccinelle.png", "chaud": Vector2(0.16, 0.12), "ancre": Vector2(0.533, 0.594), "facteur": 1.0},
	{"nom": "Abeille", "fichier": "abeille.png", "chaud": Vector2(0.14, 0.12), "ancre": Vector2(0.534, 0.585), "facteur": 1.0},
	{"nom": "Sans curseur", "fichier": "", "chaud": Vector2(0.5, 0.5), "ancre": Vector2(0.5, 0.5), "facteur": 1.0},
]
const DEFAUT := 0                       # (B23 · §31.1) BUREAU : la MAIN — « bien sûr qu'il faut remettre la main »
const SANS := 3                         # (B23 · §31.1) l'entrée « sans curseur » — ANDROID par défaut
const HAUTEUR := 64.0                   # la hauteur de RÉFÉRENCE du pointeur posé — × `facteur` : la Main tombe à 32
const REGLAGE := "user://reglages_puzzle.cfg"


# (B23 · §31.1) LE COMMUTATEUR DU HARNAIS — et il est là POUR QUE LA PREUVE PUISSE ÊTRE CONTREFACTUELLE.
# ⚠⚠ SANS LUI, LA DEMANDE DE FABRICE SERAIT INVÉRIFIABLE SUR SON POSTE : « bureau → Main, Android → sans curseur »
#   est une affirmation sur DEUX plateformes, et la preuve tourne sur UNE seule (Linux). Ce drapeau laisse le
#   harnais jouer les deux côtés dans le même run, et donc MESURER que le bureau ne bascule pas.
# ⚠ IL EST FAUX PAR DÉFAUT ET RIEN DANS LE JEU NE L'ÉCRIT : seul `outils/` le pose. Le jeu livré ne lit que
#   `OS.has_feature("android")`, vrai dans le paquet Android et faux ailleurs — par construction.
static var forcer_android := false


# (B23 · §31.1) SOMMES-NOUS SUR ANDROID ? La SEULE porte — le jeu, l'accueil et le harnais la lisent tous ici, et
# aucun d'eux ne rappelle `OS.has_feature` pour son compte (deux lecteurs finissent toujours par avoir deux
# vérités : c'est la leçon qui a fait naître ce fichier).
static func android() -> bool:
	return forcer_android or OS.has_feature("android")


# (B23 · §31.1) LE DÉFAUT, SELON LA PLATEFORME — « bureau → la MAIN ; Android → sans curseur ».
# ⚠ C'EST UNE FONCTION ET NON UNE CONSTANTE, et il le fallait : une `const` est figée à la compilation, elle ne
#   peut pas répondre « ça dépend de la cible ». Les deux scènes (`accueil.gd`, `puzzle.gd`) l'appellent.
static func defaut() -> int:
	return SANS if android() else DEFAUT


# (B23 · §31.1) LES TROIS ENTRÉES MONTRÉES À L'ACCUEIL, DANS L'ORDRE DES TROIS EMPLACEMENTS.
# ⚠ SUR ANDROID LA MAIN SORT ET « SANS CURSEUR » PREND SON EMPLACEMENT (le rang 0), Coccinelle et Abeille gardent
#   les rangs 1 et 2 : les trois `case_curseur_i` restent au même endroit de l'écran, seule la case 0 change de
#   CONTENU. C'est ce qui rend la disposition de Fabrice valable telle quelle.
# ⚠ DEUX BRANCHES ÉCRITES EN ENTIER, ET CE N'EST PAS DE LA VERBOSITÉ : un ternaire (`[…] if … else […]`) rend un
#   `Array` NU, que GDScript refuse ensuite d'affecter à un `Array[int]` — l'erreur tombe À L'EXÉCUTION, pas à la
#   compilation. Le puzzle adulte l'a payée au premier run de son harnais (sa B13) ; on ne la repaie pas.
static func visibles() -> Array[int]:
	var v: Array[int] = []
	if android():
		v.append(SANS)
	else:
		v.append(0)
	v.append(1)
	v.append(2)
	return v


# (B23) COMBIEN D'ENTRÉES ATTENDENT UN FICHIER IMAGE — le compte que les harnais et l'accueil comparent au nombre
# de textures réellement chargées depuis le paquet. Il valait `TABLE.size()` tant que toutes les entrées avaient
# une image ; confondre les deux ferait tomber un rouge sur un jeu juste.
static func nombre_images() -> int:
	var n := 0
	for i in TABLE.size():
		if not sans_curseur(i):
			n += 1
	return n


# (B23 · §31.2) LE FACTEUR DE TAILLE D'UN CURSEUR — 0,5 pour la Main, 1,0 pour les deux amis. Une seule porte,
# lue par le pointeur de souris ET par le sprite dessiné au doigt.
static func facteur(i: int) -> float:
	return float(TABLE[i].get("facteur", 1.0)) if i >= 0 and i < TABLE.size() else 1.0


# (B23 · §31.2) LA HAUTEUR RÉELLEMENT POSÉE POUR CE CURSEUR — 32 px pour la Main, 64 pour la coccinelle et
# l'abeille. C'est ce nombre que le harnais relit, et c'est le même que celui qui sert à redimensionner l'image.
static func hauteur(i: int) -> float:
	return HAUTEUR * facteur(i)


# (B14 · §22) LE SEUL TEST QUI DISTINGUE L'ENTRÉE « SANS CURSEUR » — et il se lit sur la table, pas sur un index
# écrit en dur : le jour où l'ordre des amis changerait, ce test suivrait tout seul. Un index hors table rend
# `true` (pas de curseur) plutôt que de faire semblant d'en avoir un.
static func sans_curseur(i: int) -> bool:
	if i < 0 or i >= TABLE.size():
		return true
	return str(TABLE[i]["fichier"]) == ""


# La texture d'un curseur, ou `null` si le fichier manque (l'accueil l'écrit alors en toutes lettres au lieu de
# dessiner un curseur de remplacement — on ne fait pas semblant).
# ⚠ (B14) « SANS CURSEUR » REND `null` **PAR CONSTRUCTION**, et c'est ce qui fait tomber tout le reste sans un
#   seul cas particulier : `_taille_curseur_doigt()` rend zéro, donc `_decal_plein()` aussi, donc la pointe visée
#   EST le doigt, et le nœud dessiné reste invisible. C'est le mode d'avant le bouton, retrouvé par soustraction.
static func texture(i: int) -> Texture2D:
	if i < 0 or i >= TABLE.size() or sans_curseur(i):
		return null
	var chemin: String = DOSSIER + str(TABLE[i]["fichier"])
	if not ResourceLoader.exists(chemin):
		return null
	return load(chemin) as Texture2D


# POSER le curseur choisi comme pointeur de souris. Rend la taille réellement posée (le harnais la relit).
# ⚠ `duplicate()` sur l'image : la texture est partagée avec l'aperçu de l'accueil ; la redimensionner en place
#   rétrécirait aussi la vignette affichée. Payé une fois, jamais deux.
# ⚠ (B10) `decompress()` AVANT DE REDIMENSIONNER, ET CE N'EST PAS UNE PRÉCAUTION DE STYLE : depuis B5,
#   `project.godot` porte `textures/vram_compression/import_etc2_astc=true` (sans quoi Godot REFUSE d'exporter
#   vers Android). Le paquet Android reçoit donc une VARIANTE compressée en VRAM des trois curseurs, et sur cette
#   variante `get_image()` rend une Image COMPRESSÉE — `resize()` la refuse alors en erreur et le pointeur posé
#   serait vide. C'est le correctif que le jeu des points reliés a dû écrire (sa B3) ; on ne le repaie pas ici.
# ⚠⚠ (B14 · §22) « SANS CURSEUR » **REND LE POINTEUR SYSTÈME**, ET IL FAUT L'ÉCRIRE EXPRESSÉMENT :
#   `Input.set_custom_mouse_cursor` est GLOBAL au processus et il PERSISTE. Sans la ligne ci-dessous, un enfant qui
#   ouvre l'accueil avec la coccinelle puis coche « sans curseur » garderait la coccinelle sous la souris jusqu'à
#   la fermeture du jeu — le choix n'aurait aucun effet visible au bureau. `null` restaure la flèche du système.
static func poser(i: int) -> Vector2:
	if sans_curseur(i):
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
		return Vector2.ZERO
	var tex := texture(i)
	if tex == null:
		push_warning("[puzzle] curseur absent ou index hors table : " + str(i))
		return Vector2.ZERO
	var img: Image = tex.get_image().duplicate()
	if img.is_compressed():
		img.decompress()
	# ⚠ (B23 · §31.2) LA HAUTEUR VIENT DE LA TABLE, PLUS DE LA CONSTANTE : la Main est posée à 32 px, la
	#   coccinelle et l'abeille restent à 64. Une seule ligne change, et elle ne connaît aucun index.
	var ech: float = hauteur(i) / float(img.get_height())
	var l := int(round(float(img.get_width()) * ech))
	var h := int(round(float(img.get_height()) * ech))
	img.resize(l, h, Image.INTERPOLATE_LANCZOS)
	var c: Vector2 = chaud(i)                # (B10) la MÊME porte que le curseur dessiné : une seule lecture
	Input.set_custom_mouse_cursor(ImageTexture.create_from_image(img), Input.CURSOR_ARROW,
		Vector2(c.x * float(l), c.y * float(h)))
	return Vector2(float(l), float(h))


# (B10) LES DEUX FRACTIONS, LUES PAR UNE SEULE PORTE. Le pointeur de souris, le curseur dessiné au doigt et le
# harnais lisent tous ici : une table à deux lecteurs finit toujours par avoir deux vérités.
static func chaud(i: int) -> Vector2:
	return TABLE[i]["chaud"] if i >= 0 and i < TABLE.size() else Vector2(0.5, 0.5)


static func ancre(i: int) -> Vector2:
	return TABLE[i]["ancre"] if i >= 0 and i < TABLE.size() else Vector2(0.5, 0.5)


# LE CHOIX RELU. Un réglage absent, illisible ou hors table rend le défaut : le jeu démarre toujours, même si le
# fichier a été effacé à la main.
# ⚠⚠ (B23 · §31.1) LE FILTRE PAR `visibles()` N'EST PAS UNE PRÉCAUTION DE STYLE : sur Android la Main n'est plus
#   proposée, mais le téléphone de Fabrice porte DÉJÀ un `reglages_puzzle.cfg` qui peut la nommer (et le « 0 »
#   qu'y a écrit B14 la nomme, maintenant que l'index 0 est la Main). Sans ce dernier filet, le jeu se serait
#   ouvert sur un curseur que l'accueil ne montre plus — aucune case cochée, et aucun moyen de comprendre
#   pourquoi. Un choix devenu invisible retombe donc sur le défaut de la plateforme.
# ⚠ ET IL NE TOUCHE PAS AU BUREAU : là, `visibles()` rend [0, 1, 2] — tout choix déjà écrit y est valide.
static func lire_choix() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(REGLAGE) != OK:
		return defaut()
	var i := int(cfg.get_value("jeu", "curseur", defaut()))
	if i < 0 or i >= TABLE.size():
		return defaut()
	return i if visibles().has(i) else defaut()


static func noter_choix(i: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load(REGLAGE)                    # on relit d'abord : ce fichier accueillera d'autres réglages plus tard
	cfg.set_value("jeu", "curseur", clampi(i, 0, TABLE.size() - 1))
	cfg.save(REGLAGE)


static func nom(i: int) -> String:
	return str(TABLE[i]["nom"]) if i >= 0 and i < TABLE.size() else "?"
