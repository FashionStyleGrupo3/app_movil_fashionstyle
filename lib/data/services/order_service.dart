// @source-mirror: src/services/pedidoServicio.js, src/services/facturaServicio.js
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/data/models/order/order_model.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  static OrderService get instance => _instance;

  static const Map<String, String> estadosPedido = {
    'Pendiente_Pago': 'Pendiente de pago',
    'Pagado': 'Pagado',
    'En_Preparacion': 'En preparación',
    'Enviado': 'Enviado',
    'Entregado': 'Entregado',
    'Cancelado': 'Cancelado',
    'Revision_Pago': 'Pago en revisión',
    'Expirado': 'Expirado',
    'Rechazado': 'Pago rechazado',
  };

  static const List<String> transportadorasSugeridas = [
    'Coordinadora Mercantil',
    'Envia',
    'Servientrega',
    'Interrapidísimo',
    'TCC',
    'Deprisa',
  ];

  OrderService._internal();

  static const String ruta = '/pedidos';

  Future<PaginatedResponse<OrderModel>> listarPedidos({
    int pagina = 1,
    String estado = '',
    String buscar = '',
    int porPagina = 15,
  }) async {
    final params = <String, dynamic>{
      'page': pagina,
      'per_page': porPagina,
    };
    if (estado.isNotEmpty) params['estado'] = estado;
    if (buscar.isNotEmpty) params['buscar'] = buscar;

    final response = await ApiClient.instance.dio.get(ruta, queryParameters: params);
    return ApiResponseParser.extractPaginated<OrderModel>(
      response,
      (map) => OrderModel.fromJson(map),
    );
  }

  Future<OrderModel> obtenerPedido(int id) async {
    final response = await ApiClient.instance.dio.get('$ruta/$id');
    final data = ApiResponseParser.extractData(response);
    return OrderModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<OrderModel> actualizarDespacho(
    int id, {
    required String estado,
    String? empresaTransportadora,
    String? transportadora,
    String? numeroGuia,
    String? notas,
  }) async {
    final carrier = transportadora ?? empresaTransportadora;
    final response = await ApiClient.instance.dio.put(
      '$ruta/$id',
      data: {
        'estado': estado,
        'empresa_transportadora': carrier != null && carrier.trim().isNotEmpty
            ? carrier.trim()
            : null,
        'numero_guia': numeroGuia != null && numeroGuia.trim().isNotEmpty
            ? numeroGuia.trim()
            : null,
        if (notas != null && notas.trim().isNotEmpty) 'notas': notas.trim(),
      },
    );
    final data = ApiResponseParser.extractData(response);
    return OrderModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<OrderModel> actualizarEnvio(
    int id, {
    required String estado,
    String? transportadora,
    String? numeroGuia,
    String? notas,
  }) async => actualizarDespacho(
    id,
    estado: estado,
    empresaTransportadora: transportadora,
    numeroGuia: numeroGuia,
  );
}

// --- FACTURAS (InvoiceService) ---
