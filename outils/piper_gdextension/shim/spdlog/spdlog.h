// Bouchon spdlog — piper.cpp journalise via spdlog, dont CoccOs n'a pas besoin.
// Plutôt que d'ajouter une dépendance, on absorbe les appels : les messages de
// diagnostic de Piper sont silencieux, les erreurs remontent déjà par exception.
#ifndef COCCOS_SHIM_SPDLOG_H
#define COCCOS_SHIM_SPDLOG_H
namespace spdlog {
// piper.cpp teste le niveau avant de composer certains messages coûteux :
// on répond « non » pour que ce travail soit simplement sauté.
namespace level {
enum level_enum { trace, debug, info, warn, err, critical, off };
}
inline bool should_log(level::level_enum) { return false; }
template <typename... A> inline void debug(A &&...) {}
template <typename... A> inline void info(A &&...) {}
template <typename... A> inline void warn(A &&...) {}
template <typename... A> inline void error(A &&...) {}
template <typename... A> inline void critical(A &&...) {}
}  // namespace spdlog
#endif
