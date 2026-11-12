// @source-mirror: src/services/clienteApi.js
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fashion_style_mobile/core/network/change_bus.dart';

final RegExp patronDatosSensibles = RegExp(
  r'(sqlstate|sql|database|query|exception|dioexception|bad response|status code|response\.data|pdo|mysql|mysqli|postgres|sqlite|mariadb|connection:|host:|port:|trace|stack|constraint|foreign key|primary key|duplicate key|integrity constraint|unknown column|table|tbl_|where|column|field list|data truncated|syntax error|undefined index|undefined variable|failed host lookup|connection refused|errno|127\.0\.0\.1|localhost|3306|8000|password_hash|secret|api_key|access_token|bearer|laravel|artisan|vendor|\.php|\.dart|app/http|call stack)',
  caseSensitive: false,
);

const String mensajeServicioNoDisponible =
    'El servicio no está disponible temporalmente. Por favor, intenta de nuevo en unos momentos.';

const String mensajeConexionFallida =
    'No fue posible conectar con el servidor. Revisa tu conexión a internet e intenta nuevamente.';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get instance => _instance;

  late final Dio dio;

  String? Function()? socketIdProvider;
  void Function()? onUnauthorizedCallback;

  ApiClient._internal() {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://fashionstyle.api.adsocidm.com/public/api',
    );

    final baseOptions = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    dio = Dio(baseOptions);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('fs_token');
            if (token != null && token.isNotEmpty && token != 'undefined') {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}

          final socketId = socketIdProvider?.call();
          if (socketId != null && socketId.isNotEmpty) {
            options.headers['X-Socket-ID'] = socketId;
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          const metodosQueModifican = ['post', 'put', 'patch', 'delete'];
          final metodo = response.requestOptions.method.toLowerCase();

          if (metodosQueModifican.contains(metodo)) {
            ChangeBus.instance.emitirCambio(
              ChangeBus.normalizarRuta(
                response.requestOptions.path,
                response.requestOptions.baseUrl,
              ),
            );
          }

          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          if (error.response?.data is Map<String, dynamic>) {
            final data = error.response!.data as Map<String, dynamic>;
            final msg = data['message'] ?? data['mensaje'];
            if ((msg is String && patronDatosSensibles.hasMatch(msg)) ||
                (error.response?.statusCode ?? 0) >= 500) {
              data['message'] = mensajeServicioNoDisponible;
              data.remove('exception');
              data.remove('file');
              data.remove('line');
              data.remove('trace');
            }
          }

          // Nota: No se limpia la sesión en solicitudes transitorias fallidas.
          // Solo el cierre de sesión explícito por parte del usuario (cerrarSesion) invalida el token.

          return handler.next(error);
        },
      ),
    );
  }

  static String sanitizarTextoError(
    dynamic texto, [
    String fallback = mensajeServicioNoDisponible,
  ]) {
    if (texto == null) return fallback;
    var limpio = texto.toString().trim();
    limpio = limpio
        .replaceFirst(RegExp(r'^(Exception|Error|DioException|ClientException|SocketException):\s*', caseSensitive: false), '')
        .trim();

    if (limpio.startsWith('"') && limpio.endsWith('"') && limpio.length > 1) {
      limpio = limpio.substring(1, limpio.length - 1).trim();
    }

    if (limpio.isEmpty || patronDatosSensibles.hasMatch(limpio) || limpio.length > 220) {
      return fallback;
    }

    final minusculas = limpio.toLowerCase();
    if (minusculas.contains('unauthenticated') || minusculas.contains('no autenticado')) {
      return 'Tu sesión ha expirado. Por favor inicia sesión nuevamente.';
    }
    if (minusculas.contains('unauthorized') || minusculas.contains('no autorizado')) {
      return 'No tienes permisos suficientes para realizar esta acción.';
    }
    if (minusculas.contains('csrf token mismatch')) {
      return 'Tu sesión se desactualizó. Por favor recarga e intenta de nuevo.';
    }
    if (minusculas.contains('too many requests') || minusculas.contains('demasiados intentos')) {
      return 'Has realizado demasiados intentos. Espera unos momentos antes de continuar.';
    }
    if (minusculas.contains('invalid credentials') || minusculas.contains('credenciales incorrectas')) {
      return 'El correo o la contraseña son incorrectos.';
    }

    return limpio;
  }

  static String obtenerMensajeError(
    dynamic error, [
    String fallback = 'No se pudo completar la operación. Por favor intenta nuevamente.',
  ]) {
    if (error == null) return fallback;

    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'El servidor tardó demasiado en responder. Verifica tu conexión a internet.';
      }
      if (error.type == DioExceptionType.connectionError || error.response == null) {
        return mensajeConexionFallida;
      }

      final status = error.response?.statusCode ?? 0;
      final raw = error.response?.data;

      if (raw is Map<String, dynamic> && raw['errors'] != null) {
        final validacion = raw['errors'];
        if (validacion is Map<String, dynamic> && validacion.isNotEmpty) {
          final buffer = StringBuffer();
          for (final entry in validacion.values) {
            if (entry is List) {
              for (final item in entry) {
                if (item != null) buffer.write('$item ');
              }
            } else if (entry != null) {
              buffer.write('$entry ');
            }
          }
          final textoValidacion = buffer.toString().trim();
          if (textoValidacion.isNotEmpty && !patronDatosSensibles.hasMatch(textoValidacion)) {
            return sanitizarTextoError(textoValidacion, fallback);
          }
        }
      }

      if (status == 401) {
        return 'Tu sesión ha expirado o las credenciales no son válidas.';
      }
      if (status == 403) {
        return 'No tienes autorización para realizar esta acción.';
      }
      if (status == 404) {
        return 'El elemento solicitado no fue encontrado o ya no está disponible.';
      }
      if (status == 429) {
        return 'Has realizado demasiados intentos. Por favor espera unos momentos.';
      }
      if (status >= 500) {
        return mensajeServicioNoDisponible;
      }

      final mensajeOriginal = raw is String
          ? raw
          : (raw is Map<String, dynamic>
              ? (raw['message'] ?? raw['mensaje'] ?? raw['error'] ?? '')
              : '');

      return sanitizarTextoError(mensajeOriginal, fallback);
    }

    return sanitizarTextoError(error, fallback);
  }
}
