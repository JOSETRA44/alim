/// Presets de fábrica. También sirven como documentación viva del formato:
/// el editor del Dev Mode los carga como punto de partida.
library;

/// Tema por defecto: un lienzo en calma. Superficie blanco-papel con un solo
/// hilo de tinta verde-pino — la identidad de ALIM es que el usuario pinta
/// encima.
const defaultSpecJson = '''
{
  "alim": "0.1",
  "meta": {"name": "Lienzo", "author": "ALIM"},
  "tokens": {
    "color": {
      "seed": "#3D5A50",
      "light": {"surface": "#FAFAF8"},
      "dark": {}
    },
    "typography": {"scale": 1.0},
    "shape": {"radius": {"sm": 8, "md": 12, "lg": 16}},
    "spacing": {"unit": 8},
    "density": 0
  },
  "components": {
    "chat_bubble": {
      "incoming": "@surfaceContainerHighest",
      "outgoing": "@primaryContainer",
      "radius": 16,
      "tailRadius": 4,
      "maxWidthFraction": 0.75
    }
  }
}
''';

/// Oscuro editorial: tinta sobre pizarra, acento dorado desaturado,
/// radios pequeños y burbujas casi planas.
const _tintaSpecJson = '''
{
  "alim": "0.1",
  "meta": {"name": "Tinta", "author": "ALIM"},
  "tokens": {
    "color": {
      "seed": "#C9A15C",
      "light": {},
      "dark": {
        "surface": "#14171C",
        "surfaceContainerHighest": "#1E232B",
        "primary": "#C9A15C",
        "onPrimary": "#14171C"
      }
    },
    "typography": {"scale": 1.0},
    "shape": {"radius": {"sm": 4, "md": 6, "lg": 8}},
    "spacing": {"unit": 8},
    "density": -0.5
  },
  "components": {
    "chat_bubble": {
      "incoming": "@surfaceContainerHighest",
      "outgoing": "#2C2417",
      "radius": 6,
      "tailRadius": 6,
      "maxWidthFraction": 0.8
    }
  }
}
''';

/// Lúdico: violeta perivinca, radios generosos, burbujas totalmente redondas.
const _burbujaSpecJson = '''
{
  "alim": "0.1",
  "meta": {"name": "Burbuja", "author": "ALIM"},
  "tokens": {
    "color": {
      "seed": "#6C63D2",
      "light": {},
      "dark": {}
    },
    "typography": {"scale": 1.05},
    "shape": {"radius": {"sm": 12, "md": 20, "lg": 28}},
    "spacing": {"unit": 8},
    "density": 0
  },
  "components": {
    "chat_bubble": {
      "incoming": "@secondaryContainer",
      "outgoing": "@primaryContainer",
      "radius": 24,
      "tailRadius": 24,
      "maxWidthFraction": 0.7
    }
  }
}
''';

/// Demostración del spec v1 completo: colores por EXPRESIÓN (memoizados por
/// contexto) y layout de bloques del interior de la burbuja.
const _expresivoSpecJson = r'''
{
  "alim": "0.1",
  "meta": {"name": "Expresivo", "author": "ALIM"},
  "tokens": {
    "color": {"seed": "#B3541E", "light": {}, "dark": {}},
    "typography": {"scale": 1.0},
    "shape": {"radius": {"sm": 8, "md": 14, "lg": 20}},
    "spacing": {"unit": 8},
    "density": 0
  },
  "components": {
    "chat_bubble": {
      "incoming": "${message.isGroup ? tokens.color.tertiaryContainer : tokens.color.surfaceContainerHighest}",
      "outgoing": "${message.isRead ? tokens.color.primaryContainer : tokens.color.secondaryContainer}",
      "radius": 18,
      "tailRadius": 4,
      "maxWidthFraction": 0.8,
      "layout": {
        "type": "column",
        "children": [
          {"type": "sender"},
          {"type": "text"},
          {
            "type": "row",
            "children": [
              {"type": "text", "value": "${message.isOutgoing ? 'tú' : ''}", "style": "label"},
              {"type": "spacer", "size": 6},
              {"type": "time"},
              {"type": "spacer", "size": 4},
              {"type": "status"}
            ]
          }
        ]
      }
    }
  }
}
''';

/// Presets disponibles en el Dev Mode, en orden de presentación.
const presetSpecs = <String, String>{
  'Lienzo': defaultSpecJson,
  'Tinta': _tintaSpecJson,
  'Burbuja': _burbujaSpecJson,
  'Expresivo': _expresivoSpecJson,
};
