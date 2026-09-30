#include "piper_tts.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <piper.hpp>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <string>

using namespace godot;

namespace coccos {

PiperTTS *PiperTTS::singleton = nullptr;

PiperTTS::PiperTTS() {
	singleton = this;
}

PiperTTS::~PiperTTS() {
	decharger();
	if (singleton == this) {
		singleton = nullptr;
	}
}

PiperTTS *PiperTTS::get_singleton() {
	return singleton;
}

// --- Casse : un mot tout en capitales est LU, pas épelé --------------------------

// Les capitales que CoccOs peut rencontrer : latin de base, latin-1 accentué,
// plus Œ et Ÿ que le latin-1 place hors de sa plage de capitales.
static bool est_capitale(char32_t c) {
	return (c >= U'A' && c <= U'Z') || (c >= 0x00C0 && c <= 0x00D6) ||
			(c >= 0x00D8 && c <= 0x00DE) || c == 0x0152 || c == 0x0178;
}

String PiperTTS::texte_pour_tts(const String &texte) {
	// Même règle que outils/generer_voix_bureau.py : toute suite d'au moins
	// deux capitales passe en minuscules ; une capitale isolée est conservée.
	String sortie;
	const int n = texte.length();
	int i = 0;
	while (i < n) {
		int j = i;
		while (j < n && est_capitale(texte[j])) {
			j++;
		}
		if (j - i >= 2) {
			sortie += texte.substr(i, j - i).to_lower();
			i = j;
		} else if (j > i) {
			sortie += texte.substr(i, j - i);
			i = j;
		} else {
			sortie += String::chr(texte[i]);
			i++;
		}
	}
	return sortie;
}

// --- Chargement -------------------------------------------------------------------

bool PiperTTS::charger(const String &chemin_modele, const String &chemin_espeak_data) {
	decharger();
	erreur = "";
	try {
		config = std::make_unique<piper::PiperConfig>();
		config->eSpeakDataPath = std::string(chemin_espeak_data.utf8().get_data());
		config->useESpeak = true;
		piper::initialize(*config);

		voice = std::make_unique<piper::Voice>();
		std::optional<piper::SpeakerId> locuteur;
		const std::string modele(chemin_modele.utf8().get_data());
		piper::loadVoice(*config, modele, modele + ".json", *voice, locuteur);
	} catch (const std::exception &e) {
		erreur = String("Piper : ") + String(e.what());
		voice.reset();
		config.reset();
		return false;
	}
	return true;
}

bool PiperTTS::est_pret() const {
	return voice != nullptr;
}

void PiperTTS::decharger() {
	voice.reset();
	if (config) {
		piper::terminate(*config);
		config.reset();
	}
}

String PiperTTS::derniere_erreur() const {
	return erreur;
}

// --- Recette de sortie : 22050 -> 44100, crête à -4 dB -----------------------------

// Rééchantillonnage par sinus cardinal fenêtré (Blackman, 32 lobes) : le ratio
// est un entier (2x), mais une simple duplication ou une interpolation linéaire
// laisserait un repli audible dans l'aigu — sur une voix d'enfant on l'entend.
static std::vector<int16_t> reechantillonner(const std::vector<int16_t> &source,
		int frequence_source, int frequence_cible) {
	if (frequence_source == frequence_cible || source.empty()) {
		return source;
	}
	const double ratio = double(frequence_cible) / double(frequence_source);
	// Le filtre coupe à la plus basse des deux Nyquist, pour couvrir aussi une
	// éventuelle décimation (frequence_cible < frequence_source).
	const double coupure = std::min(1.0, ratio) * 0.5;
	const int lobes = 16;
	const double pas = 1.0 / ratio;  // en échantillons source
	const double demi_fenetre = double(lobes) / (2.0 * coupure);

	const size_t n_sortie = size_t(double(source.size()) * ratio);
	std::vector<int16_t> sortie;
	sortie.reserve(n_sortie);
	const double pi = 3.14159265358979323846;

	for (size_t k = 0; k < n_sortie; k++) {
		const double centre = double(k) * pas;
		const int debut = int(std::ceil(centre - demi_fenetre));
		const int fin = int(std::floor(centre + demi_fenetre));
		double somme = 0.0;
		double poids = 0.0;
		for (int i = debut; i <= fin; i++) {
			if (i < 0 || i >= int(source.size())) {
				continue;
			}
			const double x = centre - double(i);
			// sinc normalisé à la coupure
			const double u = 2.0 * coupure * x;
			const double sinc = (std::fabs(u) < 1e-9) ? 1.0 : std::sin(pi * u) / (pi * u);
			// fenêtre de Blackman sur [-demi_fenetre, +demi_fenetre]
			const double t = (x + demi_fenetre) / (2.0 * demi_fenetre);
			const double w = 0.42 - 0.5 * std::cos(2.0 * pi * t) + 0.08 * std::cos(4.0 * pi * t);
			const double h = sinc * w;
			somme += h * double(source[i]);
			poids += h;
		}
		const double v = (poids > 1e-9) ? somme / poids : 0.0;
		sortie.push_back(int16_t(std::clamp(v, -32768.0, 32767.0)));
	}
	return sortie;
}

std::vector<int16_t> PiperTTS::mettre_au_format(const std::vector<int16_t> &brut,
		int frequence_source) const {
	std::vector<int16_t> audio = reechantillonner(brut, frequence_source, frequence_sortie);

	// Normalisation de crête : mêmes -4 dB que les 395 clips, mesurés APRÈS
	// rééchantillonnage (le filtre peut faire dépasser légèrement la crête).
	int32_t crete = 0;
	for (int16_t e : audio) {
		crete = std::max(crete, int32_t(std::abs(int32_t(e))));
	}
	if (crete > 0) {
		const double cible = std::pow(10.0, crete_db / 20.0) * 32767.0;
		const double gain = cible / double(crete);
		for (int16_t &e : audio) {
			e = int16_t(std::clamp(std::lround(double(e) * gain), -32768L, 32767L));
		}
	}
	return audio;
}

// --- Synthèse ----------------------------------------------------------------------

Ref<AudioStreamWAV> PiperTTS::synthese(const String &texte) {
	erreur = "";
	if (!est_pret()) {
		erreur = "Piper : modèle non chargé.";
		return Ref<AudioStreamWAV>();
	}
	const String prepare = texte_pour_tts(texte);
	if (prepare.strip_edges().is_empty()) {
		erreur = "Piper : texte vide.";
		return Ref<AudioStreamWAV>();
	}

	std::vector<int16_t> brut;
	int frequence_source = 22050;
	try {
		voice->synthesisConfig.lengthScale = float(length_scale);
		frequence_source = voice->synthesisConfig.sampleRate;
		piper::SynthesisResult resultat;
		piper::textToAudio(*config, *voice, std::string(prepare.utf8().get_data()),
				brut, resultat, nullptr);
	} catch (const std::exception &e) {
		erreur = String("Piper : ") + String(e.what());
		return Ref<AudioStreamWAV>();
	}
	if (brut.empty()) {
		erreur = "Piper : synthèse vide pour « " + texte + " ».";
		return Ref<AudioStreamWAV>();
	}

	const std::vector<int16_t> audio = mettre_au_format(brut, frequence_source);

	PackedByteArray octets;
	octets.resize(int64_t(audio.size()) * 2);
	std::memcpy(octets.ptrw(), audio.data(), audio.size() * 2);

	Ref<AudioStreamWAV> flux;
	flux.instantiate();
	flux->set_format(AudioStreamWAV::FORMAT_16_BITS);
	flux->set_mix_rate(frequence_sortie);
	flux->set_stereo(false);
	flux->set_data(octets);
	return flux;
}

// --- Réglages -----------------------------------------------------------------------

void PiperTTS::set_length_scale(double v) { length_scale = v; }
double PiperTTS::get_length_scale() const { return length_scale; }
void PiperTTS::set_crete_db(double v) { crete_db = v; }
double PiperTTS::get_crete_db() const { return crete_db; }
void PiperTTS::set_frequence_sortie(int v) { frequence_sortie = std::max(8000, v); }
int PiperTTS::get_frequence_sortie() const { return frequence_sortie; }

void PiperTTS::_bind_methods() {
	ClassDB::bind_method(D_METHOD("charger", "chemin_modele", "chemin_espeak_data"),
			&PiperTTS::charger);
	ClassDB::bind_method(D_METHOD("est_pret"), &PiperTTS::est_pret);
	ClassDB::bind_method(D_METHOD("decharger"), &PiperTTS::decharger);
	ClassDB::bind_method(D_METHOD("synthese", "texte"), &PiperTTS::synthese);
	ClassDB::bind_method(D_METHOD("derniere_erreur"), &PiperTTS::derniere_erreur);
	ClassDB::bind_static_method("PiperTTS", D_METHOD("texte_pour_tts", "texte"),
			&PiperTTS::texte_pour_tts);

	ClassDB::bind_method(D_METHOD("set_length_scale", "valeur"), &PiperTTS::set_length_scale);
	ClassDB::bind_method(D_METHOD("get_length_scale"), &PiperTTS::get_length_scale);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "length_scale"), "set_length_scale", "get_length_scale");

	ClassDB::bind_method(D_METHOD("set_crete_db", "valeur"), &PiperTTS::set_crete_db);
	ClassDB::bind_method(D_METHOD("get_crete_db"), &PiperTTS::get_crete_db);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "crete_db"), "set_crete_db", "get_crete_db");

	ClassDB::bind_method(D_METHOD("set_frequence_sortie", "valeur"), &PiperTTS::set_frequence_sortie);
	ClassDB::bind_method(D_METHOD("get_frequence_sortie"), &PiperTTS::get_frequence_sortie);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "frequence_sortie"), "set_frequence_sortie", "get_frequence_sortie");
}

}  // namespace coccos
