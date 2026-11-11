// @source-mirror: src/stores/autenticacion.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

class AuthState {
  final String? token;
  final Map<String, dynamic>? usuario;
  final List<String> roles;
  final bool sesionHidratada;
  final bool cargando;

  const AuthState({
    this.token,
    this.usuario,
    this.roles = const [],
    this.sesionHidratada = false,
    this.cargando = false,
  });

  bool get estaAutenticado => token != null && token!.isNotEmpty && token != 'undefined';

  List<String> get rolesNormalizados {
    final List<dynamic> lista = roles.isNotEmpty
        ? roles
        : (usuario?['roles'] is List
            ? usuario!['roles'] as List
            : (usuario?['rol'] != null ? [usuario!['rol']] : []));

    final Set<String> normalizados = {};
    for (final r in lista) {
      if (r is String) {
        final limpio = r.trim().toLowerCase();
        if (limpio.isNotEmpty) normalizados.add(limpio);
      } else if (r is Map) {
        final nombre = r['name'] ?? r['nombre'] ?? r['rol'];
        if (nombre != null) {
          final limpio = nombre.toString().trim().toLowerCase();
          if (limpio.isNotEmpty) normalizados.add(limpio);
        }
      } else if (r != null) {
        final limpio = r.toString().trim().toLowerCase();
        if (limpio.isNotEmpty) normalizados.add(limpio);
      }
    }
    return normalizados.toList();
  }

  bool get esAdmin => rolesNormalizados.any((r) => const ['admin', 'administrador', 'super-admin'].contains(r));

  bool get esEmpleado => rolesNormalizados.any((r) => const ['empleado', 'staff'].contains(r));

  bool get esPersonal => esAdmin || esEmpleado;

  bool get tieneAccesoAdmin => esAdmin || esEmpleado || esPersonal;

  String get nombreUsuario => (usuario?['nombre'] ?? usuario?['name'] ?? 'Usuario').toString();

  String get correoUsuario => (usuario?['email'] ?? usuario?['correo'] ?? '').toString();

  String? get fotoUsuario => usuario?['foto_perfil']?.toString() ?? usuario?['foto']?.toString();

  String get rolUsuario {
    if (esAdmin) return 'admin';
    if (esEmpleado) return 'empleado';
    return rolesNormalizados.isNotEmpty ? rolesNormalizados.first : 'cliente';
  }

  String get rutaInicial => (esAdmin || esEmpleado) ? '/admin' : '/';

  int? get usuarioId => usuario != null ? JsonParser.toInt(usuario!['id_usuario'] ?? usuario!['id']) : null;

  AuthState copyWith({
    String? token,
    Map<String, dynamic>? usuario,
    List<String>? roles,
    bool? sesionHidratada,
    bool? cargando,
    bool limpiarToken = false,
    bool limpiarUsuario = false,
  }) {
    return AuthState(
      token: limpiarToken ? null : (token ?? this.token),
      usuario: limpiarUsuario ? null : (usuario ?? this.usuario),
      roles: roles ?? this.roles,
      sesionHidratada: sesionHidratada ?? this.sesionHidratada,
      cargando: cargando ?? this.cargando,
    );
  }
}
