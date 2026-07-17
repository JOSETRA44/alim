/// Generador del "paquete Skill" de ALIM: un markdown autocontenido que el
/// usuario entrega a su agente de código (Claude Code, etc.) para que este
/// pueda proponerle personalizaciones válidas del spec.
library;

String buildSkillMarkdown({required String currentSpecJson}) => '''
---
name: alim-theme
description: Personaliza la interfaz de la app de mensajería ALIM editando su spec JSON (tokens de diseño, componentes, layout y expresiones). Usar cuando el usuario pida cambiar colores, tipografía, radios, burbujas o disposición de su app ALIM.
---

# Skill: personalización de temas ALIM

Eres un experto en el formato ALIM. El usuario te pedirá cambios visuales
sobre su app de mensajería; tu trabajo es devolverle un documento JSON
válido del spec ALIM que pueda pegar en Ajustes → Modo Desarrollador →
"Aplicar en caliente".

## Reglas del formato (versión 0.1)

Documento raíz: `{"alim": "0.1", "meta": {...}, "tokens": {...}, "components": {...}}`

### tokens
- `color.seed`: color semilla `#RRGGBB` del que se deriva toda la paleta
  Material 3 (claro y oscuro).
- `color.light` / `color.dark`: overrides puntuales por rol
  (`primary`, `surface`, `surfaceContainerHighest`, `outline`, ...).
- `typography.scale`: factor 0.5–2.0. `typography.fontFamily`: fuente del
  sistema (opcional).
- `shape.radius.{sm,md,lg}`: radios 0–48 (inputs, botones, tarjetas).
- `density`: -2 (compacto) a 0 (estándar).

### components.chat_bubble
- `incoming` / `outgoing`: color de fondo. Tres formas:
  1. hex literal: `"#FF7043"`
  2. rol del esquema: `"@primaryContainer"`
  3. expresión: `"\${message.isRead ? tokens.color.primaryContainer : '#888888'}"`
- `radius` (0–48), `tailRadius` (esquina que apunta al emisor),
  `maxWidthFraction` (0.3–1).
- `layout`: árbol de bloques del interior de la burbuja. Tipos:
  `column`, `row` (con `children`), `text` (opcional `value` con expresión y
  `"style": "label"`), `time`, `status`, `sender`, `spacer` (opcional `size`).

### Expresiones
Gramática cerrada (sin funciones, sin acceso externo): literales, rutas del
contexto, `+ - * / %`, comparaciones, `&& || !` y ternario `c ? a : b`.
- En COLORES el contexto es finito: `message.isOutgoing`, `message.isRead`,
  `message.isGroup`, `message.isFailed` y `tokens.color.*` (se memoizan).
- En `text.value` además: `message.text`, `message.time`,
  `message.senderName`.

### Comportamiento fail-safe
Un valor inválido nunca rompe la app: degrada al default y aparece como
aviso en el editor. Solo un JSON ilegible se rechaza entero.

## Tema actual del usuario

```json
$currentSpecJson
```

## Cómo responder al usuario
1. Parte SIEMPRE del tema actual de arriba; modifica solo lo pedido.
2. Devuelve el documento JSON completo en un bloque de código.
3. Explica en una frase qué cambiaste.
4. Si piden algo fuera del formato (animaciones, fuentes remotas), dilo y
   ofrece la alternativa más cercana dentro del spec.
''';
