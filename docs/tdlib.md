# Motor TDLib

## Requisitos

1. **Binarios nativos** (no se commitean; `.gitignore` los excluye):

   ```powershell
   pwsh scripts/setup_tdlib.ps1          # Windows + Android
   pwsh scripts/setup_tdlib.ps1 -SkipAndroid
   ```

   - Windows: `windows/tdlib/tdjson.dll` (+ OpenSSL/zlib) desde NuGet
     `tdlib.native.win-x64`. El CMake del runner los copia junto al `.exe`.
   - Android: `android/app/src/main/jniLibs/<abi>/libtdjson.so` desde
     up9cloud/android-libtdjson.

2. **Credenciales** en `env.local.json` (gitignored), obtenidas en
   https://my.telegram.org → API development tools:

   ```json
   {
     "ALIM_ENGINE": "tdlib",
     "ALIM_TELEGRAM_API_ID": 12345678,
     "ALIM_TELEGRAM_API_HASH": "..."
   }
   ```

## Ejecutar

```powershell
flutter run -d windows --dart-define-from-file=env.local.json
```

Sin `--dart-define-from-file` (o con `ALIM_ENGINE` = `mock`) la app usa el
motor simulado; no hace falta red ni binarios.

## Arquitectura del adaptador (packages/alim_engine_tdlib)

- **Interfaz JSON, no clases generadas**: cliente propio sobre
  `td_create_client_id`/`td_send`/`td_receive` vía `dart:ffi`. Tolera drift
  de versiones 1.8.x y funciona idéntico en todas las plataformas.
- **Hilos**: `td_send` es thread-safe y se llama desde el isolate principal;
  un isolate dedicado (`alim-tdlib-receiver`) ejecuta el loop bloqueante
  `td_receive(0.5)` y cede el event loop en cada vuelta para poder recibir
  la orden de parada (cierre ordenado en <500 ms, kill forzado a los 3 s).
- **Hot-restart**: el id del cliente nativo se persiste en
  `<db>/.alim_client_id`; al arrancar, si hay un id huérfano del mismo
  proceso se le envía `close` (enviar a un id inexistente es inocuo).
- **Directorios**: `database_directory`/`files_directory` se resuelven con
  path_provider, se crean y se verifica escritura ANTES de
  `setTdlibParameters`.
- **Ciclo de vida**: `AppLifecycleListener` en `app.dart` — detach →
  `dispose()`; pause/resume → opción `online` de TDLib.

## Gotchas conocidas

- La dll de NuGet puede ser más nueva (1.8.6x) que los .so de Android:
  aceptable con la interfaz JSON para el subconjunto que usamos, pero
  conviene alinear versiones cuando haya builds reproducibles.
- `td_receive` devuelve strings propiedad de TDLib: se copian y jamás se
  liberan desde Dart.
- Ids de chat/mensaje/usuario son int53 (números JSON); `order` es int64 y
  llega como string → se compara como BigInt.
