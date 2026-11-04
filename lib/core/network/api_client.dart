// @source-mirror: src/services/clienteApi.js
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'change_bus.dart';

final RegExp patronDatosSensibles = RegExp(
  r'(sqlstate|sql|database|query|exception|pdo|mysql|postgres|sqlite|connection:|host:|port:|trace|stack|constraint|foreign key|duplicate key|table|where|127\.0\.0\.1|localhost|3306|password_hash|secret|api_key|access_token|bearer|\b(SELECT|INSERT|UPDATE|DELETE|ALTER|DROP|FROM|LIMIT)\b)',
  caseSensitive: false,
);

const String mensajeServicioNoDisponible =
    'El servicio no está disponible temporalmente. Por favor, intenta de nuevo en unos momentos.';

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

          if (error.response?.statusCode == 401) {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('fs_token');
              await prefs.remove('fs_user');
              await prefs.remove('fs_roles');
            } catch (_) {}

            onUnauthorizedCallback?.call();
          }

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
    final limpio = texto.toString().trim();
    if (limpio.isEmpty || patronDatosSensibles.hasMatch(limpio) || limpio.length > 180) {
      return fallback;
    }
    return limpio;
  }

  static String obtenerMensajeError(
    dynamic error, [
    String fallback = 'No se pudo completar la operación. Verifica los datos e intenta nuevamente.',
  ]) {
    if (error is! DioException) {
      return sanitizarTextoError(error, fallback);
    }

    if (error.response == null) {
      return 'No se pudo conectar con el servidor. Verifica tu conexión e intenta nuevamente.';
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
          return textoValidacion;
        }
      }
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
}
