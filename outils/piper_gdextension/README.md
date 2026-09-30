# PiperTTS — la voix femme siwis dit n'importe quel mot, à la volée

Extension native (GDExtension, Linux x86_64) qui charge le modèle Piper **une
fois** et le garde résident. Un mot hors du vocabulaire fixe du bureau coûte
alors ~100–200 ms, et il sort avec **le même timbre, le même niveau et le même
débit** que les 395 clips embarqués dans `lang/fr/voix/`.

Avant, un mot inconnu tombait sur la synthèse du système : une autre voix, un
autre timbre, souvent robotique. Pour un enfant qui apprend à lire, ce
changement de voix en plein milieu est un décrochage. C'est ce que ce jalon
supprime — sur Linux desktop (le web et Android viennent ensuite).

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
