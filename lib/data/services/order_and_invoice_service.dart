// @source-mirror: src/services/pedidoServicio.js, src/services/facturaServicio.js
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response_parser.dart';
import '../../core/utils/image_url_resolver.dart';

// --- PEDIDOS (OrderService) ---

const Map<String, String> estadosPedido = {
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

const List<String> estadosSinFlujo = [
  'Cancelado',
  'Expirado',
  'Rechazado',
  'Revision_Pago',
];

const List<String> estadosConGuia = [
  'Enviado',
  'Entregado',
];

const List<String> transportadorasSugeridas = [
  'Servientrega',
  'Coordinadora',
  'Interrapidísimo',
  'Envía',
  'TCC',
  'Deprisa',
  '4-72',
];

const Map<String, String> estadosAlternos = {
  'pendiente': 'Pendiente_Pago',
  'pagado': 'Pagado',
  'preparacion': 'En_Preparacion',
  'en_preparacion': 'En_Preparacion',
  'enviado': 'Enviado',
  'entregado': 'Entregado',
  'cancelado': 'Cancelado',
  'revision_pago': 'Revision_Pago',
  'expirado': 'Expirado',
  'rechazado': 'Rechazado',
};

String normalizarEstadoPedido(dynamic valor) {
  if (valor == null) return 'Pendiente_Pago';
  final str = valor.toString().toLowerCase();
  return estadosAlternos[str] ?? valor.toString();
}

class OrderItemDetail {
  final int? id;
  final int? productoId;
  final int? varianteId;
  final String nombre;
  final String imagen;
  final String talla;
  final String sku;
  final int cantidad;
  final double precio;
  final double subtotal;

  const OrderItemDetail({
    this.id,
    this.productoId,
    this.varianteId,
    required this.nombre,
    required this.imagen,
    required this.talla,
    required this.sku,
    required this.cantidad,
    required this.precio,
    required this.subtotal,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> map) {
    final cantidad = JsonParser.toInt(map['cantidad']);
    final precio = JsonParser.toDouble(map['precio_unitario'] ?? map['precio']);

    final prodMap = map['producto'] is Map<String, dynamic> ? map['producto'] as Map<String, dynamic> : null;
    final varMap = map['variante'] is Map<String, dynamic> ? map['variante'] as Map<String, dynamic> : null;
    final varProdMap = varMap?['producto'] is Map<String, dynamic> ? varMap!['producto'] as Map<String, dynamic> : null;

    final rawImgs = prodMap?['imagenes'] ?? varProdMap?['imagenes'] ?? [];
    dynamic principalImg;
    if (rawImgs is List && rawImgs.isNotEmpty) {
      principalImg = rawImgs.firstWhere(
        (img) => img is Map && JsonParser.toBool(img['es_principal']),
        orElse: () => rawImgs.first,
      );
    }

    final nombre = JsonParser.toStr(
      varProdMap?['nombre'] ?? prodMap?['nombre'] ?? map['nombre_producto'],
      'Prenda',
    );

    return OrderItemDetail(
      id: map['id'] != null ? JsonParser.toInt(map['id']) : null,
      productoId: map['producto_id'] != null
          ? JsonParser.toInt(map['producto_id'])
          : (prodMap?['id_producto'] != null ? JsonParser.toInt(prodMap!['id_producto']) : null),
      varianteId: map['producto_variante_id'] != null
          ? JsonParser.toInt(map['producto_variante_id'])
          : (varMap?['id_variante'] != null ? JsonParser.toInt(varMap!['id_variante']) : null),
      nombre: nombre,
      imagen: ImageUrlResolver.resolve(principalImg ?? map['imagen']),
      talla: JsonParser.toStr(varMap?['talla'] ?? map['talla']),
      sku: JsonParser.toStr(varMap?['sku'] ?? map['sku']),
      cantidad: cantidad,
      precio: precio,
      subtotal: JsonParser.toDouble(map['subtotal'], cantidad * precio),
    );
  }
}

class OrderModel {
  final int id;
  final String referencia;
  final String estado;
  final double total;
  final double subtotal;
  final double envio;
  final String? fecha;
  final String? fechaPedido;
  final String clienteNombre;
  final String clienteCorreo;
  final String telefono;
  final String direccion;
  final String ciudad;
  final String departamento;
  final String metodoPago;
  final String notas;
  final String empresaTransportadora;
  final String numeroGuia;
  final int? facturaId;
  final List<OrderItemDetail> detalles;
  final Map<String, dynamic> original;

  const OrderModel({
    required this.id,
    required this.referencia,
    required this.estado,
    required this.total,
    required this.subtotal,
    required this.envio,
    this.fecha,
    this.fechaPedido,
    required this.clienteNombre,
    required this.clienteCorreo,
    required this.telefono,
    required this.direccion,
    required this.ciudad,
    required this.departamento,
    required this.metodoPago,
    required this.notas,
    required this.empresaTransportadora,
    required this.numeroGuia,
    this.facturaId,
    required this.detalles,
    required this.original,
  });

  factory OrderModel.fromJson(Map<String, dynamic> map) {
    final id = JsonParser.toInt(map['id'] ?? map['id_pedido']);
    final userMap = map['usuario'] is Map<String, dynamic>
        ? map['usuario'] as Map<String, dynamic>
        : (map['cliente'] is Map<String, dynamic>
            ? map['cliente'] as Map<String, dynamic>
            : (map['user'] is Map<String, dynamic> ? map['user'] as Map<String, dynamic> : {}));

    final rawDetalles = map['detalles'] ?? map['detalle_pedidos'] ?? map['detalles_pedido'] ?? map['items'];
    final List<OrderItemDetail> items = [];
    if (rawDetalles is List) {
      for (final d in rawDetalles) {
        if (d is Map<String, dynamic>) {
          items.add(OrderItemDetail.fromJson(d));
        }
      }
    }

    final facturaMap = map['factura'] is Map<String, dynamic> ? map['factura'] as Map<String, dynamic> : null;
    final rawFacturaId = facturaMap?['id'] ?? map['factura_id'];

    return OrderModel(
      id: id,
      referencia: JsonParser.toStr(
        map['referencia'] ?? map['referencia_pasarela'] ?? map['codigo'],
        'PED-$id',
      ),
      estado: normalizarEstadoPedido(map['estado']),
      total: JsonParser.toDouble(map['monto_total'] ?? map['total']),
      subtotal: JsonParser.toDouble(map['subtotal'] ?? map['monto_subtotal']),
      envio: JsonParser.toDouble(map['costo_envio'] ?? map['envio']),
      fecha: map['created_at']?.toString() ?? map['fecha_pedido']?.toString() ?? map['fecha']?.toString(),
      fechaPedido: map['fecha_pedido']?.toString() ?? map['created_at']?.toString(),
      clienteNombre: JsonParser.toStr(userMap['nombre'] ?? map['nombre_cliente'], 'Cliente'),
      clienteCorreo: JsonParser.toStr(userMap['correo'] ?? userMap['email']),
      telefono: JsonParser.toStr(map['telefono_contacto'] ?? userMap['telefono']),
      direccion: JsonParser.toStr(map['direccion_envio'] ?? userMap['direccion']),
      ciudad: JsonParser.toStr(map['ciudad_envio'] ?? userMap['ciudad']),
      departamento: JsonParser.toStr(map['departamento_envio'] ?? userMap['departamento']),
      metodoPago: JsonParser.toStr(map['metodo_pago']),
      notas: JsonParser.toStr(map['notas_cliente'] ?? map['notas']),
      empresaTransportadora: JsonParser.toStr(map['empresa_transportadora']),
      numeroGuia: JsonParser.toStr(map['numero_guia']),
      facturaId: rawFacturaId != null ? JsonParser.toInt(rawFacturaId) : null,
      detalles: items,
      original: map,
    );
  }
}

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

const List<String> extensionesCargaMasiva = ['xlsx', 'csv'];
const int tamanoMaximoCargaMb = 5;

const String plantillaCsvContenido = '''pedido_id,venta_id,fecha_emision,cliente_documento,notas
15,,2026-10-16,1020304050,Factura pedido online
,8,2026-10-16,,Venta de mostrador''';

class InvoiceItemDetail {
  final String descripcion;
  final String talla;
  final int cantidad;
  final double precio;
  final double subtotal;

  const InvoiceItemDetail({
    required this.descripcion,
    required this.talla,
    required this.cantidad,
    required this.precio,
    required this.subtotal,
  });

  factory InvoiceItemDetail.fromJson(Map<String, dynamic> map) {
    final cantidad = JsonParser.toInt(map['cantidad']);
    final precio = JsonParser.toDouble(map['precio_unitario'] ?? map['precio']);

    final varMap = map['variante'] is Map<String, dynamic> ? map['variante'] as Map<String, dynamic> : null;
    final prodMap = map['producto'] is Map<String, dynamic>
        ? map['producto'] as Map<String, dynamic>
        : (varMap?['producto'] is Map<String, dynamic> ? varMap!['producto'] as Map<String, dynamic> : null);

    final desc = JsonParser.toStr(
      map['descripcion'] ?? prodMap?['nombre'] ?? map['nombre_producto'],
      'Prenda',
    );

    return InvoiceItemDetail(
      descripcion: desc,
      talla: JsonParser.toStr(varMap?['talla'] ?? map['talla']),
      cantidad: cantidad,
      precio: precio,
      subtotal: JsonParser.toDouble(map['subtotal'], cantidad * precio),
    );
  }
}

class InvoiceModel {
  final int id;
  final String numero;
  final String? fecha;
  final String estado;
  final int? pedidoId;
  final int? ventaId;
  final String origen;
  final double subtotal;
  final double impuestos;
  final double descuento;
  final double total;
  final String metodoPago;
  final String notas;
  final String clienteNombre;
  final String clienteDocumento;
  final String clienteCorreo;
  final String clienteDireccion;
  final String clienteCiudad;
  final List<InvoiceItemDetail> detalles;
  final Map<String, dynamic> original;

  const InvoiceModel({
    required this.id,
    required this.numero,
    this.fecha,
    required this.estado,
    this.pedidoId,
    this.ventaId,
    required this.origen,
    required this.subtotal,
    required this.impuestos,
    required this.descuento,
    required this.total,
    required this.metodoPago,
    required this.notas,
    required this.clienteNombre,
    required this.clienteDocumento,
    required this.clienteCorreo,
    required this.clienteDireccion,
    required this.clienteCiudad,
    required this.detalles,
    required this.original,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> map) {
    final id = JsonParser.toInt(map['id'] ?? map['id_factura']);
    final pedido = map['pedido'] is Map<String, dynamic> ? map['pedido'] as Map<String, dynamic> : {};
    final venta = map['venta'] is Map<String, dynamic> ? map['venta'] as Map<String, dynamic> : {};
    final usuario = pedido['usuario'] is Map<String, dynamic>
        ? pedido['usuario'] as Map<String, dynamic>
        : (venta['cliente'] is Map<String, dynamic>
            ? venta['cliente'] as Map<String, dynamic>
            : (map['usuario'] is Map<String, dynamic> ? map['usuario'] as Map<String, dynamic> : {}));

    final rawDetalles = map['detalles'] ?? pedido['detalles'] ?? venta['detalles'] ?? [];
    final List<InvoiceItemDetail> items = [];
    if (rawDetalles is List) {
      for (final d in rawDetalles) {
        if (d is Map<String, dynamic>) {
          items.add(InvoiceItemDetail.fromJson(d));
        }
      }
    }

    final subtotal = JsonParser.toDouble(map['subtotal']);
    final impuestos = JsonParser.toDouble(map['impuestos'] ?? map['iva'] ?? map['valor_iva']);
    final descuento = JsonParser.toDouble(map['descuento']);
    final pedidoId = map['pedido_id'] != null ? JsonParser.toInt(map['pedido_id']) : null;
    final ventaId = map['venta_id'] != null ? JsonParser.toInt(map['venta_id']) : null;

    final origen = pedidoId != null ? 'pedido' : (ventaId != null ? 'venta' : 'manual');

    return InvoiceModel(
      id: id,
      numero: JsonParser.toStr(map['numero_factura'] ?? map['numero'] ?? map['consecutivo'], 'FAC-$id'),
      fecha: map['fecha_emision']?.toString() ?? map['created_at']?.toString(),
      estado: JsonParser.toStr(map['estado'], 'Emitida'),
      pedidoId: pedidoId,
      ventaId: ventaId,
      origen: origen,
      subtotal: subtotal,
      impuestos: impuestos,
      descuento: descuento,
      total: JsonParser.toDouble(map['total'] ?? map['monto_total'], subtotal + impuestos - descuento),
      metodoPago: JsonParser.toStr(map['metodo_pago'] ?? venta['medio_pago'] ?? pedido['metodo_pago']),
      notas: JsonParser.toStr(map['notas'] ?? map['observaciones']),
      clienteNombre: JsonParser.toStr(map['cliente_nombre'] ?? usuario['nombre'], 'Consumidor final'),
      clienteDocumento: JsonParser.toStr(map['cliente_documento'] ?? map['nit'] ?? usuario['documento']),
      clienteCorreo: JsonParser.toStr(map['cliente_correo'] ?? usuario['correo'] ?? usuario['email']),
      clienteDireccion: JsonParser.toStr(map['cliente_direccion'] ?? pedido['direccion_envio']),
      clienteCiudad: JsonParser.toStr(pedido['ciudad_envio']),
      detalles: items,
      original: map,
    );
  }
}

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
