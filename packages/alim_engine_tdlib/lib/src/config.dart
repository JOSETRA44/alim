/// Configuración inyectada al inicializar TDLib.
///
/// Mandato del plan: los directorios NUNCA se dejan al default de TDLib.
/// Si [databaseDirectory]/[filesDirectory] son null, el motor los resuelve
/// explícitamente con path_provider durante `start()` y verifica escritura
/// antes de inicializar.
class TdlibConfig {
  const TdlibConfig({
    required this.apiId,
    required this.apiHash,
    this.databaseDirectory,
    this.filesDirectory,
    this.systemLanguageCode = 'es',
    this.deviceModel = 'ALIM',
    this.applicationVersion = '0.1.0',
    this.useTestDc = false,
  });

  final int apiId;
  final String apiHash;
  final String? databaseDirectory;
  final String? filesDirectory;
  final String systemLanguageCode;
  final String deviceModel;
  final String applicationVersion;
  final bool useTestDc;
}
