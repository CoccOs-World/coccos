# CoccOs 🐞

**Le bureau d'ordinateur des enfants — libre et gratuit.**

CoccOs est un mini-bureau d'ordinateur pour les jeunes enfants : de vraies
icônes, de vraies fenêtres, une barre des tâches… à hauteur d'enfant. On y
apprend l'ordinateur — le vrai, avec une souris et un clavier — en s'amusant,
dans un monde où **aucun geste n'est puni**. Né du projet d'un papa pour sa
fille autiste, CoccOs prend le contre-pied des écrans qu'on *subit* : ici
l'enfant **agit**.

🌐 **Site, version jouable en ligne et téléchargements : https://coccos.fr**

## Ce que CoccOs sait faire

- **5 jeux calmes et prévisibles** — souris (Découverte, Les ballons) et
  clavier (Les lettres, Les mots, La chasse aux lettres), tous parlants,
  tous sans échec ni chrono : la difficulté suit le succès, jamais le temps
- 💬 **Mon classeur** — un classeur de communication (CAA) : l'enfant touche
  une vignette, la voix la dit. Les planches créées avec
  [TLAb](https://techlab-handicap.org/apps/tlab/) (APF France handicap)
  s'importent en deux gestes ; vignettes personnalisées possibles avec une
  photo du vrai objet ; réorganisation derrière un cadenas à code
- 📺 **Ma télé** — une télévision à **liste fermée** : uniquement les vidéos
  choisies par l'adulte, pas de flux infini, pas d'algorithme, pas de
  suggestion. Conversion automatique à l'import (ffmpeg)
- 🔑 **Espace famille** — le même CoccOs sur tous les appareils, par un simple
  code famille **sans aucune donnée personnelle** : synchro en wifi local
  (sans internet ni serveur) ou via n'importe quel serveur WebDAV
- **Les parents gardent la main** — réglages sous code PIN : stimulations
  dosables une à une, mots à apprendre, curseurs, fonds, applications
- **Les meilleurs logiciels libres invités** — TuxPaint, GCompris, TuxMath se
  lancent depuis le bureau de l'enfant (Linux et Android)
- **4 plateformes** — Linux (.deb), Windows (installeur), Android (APK,
  mode tactile avec clavier dessiné), et le navigateur

## La philosophie

Aucun échec possible · aucun chrono · pas de stimuli inutiles (tout se règle
ou se coupe) · l'enfant agit, il ne consomme pas · pensé d'abord pour les
jeunes enfants et les profils atypiques.

**La mission** : que n'importe qui puisse ajouter ses traductions, ses mots —
et à terme ses propres activités. Le code est libre, et **l'usage et la
création à la maison doivent être possibles sans connaissance technique.**

## Construire depuis les sources

CoccOs est un projet [Godot](https://godotengine.org) 4.6 (GDScript, rendu
GL Compatibility) sans aucune dépendance externe — ouvrez le dossier dans
l'éditeur Godot et lancez.

```bash
godot --path . # lancer
godot --headless --path . --export-release "Web" sortie/index.html # exporter
```

Les presets d'export (`export_presets.cfg`) ne sont pas versionnés (fichier
propre à chaque machine) : créez les vôtres dans l'éditeur (Linux, Windows,
Web, Android). Textures Android : `import_etc2_astc=true` est déjà réglé.
⚠ **Filtre d'export à poser dans CHAQUE preset** (onglet Ressources →
« Filtres pour exporter des fichiers non-ressources ») :
`lang/*/textes.xml, classeur/*.tlab` (+ `voix_android/*` pour Android).
Ce ne sont pas des ressources Godot : sans ce filtre, ils manquent du paquet
sans aucune erreur à l'export — l'interface perd ses textes et « Mon classeur »
s'ouvre vide (les 6 planches par défaut ne sont pas semées). Vérifier un
paquet : `outils/preuve_classeur_paquet.gd`.
La conversion vidéo de « Ma télé » utilise `ffmpeg` (paquet système sur
Linux ; à placer à côté de `coccos.exe` sur Windows).

## Traduire CoccOs

Toute l'interface vit dans `lang/fr/textes.xml` et les voix dans
`lang/fr/voix/`. **Traduire = dupliquer le dossier** `lang/fr/` en
`lang/<code>/` et traduire les valeurs (les clés ne changent jamais).
Des voix enregistrées (la voix de papa ou maman !) peuvent remplacer la
synthèse : déposer des fichiers audio dans le dossier utilisateur
`lang/<code>/voix/<catégorie>/<terme>.wav` — sans rien reconstruire.

## Licences

- **Code** : [GPL v3](LICENSE) — CoccOs est et restera libre ; tout dérivé
  doit le rester aussi.
- **Images et sons du projet** (mascotte, curseurs, fonds, sons générés) :
  [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.fr).
- **Pictogrammes des planches d'exemple du classeur** : pictogrammes
  [ARASAAC](https://arasaac.org) — © Gobierno de Aragón, auteur Sergio
  Palao, licence
  [CC BY-NC-SA](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr)
  (usage non commercial). CoccOs est un projet non commercial.

---

*CoccOs — un projet libre de Freddy Maillard. Fait avec Godot Engine.*
*Pensé par Freddy, codé par Claude (Anthropic), dessiné par Gemini (Google) —*
*chaque part revient à son créateur.*
*Aucune publicité, aucun traqueur, aucune donnée collectée. 🐞*
