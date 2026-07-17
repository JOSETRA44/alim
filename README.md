# ALIM

App de mensajería Flutter cuyo valor central es la **personalización extrema
de la interfaz en runtime**: un Modo Desarrollador dentro de la app permite
editar un spec JSON propio (formato **ALIM**) —tokens de diseño, componentes,
layout de bloques y expresiones— y aplicarlo en caliente.

## Arquitectura

Workspace pub multi-paquete con Clean Architecture; la regla de dependencias
es física: la UI solo conoce `alim_engine` (dominio).

| Paquete | Rol |
|---|---|
| `packages/alim_core` | Primitivas compartidas (StateStream, Result, logging). Sin Flutter. |
| `packages/alim_engine` | Dominio puro: entidades + contrato `MessagingEngine`. |
| `packages/alim_engine_mock` | Motor simulado (desarrollo de UI y tests). |
| `packages/alim_engine_tdlib` | Motor real Telegram vía TDLib (FFI, interfaz JSON). Ver `docs/tdlib.md`. |
| `packages/alim_engine_supabase` | Motor propio local-first: Drift (SQLite) como única fuente de verdad, Supabase solo como capa de sync. |
| `packages/alim_keystore` | Claves de cifrado de las BD locales, custodiadas por el almacén seguro del SO. |
| `packages/alim_spec` | Formato ALIM: parser fail-safe, evaluador de expresiones y presets. Dart puro. |
| `packages/alim_theme_engine` | Compila el spec a `ThemeData` inmutable (anti-jank: nada se evalúa en build). |
| `lib/` | Composition root: Riverpod, GoRouter, features (auth, chats, chat, settings, dev_mode). |

Los tres motores son intercambiables **en runtime** desde el Modo
Desarrollador: cambiar de motor no toca ninguna feature.

## Puesta a punto

```powershell
# Binarios de TDLib (tdjson.dll en Windows, .so en Android):
pwsh scripts/setup_tdlib.ps1

# OpenSSL, que SQLCipher necesita para cifrar la BD local en Windows:
pwsh scripts/setup_openssl.ps1
```

## Ejecutar

```powershell
# Motor simulado (sin red, sin credenciales):
flutter run -d windows

# Con credenciales (Telegram y/o Supabase):
flutter run -d windows --dart-define-from-file=env.local.json
```

`env.local.json` (gitignored) define `ALIM_ENGINE`, `ALIM_TELEGRAM_API_ID`,
`ALIM_TELEGRAM_API_HASH` (de https://my.telegram.org), `ALIM_SUPABASE_URL` y
`ALIM_SUPABASE_ANON_KEY`.

En el motor simulado: cualquier teléfono; un código de 5 dígitos autentica;
`11111` fuerza el flujo 2FA (contraseña `alim`). En el motor Supabase el login
es por código de un solo uso enviado al correo.

## Seguridad

Las bases de datos locales (historial de mensajes) van **cifradas en reposo**;
la clave la custodia el almacén seguro del SO (Windows DPAPI / Android
Keystore). El aislamiento entre usuarios en Supabase se apoya en RLS,
verificada con un escenario de intrusión. Ver **`docs/security.md`**.

## Tests

```powershell
flutter test                                    # app (widgets)
flutter test integration_test -d windows        # E2E: verifica el cifrado real en disco
# y dentro de cada paquete: flutter test  (o dart test en los puros)
```

## Modo Desarrollador

Ajustes → Modo Desarrollador:

- **Editor** del spec ALIM con presets (Lienzo, Tinta, Burbuja, Expresivo),
  avisos del parser/compilador y "Aplicar en caliente". El tema persiste
  entre arranques.
- **Inspector**: toque largo sobre una burbuja → su ruta en el spec y el
  fragmento JSON que la gobierna.
- **Import/export** de temas `.alim`.
- **Exportador de Skill**: genera un markdown con el formato ALIM y tu tema
  actual, listo para entregárselo a un agente de código y pedirle más
  personalización.
- **Selector de motor** (simulado / Telegram / ALIM nativo) sin recompilar.
