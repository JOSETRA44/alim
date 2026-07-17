/// Layout de bloques del formato ALIM (v1: interior de componentes).
///
/// Contrato anti-jank: el árbol JSON se compila UNA vez a nodos tipados con
/// expresiones ya parseadas ([CompiledBlock.compile]); construir widgets por
/// mensaje a partir de nodos tipados es trabajo normal de Flutter, sin JSON
/// ni parsing por frame.
library;

import 'package:alim_spec/alim_spec.dart';
import 'package:flutter/material.dart';

/// Datos del mensaje visibles para el layout y sus expresiones.
/// Independiente del dominio de mensajería: la app hace el mapeo.
class BubbleMessageData {
  const BubbleMessageData({
    required this.text,
    required this.timeLabel,
    required this.isOutgoing,
    required this.isRead,
    required this.isGroup,
    required this.isFailed,
    required this.isSending,
    this.senderName,
  });

  final String text;
  final String timeLabel;
  final bool isOutgoing;
  final bool isRead;
  final bool isGroup;
  final bool isFailed;
  final bool isSending;
  final String? senderName;

  /// Contexto completo para expresiones de CONTENIDO (los estilos de color
  /// usan la clave finita, no esto).
  ExprContext toExprContext() => {
        'message': {
          'text': text,
          'time': timeLabel,
          'senderName': senderName ?? '',
          'isOutgoing': isOutgoing,
          'isRead': isRead,
          'isGroup': isGroup,
          'isFailed': isFailed,
        },
      };
}

sealed class BlockNode {
  const BlockNode();
}

class ColumnNode extends BlockNode {
  const ColumnNode(this.children);

  final List<BlockNode> children;
}

class RowNode extends BlockNode {
  const RowNode(this.children);

  final List<BlockNode> children;
}

class TextNode extends BlockNode {
  const TextNode({this.value, this.isLabel = false});

  /// Expresión compilada; null = texto del mensaje.
  final AlimExpression? value;

  /// true → estilo labelSmall (secundario); false → bodyLarge.
  final bool isLabel;
}

class TimeNode extends BlockNode {
  const TimeNode();
}

class StatusNode extends BlockNode {
  const StatusNode();
}

class SenderNode extends BlockNode {
  const SenderNode();
}

class SpacerNode extends BlockNode {
  const SpacerNode(this.size);

  /// null = flexible (Spacer); valor = hueco fijo en px.
  final double? size;
}

/// Árbol de layout compilado, listo para renderizar.
class CompiledBlock {
  const CompiledBlock._(this.root);

  final BlockNode root;

  /// Compila el árbol JSON. Fail-safe: los nodos inválidos se descartan con
  /// un issue; si la raíz es inválida devuelve null (layout nativo).
  static CompiledBlock? compile(Object? raw, List<SpecIssue> issues,
      {String path = 'layout'}) {
    final root = _node(raw, issues, path);
    return root == null ? null : CompiledBlock._(root);
  }

  static BlockNode? _node(Object? raw, List<SpecIssue> issues, String path) {
    if (raw is! Map<String, Object?>) {
      issues.add(SpecIssue(
          SpecSeverity.warning, path, 'Un bloque debe ser un objeto'));
      return null;
    }
    final type = raw['type'];
    switch (type) {
      case 'column' || 'row':
        final children = <BlockNode>[];
        final rawChildren = raw['children'];
        if (rawChildren is List) {
          for (final (i, child) in rawChildren.indexed) {
            final node = _node(child, issues, '$path.children[$i]');
            if (node != null) children.add(node);
          }
        }
        return type == 'column' ? ColumnNode(children) : RowNode(children);
      case 'text':
        AlimExpression? value;
        final rawValue = raw['value'];
        if (rawValue is String) {
          try {
            value = compileTemplate(rawValue);
          } on ExpressionException catch (e) {
            issues.add(SpecIssue(
                SpecSeverity.warning, '$path.value', e.message));
          }
        }
        return TextNode(value: value, isLabel: raw['style'] == 'label');
      case 'time':
        return const TimeNode();
      case 'status':
        return const StatusNode();
      case 'sender':
        return const SenderNode();
      case 'spacer':
        final size = raw['size'];
        return SpacerNode(size is num ? size.toDouble() : null);
      default:
        issues.add(SpecIssue(
            SpecSeverity.warning, path, "Tipo de bloque desconocido '$type'"));
        return null;
    }
  }

  /// Renderiza el árbol para un mensaje. [onSurface]/[onSurfaceVariant]
  /// llegan del estilo resuelto de la burbuja.
  Widget build(
    BuildContext context,
    BubbleMessageData data, {
    required Widget statusIcon,
  }) {
    final exprContext = data.toExprContext();
    return _widget(context, root, data, exprContext, statusIcon);
  }

  Widget _widget(
    BuildContext context,
    BlockNode node,
    BubbleMessageData data,
    ExprContext exprContext,
    Widget statusIcon,
  ) {
    final theme = Theme.of(context);
    switch (node) {
      case ColumnNode(:final children):
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final child in children)
              _widget(context, child, data, exprContext, statusIcon),
          ],
        );
      case RowNode(:final children):
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final child in children)
              _widget(context, child, data, exprContext, statusIcon),
          ],
        );
      case TextNode(:final value, :final isLabel):
        String text;
        if (value == null) {
          text = data.text;
        } else {
          try {
            text = '${value.evaluate(exprContext) ?? ''}';
          } on ExpressionException {
            text = ''; // fail-safe: expresión rota no rompe el render
          }
        }
        return Text(
          text,
          style: isLabel
              ? theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)
              : theme.textTheme.bodyLarge,
        );
      case TimeNode():
        return Text(
          data.timeLabel,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        );
      case StatusNode():
        return data.isOutgoing ? statusIcon : const SizedBox.shrink();
      case SenderNode():
        final sender = data.senderName;
        if (sender == null || data.isOutgoing || !data.isGroup) {
          return const SizedBox.shrink();
        }
        return Text(
          sender,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        );
      case SpacerNode(:final size):
        return size == null
            ? const SizedBox(width: 8)
            : SizedBox(width: size, height: size);
    }
  }
}

/// Compila un valor de plantilla: `${expr}` (string completo) se compila
/// como expresión; cualquier otro string es literal.
AlimExpression compileTemplate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.startsWith(r'${') && trimmed.endsWith('}')) {
    return AlimExpression.compile(
        trimmed.substring(2, trimmed.length - 1));
  }
  // Literal: se envuelve como expresión de string constante.
  return AlimExpression.compile("'${trimmed.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'");
}
