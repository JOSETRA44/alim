/// Mini-lenguaje de expresiones del formato ALIM.
///
/// Seguridad por construcción: la gramática es cerrada — literales,
/// rutas del contexto inyectado (`message.isOutgoing`,
/// `tokens.color.primary`), operadores aritméticos/lógicos/comparación y
/// ternario. No hay llamadas a funciones, ni asignación, ni forma alguna de
/// tocar algo fuera del contexto.
///
/// Contrato de rendimiento (mandato anti-jank): [AlimExpression.compile]
/// parsea UNA vez a AST al cargar el tema; [AlimExpression.evaluate] es puro
/// y barato, y el theme engine memoiza sus resultados por clave de contexto.
library;

/// Error de compilación o evaluación de una expresión.
class ExpressionException implements Exception {
  const ExpressionException(this.message, {this.position});

  final String message;
  final int? position;

  @override
  String toString() =>
      'ExpressionException($message${position == null ? '' : ' @$position'})';
}

/// Contexto de evaluación: ámbitos anidados por nombre
/// (p. ej. `{'message': {'isOutgoing': true}, 'tokens': {...}}`).
typedef ExprContext = Map<String, Object?>;

/// Expresión compilada e inmutable.
class AlimExpression {
  const AlimExpression._(this.source, this._root);

  final String source;
  final _Node _root;

  /// Parsea [source]. Lanza [ExpressionException] si es inválida.
  static AlimExpression compile(String source) {
    final tokens = _Lexer(source).tokenize();
    final parser = _Parser(tokens, source);
    final root = parser.parseExpression();
    parser.expectEnd();
    return AlimExpression._(source, root);
  }

  /// Evalúa contra [context]. Los valores posibles son num, String, bool y
  /// null. Lanza [ExpressionException] ante tipos incompatibles o rutas
  /// inexistentes (el llamador degrada a default, fail-safe).
  Object? evaluate(ExprContext context) => _root.eval(context);
}

// --- Lexer -------------------------------------------------------------------

enum _TokenType {
  number,
  string,
  identifier,
  operator_,
  end,
}

class _Token {
  const _Token(this.type, this.text, this.position);

  final _TokenType type;
  final String text;
  final int position;
}

class _Lexer {
  _Lexer(this.source);

  final String source;
  int _i = 0;

  static const _twoCharOps = {'==', '!=', '<=', '>=', '&&', '||'};
  static const _oneCharOps = {
    '+', '-', '*', '/', '%', '<', '>', '!', '?', ':', '(', ')', '.',
  };

  List<_Token> tokenize() {
    final tokens = <_Token>[];
    while (true) {
      _skipWhitespace();
      if (_i >= source.length) break;
      final start = _i;
      final char = source[_i];

      if (_isDigit(char)) {
        while (_i < source.length && _isDigit(source[_i])) {
          _i++;
        }
        if (_i < source.length &&
            source[_i] == '.' &&
            _i + 1 < source.length &&
            _isDigit(source[_i + 1])) {
          _i++;
          while (_i < source.length && _isDigit(source[_i])) {
            _i++;
          }
        }
        tokens.add(_Token(_TokenType.number, source.substring(start, _i), start));
        continue;
      }

      if (char == "'") {
        final buffer = StringBuffer();
        _i++;
        while (true) {
          if (_i >= source.length) {
            throw ExpressionException('String sin cerrar', position: start);
          }
          final c = source[_i];
          if (c == r'\' && _i + 1 < source.length) {
            buffer.write(source[_i + 1]);
            _i += 2;
            continue;
          }
          if (c == "'") {
            _i++;
            break;
          }
          buffer.write(c);
          _i++;
        }
        tokens.add(_Token(_TokenType.string, buffer.toString(), start));
        continue;
      }

      if (_isIdentifierStart(char)) {
        while (_i < source.length && _isIdentifierPart(source[_i])) {
          _i++;
        }
        tokens.add(
            _Token(_TokenType.identifier, source.substring(start, _i), start));
        continue;
      }

      if (_i + 1 < source.length &&
          _twoCharOps.contains(source.substring(_i, _i + 2))) {
        tokens.add(_Token(_TokenType.operator_, source.substring(_i, _i + 2), start));
        _i += 2;
        continue;
      }

      if (_oneCharOps.contains(char)) {
        tokens.add(_Token(_TokenType.operator_, char, start));
        _i++;
        continue;
      }

      throw ExpressionException("Carácter inesperado '$char'", position: _i);
    }
    tokens.add(_Token(_TokenType.end, '', source.length));
    return tokens;
  }

  void _skipWhitespace() {
    while (_i < source.length && (source[_i] == ' ' || source[_i] == '\t')) {
      _i++;
    }
  }

  static bool _isDigit(String c) =>
      c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;

  static bool _isIdentifierStart(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 0x41 && code <= 0x5A) ||
        (code >= 0x61 && code <= 0x7A) ||
        c == '_';
  }

  static bool _isIdentifierPart(String c) =>
      _isIdentifierStart(c) || _isDigit(c);
}

// --- Parser (descenso recursivo por precedencia) ------------------------------

class _Parser {
  _Parser(this._tokens, this.source);

  final List<_Token> _tokens;
  final String source;
  int _i = 0;

  _Token get _current => _tokens[_i];

  bool _matchOp(String op) {
    if (_current.type == _TokenType.operator_ && _current.text == op) {
      _i++;
      return true;
    }
    return false;
  }

  void _expectOp(String op) {
    if (!_matchOp(op)) {
      throw ExpressionException("Se esperaba '$op'",
          position: _current.position);
    }
  }

  void expectEnd() {
    if (_current.type != _TokenType.end) {
      throw ExpressionException(
          "Sobra '${_current.text}' al final de la expresión",
          position: _current.position);
    }
  }

  _Node parseExpression() => _ternary();

  _Node _ternary() {
    final condition = _or();
    if (!_matchOp('?')) return condition;
    final whenTrue = parseExpression();
    _expectOp(':');
    final whenFalse = parseExpression();
    return _Ternary(condition, whenTrue, whenFalse);
  }

  _Node _or() {
    var left = _and();
    while (_matchOp('||')) {
      left = _Logical(left, _and(), isAnd: false);
    }
    return left;
  }

  _Node _and() {
    var left = _equality();
    while (_matchOp('&&')) {
      left = _Logical(left, _equality(), isAnd: true);
    }
    return left;
  }

  _Node _equality() {
    var left = _comparison();
    while (true) {
      if (_matchOp('==')) {
        left = _Binary(left, _comparison(), '==');
      } else if (_matchOp('!=')) {
        left = _Binary(left, _comparison(), '!=');
      } else {
        return left;
      }
    }
  }

  _Node _comparison() {
    var left = _additive();
    while (true) {
      final op = ['<=', '>=', '<', '>']
          .where(_peekOp)
          .firstOrNull;
      if (op == null) return left;
      _matchOp(op);
      left = _Binary(left, _additive(), op);
    }
  }

  _Node _additive() {
    var left = _multiplicative();
    while (true) {
      if (_matchOp('+')) {
        left = _Binary(left, _multiplicative(), '+');
      } else if (_matchOp('-')) {
        left = _Binary(left, _multiplicative(), '-');
      } else {
        return left;
      }
    }
  }

  _Node _multiplicative() {
    var left = _unary();
    while (true) {
      final op = ['*', '/', '%'].where(_peekOp).firstOrNull;
      if (op == null) return left;
      _matchOp(op);
      left = _Binary(left, _unary(), op);
    }
  }

  bool _peekOp(String op) =>
      _current.type == _TokenType.operator_ && _current.text == op;

  _Node _unary() {
    if (_matchOp('!')) return _Not(_unary());
    if (_matchOp('-')) return _Negate(_unary());
    return _primary();
  }

  _Node _primary() {
    final token = _current;
    switch (token.type) {
      case _TokenType.number:
        _i++;
        return _Literal(num.parse(token.text));
      case _TokenType.string:
        _i++;
        return _Literal(token.text);
      case _TokenType.identifier:
        _i++;
        if (token.text == 'true') return const _Literal(true);
        if (token.text == 'false') return const _Literal(false);
        if (token.text == 'null') return const _Literal(null);
        final path = [token.text];
        while (_matchOp('.')) {
          final part = _current;
          if (part.type != _TokenType.identifier) {
            throw ExpressionException('Se esperaba un nombre tras "."',
                position: part.position);
          }
          _i++;
          path.add(part.text);
        }
        return _Reference(path);
      case _TokenType.operator_ when token.text == '(':
        _i++;
        final inner = parseExpression();
        _expectOp(')');
        return inner;
      default:
        throw ExpressionException("Token inesperado '${token.text}'",
            position: token.position);
    }
  }
}

// --- AST ----------------------------------------------------------------------

sealed class _Node {
  const _Node();

  Object? eval(ExprContext context);
}

class _Literal extends _Node {
  const _Literal(this.value);

  final Object? value;

  @override
  Object? eval(ExprContext context) => value;
}

class _Reference extends _Node {
  const _Reference(this.path);

  final List<String> path;

  @override
  Object? eval(ExprContext context) {
    Object? current = context;
    for (final part in path) {
      if (current is! Map) {
        throw ExpressionException(
            "Ruta desconocida '${path.join('.')}' (en '$part')");
      }
      if (!current.containsKey(part)) {
        throw ExpressionException("Ruta desconocida '${path.join('.')}'");
      }
      current = current[part];
    }
    return current;
  }
}

class _Ternary extends _Node {
  const _Ternary(this.condition, this.whenTrue, this.whenFalse);

  final _Node condition;
  final _Node whenTrue;
  final _Node whenFalse;

  @override
  Object? eval(ExprContext context) =>
      _asBool(condition.eval(context)) ? whenTrue.eval(context) : whenFalse.eval(context);
}

class _Logical extends _Node {
  const _Logical(this.left, this.right, {required this.isAnd});

  final _Node left;
  final _Node right;
  final bool isAnd;

  @override
  Object? eval(ExprContext context) {
    final l = _asBool(left.eval(context));
    // Cortocircuito.
    if (isAnd && !l) return false;
    if (!isAnd && l) return true;
    return _asBool(right.eval(context));
  }
}

class _Not extends _Node {
  const _Not(this.operand);

  final _Node operand;

  @override
  Object? eval(ExprContext context) => !_asBool(operand.eval(context));
}

class _Negate extends _Node {
  const _Negate(this.operand);

  final _Node operand;

  @override
  Object? eval(ExprContext context) => -_asNum(operand.eval(context));
}

class _Binary extends _Node {
  const _Binary(this.left, this.right, this.op);

  final _Node left;
  final _Node right;
  final String op;

  @override
  Object? eval(ExprContext context) {
    final l = left.eval(context);
    final r = right.eval(context);
    switch (op) {
      case '==':
        return l == r;
      case '!=':
        return l != r;
      case '+':
        if (l is String || r is String) {
          return '${l ?? ''}${r ?? ''}';
        }
        return _asNum(l) + _asNum(r);
      case '-':
        return _asNum(l) - _asNum(r);
      case '*':
        return _asNum(l) * _asNum(r);
      case '/':
        final divisor = _asNum(r);
        if (divisor == 0) throw const ExpressionException('División por cero');
        return _asNum(l) / divisor;
      case '%':
        final divisor = _asNum(r);
        if (divisor == 0) throw const ExpressionException('Módulo por cero');
        return _asNum(l) % divisor;
      case '<':
        return _asNum(l) < _asNum(r);
      case '<=':
        return _asNum(l) <= _asNum(r);
      case '>':
        return _asNum(l) > _asNum(r);
      case '>=':
        return _asNum(l) >= _asNum(r);
      default:
        throw ExpressionException("Operador desconocido '$op'");
    }
  }
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  throw ExpressionException('Se esperaba booleano, llegó ${_typeName(value)}');
}

num _asNum(Object? value) {
  if (value is num) return value;
  throw ExpressionException('Se esperaba número, llegó ${_typeName(value)}');
}

String _typeName(Object? value) => switch (value) {
      null => 'null',
      num _ => 'número',
      String _ => 'texto',
      bool _ => 'booleano',
      _ => value.runtimeType.toString(),
    };
