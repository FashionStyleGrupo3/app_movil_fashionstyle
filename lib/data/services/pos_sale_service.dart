// @source-mirror: src/services/ventaServicio.js, src/services/pagoServicio.js
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/data/models/pos/pos_sale_model.dart';
import 'package:fashion_style_mobile/data/models/pos/pos_sales_summary.dart';

class PosSaleService {
  static final PosSaleService _instance = PosSaleService._internal();
  static PosSaleService get instance => _instance;

  PosSaleService._internal();

  static const String ruta = '/ventas';

  Future<PaginatedResponse<PosSaleModel>> listarVentas({
    int pagina = 1,
    String medioPago = '',
    String estado = '',
    String buscar = '',
    int porPagina = 15,
  }) async {
    final params = <String, dynamic>{
      'page': pagina,
      'per_page': porPagina,
    };
    if (medioPago.isNotEmpty) params['medio_pago'] = medioPago;
    if (estado.isNotEmpty) params['estado'] = estado;
    if (buscar.isNotEmpty) params['buscar'] = buscar;

    final response = await ApiClient.instance.dio.get(ruta, queryParameters: params);
    return ApiResponseParser.extractPaginated<PosSaleModel>(
      response,
      (map) => PosSaleModel.fromJson(map),
    );
  }

  Future<PosSalesSummary> obtenerResumenVentas() async {
    final response = await ApiClient.instance.dio.get('$ruta/resumen');
    final data = ApiResponseParser.extractData(response);
    return PosSalesSummary.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<PosSaleModel> registrarVenta({
    required List<Map<String, dynamic>> items,
    String medioPago = 'efectivo',
    String notas = '',
    String clienteNombre = '',
    String clienteDocumento = '',
  }) async {
    final detalles = items.map((item) {
      return {
        'variante_id': JsonParser.toInt(item['varianteId'] ?? item['variante_id']),
        if (item['productoId'] != null || item['producto_id'] != null)
          'producto_id': JsonParser.toInt(item['productoId'] ?? item['producto_id']),
        'cantidad': JsonParser.toInt(item['cantidad'], 1),
        'precio_unitario': JsonParser.toDouble(item['precio'] ?? item['precio_unitario']),
      };
    }).toList();

    final payload = {
      'medio_pago': medioPago,
      'generar_factura': true,
      'notas': notas.trim().isNotEmpty ? notas.trim() : null,
      'observaciones': notas.trim().isNotEmpty ? notas.trim() : null,
      'cliente_nombre': clienteNombre.trim().isNotEmpty ? clienteNombre.trim() : null,
      'cliente_documento': clienteDocumento.trim().isNotEmpty ? clienteDocumento.trim() : null,
      'detalles': detalles,
      'items': detalles,
    };

    final response = await ApiClient.instance.dio.post(ruta, data: payload);
    final data = ApiResponseParser.extractData(response);
    return PosSaleModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<PosSaleModel> cancelarVenta(int id, [String motivo = '']) async {
    final response = await ApiClient.instance.dio.post(
      '$ruta/$id/cancelar',
      data: {
        'motivo': motivo.trim().isNotEmpty ? motivo.trim() : 'Cancelación desde panel administrativo',
      },
    );
    final data = ApiResponseParser.extractData(response);
    return PosSaleModel.fromJson(data is Map<String, dynamic> ? data : {});
  }
}

// --- CONTROL FINANCIERO Y DISPERSIÓN (PaymentConfigService) ---
