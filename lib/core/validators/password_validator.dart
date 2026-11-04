// @source-mirror: src/utils/validarPassword.js

class PasswordRequirement {
  final String id;
  final String texto;
  final bool Function(String) cumple;

  const PasswordRequirement({
    required this.id,
    required this.texto,
    required this.cumple,
  });
}

const List<String> palabrasComunesProhibidas = [
  'password',
  'contrasena',
  'qwerty',
  'abcdef',
  'fashionstyle',
  'admin',
  'administrador',
  'bienvenido',
  'colombia',
  'iloveyou',
];

String _normalizarParaComparacion(String texto) {
  return texto
      .toLowerCase()
      .replaceAll(RegExp(r'[áàäâã]', caseSensitive: false), 'a')
      .replaceAll(RegExp(r'[éèëê]', caseSensitive: false), 'e')
      .replaceAll(RegExp(r'[íìïî]', caseSensitive: false), 'i')
      .replaceAll(RegExp(r'[óòöôõ]', caseSensitive: false), 'o')
      .replaceAll(RegExp(r'[úùüû]', caseSensitive: false), 'u')
      .replaceAll(RegExp(r'[ñ]', caseSensitive: false), 'n')
      .replaceAll(RegExp(r'[^a-z]'), '');
}

final List<PasswordRequirement> requisitosPassword = [
  PasswordRequirement(
    id: 'largo',
    texto: 'Entre 10 y 64 caracteres',
    cumple: (p) => p.length >= 10 && p.length <= 64,
  ),
  PasswordRequirement(
    id: 'mayus',
    texto: 'Una mayúscula',
    cumple: (p) => RegExp(r'[A-Z]').hasMatch(p),
  ),
  PasswordRequirement(
    id: 'minus',
    texto: 'Una minúscula',
    cumple: (p) => RegExp(r'[a-z]').hasMatch(p),
  ),
  PasswordRequirement(
    id: 'numero',
    texto: 'Un número',
    cumple: (p) => RegExp(r'\d').hasMatch(p),
  ),
  PasswordRequirement(
    id: 'simbolo',
    texto: r'Un símbolo (! @ # $ %)',
    cumple: (p) => RegExp(r'[^a-zA-Z0-9\s]').hasMatch(p),
  ),
  PasswordRequirement(
    id: 'comun',
    texto: 'No es una palabra común (ej. "Password")',
    cumple: (p) {
      if (p.isEmpty) return true;
      final base = _normalizarParaComparacion(p);
      return !palabrasComunesProhibidas.contains(base);
    },
  ),
];

bool passwordEsSegura(String? password) {
  final p = password ?? '';
  return requisitosPassword.every((r) => r.cumple(p));
}
