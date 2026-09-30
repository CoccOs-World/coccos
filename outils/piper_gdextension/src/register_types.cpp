#include "register_types.h"

#include "piper_tts.h"

#include <gdextension_interface.h>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

static coccos::PiperTTS *piper_tts_singleton = nullptr;

void initialize_piper_tts_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	GDREGISTER_CLASS(coccos::PiperTTS);
	piper_tts_singleton = memnew(coccos::PiperTTS);
	Engine::get_singleton()->register_singleton("PiperTTS", piper_tts_singleton);
}

void uninitialize_piper_tts_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	Engine::get_singleton()->unregister_singleton("PiperTTS");
	if (piper_tts_singleton) {
		memdelete(piper_tts_singleton);
		piper_tts_singleton = nullptr;
	}
}

extern "C" {
GDExtensionBool GDE_EXPORT piper_tts_library_init(
		GDExtensionInterfaceGetProcAddress p_get_proc_address,
		const GDExtensionClassLibraryPtr p_library,
		GDExtensionInitialization *r_initialization) {
	godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
	init_obj.register_initializer(initialize_piper_tts_module);
	init_obj.register_terminator(uninitialize_piper_tts_module);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
	return init_obj.init();
}
}
