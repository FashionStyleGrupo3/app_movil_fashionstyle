// @source-mirror: src/services/pedidoServicio.js, src/services/facturaServicio.js
import 'package:dio/dio.dart';
import 'package:fashion_style_mobile/core/constants/invoice_constants.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/data/models/invoice/invoice_model.dart';
import 'package:fashion_style_mobile/data/models/order/order_model.dart';

class InvoiceService {
  static final InvoiceService _instance = InvoiceService._internal();
  static InvoiceService get instance => _instance;

  static const String plantillaCsvContenido = 'numero_factura,cliente,fecha,total,estado\n';

  InvoiceService._internal();

  static const String ruta = '/facturas';

  Future<PaginatedResponse<InvoiceModel>> listarFacturas({
    int pagina = 1,
    String buscar = '',
    int porPagina = 15,
  }) async {
    final params = <String, dynamic>{
      'page': pagina,
      'per_page': porPagina,
    };
    if (buscar.isNotEmpty) params['buscar'] = buscar;

    final response = await ApiClient.instance.dio.get(ruta, queryParameters: params);
    return ApiResponseParser.extractPaginated<InvoiceModel>(
      response,
      (map) => InvoiceModel.fromJson(map),
    );
  }

  Future<InvoiceModel> obtenerFactura(int id) async {
    final response = await ApiClient.instance.dio.get('$ruta/$id');
    final data = ApiResponseParser.extractData(response);
    return InvoiceModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<InvoiceModel> crearFactura({
    required String origen,
    required int referenciaId,
    String? fechaEmision,
    String? clienteDocumento,
    String? notas,
    String? metodoPago,
  }) async {
    final payload = {
      'pedido_id': origen == 'pedido' ? referenciaId : null,
      'venta_id': origen == 'venta' ? referenciaId : null,
      'fecha_emision': fechaEmision,
      'cliente_documento': clienteDocumento != null && clienteDocumento.trim().isNotEmpty
          ? clienteDocumento.trim()
          : null,
      'notas': notas != null && notas.trim().isNotEmpty ? notas.trim() : null,
    };

    final response = await ApiClient.instance.dio.post(ruta, data: payload);
    final data = ApiResponseParser.extractData(response);
    return InvoiceModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<InvoiceModel> autoFacturarPedido(
    dynamic pedido, {
    Map<String, dynamic>? transaccionWompi,
    String notasAdicionales = '',
  }) async {
    final int pedidoId;
    String doc = '';
    String? referencia;
    String? metodoPago;

    if (pedido is OrderModel) {
      pedidoId = pedido.id;
      referencia = pedido.referencia;
      metodoPago = pedido.metodoPago;
    } else if (pedido is Map<String, dynamic>) {
      pedidoId = JsonParser.toInt(pedido['id'] ?? pedido['id_pedido']);
      final cliente = pedido['cliente'] ?? pedido['usuario'] ?? {};
      if (cliente is Map) {
        doc = JsonParser.toStr(cliente['documento'] ?? cliente['numero_documento']);
      }
      referencia = pedido['referencia']?.toString();
      metodoPago = pedido['metodo_pago']?.toString();
    } else {
      pedidoId = JsonParser.toInt(pedido);
    }

    var notaAuto = 'Facturación automática pedido #$pedidoId';
    if (referencia != null && referencia.isNotEmpty) {
      notaAuto += ' · Ref: $referencia';
    }
    if (transaccionWompi != null && transaccionWompi['id'] != null) {
      final tid = transaccionWompi['id'];
      final mtype = transaccionWompi['payment_method_type'] ?? 'Aprobada';
      notaAuto += ' · Transacción Wompi: $tid ($mtype)';
    } else if (metodoPago != null && metodoPago.isNotEmpty) {
      notaAuto += ' · Pago: $metodoPago';
    }
    if (notasAdicionales.isNotEmpty) {
      notaAuto += ' | $notasAdicionales';
    }

    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    return crearFactura(
      origen: 'pedido',
      referenciaId: pedidoId,
      fechaEmision: hoy,
      clienteDocumento: doc.isNotEmpty ? doc : null,
      notas: notaAuto,
    );
  }

  String? validarArchivoCargaMasiva({
    required String fileName,
    required int sizeInBytes,
  }) {
    if (fileName.trim().isEmpty) return 'Selecciona un archivo.';
    final parts = fileName.split('.');
    final extension = parts.length > 1 ? parts.last.toLowerCase() : '';
    if (!extensionesCargaMasiva.contains(extension)) {
      return 'Formato no permitido. Solo se aceptan archivos .xlsx o .csv.';
    }
    if (sizeInBytes > tamanoMaximoCargaMb * 1024 * 1024) {
      return 'El archivo supera el límite de $tamanoMaximoCargaMb MB.';
    }
    return null;
  }

  Future<Map<String, dynamic>> cargarFacturasMasivo({
    required String filePath,
    required String fileName,
    void Function(int porcentaje)? alProgresar,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'archivo': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await ApiClient.instance.dio.post(
      '$ruta/carga-masiva',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
      onSendProgress: (sent, total) {
        if (alProgresar != null && total > 0) {
          alProgresar(((sent / total) * 100).round());
        }
      },
    );

    final raw = ApiResponseParser.extractData(response);
    final datos = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final errores = datos['errores'] ?? datos['errors'] ?? datos['fallidas'] ?? [];

    return {
      'importadas': JsonParser.toInt(datos['importadas'] ?? datos['creadas'] ?? datos['total_importadas']),
      'errores': errores is List ? errores : [],
      'mensaje': JsonParser.toStr(datos['mensaje'] ?? datos['message']),
    };
  }
}
