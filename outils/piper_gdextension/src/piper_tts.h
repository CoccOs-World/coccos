// PiperTTS — synthèse vocale Piper (voix siwis femme) à la volée dans CoccOs.
//
// Le modèle .onnx est chargé UNE fois et reste résident : chaque mot coûte
// alors quelques dizaines de millisecondes, temps réel acquis.
//
// L'extension reproduit la recette des 395 clips pré-rendus
// (outils/generer_voix_bureau.py) pour que le mot synthétisé à la volée soit
// indiscernable de ses voisins enregistrés :
//   1. un mot d'au moins deux capitales est mis en minuscules (sinon espeak
//      l'ÉPELLE) ;
//   2. length_scale 1.3 (débit posé, adapté à un enfant qui apprend) ;
//   3. rééchantillonnage 22050 -> 44100 Hz ;
//   4. normalisation de crête à -4 dB.
//
// Ni le modèle (61 Mo) ni les bibliothèques Piper n'entrent dans le dépôt :
// l'extension reçoit leurs chemins au chargement.
#ifndef COCCOS_PIPER_TTS_H
#define COCCOS_PIPER_TTS_H

#include <godot_cpp/classes/audio_stream_wav.hpp>
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/class_db.hpp>

#include <memory>
#include <vector>

namespace piper {
struct PiperConfig;
struct Voice;
}  // namespace piper

namespace coccos {

class PiperTTS : public godot::Object {
	GDCLASS(PiperTTS, godot::Object)

public:
	PiperTTS();
	~PiperTTS();

	static PiperTTS *get_singleton();

	// Charge le modèle et l'annexe espeak-ng. À appeler une fois au démarrage.
	bool charger(const godot::String &chemin_modele, const godot::String &chemin_espeak_data);
	bool est_pret() const;
	void decharger();

	// Rend le texte en audio prêt à jouer, ou null si la synthèse échoue.
	godot::Ref<godot::AudioStreamWAV> synthese(const godot::String &texte);

	// Dernier message d'erreur (chaîne vide si tout va bien).
	godot::String derniere_erreur() const;

	// Réglages de la recette — valeurs par défaut = celles des 395 clips.
	void set_length_scale(double v);
	double get_length_scale() const;
	void set_crete_db(double v);
	double get_crete_db() const;
	void set_frequence_sortie(int v);
	int get_frequence_sortie() const;

	// Casse normalisée pour le phonémiseur (exposée pour les preuves).
	static godot::String texte_pour_tts(const godot::String &texte);

protected:
	static void _bind_methods();

private:
	static PiperTTS *singleton;

	std::unique_ptr<piper::PiperConfig> config;
	std::unique_ptr<piper::Voice> voice;
	godot::String erreur;

	double length_scale = 1.3;
	double crete_db = -4.0;
	int frequence_sortie = 44100;

	// Recette de sortie : 22050 -> frequence_sortie puis crête à crete_db.
	std::vector<int16_t> mettre_au_format(const std::vector<int16_t> &brut, int frequence_source) const;
};

}  // namespace coccos

#endif
