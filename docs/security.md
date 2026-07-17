# Revisión de seguridad — ALIM

Estado a 2026-07-11 (Hito 6). Este documento recoge el modelo de amenazas,
lo que se verificó y cómo, y lo que queda como deuda consciente.

## 1. Secretos

- `env.local.json` (api_id/api_hash de Telegram, URL y clave publicable de
  Supabase) está en `.gitignore` y **no** aparece en `git ls-files`.
- La clave de Supabase que se embebe en la app es la *publishable* (antes
  "anon"): está pensada para ser pública. Lo que protege los datos es RLS,
  no el secreto de esa clave.
- Los logs (`AlimLogger`) nunca registran contenido de mensajes, códigos de
  verificación ni contraseñas — solo identificadores. Verificado por
  inspección de todas las llamadas a `_log.*`.
- TDLib arranca con `setLogVerbosityLevel: 1`; su logger nativo, que por
  defecto es muy verboso, no vuelca tráfico a stdout.

## 2. Cifrado en reposo

| Base de datos | Contenido | Estado |
|---|---|---|
| Binlog de TDLib | historial de Telegram, sesión | **Cifrado** (`database_encryption_key`) |
| SQLite de Drift | historial del motor ALIM nativo | **Cifrado** (SQLCipher) |

La clave son 32 bytes de `Random.secure()`, distinta por base de datos, y la
custodia el **almacén seguro del sistema operativo** (Windows DPAPI /
Android Keystore) vía `flutter_secure_storage`. Ver `packages/alim_keystore`.

Consecuencias asumidas:

- Si se pierde la clave (reinstalación, reseteo del almacén del SO), los
  datos locales son **irrecuperables por diseño**: hay que volver a iniciar
  sesión. El historial vive en el servidor, así que no es pérdida real.
- Al arrancar por primera vez con cifrado, un binlog heredado *en claro* se
  detecta (ausencia del marcador `.alim_encrypted`) y se descarta: TDLib no
  puede abrir con clave una base creada sin ella.
- SQLCipher en Windows **requiere OpenSSL de desarrollo**; se provisiona con
  `scripts/setup_openssl.ps1` (vcpkg). En Android el plugin ya trae los
  binarios.
- Existe un `assert` que verifica `PRAGMA cipher_version` al abrir: si la
  librería nativa cargada NO fuera SQLCipher, la base se escribiría en claro
  *en silencio*. El assert lo convierte en un fallo ruidoso en debug.

## 3. Aislamiento entre usuarios (RLS de Supabase)

RLS activa en las 5 tablas. La membresía se comprueba con
`is_conversation_member()` (`SECURITY DEFINER`) para romper la recursión de
las políticas. `conversations` y `conversation_members` **no tienen política
de INSERT**: la única vía de crear una conversación es el RPC
`create_conversation()`, que fuerza `auth.uid()` como creador.

Verificado ejecutando SQL como el rol `authenticated` con el JWT de cada
usuario (no como `postgres`, que se salta RLS). Escenario: Alice y Bob
comparten un chat privado; Mallory no es miembro.

| Ataque de Mallory | Resultado |
|---|---|
| Leer los mensajes del chat ajeno | 0 filas |
| Leer la conversación / sus miembros | 0 filas |
| Insertar un mensaje en el chat ajeno | bloqueado |
| Auto-añadirse como miembro | bloqueado |
| Suplantar a Alice (`sender_id` falso) | bloqueado |

Control positivo: Bob (sí miembro) lee el mensaje correctamente — los ceros
de arriba no son un falso negativo.

Nadie puede editar mensajes (no hay política de UPDATE en `messages`). El
borrado sí está permitido, pero **solo al remitente de cada mensaje**
(política `messages_delete_own`), y verificado con el mismo método de
impersonación de roles:

| Acción | Resultado |
|---|---|
| Bob (miembro, no autor) borra el mensaje de Alice | bloqueado |
| Alice (autora) borra su propio mensaje | permitido |
| El otro mensaje de Alice tras ese borrado | intacto |

En la app el borrado es "para todos" (revoke en TDLib; borrado de la fila en
Supabase, que RLS solo concede al autor) y se refleja en el resto de
dispositivos por Realtime (`messages` tiene `REPLICA IDENTITY FULL` para que
el evento de DELETE incluya `conversation_id`, no solo la PK).

### Avisos de `get_advisors` triados

- `create_conversation` y `is_conversation_member` ejecutables por
  `authenticated`: **intencionado**. El primero es el punto de entrada RPC; el
  segundo lo invocan las propias políticas RLS.
- `rls_auto_enable` ejecutable por `anon`: **falso positivo**. Es una función
  de plataforma de Supabase (no del proyecto) y devuelve `event_trigger`, un
  tipo que PostgREST no puede invocar por RPC.

## 4. Android

- `allowBackup="false"`, `fullBackupContent="false"` y
  `data_extraction_rules.xml` excluyendo todos los dominios. Sin esto (el
  valor por defecto es `allowBackup=true`) las bases locales serían
  extraíbles con `adb backup` o acabarían en el backup en la nube.
- Único permiso: `INTERNET`. Sin tráfico en claro, sin componentes exportados
  más allá del launcher.

## 5. Superficie de ejecución del spec ALIM

El mini-lenguaje de expresiones tiene un evaluador **propio** con gramática
cerrada (`packages/alim_spec/lib/src/expression.dart`): literales, rutas del
contexto, aritmética, comparaciones, booleanos y ternario. No hay llamadas a
función, ni acceso a nada fuera del contexto que se le inyecta. Un tema
`.alim` importado no puede ejecutar código arbitrario. Cubierto por 11 tests,
incluidos entradas hostiles.

## 6. Borrado de cuenta (RGPD)

`conversations.created_by` y `messages.sender_id` apuntaban a `auth.users`
**sin cláusula `ON DELETE`**: borrar una cuenta fallaba con violación de clave
foránea, haciendo imposible ejercer el derecho de supresión. Corregido:

- `created_by` → `ON DELETE SET NULL` (la conversación sobrevive para el resto).
- `sender_id` → `ON DELETE CASCADE` (los mensajes se van con la cuenta).

Verificado borrando una cuenta con conversación y mensajes.

## 7. Pendiente / deuda consciente

- **Migrar a `sqlite3mc`** cuando el SDK de Dart permita drift ≥ 2.32:
  jubilaría `sqlcipher_flutter_libs` (deprecado) y eliminaría la dependencia
  de OpenSSL/vcpkg en Windows.
- **Rotación de claves**: hoy la clave de cifrado no se rota nunca.
- **Edición de mensajes**: no implementada (no hay política de UPDATE).
