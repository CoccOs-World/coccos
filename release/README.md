# Fabriquer et publier CoccOs

Tout ce qui sert à produire les installables et à les diffuser vit ici, dans le
dépôt : un clone suffit. Ce qui **n'y est pas** — et ne peut pas y être — est
listé en fin de page.

## Les quatre cibles

| Cible | Produit par | Sortie |
|---|---|---|
| Linux `.deb` | `release/build_deb.sh` | `../installeur/coccos_<version>_amd64.deb` |
| Dépôt APT signé | `release/publier_apt.sh` | `<site>/apt/` |
| Windows | export Godot + `makensis` | `<site>/coccos_setup.exe` |
| Android `.apk` | export Godot | `<site>/coccos.apk` |
| Web | export Godot | `<site>/jeu/` |

La **version** est lue dans `project.godot` (`config/version`) — c'est la source
unique de vérité. On la monte avant de fabriquer, jamais après.

## Le rituel, dans l'ordre

```bash
# 0. partir de main à jour
git pull --ff-only

# 1. importer le projet avec le moteur de la bonne version
"$COCCOS_GODOT" --headless --import

# 2. les trois exports Godot
"$COCCOS_GODOT" --headless --export-release "Web"
"$COCCOS_GODOT" --headless --export-release "Windows Desktop"
"$COCCOS_GODOT" --headless --export-debug   "Android"     # voir « signature » plus bas

# 3. l'installeur Windows (la version s'injecte, pas d'édition à la main)
VERSION=$(grep -E '^config/version=' project.godot | cut -d'"' -f2)
(cd ../installeur/windows && makensis -DAPP_VERSION=$VERSION \
    "$OLDPWD/release/windows/coccos_installer.nsi")

# 4. le paquet Linux, puis le dépôt APT signé
bash release/build_deb.sh
bash release/publier_apt.sh

# 5. copier les binaires à la racine du site, puis publier
#    (rsync avec excludes ANCRÉS — sinon jeu/index.html est exclu)
rsync -av --exclude '/index.html' --exclude '/guide.html' \
          --exclude '/images' --exclude '/_odoo' \
          <site>/ coccos.fr:/var/www/coccos/
```

Puis **les footers** : les vues Odoo 2902 (accueil) et 2904 (guide) portent le
numéro de version. ⚠️ `arch_db` est un champ **traduit** : écrire en `fr_FR`,
pas dans la langue source, sinon la page ne change pas (piège N026). Redémarrer
Odoo ensuite, pour le cache QWeb.

## Vérifier — ne jamais supposer

- `md5sum` local **et** sur le serveur, pour chacun des trois binaires
- `gpgv --keyring ./coccos-archive-keyring.gpg InRelease` → « Bonne signature »
- les URL en 200 : `/`, `/guide`, `/jeu/`, `/apt/InRelease`
- `sudo apt update` sur une machine où CoccOs est installé
- **rsync ne purge pas** : les anciens `.deb` restent dans `/apt/` sur le serveur
- **le cache navigateur** : `.pck` et `.wasm` ont des noms fixes et `max-age`
  30 jours — un visiteur récent garde l'ancienne version. Tester en navigation
  privée, et casser le cache si la version doit arriver tout de suite.

## Signature Android — le piège qui casse les mises à jour

L'APK publié jusqu'ici est signé par le **keystore de debug** du poste qui l'a
fabriqué. Or un keystore de debug est **engendré par machine** : signer depuis un
autre poste produit un certificat différent, et **Android refuse alors la mise à
jour** chez tous ceux qui ont déjà installé — désinstallation obligatoire, et
réglages perdus.

Avant de publier un APK depuis un poste qui ne l'a jamais fait, comparer :

```bash
keytool -list -keystore ~/.android/debug.keystore -storepass android \
  -alias androiddebugkey -rfc | openssl x509 -noout -fingerprint -sha256
```

Empreinte des APK publiés à ce jour :
`3bbb1a4c61ce9c9e25edce0b7093cf3294d567d9694b04658fd230e659c53683`

Si elle diffère, **ne pas publier** : voir la tâche #226 (keystore de release).

## Signer le dépôt APT à plusieurs

`publier_apt.sh` accepte plusieurs identités, séparées par `;` :

```bash
COCCOS_CLES="CoccOs (cle de signature du depot APT);CoccOs — Fabrice Barbier" \
  bash release/publier_apt.sh
```

L'`InRelease` porte alors **toutes** les signatures, et `apt` l'accepte dès
qu'**une** des clés est dans le trousseau de la machine : c'est le mécanisme de
rotation de clé d'archive Debian. Chaque mainteneur garde sa clé privée chez
lui, révocable séparément.

Une clé protégée par phrase de passe exige un **agent gpg amorcé** (signer une
fois à la main dans la session suffit). Le script ne code aucune phrase de passe.

## Ce qui n'est pas dans le dépôt

| Quoi | Pourquoi | Comment l'obtenir |
|---|---|---|
| Moteur Godot 4.7.2 | binaire de 120 Mo | `COCCOS_GODOT=/chemin/Godot_v4.7.2-stable_linux.x86_64` |
| Modèles d'export Godot | 1,3 Go | `Godot_v4.7.2-stable_export_templates.tpz`, à dézipper dans `~/.local/share/godot/export_templates/4.7.2.stable/` |
| Template de build Android | 214 Mo, régénérable | dézipper `android_source.zip` dans `android/build/`, **puis `touch android/build/.gdignore`** (l'archive ne le contient pas ; sans lui Godot indexe les `.webp` du template et Gradle casse) |
| `voix_android/` | modèle sherpa de 63 Mo | paquet `vits-piper-fr_FR-siwis-medium` |
| `bin/*.so` | compilés par plateforme | voir `outils/piper_gdextension/README.md` |
| `export_presets.cfg` | réécrit par Godot, chemins et mots de passe locaux | comparer au `export_presets.cfg.exemple` d'à côté |
| Clé GPG privée du dépôt APT | un secret ne se versionne pas | trousseau gpg du mainteneur |
| Keystores Android | portent un mot de passe | sOocret |
| Accès SSH à `coccos.fr` | — | compte `fabrice`/`ubuntu`, groupe `coccos-publi` |

## Variables d'environnement

| Variable | Défaut | Rôle |
|---|---|---|
| `COCCOS_GODOT` | `../outils/Godot_v4.7*-stable_linux.x86_64` | le moteur |
| `COCCOS_SORTIE` | `../installeur` | où atterrissent les `.deb` |
| `COCCOS_SITE` | `../site` | la racine du site à publier |
| `COCCOS_CLES` | la clé historique | identités de signature, séparées par `;` |
