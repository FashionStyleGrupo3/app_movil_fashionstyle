// @source-mirror: src/services/usuarioServicio.js, src/services/seguridadServicio.js, src/utils/auditoriaTexto.js
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  static SecurityService get instance => _instance;

  SecurityService._internal();

  List<Map<String, dynamic>> _extraerLista(dynamic respuesta) {
    final datos = ApiResponseParser.extractData(respuesta);
    if (datos is List) {
      return datos.whereType<Map<String, dynamic>>().toList();
    }
    if (datos is Map<String, dynamic> && datos['data'] is List) {
      return (datos['data'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> obtenerClientes() async {
    final response = await ApiClient.instance.dio.get('/clientes');
    return _extraerLista(response);
  }

  Future<Map<String, dynamic>> actualizarCliente(int id, Map<String, dynamic> datos) async {
    final response = await ApiClient.instance.dio.put('/clientes/$id', data: datos);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    final response = await ApiClient.instance.dio.get('/usuarios');
    return _extraerLista(response);
  }

  Future<Map<String, dynamic>> crearUsuario(Map<String, dynamic> datos) async {
    final response = await ApiClient.instance.dio.post('/usuarios', data: datos);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> actualizarUsuario(int id, Map<String, dynamic> datos) async {
    final response = await ApiClient.instance.dio.put('/usuarios/$id', data: datos);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> asignarRolUsuario(int id, String rol) async {
    final response = await ApiClient.instance.dio.post(
      '/usuarios/$id/asignar-rol',
      data: {'rol': rol},
    );
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : {};
  }

  Future<PaginatedResponse<Map<String, dynamic>>> obtenerAuditorias([
    Map<String, dynamic>? filtros,
  ]) async {
    final response = await ApiClient.instance.dio.get(
      '/auditorias',
      queryParameters: filtros,
    );
    return ApiResponseParser.extractPaginated<Map<String, dynamic>>(
      response,
      (map) => map,
    );
  }
}

// --- FORMATEADOR DE BITÁCORA (AuditTextFormatter) ---
