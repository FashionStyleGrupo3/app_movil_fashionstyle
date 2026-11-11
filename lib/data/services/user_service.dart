// @source-mirror: src/services/usuarioServicio.js, src/services/seguridadServicio.js, src/utils/auditoriaTexto.js
import 'package:dio/dio.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  static UserService get instance => _instance;

  UserService._internal();

  Future<Map<String, dynamic>> obtenerPerfilActual() async {
    final response = await ApiClient.instance.dio.get('/me');
    final datos = ApiResponseParser.extractData(response);
    if (datos is Map<String, dynamic>) {
      final user = datos['user'] ?? datos['usuario'];
      if (user is Map<String, dynamic>) return user;
      return datos;
    }
    return {};
  }

  Future<Map<String, dynamic>> actualizarPerfil(Map<String, dynamic> datos) async {
    final response = await ApiClient.instance.dio.put('/me', data: datos);
    final cuerpo = ApiResponseParser.extractData(response);
    if (cuerpo is Map<String, dynamic>) {
      final user = cuerpo['user'] ?? cuerpo['usuario'];
      if (user is Map<String, dynamic>) return user;
      return cuerpo;
    }
    return {};
  }

  Future<Map<String, dynamic>> actualizarContrasena({
    required String passwordActual,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await ApiClient.instance.dio.put(
      '/me/password',
      data: {
        'password_actual': passwordActual,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> solicitarCambioCorreo(String correoNuevo) async {
    final response = await ApiClient.instance.dio.post(
      '/me/email-change/request',
      data: {'correo_nuevo': correoNuevo},
    );
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> confirmarCambioCorreo(String codigo) async {
    final response = await ApiClient.instance.dio.post(
      '/me/email-change/confirm',
      data: {'codigo': codigo},
    );
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> subirFotoPerfil(String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'foto': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await ApiClient.instance.dio.post(
      '/me/foto',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );

    final cuerpo = ApiResponseParser.extractData(response);
    if (cuerpo is Map<String, dynamic>) {
      final user = cuerpo['user'] ?? cuerpo['usuario'];
      if (user is Map<String, dynamic>) return user;
      return cuerpo;
    }
    return {};
  }

  Future<Map<String, dynamic>> usarFotoDeGoogle(String credential) async {
    final response = await ApiClient.instance.dio.post(
      '/me/foto/google',
      data: {'credential': credential},
    );
    final cuerpo = ApiResponseParser.extractData(response);
    if (cuerpo is Map<String, dynamic>) {
      final user = cuerpo['user'] ?? cuerpo['usuario'];
      if (user is Map<String, dynamic>) return user;
      return cuerpo;
    }
    return {};
  }

  Future<Map<String, dynamic>> quitarFotoPerfil() async {
    final response = await ApiClient.instance.dio.delete('/me/foto');
    final cuerpo = ApiResponseParser.extractData(response);
    if (cuerpo is Map<String, dynamic>) {
      final user = cuerpo['user'] ?? cuerpo['usuario'];
      if (user is Map<String, dynamic>) return user;
      return cuerpo;
    }
    return {};
  }
}

// --- SERVICIO DE SEGURIDAD Y CLIENTES (SecurityService) ---
