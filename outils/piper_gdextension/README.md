# PiperTTS — la voix femme siwis dit n'importe quel mot, à la volée

Extension native (GDExtension, Linux x86_64) qui charge le modèle Piper **une
fois** et le garde résident. Un mot hors du vocabulaire fixe du bureau coûte
alors ~100–200 ms, et il sort avec **le même timbre, le même niveau et le même
débit** que les 395 clips embarqués dans `lang/fr/voix/`.

Avant, un mot inconnu tombait sur la synthèse du système : une autre voix, un
autre timbre, souvent robotique. Pour un enfant qui apprend à lire, ce
changement de voix en plein milieu est un décrochage. C'est ce que ce jalon
supprime — sur Linux desktop, et sur Android arm64 (voir plus bas).

## Ce qui est versionné, ce qui ne l'est pas

Le **code source** est ici. Les **artefacts** ne le sont pas : le modèle
`.onnx` (61 Mo), les bibliothèques Piper et le `.so` compilé restent hors du
dépôt (voir `.gitignore`).

## Voie de build : on ne recompile presque rien

Le binaire Piper natif déjà installé (`~/.local/opt/piper/`) livre
`libpiper_phonemize`, `libonnxruntime` et `libespeak-ng`. On s'y **lie** au lieu
de les reconstruire — seul `piper.cpp` et le pont Godot sont compilés. Le
journal de Piper passe par un bouchon `shim/spdlog/` : pas de dépendance de
plus, et les erreurs remontent déjà par exception.

## Construire

```bash
pip install --user scons                    # + cmake si absent
git clone --depth 1 https://github.com/godotengine/godot-cpp.git ~/dev/tiers/godot-cpp
git clone --depth 1 https://github.com/rhasspy/piper.git            ~/dev/tiers/piper
git clone --depth 1 https://github.com/rhasspy/piper-phonemize.git  ~/dev/tiers/piper-phonemize

# godot-cpp, contre l'API du Godot qui lance le jeu
Godot_v4.7.2-stable_linux.x86_64 --headless --dump-extension-api --dump-gdextension-interface
cp ~/dev/tiers/godot-cpp/gdextension/gdextension_interface.json .
scons -C ~/dev/tiers/godot-cpp platform=linux target=template_debug \
      gdextension_dir=$PWD custom_api_file=$PWD/extension_api.json -j4

# en-têtes onnxruntime 1.14.1 (ceux du .so livré par Piper) et espeak-ng
# puis, ici :
scons -j4
```

Les emplacements se surchargent par variables d'environnement — voir l'en-tête
du `SConstruct`.

## Construire pour Android arm64 (moteur sherpa-onnx)

Sur Android, Piper natif n'est pas disponible : le même modèle siwis est joué
par **sherpa-onnx** (Apache-2.0) via son **API C**. Un seul interrupteur de
compilation, `COCCOS_TTS_SHERPA`, échange le moteur ; la recette de son — casse,
`length_scale` 1.3, 22050 → 44100 Hz, crête −4 dB — est le **code commun**, donc
le son reste le même d'une plateforme à l'autre.

```bash
# NDK (version par défaut de godot-cpp)
export ANDROID_HOME=$HOME/Android/Sdk
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "ndk;28.1.13356709"

# sherpa-onnx : l'AAR officiel, dont on ne garde que l'arm64
curl -LO https://github.com/k2-fsa/sherpa-onnx/releases/download/v1.13.8/sherpa-onnx-1.13.8.aar
unzip -d aar sherpa-onnx-1.13.8.aar
mkdir -p ~/dev/tiers/sherpa-onnx/{arm64-v8a,include}
cp aar/jni/arm64-v8a/lib{onnxruntime,sherpa-onnx-c-api}.so ~/dev/tiers/sherpa-onnx/arm64-v8a/
curl -Lo ~/dev/tiers/sherpa-onnx/include/c-api.h \
  https://raw.githubusercontent.com/k2-fsa/sherpa-onnx/v1.13.8/sherpa-onnx/c-api/c-api.h

# godot-cpp pour arm64, puis l'extension
scons -C ~/dev/tiers/godot-cpp platform=android arch=arm64 target=template_debug api_version=4.7 -j8
scons platform=android arch=arm64 target=template_debug
```

Le lien se fait avec `--no-undefined` : **si un symbole sherpa ne résout pas, le
`.so` n'est pas produit**. C'est la preuve du build, puisqu'on ne peut pas
exécuter de l'arm64 sur un poste x86.

Deux différences à connaître côté sherpa :

- la **table de jetons** est un fichier à part (Piper la lisait dans le
  `.onnx.json`). L'extension la cherche en `tokens.txt` à côté du modèle, sinon
  en `<modele>.tokens.txt` — la signature de `charger()` ne bouge pas ;
- le paramètre `speed` de `SherpaOnnxOfflineTtsGenerate` **écrase**
  `length_scale` (`length_scale = 1/speed`). On passe donc `speed = 1.0` et on
  garde notre 1.3 posé dans la config VITS au chargement.

## API vue de GDScript

```gdscript
var piper := Engine.get_singleton("PiperTTS")
piper.charger(chemin_modele, chemin_espeak_data)   # une fois, au démarrage
var flux: AudioStreamWAV = piper.synthese("MAISON")  # 44100 Hz mono, crête -4 dB
```

`length_scale` (1.3), `crete_db` (-4.0) et `frequence_sortie` (44100) sont
réglables ; leurs valeurs par défaut sont exactement celles des 395 clips.
Le jeu passe par `scripts/voix_piper.gd`, qui trouve le modèle, met les mots en
cache dans `user://` et s'efface proprement si l'extension est absente.

## Licences

CoccOs est en **GPLv3**. Les briques utilisées : piper, piper-phonemize,
onnxruntime et godot-cpp sont en **MIT** ; espeak-ng est en **GPLv3**. La GPLv3
absorbe MIT et espeak-ng partage sa licence : l'ensemble est compatible.

## Preuves

- `outils/preuve_voix_piper.gd` — extension chargée, latence, cache, recette,
  casse, branchement de `Voix.dire`.
- `outils/preuve_voix_identite.py` — timbre, niveau et débit face aux clips
  embarqués (à lancer après la précédente).
