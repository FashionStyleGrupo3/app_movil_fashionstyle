// @source-mirror: src/services/ventaServicio.js, src/services/pagoServicio.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/data/models/pos/pos_sale_detail.dart';

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

  String get usuarioNombre => original['usuario']?['nombre']?.toString() ?? original['vendedor']?['nombre']?.toString() ?? 'Cajero';

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
