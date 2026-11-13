// @source-mirror: src/views/publico/VistaContacto.vue, src/views/admin/VistaMensajesContacto.vue, app/Http/Controllers/api/ContactoController.php
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

class ContactService {
  static final ContactService _instance = ContactService._internal();
  static ContactService get instance => _instance;

  ContactService._internal();

  /// Información pública de la tienda física (dirección, teléfonos, horario, coordenadas)
  Future<Map<String, dynamic>> obtenerInformacion() async {
    try {
      final response = await ApiClient.instance.dio.get('/contacto');
      final data = ApiResponseParser.extractData(response);
      return data is Map<String, dynamic> ? data : {};
    } catch (_) {
      return {};
    }
  }

  /// Radicar mensaje o PQRS
  Future<Map<String, dynamic>> radicarMensaje(Map<String, dynamic> payload) async {
    final response = await ApiClient.instance.dio.post('/contacto', data: payload);
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : (response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : {});
  }

  /// Consultar estado de solicitud por radicado y correo
  Future<Map<String, dynamic>> consultarRadicado(String radicado, String correo) async {
    final response = await ApiClient.instance.dio.get(
      '/contacto/consulta',
      queryParameters: {
        'radicado': radicado.trim(),
        'correo': correo.trim(),
      },
    );
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : (response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : {});
  }

  /// Bandeja del personal administrativo (RE014)
  Future<Map<String, dynamic>> listarMensajes({
    int pagina = 1,
    String? estado,
    String? tipo,
    String? buscar,
  }) async {
    final params = <String, dynamic>{'page': pagina};
    if (estado != null && estado.isNotEmpty) params['estado'] = estado;
    if (tipo != null && tipo.isNotEmpty) params['tipo'] = tipo;
    if (buscar != null && buscar.trim().isNotEmpty) params['buscar'] = buscar.trim();

    final response = await ApiClient.instance.dio.get(
      '/mensajes-contacto',
      queryParameters: params,
    );

    final raw = response.data;
    List<Map<String, dynamic>> items = [];
    int totalPaginas = 1;
    int totalRegistros = 0;
    int nuevos = 0;

    if (raw is Map<String, dynamic>) {
      final meta = raw['meta'];
      if (meta is Map<String, dynamic>) {
        nuevos = JsonParser.toInt(meta['nuevos']);
      }

      final dataField = raw['data'];
      if (dataField is List) {
        items = dataField.whereType<Map<String, dynamic>>().toList();
        totalRegistros = items.length;
      } else if (dataField is Map<String, dynamic>) {
        final list = dataField['data'];
        if (list is List) {
          items = list.whereType<Map<String, dynamic>>().toList();
        }
        totalPaginas = JsonParser.toInt(dataField['last_page'], 1);
        totalRegistros = JsonParser.toInt(dataField['total'], items.length);
      }
    }

    return {
      'mensajes': items,
      'totalPaginas': totalPaginas,
      'totalRegistros': totalRegistros,
      'nuevos': nuevos,
    };
  }

  /// Marcar mensaje como leído o actualizar estado
  Future<void> cambiarEstado(int id, String nuevoEstado) async {
    await ApiClient.instance.dio.patch('/mensajes-contacto/$id', data: {
      'estado': nuevoEstado,
    });
  }

  /// Responder mensaje (envía correo al cliente y guarda historial)
  Future<Map<String, dynamic>> responderMensaje(int id, String mensaje) async {
    final response = await ApiClient.instance.dio.post(
      '/mensajes-contacto/$id/responder',
      data: {'mensaje': mensaje.trim()},
    );
    final data = ApiResponseParser.extractData(response);
    return data is Map<String, dynamic> ? data : (response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : {});
  }
}
