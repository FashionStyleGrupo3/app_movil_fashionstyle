// @source-mirror: src/services/ventaServicio.js, src/services/pagoServicio.js
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response_parser.dart';

// --- VENTAS POS (PosSaleService) ---

const Map<String, String> mediosPagoPos = {
  'efectivo': 'Efectivo',
  'tarjeta': 'Tarjeta',
  'transferencia': 'Transferencia / Nequi / Daviplata',
  'debito': 'Débito',
  'credito': 'Crédito',
};

class PosSaleDetail {
  final int? id;
  final int? varianteId;
  final String nombre;
  final String talla;
  final String sku;
  final int cantidad;
  final double precio;
  final double subtotal;

  const PosSaleDetail({
    this.id,
    this.varianteId,
    required this.nombre,
    required this.talla,
    required this.sku,
    required this.cantidad,
    required this.precio,
    required this.subtotal,
  });

  factory PosSaleDetail.fromJson(Map<String, dynamic> map) {
    final cantidad = JsonParser.toInt(map['cantidad']);
    final precio = JsonParser.toDouble(map['precio_unitario'] ?? map['precio']);

    final varMap = map['variante'] is Map<String, dynamic> ? map['variante'] as Map<String, dynamic> : null;
    final prodMap = map['producto'] is Map<String, dynamic>
        ? map['producto'] as Map<String, dynamic>
        : (varMap?['producto'] is Map<String, dynamic> ? varMap!['producto'] as Map<String, dynamic> : null);

    final nombre = JsonParser.toStr(
      varMap?['producto']?['nombre'] ?? prodMap?['nombre'] ?? map['nombre_producto'],
      'Prenda',
    );

    return PosSaleDetail(
      id: map['id'] != null ? JsonParser.toInt(map['id']) : null,
      varianteId: map['variante_id'] != null
          ? JsonParser.toInt(map['variante_id'])
          : (varMap?['id_variante'] != null ? JsonParser.toInt(varMap!['id_variante']) : null),
      nombre: nombre,
      talla: JsonParser.toStr(varMap?['talla'] ?? map['talla']),
      sku: JsonParser.toStr(varMap?['sku'] ?? map['sku']),
      cantidad: cantidad,
      precio: precio,
      subtotal: JsonParser.toDouble(map['subtotal'], cantidad * precio),
    );
  }
}

class PosSaleModel {
  final int id;
  final String codigo;
  final String? fecha;
  final String estado;
  final String medioPago;
  final double total;
  final String notas;
  final String clienteNombre;
  final String clienteDocumento;
  final int? facturaId;
  final String? facturaNumero;
  final double facturaSubtotal;
  final double facturaImpuesto;
  final List<PosSaleDetail> detalles;
  final Map<String, dynamic> original;

  const PosSaleModel({
    required this.id,
    required this.codigo,
    this.fecha,
    required this.estado,
    required this.medioPago,
    required this.total,
    required this.notas,
    required this.clienteNombre,
    required this.clienteDocumento,
    this.facturaId,
    this.facturaNumero,
    required this.facturaSubtotal,
    required this.facturaImpuesto,
    required this.detalles,
    required this.original,
  });

  factory PosSaleModel.fromJson(Map<String, dynamic> map) {
    final id = JsonParser.toInt(map['id'] ?? map['id_venta']);
    final usuario = map['usuario'] is Map<String, dynamic>
        ? map['usuario'] as Map<String, dynamic>
        : (map['vendedor'] is Map<String, dynamic>
            ? map['vendedor'] as Map<String, dynamic>
            : (map['cliente'] is Map<String, dynamic> ? map['cliente'] as Map<String, dynamic> : {}));

    final rawDetalles = map['detalles'] ?? map['detalle_ventas'] ?? map['items'] ?? [];
    final List<PosSaleDetail> items = [];
    if (rawDetalles is List) {
      for (final d in rawDetalles) {
        if (d is Map<String, dynamic>) {
          items.add(PosSaleDetail.fromJson(d));
        }
      }
    }

    final facturaMap = map['factura'] is Map<String, dynamic> ? map['factura'] as Map<String, dynamic> : null;

    return PosSaleModel(
      id: id,
      codigo: JsonParser.toStr(
        map['numero_comprobante'] ?? map['codigo'] ?? map['referencia'],
        'VTA-$id',
      ),
      fecha: map['created_at']?.toString() ?? map['fecha_venta']?.toString() ?? map['fecha']?.toString(),
      estado: JsonParser.toStr(map['estado'], 'Activa'),
      medioPago: JsonParser.toStr(map['medio_pago'] ?? map['metodo_pago'], 'efectivo'),
      total: JsonParser.toDouble(map['total'] ?? map['monto_total']),
      notas: JsonParser.toStr(map['notas'] ?? map['observaciones']),
      clienteNombre: JsonParser.toStr(map['cliente_nombre'] ?? usuario['nombre'], 'Consumidor final'),
      clienteDocumento: JsonParser.toStr(facturaMap?['cliente_documento'] ?? map['cliente_documento']),
      facturaId: facturaMap?['id'] != null
          ? JsonParser.toInt(facturaMap!['id'])
          : (map['factura_id'] != null ? JsonParser.toInt(map['factura_id']) : null),
      facturaNumero: facturaMap?['numero_factura']?.toString(),
      facturaSubtotal: JsonParser.toDouble(facturaMap?['subtotal']),
      facturaImpuesto: JsonParser.toDouble(facturaMap?['impuesto']),
      detalles: items,
      original: map,
    );
  }
}

class PosSalesSummary {
  final int ventasHoy;
  final double montoHoy;
  final double montoActivas;
  final Map<String, dynamic> porMedioPago;

  const PosSalesSummary({
    required this.ventasHoy,
    required this.montoHoy,
    required this.montoActivas,
    required this.porMedioPago,
  });

  factory PosSalesSummary.fromJson(Map<String, dynamic> map) {
    return PosSalesSummary(
      ventasHoy: JsonParser.toInt(map['ventas_hoy'] ?? map['total_ventas_hoy']),
      montoHoy: JsonParser.toDouble(map['monto_hoy'] ?? map['ingresos_hoy']),
      montoActivas: JsonParser.toDouble(map['monto_activas'] ?? map['total_activas']),
      porMedioPago: map['por_medio_pago'] is Map<String, dynamic>
          ? map['por_medio_pago'] as Map<String, dynamic>
          : (map['desglose_medios'] is Map<String, dynamic>
              ? map['desglose_medios'] as Map<String, dynamic>
              : (map['medios_pago'] is Map<String, dynamic> ? map['medios_pago'] as Map<String, dynamic> : {})),
    );
  }
}

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

const String claveStorageConfig = 'fs_config_pasarela_pagos';

class BankAccountConfig {
  final int id;
  final String banco;
  final String tipoCuenta;
  final String numeroCuenta;
  final String titular;
  final String concepto;
  final double porcentaje;
  final bool activa;
  final double? montoAsignado;

  String get tipo => tipoCuenta;

  const BankAccountConfig({
    required this.id,
    required this.banco,
    required this.tipoCuenta,
    required this.numeroCuenta,
    required this.titular,
    required this.concepto,
    required this.porcentaje,
    required this.activa,
    this.montoAsignado,
  });

  factory BankAccountConfig.fromJson(Map<String, dynamic> map) {
    return BankAccountConfig(
      id: JsonParser.toInt(map['id']),
      banco: JsonParser.toStr(map['banco']),
      tipoCuenta: JsonParser.toStr(map['tipo_cuenta'] ?? map['tipoCuenta']),
      numeroCuenta: JsonParser.toStr(map['numero_cuenta'] ?? map['numeroCuenta']),
      titular: JsonParser.toStr(map['titular']),
      concepto: JsonParser.toStr(map['concepto']),
      porcentaje: JsonParser.toDouble(map['porcentaje']),
      activa: map['activa'] == null ? true : JsonParser.toBool(map['activa']),
      montoAsignado: map['monto_asignado'] != null ? JsonParser.toDouble(map['monto_asignado']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'banco': banco,
      'tipo_cuenta': tipoCuenta,
      'numero_cuenta': numeroCuenta,
      'titular': titular,
      'concepto': concepto,
      'porcentaje': porcentaje,
      'activa': activa,
      if (montoAsignado != null) 'monto_asignado': montoAsignado,
    };
  }

  BankAccountConfig copyWith({double? montoAsignado}) {
    return BankAccountConfig(
      id: id,
      banco: banco,
      tipoCuenta: tipoCuenta,
      numeroCuenta: numeroCuenta,
      titular: titular,
      concepto: concepto,
      porcentaje: porcentaje,
      activa: activa,
      montoAsignado: montoAsignado ?? this.montoAsignado,
    );
  }
}

class ParallelPaymentControl {
  final double recaudoWompiOnline;
  final int cantidadPedidosPagados;
  final double recaudoPosMostrador;
  final int cantidadVentasPos;
  final double recaudoTotalConsolidado;
  final int facturasEmitidas;
  final List<dynamic> transacciones;

  const ParallelPaymentControl({
    required this.recaudoWompiOnline,
    required this.cantidadPedidosPagados,
    required this.recaudoPosMostrador,
    required this.cantidadVentasPos,
    required this.recaudoTotalConsolidado,
    required this.facturasEmitidas,
    required this.transacciones,
  });

  factory ParallelPaymentControl.fromJson(Map<String, dynamic> map) {
    return ParallelPaymentControl(
      recaudoWompiOnline: JsonParser.toDouble(map['recaudo_wompi_online']),
      cantidadPedidosPagados: JsonParser.toInt(map['cantidad_pedidos_pagados']),
      recaudoPosMostrador: JsonParser.toDouble(map['recaudo_pos_mostrador']),
      cantidadVentasPos: JsonParser.toInt(map['cantidad_ventas_pos']),
      recaudoTotalConsolidado: JsonParser.toDouble(map['recaudo_total_consolidado']),
      facturasEmitidas: JsonParser.toInt(map['facturas_emitidas']),
      transacciones: map['transacciones'] is List ? map['transacciones'] as List : [],
    );
  }
}

class PaymentConfigService {
  static final PaymentConfigService _instance = PaymentConfigService._internal();
  static PaymentConfigService get instance => _instance;

  PaymentConfigService._internal();

  static const List<Map<String, dynamic>> cuentasPredeterminadas = [
    {
      'id': 1,
      'banco': 'Bancolombia',
      'tipo_cuenta': 'Ahorros',
      'numero_cuenta': '245-891024-11',
      'titular': 'Taller de confección & Operarios',
      'concepto': 'Mano de Obra y confección Textil',
      'porcentaje': 60.0,
      'activa': true,
    },
    {
      'id': 2,
      'banco': 'Bancolombia',
      'tipo_cuenta': 'Corriente',
      'numero_cuenta': '031-458920-55',
      'titular': 'FashionStyle S.A.S.',
      'concepto': 'Comercializacion y Operacion',
      'porcentaje': 25.0,
      'activa': true,
    },
    {
      'id': 3,
      'banco': 'Davivienda',
      'tipo_cuenta': 'Ahorros',
      'numero_cuenta': '008-921478-03',
      'titular': 'Fondo de Materia Prima e Insumos',
      'concepto': 'reposicion de Telas y Fornituras',
      'porcentaje': 15.0,
      'activa': true,
    },
  ];

  Future<Map<String, dynamic>> obtenerConfiguracionPasarela() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(claveStorageConfig);
    if (guardado == null) {
      return {
        'moneda': 'COP',
        'cuentas_bancarias': cuentasPredeterminadas.map((e) => BankAccountConfig.fromJson(e)).toList(),
      };
    }

    try {
      final parsed = jsonDecode(guardado) as Map<String, dynamic>;
      final rawCuentas = parsed['cuentas_bancarias'];
      List<BankAccountConfig> cuentas = [];
      if (rawCuentas is List) {
        cuentas = rawCuentas.whereType<Map<String, dynamic>>().map((e) => BankAccountConfig.fromJson(e)).toList();
      } else {
        cuentas = cuentasPredeterminadas.map((e) => BankAccountConfig.fromJson(e)).toList();
      }

      return {
        'moneda': JsonParser.toStr(parsed['moneda'], 'COP'),
        'cuentas_bancarias': cuentas,
      };
    } catch (_) {
      return {
        'moneda': 'COP',
        'cuentas_bancarias': cuentasPredeterminadas.map((e) => BankAccountConfig.fromJson(e)).toList(),
      };
    }
  }

  Future<void> guardarConfiguracionPasarela({
    String moneda = 'COP',
    required List<BankAccountConfig> cuentasBancarias,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'moneda': moneda,
      'cuentas_bancarias': cuentasBancarias.map((c) => c.toJson()).toList(),
    };
    await prefs.setString(claveStorageConfig, jsonEncode(map));
  }

  Future<List<BankAccountConfig>> obtenerCuentasDispersion() async {
    final conf = await obtenerConfiguracionPasarela();
    return (conf['cuentas_bancarias'] as List<BankAccountConfig>?) ?? [];
  }

  Map<String, dynamic> validarPorcentajesDispersion(List<BankAccountConfig> cuentas) {
    final total = cuentas.where((c) => c.activa).fold<double>(0.0, (acc, c) => acc + c.porcentaje);
    final valido = (total - 100.0).abs() < 0.01;
    return {
      'valido': valido,
      'mensaje': valido
          ? 'Válido'
          : 'La suma de porcentajes de cuentas activas debe ser exactamente 100% (actual: ${total.toStringAsFixed(1)}%)',
    };
  }

  List<BankAccountConfig> calcularDispersionFondos(
    double montoTotal,
    List<BankAccountConfig> cuentas,
  ) {
    final activas = cuentas.where((c) => c.activa).toList();
    return activas.map((c) {
      final valorAsignado = ((montoTotal * c.porcentaje) / 100).roundToDouble();
      return c.copyWith(montoAsignado: valorAsignado);
    }).toList();
  }

  Future<ParallelPaymentControl> obtenerControlParaleloPagos() async {
    final response = await ApiClient.instance.dio.get('/pagos/control-paralelo');
    final data = ApiResponseParser.extractData(response);
    return ParallelPaymentControl.fromJson(data is Map<String, dynamic> ? data : {});
  }
}
