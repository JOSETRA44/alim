/// Custodia de las claves de cifrado de las bases de datos locales.
///
/// La clave NUNCA se deriva de nada adivinable ni se guarda en un archivo
/// del proyecto: se genera con [Random.secure] y vive en el almacén seguro
/// del sistema operativo (Windows DPAPI, Android Keystore), que la protege
/// con las credenciales del usuario/dispositivo.
library;

export 'src/key_store.dart';
