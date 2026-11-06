// @source-mirror: src/stores/autenticacion.js
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response_parser.dart';

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

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    inicializarDesdeStorage();
  }

  static List<String> _extraerRoles(dynamic rolesCrudos, Map<String, dynamic>? usuarioActual) {
    List<dynamic> lista;
    if (rolesCrudos is List) {
      lista = rolesCrudos;
    } else if (rolesCrudos is Map) {
      lista = rolesCrudos.values.toList();
    } else if (usuarioActual?['roles'] is List) {
      lista = usuarioActual!['roles'] as List;
    } else if (usuarioActual?['rol'] != null) {
      lista = [usuarioActual!['rol']];
    } else {
      lista = [];
    }

    final Set<String> res = {};
    for (final rol in lista) {
      if (rol is String) {
        final limpio = rol.trim().toLowerCase();
        if (limpio.isNotEmpty) res.add(limpio);
      } else if (rol is Map) {
        final n = rol['name'] ?? rol['nombre'] ?? rol['rol'];
        if (n != null) {
          final limpio = n.toString().trim().toLowerCase();
          if (limpio.isNotEmpty) res.add(limpio);
        }
      } else if (rol != null) {
        final limpio = rol.toString().trim().toLowerCase();
        if (limpio.isNotEmpty) res.add(limpio);
      }
    }
    return res.toList();
  }

  Future<void> inicializarDesdeStorage() async {
    ApiClient.instance.onUnauthorizedCallback = () {
      cerrarSesion();
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenGuardado = prefs.getString('fs_token');
      final userJson = prefs.getString('fs_user');
      final rolesJson = prefs.getString('fs_roles');

      Map<String, dynamic>? user;
      if (userJson != null && userJson.isNotEmpty && userJson != 'undefined') {
        try {
          user = jsonDecode(userJson) as Map<String, dynamic>?;
        } catch (_) {}
      }

      List<String> rolesList = [];
      if (rolesJson != null && rolesJson.isNotEmpty && rolesJson != 'undefined') {
        try {
          final decoded = jsonDecode(rolesJson);
          rolesList = _extraerRoles(decoded, user);
        } catch (_) {}
      } else if (user != null) {
        rolesList = _extraerRoles(user['roles'] ?? user['rol'], user);
      }

      state = state.copyWith(
        token: tokenGuardado != 'undefined' ? tokenGuardado : null,
        usuario: user,
        roles: rolesList,
        sesionHidratada: false,
        cargando: false,
      );
    } catch (_) {
      state = state.copyWith(cargando: false);
    }
  }

  Future<void> _persistirEnStorage(String? t, Map<String, dynamic>? u, List<String> r) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (t != null && t.isNotEmpty) {
        await prefs.setString('fs_token', t);
        if (u != null) {
          await prefs.setString('fs_user', jsonEncode(u));
        }
        await prefs.setString('fs_roles', jsonEncode(r));
      } else {
        await prefs.remove('fs_token');
        await prefs.remove('fs_user');
        await prefs.remove('fs_roles');
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> guardarSesion(Map<String, dynamic> datos) async {
    final tokenRecibido = datos['access_token'] ?? datos['token'];
    if (tokenRecibido == null || tokenRecibido.toString().trim().isEmpty) {
      throw StateError('La respuesta no contiene access_token ni token.');
    }

    final tokenStr = tokenRecibido.toString();
    final userMap = datos['user'] is Map<String, dynamic>
        ? datos['user'] as Map<String, dynamic>
        : (datos['usuario'] is Map<String, dynamic> ? datos['usuario'] as Map<String, dynamic> : null);

    final rolesList = _extraerRoles(
      datos['roles'] ?? userMap?['roles'] ?? userMap?['rol'],
      userMap,
    );

    state = state.copyWith(
      token: tokenStr,
      usuario: userMap,
      roles: rolesList,
      sesionHidratada: true,
      cargando: false,
    );

    await _persistirEnStorage(tokenStr, userMap, rolesList);
    return datos;
  }

  Future<Map<String, dynamic>> iniciarSesion(Map<String, dynamic> credenciales) async {
    state = state.copyWith(cargando: true);
    try {
      final payload = {
        ...credenciales,
        'correo': credenciales['correo'] ?? credenciales['email'],
      };
      final response = await ApiClient.instance.dio.post('/login', data: payload);
      final datos = ApiResponseParser.extractData(response);
      return await guardarSesion(datos is Map<String, dynamic> ? datos : {});
    } finally {
      state = state.copyWith(cargando: false);
    }
  }

  Future<Map<String, dynamic>> registrar(Map<String, dynamic> formulario) async {
    state = state.copyWith(cargando: true);
    try {
      final response = await ApiClient.instance.dio.post('/register', data: formulario);
      final data = ApiResponseParser.extractData(response);
      return data is Map<String, dynamic> ? data : {};
    } finally {
      state = state.copyWith(cargando: false);
    }
  }

  Future<Map<String, dynamic>> verificarCorreo({
    required String correo,
    required String codigo,
  }) async {
    state = state.copyWith(cargando: true);
    try {
      final response = await ApiClient.instance.dio.post(
        '/verify-email',
        data: {'correo': correo, 'codigo': codigo},
      );
      final datos = ApiResponseParser.extractData(response);
      return await guardarSesion(datos is Map<String, dynamic> ? datos : {});
    } finally {
      state = state.copyWith(cargando: false);
    }
  }

  Future<Map<String, dynamic>> reenviarCodigo(String correo) async {
    final response = await ApiClient.instance.dio.post(
      '/resend-verification',
      data: {'correo': correo},
    );
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> iniciarSesionConGoogle(
    String credential, {
    bool aceptaTerminos = false,
  }) async {
    if (credential.isEmpty) {
      throw ArgumentError('Google no proporcionó una credencial válida.');
    }

    state = state.copyWith(cargando: true);
    try {
      final response = await ApiClient.instance.dio.post(
        '/auth/google',
        data: {
          'credential': credential,
          'acepta_terminos': aceptaTerminos,
        },
      );
      final datos = ApiResponseParser.extractData(response);
      return await guardarSesion(datos is Map<String, dynamic> ? datos : {});
    } finally {
      state = state.copyWith(cargando: false);
    }
  }

  Future<Map<String, dynamic>> actualizarUsuario(Map<String, dynamic> datos) async {
    final Map<String, dynamic> actualizado = {
      ...(state.usuario ?? {}),
      ...datos,
    };

    List<String> rolesList = state.roles;
    if (datos.containsKey('roles') || datos.containsKey('rol')) {
      rolesList = _extraerRoles(datos['roles'] ?? datos['rol'], actualizado);
    }

    state = state.copyWith(
      usuario: actualizado,
      roles: rolesList,
    );

    await _persistirEnStorage(state.token, actualizado, rolesList);
    return actualizado;
  }

  Future<void> hidratarSesion() async {
    if (!state.estaAutenticado || state.sesionHidratada) return;

    try {
      final response = await ApiClient.instance.dio.get('/me');
      final datos = ApiResponseParser.extractData(response);
      if (datos is Map<String, dynamic>) {
        final u = datos['user'] ?? datos['usuario'] ?? datos;
        final userMap = u is Map<String, dynamic> ? u : null;
        final rolesList = _extraerRoles(
          datos['roles'] ?? userMap?['roles'] ?? userMap?['rol'],
          userMap,
        );

        state = state.copyWith(
          usuario: userMap,
          roles: rolesList,
          sesionHidratada: true,
        );

        await _persistirEnStorage(state.token, userMap, rolesList);
      }
    } catch (_) {
      state = state.copyWith(sesionHidratada: false);
      rethrow;
    }
  }

  /// Vuelve a consultar /me para que cambios de rol aplicados por administradores
  /// se reflejen en la app móvil sin necesidad de cerrar sesión.
  /// NUNCA activa spinners de carga en segundo plano ni emite nuevo estado
  /// si los roles e identidad del usuario no han cambiado.
  Future<bool> refrescarSesion() async {
    if (!state.estaAutenticado) return false;

    try {
      final response = await ApiClient.instance.dio.get('/me');
      final datos = ApiResponseParser.extractData(response);
      if (datos is Map<String, dynamic>) {
        final u = datos['user'] ?? datos['usuario'] ?? datos;
        final userMap = u is Map<String, dynamic> ? Map<String, dynamic>.from(u) : state.usuario;

        // 1. Extraer roles de múltiples orígenes posibles en la respuesta de /me
        dynamic rawRoles = datos['roles'];
        if (rawRoles == null && userMap != null) {
          rawRoles = userMap['roles'] ?? userMap['rol'];
        }

        List<String> nuevosRoles = _extraerRoles(rawRoles, userMap);

        // 2. Si /me omite los roles y no vinieron en la respuesta, preservar los roles previos existentes
        if (nuevosRoles.isEmpty && rawRoles == null && state.roles.isNotEmpty) {
          nuevosRoles = List<String>.from(state.roles);
        }

        // 3. Comparar ID de usuario, estado activo y roles ordenados para evitar rebuilds innecesarios
        final currentUserId = state.usuario?['id_usuario'] ?? state.usuario?['id'];
        final newUserId = userMap?['id_usuario'] ?? userMap?['id'];

        final currentActivo = state.usuario?['activo'] ?? true;
        final newActivo = userMap?['activo'] ?? true;

        final currentSorted = List<String>.from(state.rolesNormalizados)..sort();
        final newSorted = List<String>.from(nuevosRoles.map((r) => r.trim().toLowerCase()))..sort();

        final rolesCambiaron = jsonEncode(currentSorted) != jsonEncode(newSorted);
        final userCambio = (currentUserId != null && newUserId != null && currentUserId != newUserId) ||
            (currentActivo != newActivo);

        if (!rolesCambiaron && !userCambio) {
          // No hubo cambios relevantes en roles ni en identidad: evitar emitir nuevo estado
          return false;
        }

        // 4. Solo si cambiaron roles o estado activo se actualiza el estado (sin activar cargando)
        state = state.copyWith(
          usuario: userMap,
          roles: nuevosRoles,
          sesionHidratada: true,
          cargando: false,
        );

        await _persistirEnStorage(state.token, userMap, nuevosRoles);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> cerrarSesion() async {
    try {
      if (state.token != null) {
        await ApiClient.instance.dio.post('/logout');
      }
    } catch (_) {}

    state = const AuthState();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fs_token');
      await prefs.remove('fs_user');
      await prefs.remove('fs_roles');
      await prefs.remove('favoritos');
      await prefs.remove('fs_carrito');
    } catch (_) {}
  }

  Future<Map<String, dynamic>> solicitarRecuperacion(String email) async {
    final response = await ApiClient.instance.dio.post(
      '/forgot-password',
      data: {'correo': email},
    );
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> restablecerContrasena(Map<String, dynamic> datos) async {
    final response = await ApiClient.instance.dio.post(
      '/reset-password',
      data: {
        'correo': datos['correo'],
        'codigo': datos['codigo'],
        'nueva_password': datos['nueva_password'],
        'nueva_password_confirmation': datos['nueva_password_confirmation'],
      },
    );
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
