/// Runtime de personalización de ALIM.
///
/// Contrato de rendimiento: TODO el trabajo de estilo ocurre en la fase de
/// compilación ([ThemeCompiler.compile]), que produce objetos inmutables.
/// Los widgets solo leen `Theme.of(context)` y sus extensiones — nunca se
/// parsea ni evalúa nada dentro de un `build()`.
///
/// Este paquete no depende de ningún motor de mensajería ni de gestión de
/// estado: el hot-apply lo orquesta la app con su propio state management.
library;

export 'src/bubble_style.dart';
export 'src/compiler.dart';
