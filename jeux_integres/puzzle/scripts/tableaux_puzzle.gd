extends RefCounted
class_name TableauxPuzzle

# ============================================================================================================
# LES TABLEAUX DU JEU DES PUZZLES — UN TABLEAU = UNE IMAGE + UNE MUSIQUE
# (PUZZLE-B3, REQ_260814_PUZZLE_B3_victoire_navigation · GDD §7.10, brief §3)
#
# POURQUOI CE FICHIER EXISTE ALORS QU'IL N'Y A QU'UN SEUL TABLEAU AUJOURD'HUI — c'est exactement la demande du
# brief §3 : « rendre la musique et l'image paramétriques par tableau, pour que la balle suivante n'ait qu'à
# AJOUTER le tableau 2 sans refondre l'écran de victoire ». Le jeu ne connaît donc plus « l'image » ni « la
# musique » : il connaît LE TABLEAU COURANT, et lui demande son image et sa musique. Ajouter un tableau, ce sera
# ajouter UNE LIGNE dans `TABLE` ci-dessous et deux fichiers dans `images/` et `audio/` — pas une
# ligne de `puzzle.gd`.
#
# ⚠ (PUZZLE-B4) LE DEUXIÈME TABLEAU EST ARRIVÉ — et il a tenu la promesse de B3 : il s'est ajouté en AJOUTANT UNE
#   LIGNE à la table, sans qu'une seule règle de jeu de `puzzle.gd` change. Ce qui a dû s'ajouter EN PLUS, et
#   qu'on n'avait pas vu venir en B3, c'est la GRILLE : elle ne pouvait pas rester une constante du jeu.
#
# ============================================================================================================
# (B4) POURQUOI LA GRILLE APPARTIENT AU TABLEAU, ET NON AU JEU — la décision de découpe, exposée
# ============================================================================================================
# Quinze pièces ne se posent que de deux façons : 3 colonnes × 5 rangs, ou 5 × 3. Le bon choix ne dépend pas du
# jeu, il dépend de la FORME DU DESSIN — et les deux tableaux n'ont pas la même. On prend, à chaque fois, la
# grille dont la CELLULE est la plus proche du carré : une cellule presque carrée donne une pièce que l'enfant
# reconnaît comme une pièce de puzzle ; une cellule deux fois plus longue que large donne une lamelle.
#
#   • tableau 1 — la ferme, 956 × 1120 (PORTRAIT, rapport 0,85) :
#       3 × 5 → cellule 318,7 × 224,0 (rapport 1,42)   ← retenue (B1b)
#       5 × 3 → cellule 191,2 × 373,3 (rapport 0,51)
#   • tableau 2 — les porcelets, 2048 × 1759 (PAYSAGE/carré, rapport 1,16) :
#       5 × 3 → cellule 409,6 × 586,3 (rapport 0,70)   ← retenue (B4) — c'est la grille que le brief pressentait
#       3 × 5 → cellule 682,7 × 351,8 (rapport 1,94)
#   • tableau 3 — la fusée, 956 × 1120 (PORTRAIT, rapport 0,85) :
#       3 × 5 → cellule 318,7 × 224,0 (rapport 1,42)   ← retenue (B9) — même forme que la ferme, même grille
#       5 × 3 → cellule 191,2 × 373,3 (rapport 0,51)
#   • tableau 4 — la moto, 956 × 1120 (PORTRAIT, rapport 0,85) :
#       3 × 5 → cellule 318,7 × 224,0 (rapport 1,42)   ← retenue (B9)
#       5 × 3 → cellule 191,2 × 373,3 (rapport 0,51)
#   • tableau 5 — le tracteur, 1408 × 768 (PAYSAGE, rapport 1,83) :
#       5 × 3 → cellule 281,6 × 256,0 (rapport 1,10)   ← retenue (B9) — la cellule la plus carrée des cinq
#       3 × 5 → cellule 469,3 × 153,6 (rapport 3,06)   — trois fois plus longue que haute : des lanières
#
# La règle est donc la même aux deux tableaux, et c'est le dessin qui répond. Le reste de la mise en page —
# plateau, couronne, places de départ, modèle réduit, plein écran — se DÉDUISAIT déjà du canvas et du rapport de
# l'image (B2) : il s'adapte tout seul au paysage, sans une constante à retoucher. Le harnais le mesure.
#
# ⚠ POURQUOI 2048 × 1759 ET NON 4758 × 4087, LA TAILLE DU FICHIER DE FABRICE — décision de Code, exposée. Le
#   dessin livré fait 19,4 millions de pixels. Deux raisons de le PLAFONNER À L'IMPORT (`process/size_limit =
#   2048` dans `images/puzzle_02_deux_petit_museau.jpg.import`), et aucune de le garder entier :
#     ① beaucoup de puces Android refusent une texture de plus de 4096 px de côté — 4758 passe sur le bureau de
#       Fabrice et disparaît en silence sur la tablette, exactement le genre de panne qu'on ne voit que chez
#       l'enfant (le paquet Android, c'est B5) ;
#     ② l'image est affichée au plus grand en PLEIN ÉCRAN, soit ~900 px de large sur l'écran de référence :
#       2048 px, c'est déjà plus du double de ce que l'écran peut montrer. La finesse perdue est invisible.
#   Le FICHIER SOURCE, lui, est copié tel quel, octet pour octet (4 515 187 o) : c'est le rendu qui est plafonné,
#   pas le contenu de Fabrice.
#
# ⚠ CHAQUE CONTENU EST UN FICHIER DE CE PROJET (règle de Fabrice, GDD §6 : « on copie les contenus, on ne
#   bifurque pas sur les autres jeux — pas d'ancre pour faire des économies »). La musique du tableau 1 a été
#   COPIÉE le 14-08 depuis `boite_aux_lettres/` vers `res://audio/`, octets identiques (md5 relu), et
#   le fichier de la boîte a été retiré une fois l'ingestion vérifiée. Le harnais remesure les deux points.
#   (B4) L'IMAGE ET LA MUSIQUE DU TABLEAU 2 ont suivi exactement le même chemin le 14-08 : `deux petit
#   museau.jpg` → `res://images/puzzle_02_deux_petit_museau.jpg` (renommée pour suivre la nomenclature du
#   dossier, contenu inchangé) et `deux petit museau.mp3` → `res://audio/` (nom d'origine gardé, comme
#   pour la musique du tableau 1). Boîte vidée après vérification des octets.
#
# ⚠ (B9) LES TROIS TABLEAUX SUIVANTS ONT SUIVI LE MÊME CHEMIN, avec DEUX différences que le brief impose et qui
#   se lisent ici plutôt que dans un journal :
#     ① LA BOÎTE N'A PAS ÉTÉ VIDÉE. Elle contient les contenus d'AUTRES balles (les images « … diferences » du
#       jeu des 7 différences, les musiques n° 2 et n° 3 de chaque thème, la carotte, la citrouille). Seules les
#       SIX sources ingérées ici en sont sorties, vers `DOCS/archives/echanges/` — le reste est resté en place.
#       Retirer plus aurait fait disparaître le contenu d'une balle qui n'est pas encore jouée.
#     ② LA MUSIQUE EST ARRIVÉE EN VIDÉO. Les trois n° 1 sont des `.mp4` (h264 + aac 200 kb/s) : c'est la PISTE
#       AUDIO qui est extraite (`ffmpeg -vn -c:a libmp3lame -b:a 192k -ar 44100 -ac 2`), au profil EXACT du mp3
#       du tableau 2 déjà validé par Fabrice — 192 kb/s, 44,1 kHz, stéréo. Le jeu n'embarque donc aucune image
#       vidéo qu'il ne saurait pas lire, et la durée est celle de la vidéo (30,8 s).
#       Le nom retenu est LE TITRE DE LA CHANSON, sans le préfixe de rangement de la boîte (« fuse 1 »,
#       « moto 1 », « tracteur 1 » sont des repères de tri de Fabrice, pas des titres) : `Boum_dans_le_ciel.mp3`,
#       `Vroum_dans_la_nature.mp3`, `Tof_Tof_le_Tracteur.mp3` — la même règle que `Le_pré_vert_d_Apollo.mp3`.
#     Et les IMAGES sont copiées octet pour octet, renommées à la nomenclature du dossier (`puzzle_03_fusee.jpg`,
#     `puzzle_04_moto.jpg`, `puzzle_05_tracteur.jpg`) : md5 relu des deux côtés. Aucune n'atteint 2048 px, donc
#     aucune ne demande le plafond d'import du tableau 2.
#
# ⚠ LA MUSIQUE NE JOUE **JAMAIS** PENDANT LE PUZZLE (Fabrice, GDD §7.10, mot pour mot : « pendant le puzzle,
#   aucune musique — silence »). Elle n'existe qu'à la victoire, une fois l'image complète affichée en plein
#   écran, et elle passe UNE SEULE FOIS. C'est `puzzle.gd` qui tient cette règle ; ce fichier ne fait que dire
#   QUELLE musique appartient à QUEL tableau.
# ============================================================================================================

const TABLE := [
	{
		"nom": "La ferme",
		"image": "res://jeux_integres/puzzle/images/puzzle_01_ferme_coccinelle_cheval_abeille.png",
		"musique": "res://jeux_integres/puzzle/audio/Le_pré_vert_d_Apollo.mp3",
		"cols": 3, "rangs": 5,          # portrait 956 × 1120 → cellule 318,7 × 224,0 (cf. l'encadré des grilles)
	},
	{
		"nom": "Les porcelets",
		"image": "res://jeux_integres/puzzle/images/puzzle_02_deux_petit_museau.jpg",
		"musique": "res://jeux_integres/puzzle/audio/deux petit museau.mp3",
		"cols": 5, "rangs": 3,          # paysage 2048 × 1759 → cellule 409,6 × 586,3 (cf. l'encadré des grilles)
	},
	{
		"nom": "La fusée",
		"image": "res://jeux_integres/puzzle/images/puzzle_03_fusee.jpg",
		"musique": "res://jeux_integres/puzzle/audio/Boum_dans_le_ciel.mp3",
		"cols": 3, "rangs": 5,          # portrait 956 × 1120 → cellule 318,7 × 224,0 (cf. l'encadré des grilles)
	},
	{
		"nom": "La moto",
		"image": "res://jeux_integres/puzzle/images/puzzle_04_moto.jpg",
		"musique": "res://jeux_integres/puzzle/audio/Vroum_dans_la_nature.mp3",
		"cols": 3, "rangs": 5,          # portrait 956 × 1120 → cellule 318,7 × 224,0 (cf. l'encadré des grilles)
	},
	{
		"nom": "Le tracteur",
		"image": "res://jeux_integres/puzzle/images/puzzle_05_tracteur.jpg",
		"musique": "res://jeux_integres/puzzle/audio/Tof_Tof_le_Tracteur.mp3",
		"cols": 5, "rangs": 3,          # paysage 1408 × 768 → cellule 281,6 × 256,0 (cf. l'encadré des grilles)
	},
	# ------------------------------------------------------------------------------------------------------
	# (B15 · §23) LES QUATRE TABLEAUX À **4 PIÈCES** — AJOUTÉS **EN FIN DE TABLE**, ET C'EST LA DÉCISION CLÉ
	# ------------------------------------------------------------------------------------------------------
	# ⚠⚠ ILS SONT PRÉSENTÉS EN PREMIER À L'ENFANT (§23 : « les tout premiers puzzles ») ET POURTANT ÉCRITS EN
	#   DERNIER ICI. Ce n'est pas une contradiction, c'est la réponse au ⚠⚠ du brief : PLUSIEURS CHOSES SONT
	#   CLÉES PAR L'INDEX DE CETTE TABLE — la progression de Fabrice (`progression_puzzle.cfg`) et, surtout, les
	#   boîtes d'image modèle qu'il a posées À LA MAIN, tableau par tableau, avec l'outil DEV
	#   (`disposition_accueil.gd`, table `"modeles"`, clés 0 → 4, §20.5). Insérer les nouveaux DEVANT aurait
	#   décalé ces cinq clés d'un cran : la boîte réglée pour la ferme serait allée à la fusée, celle du tracteur
	#   (un dessin COUCHÉ, boîte deux fois moins haute) à un dessin DEBOUT. Rien n'aurait planté, et tout aurait
	#   été faux à l'écran.
	#   L'ORDRE DE PRÉSENTATION EST DONC PORTÉ PAR `FAMILLES` (juste dessous), pas par l'ordre de cette table :
	#   les index internes ne bougent JAMAIS, et ce que l'enfant voit suit la liste des familles. C'est
	#   exactement la première des deux voies que le brief autorisait — celle qui ne demande aucune migration
	#   des dispositions.
	# ⚠ AUCUNE MUSIQUE POUR L'INSTANT (§23, mot pour mot : « on n'a pas la musique ») : le champ est VIDE, et
	#   `puzzle.gd:_lancer_musique_tableau` a DÉJÀ le filet qu'il faut — il écrit l'absence au journal et passe
	#   directement aux boutons de fin. La récompense (la fête des coccos + l'image en grand), elle, est
	#   inchangée : elle ne dépend pas de la musique.
	# ⚠ LA GRILLE EST 2 × 2 POUR LES QUATRE, ET C'EST LA RÈGLE B4 QUI RÉPOND, PAS UN CHOIX PAR DÉFAUT — quatre
	#   pièces ne se posent que de trois façons (2 × 2, 1 × 4, 4 × 1), et on prend la cellule la plus proche du
	#   carré :
	#     • coccos 956 × 1120 (0,854)  : 2 × 2 → 478,0 × 560,0 (0,854) ← retenue · 1 × 4 → 3,41 · 4 × 1 → 0,21
	#     • tigrou 1920 × 1920 (1,000) : 2 × 2 → 960,0 × 960,0 (1,000) ← retenue — la cellule PARFAITEMENT carrée
	#     • deux petits chats 1920 × 1920 (1,000) : 2 × 2 → 960,0 × 960,0 (1,000) ← retenue
	#     • petite feuille 896 × 1195 (0,750) : 2 × 2 → 448,0 × 597,5 (0,750) ← retenue · 1 × 4 → 3,00 · 4 × 1 → 0,19
	#   Les quatre tombent donc sur 2 × 2, le défaut que le brief pressentait — mais par le calcul, pas par lui.
	# ⚠ AUCUNE N'ATTEINT 2048 px DE CÔTÉ (1920 au plus) : aucune ne demande le plafond d'import du tableau 2, et
	#   toutes passent la limite de texture des puces Android (4096).
	# ⚠ LES QUATRE FICHIERS SONT COPIÉS **OCTET POUR OCTET** depuis `boite_aux_lettres/puzzle 4 pieces/`, md5
	#   relu des deux côtés, et renommés à la nomenclature du dossier (`puzzle_06_…` → `puzzle_09_…`). Le nom de
	#   travail de Fabrice « deus patit chat » devient `puzzle_08_deux_petits_chats.jpg` : c'est un repère de
	#   dictée, pas un titre.
	{
		"nom": "Les coccos",
		"image": "res://jeux_integres/puzzle/images/puzzle_06_coccos.png",
		"musique": "",                  # (§23) pas encore de musique — le champ est VIDE, jamais un chemin faux
		"cols": 2, "rangs": 2,          # portrait 956 × 1120 → cellule 478,0 × 560,0 (rapport 0,854)
	},
	{
		"nom": "Tigrou",
		"image": "res://jeux_integres/puzzle/images/puzzle_07_tigrou.jpg",
		"musique": "",
		"cols": 2, "rangs": 2,          # carré 1920 × 1920 → cellule 960,0 × 960,0 (rapport 1,000)
	},
	{
		"nom": "Les deux petits chats",
		"image": "res://jeux_integres/puzzle/images/puzzle_08_deux_petits_chats.jpg",
		"musique": "",
		"cols": 2, "rangs": 2,          # carré 1920 × 1920 → cellule 960,0 × 960,0 (rapport 1,000)
	},
	{
		"nom": "La petite feuille",
		"image": "res://jeux_integres/puzzle/images/puzzle_09_petite_feuille.png",
		"musique": "",
		"cols": 2, "rangs": 2,          # portrait 896 × 1195 → cellule 448,0 × 597,5 (rapport 0,750)
		# (B17 · §25) LA RÉCOMPENSE VIDÉO — ET ELLE **REMPLACE** L'IMAGE EN GRAND, elle ne s'y ajoute pas
		# (choix n° 1 de Fabrice, 06-09). C'est la seule ligne de la table qui porte ces deux clés ; partout
		# ailleurs `chemin_video()` rend "" et le jeu garde son flux d'origine, sans une condition de plus.
		"video": "res://jeux_integres/puzzle/video/chat_qui_chante_v5.ogv",
		"video_taille": Vector2(1024.0, 1024.0),
	},
	# ------------------------------------------------------------------------------------------------------
	# (B18 · §26) LES QUATRE TABLEAUX À **30 PIÈCES** — ENCORE AJOUTÉS **EN FIN DE TABLE**
	# ------------------------------------------------------------------------------------------------------
	# ⚠⚠ MÊME RAISON QU'EN B15, ET ELLE N'A PAS FAIBLI : les index de cette table CLÉENT la progression de
	#   Fabrice (`progression_puzzle.cfg`) et les boîtes d'image modèle qu'il a posées à la main
	#   (`disposition_accueil.gd`, table `"modeles"`, clés 0 → 4). On n'insère JAMAIS devant. L'ordre que
	#   l'enfant parcourt est porté par `FAMILLES`, et par lui seul.
	# ⚠⚠ LA FAMILLE S'APPELLE « 30 pièces » — SON NOMBRE DE PIÈCES, PAS SON THÈME (Fabrice, §26, mot pour
	#   mot : « NE PAS la nommer véhicules, ce serait FAUX »). Et c'est vérifiable ici même : la moto (index
	#   3) et le tracteur (index 4) sont des véhicules, et ils sont dans la famille « 15 pièces ». Un nom de
	#   thème mentirait sur deux familles à la fois. Les familles se nomment par le nombre de pièces.
	# ⚠ LA GRILLE EST 5 × 6 POUR LES QUATRE, ET C'EST LA RÈGLE B4 QUI RÉPOND — les quatre dessins font
	#   944 × 1109 (rapport 0,851, DEBOUT), et trente pièces se posent de huit façons. On prend la cellule la
	#   plus proche du carré :
	#     5 × 6  → cellule 188,80 × 184,83 (rapport 1,021)   ← retenue — à 2 % du carré parfait
	#     6 × 5  → cellule 157,33 × 221,80 (rapport 0,709)
	#     3 × 10 → cellule 314,67 × 110,90 (rapport 2,838)
	#     10 × 3 → cellule  94,40 × 369,67 (rapport 0,255)
	#     2 × 15 → cellule 472,00 ×  73,93 (rapport 6,384)   · 15 × 2 → 0,113 · 1 × 30 et 30 × 1 : absurdes
	#   ⚠ ET C'EST **TRENTE** ET NON VINGT PARCE QUE FABRICE L'A TRANCHÉ (§26 : « se rapprocher de 30 plutôt
	#     que de 20 ») — la forme du dessin, elle, aurait aussi bien accueilli un 4 × 5 ; c'est le nombre qui
	#     est une demande, la disposition qui est un calcul.
	# ⚠ AUCUNE N'ATTEINT 2048 px DE CÔTÉ (1109 au plus) : aucune ne demande le plafond d'import du tableau 2,
	#   et toutes passent très loin sous la limite de texture des puces Android (4096).
	# ⚠ LES QUATRE IMAGES SONT COPIÉES **OCTET POUR OCTET** depuis `boite_aux_lettres/{camion,voiture,hélico,
	#   soucoupe vollante}/`, md5 relu des deux côtés, renommées à la nomenclature du dossier
	#   (`puzzle_10_…` → `puzzle_13_…`). L'extension passe de `.jpeg` à `.jpg` : c'est le nom du dossier, pas
	#   le contenu — les octets sont les mêmes, et le harnais le remesure.
	# ⚠⚠ ET LA MUSIQUE, ELLE, EXISTE DÈS LE PREMIER JOUR — c'est la différence nette avec les quatre tableaux
	#   à 4 pièces, dont le champ `musique` est encore vide (§23). Fabrice a tranché la **n° 3** de chaque
	#   thème (§26), pas la n° 1 : `En_route_avec_l_abeille` · `La_balade_en_auto_rouge` ·
	#   `L_envol_en_Helicococcos` · `Sourires_à_bord`. Les quatre sont arrivées en `.mp4` et c'est la PISTE
	#   AUDIO qui est extraite (`ffmpeg -vn -c:a libmp3lame -b:a 192k -ar 44100 -ac 2`), au profil EXACT du
	#   mp3 du tableau 2 validé par Fabrice — 192 kb/s, 44,1 kHz, stéréo, la recette de B9. Le nom retenu est
	#   LE TITRE DE LA CHANSON, sans le préfixe de rangement de la boîte (« 3 » devant « Sourires_à_bord »
	#   est un repère de tri de Fabrice, pas un titre) : la même règle qu'en B9.
	# ⚠ TROIS DES QUATRE CHANSONS DURENT ~2 min 40 (157 s · 151 s · 161 s) LÀ OÙ TOUTES LES PRÉCÉDENTES
	#   FAISAIENT 31 s. Rien à changer pour autant, et c'est écrit ici pour qu'on ne le prenne pas pour une
	#   panne : la musique de victoire passe UNE fois et le **STOP rouge** est là tout du long — c'est
	#   l'enfant qui décide d'écouter jusqu'au bout ou d'abréger (GDD §7.10). La quatrième (« Sourires à
	#   bord », 31 s) est au format des anciennes.
	{
		"nom": "Le camion",
		"image": "res://jeux_integres/puzzle/images/puzzle_10_camion.jpg",
		"musique": "res://jeux_integres/puzzle/audio/En_route_avec_l_abeille.mp3",
		"cols": 5, "rangs": 6,          # debout 944 × 1109 → cellule 188,80 × 184,83 (rapport 1,021)
	},
	{
		"nom": "La voiture",
		"image": "res://jeux_integres/puzzle/images/puzzle_11_voiture.jpg",
		"musique": "res://jeux_integres/puzzle/audio/La_balade_en_auto_rouge.mp3",
		"cols": 5, "rangs": 6,          # debout 944 × 1109 → cellule 188,80 × 184,83 (rapport 1,021)
	},
	{
		"nom": "L'hélicoccos",
		"image": "res://jeux_integres/puzzle/images/puzzle_12_helicoccos.jpg",
		"musique": "res://jeux_integres/puzzle/audio/L_envol_en_Helicococcos.mp3",
		"cols": 5, "rangs": 6,          # debout 944 × 1109 → cellule 188,80 × 184,83 (rapport 1,021)
	},
	{
		"nom": "La soucoupe volante",
		"image": "res://jeux_integres/puzzle/images/puzzle_13_soucoupe.jpg",
		"musique": "res://jeux_integres/puzzle/audio/Sourires_à_bord.mp3",
		"cols": 5, "rangs": 6,          # debout 944 × 1109 → cellule 188,80 × 184,83 (rapport 1,021)
	},
]
const DEFAUT := 0                       # le tableau 1 (la ferme) — le REPLI d'un index invalide, pas l'ouverture


# ============================================================================================================
# (B15 · §23 bis) LES FAMILLES — UN NOMBRE DE PIÈCES, ET **SON PROPRE JEU D'IMAGES**
# ============================================================================================================
# Fabrice, mot pour mot (§23 bis) : « qu'on ne partage PAS les mêmes images dans chaque famille comme dans le
# puzzle adulte. Un enfant capable de plus de pièces aura moins d'attrait pour les images du 4 pièces […] Nos
# images seront PROPRES au nombre de pièces. »
#
# ⚠⚠ C'EST LA DIFFÉRENCE NETTE AVEC LE PUZZLE ADULTE, ET ELLE SE LIT DANS LA FORME DE CETTE TABLE. Là-bas une
#   famille est une DÉCOUPE (50 · 100 · 500 · 1000) appliquée aux MÊMES images, et une matrice dit quelle image
#   est admise à quelle découpe. Ici une famille PORTE SES IMAGES : `"tableaux"` est la liste — dans l'ordre où
#   l'enfant les découvre — des index de `TABLE` qui lui appartiennent. Aucun index n'est dans deux familles, et
#   c'est ce qui rend le déblocage par famille (§23 quater) simple à écrire et impossible à confondre.
#
# ⚠⚠ L'ORDRE DE CETTE LISTE EST L'ORDRE DÉVELOPPEMENTAL (§23 bis), DU PLUS JEUNE AU PLUS GRAND : 4 pièces, puis
#   15. C'est lui, et lui seul, que les flèches ◀ [nb] ▶ de l'accueil parcourent — la famille 0 est celle sur
#   laquelle l'accueil s'ouvre TOUJOURS (§23 ter). ⚠⚠ ET C'EST TENU : le palier suivant, « 30 pièces »
#   (B18 · §26), s'est bien ajouté en UNE ligne ici, avec ses quatre images propres en fin de `TABLE` — ni
#   l'accueil, ni la progression, ni les dispositions de Fabrice n'ont eu à bouger d'un caractère.
#   ⚠ UN PALIER SE NOMME PAR SON **NOMBRE DE PIÈCES**, JAMAIS PAR SON THÈME (Fabrice, §26) : la première
#   écriture de cet encadré annonçait des paliers « véhicules, dinosaures, planètes, héros » — c'était déjà
#   faux le jour où elle a été écrite, puisque la moto et le tracteur, deux véhicules, sont dans la famille
#   « 15 pièces ». Un thème ne partitionne rien ; un nombre de pièces, si.
#
# ⚠ `pieces` EST ÉCRIT, ET IL EST VÉRIFIÉ CONTRE LA GRILLE : c'est le chiffre montré dans la pièce dessinée de
#   l'accueil. `verifier_familles()` (plus bas) relit que chaque tableau d'une famille découpe bien en ce
#   nombre-là — un tableau rangé dans la mauvaise famille afficherait « 4 » et donnerait quinze pièces.
# ============================================================================================================
const FAMILLES := [
	{"cle": "4pieces", "pieces": 4, "tableaux": [5, 6, 7, 8]},    # coccos · tigrou · 2 petits chats · petite feuille
	{"cle": "15pieces", "pieces": 15, "tableaux": [0, 1, 2, 3, 4]},  # ferme · porcelets · fusée · moto · tracteur
	# (B18 · §26) LA TROISIÈME FAMILLE, EN FIN DE LISTE PARCE QUE L'ORDRE EST DÉVELOPPEMENTAL : 4 · 15 · 30.
	# ⚠ SA CLÉ EST `30pieces` ET C'EST ELLE QUI NOMME LA LIGNE DE `progression_puzzle.cfg` : une famille
	#   nouvelle démarre donc à 0 sans rien migrer et sans rien réclamer aux deux autres (§23 quater). Le nom
	#   par le NOMBRE, jamais par le thème (§26) — cf. l'encadré des quatre tableaux ci-dessus.
	{"cle": "30pieces", "pieces": 30, "tableaux": [9, 10, 11, 12]},  # camion · voiture · hélicoccos · soucoupe
]
const DEFAUT_FAMILLE := 0               # (§23 ter) « par défaut on est sur du 4 pièces », à CHAQUE ouverture


static func nombre_familles() -> int:
	return FAMILLES.size()


static func famille_valide(f: int) -> int:
	return f if f >= 0 and f < FAMILLES.size() else DEFAUT_FAMILLE


static func cle_famille(f: int) -> String:
	return str(FAMILLES[famille_valide(f)]["cle"])


# LE NOMBRE DE PIÈCES DE LA FAMILLE — le chiffre écrit dans la pièce dessinée de l'accueil (§23 ter).
static func pieces_de_famille(f: int) -> int:
	return int(FAMILLES[famille_valide(f)]["pieces"])


static func tableaux_de_famille(f: int) -> Array:
	return FAMILLES[famille_valide(f)]["tableaux"]


static func nombre_dans_famille(f: int) -> int:
	return tableaux_de_famille(f).size()


# LE TABLEAU (index de `TABLE`) au RANG donné dans la famille. Un rang hors bornes retombe sur le premier de la
# famille — jamais sur `DEFAUT`, qui appartient à une AUTRE famille : reculer d'une famille sans le dire serait
# le pire des replis.
static func tableau_de(f: int, rang: int) -> int:
	var liste: Array = tableaux_de_famille(f)
	if liste.is_empty():
		return DEFAUT
	return int(liste[rang]) if rang >= 0 and rang < liste.size() else int(liste[0])


# LA FAMILLE À LAQUELLE APPARTIENT UN TABLEAU, et son RANG dedans. ⚠ On CHERCHE au lieu de calculer : le jour où
# une famille sera écrite dans un autre ordre, rien ici n'aura à changer.
static func famille_de(t: int) -> int:
	for f in FAMILLES.size():
		if (FAMILLES[f]["tableaux"] as Array).has(t):
			return f
	return DEFAUT_FAMILLE


static func rang_dans_famille(t: int) -> int:
	var f := famille_de(t)
	var i: int = (FAMILLES[f]["tableaux"] as Array).find(t)
	return i if i >= 0 else 0


# LE TABLEAU SUIVANT **DANS SA FAMILLE**, ou −1 s'il est le dernier. ⚠⚠ C'EST CE QUI REMPLACE `tableau + 1`
#   PARTOUT (`puzzle.gd:_niveau_suivant`, `progression_puzzle.gd`) : avec les familles, « le suivant » de l'index
#   4 (le tracteur, dernier des 15 pièces) N'EST PAS l'index 5 (les coccos, premier des 4 pièces). Un « niveau
#   suivant » qui suivrait la table ferait sauter l'enfant d'une famille à l'autre, à rebours de l'âge.
static func suivant_dans_famille(t: int) -> int:
	var f := famille_de(t)
	var r := rang_dans_famille(t)
	return tableau_de(f, r + 1) if r + 1 < nombre_dans_famille(f) else -1


# LE CONTRÔLE DE COHÉRENCE, RENDU EN CLAIR (le harnais le relit, et l'accueil l'écrit à son journal) : chaque
# tableau appartient à UNE et UNE SEULE famille, tous les index existent, et la grille de chacun donne bien le
# nombre de pièces annoncé par sa famille.
static func verifier_familles() -> Array:
	var fautes: Array = []
	var vus: Dictionary = {}
	for f in FAMILLES.size():
		var attendu: int = pieces_de_famille(f)
		for t in tableaux_de_famille(f):
			var ti := int(t)
			if ti < 0 or ti >= TABLE.size():
				fautes.append("famille « %s » : l'index %d n'existe pas dans la table" % [cle_famille(f), ti])
				continue
			if vus.has(ti):
				fautes.append("le tableau %d est dans DEUX familles (« %s » et « %s »)"
					% [ti, str(vus[ti]), cle_famille(f)])
			vus[ti] = cle_famille(f)
			if pieces(ti) != attendu:
				fautes.append("« %s » est rangé en famille « %s » (%d pièces) mais sa grille %d × %d en donne %d"
					% [nom(ti), cle_famille(f), attendu, colonnes(ti), rangs(ti), pieces(ti)])
	for t in TABLE.size():
		if not vus.has(t):
			fautes.append("le tableau %d « %s » n'appartient à AUCUNE famille" % [t, nom(t)])
	return fautes


static func nombre() -> int:
	return TABLE.size()


# LA GRILLE DU TABLEAU — le nombre de pièces reste QUINZE partout (la demande de Fabrice) ; c'est leur
# disposition qui suit la forme du dessin.
static func colonnes(t: int) -> int:
	return int(TABLE[numero_valide(t)]["cols"])


static func rangs(t: int) -> int:
	return int(TABLE[numero_valide(t)]["rangs"])


static func pieces(t: int) -> int:
	return colonnes(t) * rangs(t)


static func numero_valide(t: int) -> int:
	return t if t >= 0 and t < TABLE.size() else DEFAUT


static func nom(t: int) -> String:
	return str(TABLE[numero_valide(t)]["nom"])


static func chemin_image(t: int) -> String:
	return str(TABLE[numero_valide(t)]["image"])


static func chemin_musique(t: int) -> String:
	return str(TABLE[numero_valide(t)]["musique"])


static func image(t: int) -> Texture2D:
	var chemin := chemin_image(t)
	if not ResourceLoader.exists(chemin):
		return null
	return load(chemin) as Texture2D


# LA MUSIQUE DU TABLEAU, PRÊTE À PASSER **UNE FOIS**.
#
# ⚠⚠ LE `duplicate()` ET LE `loop = false` NE SONT PAS DE LA PRÉCAUTION DÉCORATIVE — c'est une leçon déjà payée
#   dans la fratrie CoccOs : un flux audio est une RESSOURCE PARTAGÉE. Mettre `loop` sur celui qu'on vient de
#   charger, c'est le mettre pour tous ceux qui chargeront le même fichier ensuite, et l'inverse est vrai : un
#   `.import` réglé en boucle ferait tourner la musique de victoire sans fin, alors que Fabrice demande qu'elle
#   « retentisse UNE fois ». On duplique donc le flux et on écrit la règle DANS LE CODE, là où elle se lit —
#   plutôt que de dépendre d'une case d'import que personne ne relira.
static func musique(t: int) -> AudioStream:
	var chemin := chemin_musique(t)
	if not ResourceLoader.exists(chemin):
		return null
	var flux := load(chemin) as AudioStream
	if flux == null:
		return null
	flux = flux.duplicate() as AudioStream
	if flux is AudioStreamMP3:
		(flux as AudioStreamMP3).loop = false
	elif flux is AudioStreamOggVorbis:
		(flux as AudioStreamOggVorbis).loop = false
	elif flux is AudioStreamWAV:
		(flux as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	return flux


# ============================================================================================================
# (B17 · §25) LA VIDÉO D'UN TABLEAU — UNE SEULE EN A UNE, ET LA TABLE LE DIT
# ============================================================================================================
# Fabrice, mot pour mot (§25) : « Une fois le puzzle fait et que la récompense coccos est arrivée à son terme,
# on met la vidéo et le chant de petites feuilles "Maman je reviens". » Et son choix n° 1 : **la vidéo REMPLACE
# l'image en grand plein écran** pour ce tableau — pas d'image fixe d'abord.
#
# ⚠⚠ POURQUOI LA CLÉ N'EXISTE QUE SUR UNE LIGNE, ET NON `"video": ""` SUR LES NEUF. Les huit autres tableaux
#   n'ont RIEN à déclarer : leur récompense n'a pas changé d'un octet. Une clé vide recopiée neuf fois donne
#   l'illusion d'un réglage que personne n'a pris — et le jour où une deuxième vidéo arrivera, on ne saurait
#   plus distinguer « pas de vidéo » de « pas encore décidé ». `get("video", "")` rend le même "" sans mentir.
#   C'est le MÊME raisonnement que le champ `musique` vide des quatre tableaux à 4 pièces (§23), pris à
#   l'envers : là, le vide est une décision écrite ; ici, l'absence est l'état normal.
#
# ⚠⚠ POURQUOI LE `.ogv` ET NON LE `.mp4` DE FABRICE — contrainte DURE du moteur, pas une préférence : Godot 4
#   ne lit nativement QUE l'Ogg Théora. `chat_qui_chante_v5.mp4` (H.264 + AAC, 1024 × 1024, 100,25 s) a donc
#   été converti en Théora + Vorbis, image ET son gardés, et c'est le `.ogv` qui entre dans le jeu. Le MP4
#   validé par Fabrice reste sa source, intacte, dans `travail_montage_chat/`.
#
# ⚠ `video_taille` EST ÉCRIT ICI PARCE QUE LE MOTEUR NE LE DONNE PAS AVANT DE JOUER : `VideoStreamTheora`
#   n'expose aucune dimension, et `get_video_texture()` ne rend une texture qu'une fois la lecture commencée.
#   Le cadre du plein écran doit pourtant être posé AVANT. On écrit donc la taille native (relue à la source
#   par `ffprobe` : 1024 × 1024) — et le harnais la CONFRONTE à la texture réelle une fois la vidéo lancée.
# ============================================================================================================
static func chemin_video(t: int) -> String:
	return str((TABLE[numero_valide(t)] as Dictionary).get("video", ""))


static func a_video(t: int) -> bool:
	var chemin := chemin_video(t)
	return chemin != "" and ResourceLoader.exists(chemin)


# LA TAILLE NATIVE de la vidéo du tableau, ou `Vector2.ZERO` s'il n'en a pas.
static func taille_video(t: int) -> Vector2:
	var v = (TABLE[numero_valide(t)] as Dictionary).get("video_taille", Vector2.ZERO)
	return v if v is Vector2 else Vector2.ZERO


# LA VIDÉO DU TABLEAU, PRÊTE À PASSER. ⚠ Pas de `duplicate()` ici, contrairement à `musique()` : un
# `VideoStream` ne porte AUCUN réglage de boucle (le seul `loop` est celui du LECTEUR, `VideoStreamPlayer`),
# donc il n'y a rien à protéger d'un partage — et c'est le jeu qui écrit `loop = false`, là où ça se lit.
static func video(t: int) -> VideoStream:
	var chemin := chemin_video(t)
	if not ResourceLoader.exists(chemin):
		return null
	return load(chemin) as VideoStream
